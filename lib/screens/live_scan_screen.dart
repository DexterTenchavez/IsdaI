import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/classifier_service.dart';

class LiveScanScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const LiveScanScreen({super.key, this.onClose});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  CameraController? _controller;
  final ClassifierService _classifier = ClassifierService();

  Timer? _throttleTimer;

  String _currentLabel = '';
  double _currentConfidence = 0.0;

  bool _isProcessing = false;
  bool _canProcess = false;

  @override
  void initState() {
    super.initState();
    _startLiveDetection();
  }

  Future<void> _startLiveDetection() async {
    await _classifier.loadModel();

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _controller!.initialize();

    if (mounted) {
      setState(() {});
      _controller!.startImageStream(_onFrame);
      _throttleTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) {
        setState(() => _canProcess = true);
      });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_canProcess || _isProcessing) return;

    setState(() {
      _canProcess = false;
      _isProcessing = true;
    });

    final result = await _classifier.classifyCameraImage(image);

    if (result != null && mounted) {
      setState(() {
        _currentLabel = result['label'];
        _currentConfidence = result['confidence'];
      });
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  void _handleClose() {
    _throttleTimer?.cancel();
    _controller?.stopImageStream();
    if (widget.onClose != null)
      widget.onClose!();
    else
      Navigator.pop(context);
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _controller?.stopImageStream();
    _controller?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Colors based on result
    final isFresh = _currentLabel == 'Fresh';
    final boxColor = isFresh
        ? const Color(0xFF00E676) // Bright Green
        : (_currentLabel == 'Stale'
              ? const Color(0xFFFF1744)
              : Colors.transparent); // Bright Red

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Live Camera Preview
            Positioned.fill(child: CameraPreview(_controller!)),

            // The Dynamic Object Detection Box (Center of screen)
            if (_currentLabel.isNotEmpty)
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: boxColor, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Label tag (Top Left)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: boxColor,
                          child: Text(
                            '$_currentLabel ${(_currentConfidence * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Static White Framing Guide (Always visible)
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    _corner(Alignment.topLeft),
                    _corner(Alignment.topRight),
                    _corner(Alignment.bottomLeft),
                    _corner(Alignment.bottomRight),
                  ],
                ),
              ),
            ),

            // Top Bar: Close button + LIVE indicator
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleIconButton(Icons.close_rounded, _handleClose),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _circleIconButton(Icons.flash_off_rounded, () {}),
                ],
              ),
            ),

            // Instruction Text
            const Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Text(
                'Keep the fish inside the frame.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            // Stop Detection Button
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _handleClose,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop Detection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
