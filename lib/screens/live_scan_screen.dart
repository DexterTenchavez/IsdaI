import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../theme/app_theme.dart';

// ====== CHANGE COLORS HERE ======
const Color kFreshColor = Color(0xFF22C55E); // green
const Color kStaleColor = Color(0xFFEF4444); // red
// ================================

/// Fresh = green, Stale = red.
/// Uses the class name first (Fresh_Fish / Stale_Fish),
/// falls back to class index (0 = Fresh, 1 = Stale).
bool isFreshResult(YOLOResult r) {
  final name = r.className.toLowerCase();
  if (name.contains('stale')) return false;
  if (name.contains('fresh')) return true;
  return r.classIndex == 0;
}

class LiveScanScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const LiveScanScreen({super.key, this.onClose});

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  /// Width / height of the camera frame as shown in portrait.
  /// If the boxes look shifted or stretched, try 9 / 16 or 4 / 3 here.
  static const double _cameraAspect = 3 / 4;

  final YOLOViewController _controller = YOLOViewController();

  // Latest detections, drawn by our own painter
  final ValueNotifier<List<YOLOResult>> _detections =
      ValueNotifier<List<YOLOResult>>(const []);

  double _threshold = 0.45; // raise to reduce clutter, lower to detect more
  bool _torchOn = false;
  int _frames = 0;
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    _setupWhenReady();
  }

  /// The native view needs a moment to start, so retry until the controller
  /// is initialized (max ~5 seconds).
  void _setupWhenReady() {
    int tries = 0;
    _initTimer = Timer.periodic(const Duration(milliseconds: 500), (t) async {
      tries++;
      if (_controller.isInitialized) {
        t.cancel();
        try {
          // hide the plugin's own (blue, non-recolorable) boxes; we draw ours
          await _controller.setShowOverlays(false);
          await _controller.setConfidenceThreshold(_threshold);
        } catch (e) {
          debugPrint('Setup error: $e');
        }
      } else if (tries >= 10) {
        t.cancel();
        debugPrint('YOLOViewController never initialized');
      }
    });
  }

  Future<void> _applyThreshold(double value) async {
    try {
      await _controller.setConfidenceThreshold(value);
    } catch (e) {
      debugPrint('Failed to set threshold: $e');
    }
  }

  void _onResults(List<YOLOResult> results) {
    _frames++;
    _detections.value = List<YOLOResult>.of(results);
    if (results.isNotEmpty) {
      final best = _best(results);
      debugPrint(
        'DETECT: ${results.length} • ${best.className} '
        '${(best.confidence * 100).toStringAsFixed(0)}%',
      );
    }
  }

  YOLOResult _best(List<YOLOResult> results) {
    YOLOResult best = results.first;
    for (final r in results) {
      if (r.confidence > best.confidence) best = r;
    }
    return best;
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = _controller.isTorchEnabled);
    } catch (e) {
      debugPrint('Torch error: $e');
    }
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    _detections.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera + inference (native)
            Positioned.fill(
              child: YOLOView(
                controller: _controller,
                modelPath: 'assets/models/yolo_fish_detector.tflite',
                task: YOLOTask.detect,
                useGpu: false,
                onResult: _onResults,
              ),
            ),

            // Our own green/red boxes drawn on top
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<List<YOLOResult>>(
                  valueListenable: _detections,
                  builder: (_, results, __) =>
                      CustomPaint(painter: _BoxPainter(results, _cameraAspect)),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleIconButton(Icons.close_rounded, _close),
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
                  _circleIconButton(
                    _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    _toggleTorch,
                  ),
                ],
              ),
            ),

            // Status panel + confidence slider
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<List<YOLOResult>>(
                      valueListenable: _detections,
                      builder: (_, results, __) {
                        if (results.isEmpty) {
                          return Text(
                            'No detections (frames: $_frames)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        final best = _best(results);
                        final fresh = isFreshResult(best);
                        return Text(
                          '${results.length} found • '
                          '${fresh ? 'Fresh' : 'Stale'} '
                          '${(best.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: fresh ? kFreshColor : kStaleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        const Text(
                          'Min conf',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Expanded(
                          child: Slider(
                            value: _threshold,
                            min: 0.05,
                            max: 0.9,
                            divisions: 17,
                            label: _threshold.toStringAsFixed(2),
                            onChanged: (v) => setState(() => _threshold = v),
                            onChangeEnd: _applyThreshold,
                          ),
                        ),
                        Text(
                          _threshold.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stop button
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _close,
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

/// Draws bounding boxes + labels. Fresh = green, Stale = red.
class _BoxPainter extends CustomPainter {
  final List<YOLOResult> results;
  final double cameraAspect; // width / height of the camera frame

  _BoxPainter(this.results, this.cameraAspect);

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    // The camera preview fills the screen (aspect-fill), so scale the
    // frame up to cover the view and center it (extra part is cropped).
    final viewAspect = size.width / size.height;
    late double dispW;
    late double dispH;
    if (viewAspect > cameraAspect) {
      dispW = size.width;
      dispH = size.width / cameraAspect;
    } else {
      dispH = size.height;
      dispW = size.height * cameraAspect;
    }
    final offX = (size.width - dispW) / 2;
    final offY = (size.height - dispH) / 2;

    for (final r in results) {
      final n = r.normalizedBox; // values 0..1
      final rect = Rect.fromLTRB(
        offX + n.left * dispW,
        offY + n.top * dispH,
        offX + n.right * dispW,
        offY + n.bottom * dispH,
      );

      final fresh = isFreshResult(r);
      final color = fresh ? kFreshColor : kStaleColor;

      // Box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        boxPaint,
      );

      // Label
      final label =
          '${fresh ? 'Fresh' : 'Stale'} ${(r.confidence * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      const padH = 6.0;
      const padV = 3.0;
      final labelW = tp.width + padH * 2;
      final labelH = tp.height + padV * 2;
      // put label above the box, or inside the top if there is no room
      final top = rect.top - labelH >= 0 ? rect.top - labelH : rect.top;
      final labelRect = Rect.fromLTWH(rect.left, top, labelW, labelH);

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = color,
      );
      tp.paint(canvas, Offset(labelRect.left + padH, labelRect.top + padV));
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) =>
      old.results != results || old.cameraAspect != cameraAspect;
}
