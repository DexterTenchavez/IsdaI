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

  String _currentLabel = 'Detecting...';
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
      // Start the image stream
      _controller!.startImageStream(_onFrame);

      // Throttle to 500ms
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

    final isFresh = _currentLabel == 'Fresh';
    final boxColor = isFresh
        ? AppColors.success
        : (_currentLabel == 'Stale' ? AppColors.danger : Colors.grey);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),
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
            if (_currentLabel != 'Detecting...')
              Positioned(
                bottom: 100,
                left: 40,
                right: 40,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: boxColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: boxColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confidence: ${(_currentConfidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                ? const BorderSide(color: AppColors.primaryLight, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.primaryLight, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.primaryLight, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.primaryLight, width: 4)
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
