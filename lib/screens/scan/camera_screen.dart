import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../data/fish_species_data.dart';
import '../../theme/app_theme.dart';
import '../../services/language/app_language.dart';
import '../../services/ai/classifier_service.dart';
import '../../widgets/coach_tour.dart';
import 'result_screen.dart';

/// Sheet value that means "let the model guess the species".
const String _kAuto = '__auto__';

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
  bool _flashOn = false;

  // Targets for the first-time tour.
  final GlobalKey _frameKey = GlobalKey();
  final GlobalKey _speciesKey = GlobalKey();
  final GlobalKey _flashKey = GlobalKey();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _shutterKey = GlobalKey();

  /// Species chosen by the user (SRS FR-08).
  /// null = Auto (the model's own guess is used).
  String? _species;

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
    // Start with the flash off
    try {
      await _controller!.setFlashMode(FlashMode.off);
    } catch (_) {}
    if (mounted) setState(() {});

    // The controls only exist once the camera is ready, so the first-time
    // tour starts here.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
  }

  void _startTour() {
    if (!mounted) return;
    CoachTour.showOnce(
      context,
      owner: this,
      id: 'camera',
      steps: [
        CoachStep(
          target: _frameKey,
          titleKey: 'tour_cam_frame_t',
          bodyKey: 'tour_cam_frame_b',
        ),
        CoachStep(
          target: _speciesKey,
          titleKey: 'tour_cam_species_t',
          bodyKey: 'tour_cam_species_b',
        ),
        CoachStep(
          target: _flashKey,
          titleKey: 'tour_cam_flash_t',
          bodyKey: 'tour_cam_flash_b',
          circle: true,
        ),
        CoachStep(
          target: _galleryKey,
          titleKey: 'tour_cam_gallery_t',
          bodyKey: 'tour_cam_gallery_b',
          circle: true,
        ),
        CoachStep(
          target: _shutterKey,
          titleKey: 'tour_cam_shutter_t',
          bodyKey: 'tour_cam_shutter_b',
          circle: true,
        ),
      ],
    );
  }

  /// Shows a snackbar. [key] is a translation key; the text is translated
  /// here so it always matches the current language.
  void _showMessage(String key, {Map<String, String>? args}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(key, args: args)),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// Flash works as a torch: it stays on while you frame the fish and
  /// is still lit when the photo is taken.
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final next = !_flashOn;
    try {
      await _controller!.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (e) {
      print('Flash error: $e');
      _showMessage('cam_flash_na');
    }
  }

  Future<void> _analyzeFile(XFile file) async {
    await _modelFuture;
    if (!mounted) return;

    if (!_classifier.isModelLoaded) {
      _showMessage(
        'cam_model_fail',
        args: {'error': _classifier.loadError ?? context.tr('cam_unknown')},
      );
      return;
    }

    final bytes = await file.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _showMessage('cam_read_fail');
      return;
    }

    final img.Image upright = img.bakeOrientation(decoded);
    final result = await _classifier.classifyImage(upright);

    if (!mounted) return;
    if (result != null) {
      // If the user picked a species, use it. On Auto, keep the model's guess.
      final finalResult = _species == null
          ? result
          : result.checkPickedSpecies(_species!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(result: finalResult, imagePath: file.path),
        ),
      );
    } else {
      _showMessage('cam_analyze_fail');
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
      _showMessage('cam_wrong', args: {'error': '$e'});
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
      _showMessage('cam_wrong', args: {'error': '$e'});
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.resumePreview();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    CoachTour.dismiss(owner: this);
    _controller?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Species picker (SRS FR-08): pill button + bottom sheet. Default = Auto.
  // ==========================================================================

  /// The pill at the top of the camera. Tap it to open the sheet.
  Widget _speciesButton(BuildContext context) {
    final picked = _species != null;
    final label =
        '${context.tr('species_label')}: ${_species ?? context.tr('Auto')}';

    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: StadiumBorder(
        side: BorderSide(
          color: picked
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.25),
          width: picked ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _openSpeciesSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                picked ? Icons.set_meal_rounded : Icons.auto_awesome_rounded,
                color: picked ? AppColors.accent : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet with Auto + the six species.
  Future<void> _openSpeciesSheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      builder: (sheetContext) {
        final pal = sheetContext.pal;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: pal.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    children: [
                      _sheetTile(
                        sheetContext,
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        title: sheetContext.tr('Auto'),
                        subtitle: sheetContext.tr('Species Auto Hint'),
                        selected: _species == null,
                        onTap: () => Navigator.pop(sheetContext, _kAuto),
                      ),
                      for (final s in supportedSpecies)
                        _sheetTile(
                          sheetContext,
                          leading: _speciesThumb(pal, s),
                          title: s.name,
                          subtitle: s.englishName,
                          selected: _species == s.name,
                          onTap: () => Navigator.pop(sheetContext, s.name),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // null = the sheet was dismissed without a choice, so keep what we had.
    if (picked == null || !mounted) return;
    setState(() => _species = picked == _kAuto ? null : picked);
  }

  Widget _speciesThumb(AppPalette pal, FishSpecies s) {
    const size = 48.0;
    final fallback = Container(
      width: size,
      height: size,
      color: pal.link.withValues(alpha: 0.12),
      child: Icon(Icons.set_meal_rounded, color: pal.link),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: s.imageAsset == null
          ? fallback
          : Image.asset(
              s.imageAsset!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: 150, // small copy in memory, not the full photo
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }

  Widget _sheetTile(
    BuildContext context, {
    required Widget leading,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.10)
            : pal.link.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: selected
              ? const BorderSide(color: AppColors.accent, width: 1.6)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: pal.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: pal.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
                key: _frameKey,
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
                  KeyedSubtree(
                    key: _flashKey,
                    child: _circleIconButton(
                      _flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      _toggleFlash,
                      active: _flashOn,
                    ),
                  ),
                ],
              ),
            ),

            // Species button (SRS FR-08): opens the bottom sheet, Auto default
            Positioned(
              top: 68,
              left: 0,
              right: 0,
              child: Center(
                child: KeyedSubtree(
                  key: _speciesKey,
                  child: _speciesButton(context),
                ),
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
                  child: Text(
                    context.tr('cam_hint'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  KeyedSubtree(
                    key: _galleryKey,
                    child: _circleIconButton(
                      Icons.photo_library_rounded,
                      _pickFromGallery,
                    ),
                  ),
                  GestureDetector(
                    key: _shutterKey,
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
                  // Empty spacer (same size as a button) keeps the shutter
                  // centered now that the camera switch button is removed.
                  const SizedBox(width: 46, height: 46),
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

  Widget _circleIconButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
