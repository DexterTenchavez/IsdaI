import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/classifier_service.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const CameraScreen({super.key, this.onClose});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final ClassifierService _classifier = ClassifierService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  late final Future<void> _modelFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _modelFuture = _classifier.loadModel();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
  }

  Future<void> _analyzeFile(XFile file) async {
    await _modelFuture;

    if (!_classifier.isModelLoaded) {
      _showMessage(
        'AI model failed to load: ${_classifier.loadError ?? "unknown error"}',
      );
      return;
    }

    final bytes = await file.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _showMessage('Could not read that image.');
      return;
    }

    final img.Image upright = img.bakeOrientation(decoded);
    final result = await _classifier.classifyImage(upright);

    if (!mounted) return;
    if (result != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result, imagePath: file.path),
        ),
      );
    } else {
      _showMessage('Failed to analyze image.');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _controller!.takePicture();
      await _analyzeFile(file);
    } catch (e, st) {
      print('Take picture error: $e\n$st');
      _showMessage('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    try {
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.pausePreview();
      }

      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);

      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.resumePreview();
      }

      if (file == null) return;

      if (mounted) setState(() => _isProcessing = true);
      await _analyzeFile(file);
    } catch (e, st) {
      print('Gallery error: $e\n$st');
      _showMessage('Something went wrong: $e');
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.resumePreview();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
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
                  _circleIconButton(Icons.close_rounded, () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else {
                      Navigator.pop(context);
                    }
                  }),
                  _circleIconButton(Icons.flash_off_rounded, () {}),
                ],
              ),
            ),
            Positioned(
              bottom: 124,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'One fish at a time  •  show the eye or gills',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _circleIconButton(
                    Icons.photo_library_rounded,
                    _pickFromGallery,
                  ),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 76,
                      width: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Container(
                                height: 60,
                                width: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                      ),
                    ),
                  ),
                  _circleIconButton(Icons.cameraswitch_rounded, () {}),
                ],
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
