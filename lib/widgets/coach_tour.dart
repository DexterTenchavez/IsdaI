import 'package:flutter/material.dart';
import '../services/language/app_language.dart';
import '../services/storage/guide_store.dart';
import '../theme/app_theme.dart';

class CoachStep {
  final GlobalKey? target;
  final String titleKey; // translation keys
  final String bodyKey;

  /// True for round things (icon buttons, shutter).
  final bool circle;

  const CoachStep({
    this.target,
    required this.titleKey,
    required this.bodyKey,
    this.circle = false,
  });
}

/// First-time tour: dims the screen, highlights one control at a time and
/// explains it. It is shown only once per [id] (see GuideStore).
class CoachTour {
  CoachTour._();

  static OverlayEntry? _entry;
  static Object? _owner;

  /// Starts the tour for [id] if the user has not seen it yet.
  /// [owner] is the screen's State, so only that screen can dismiss it.
  static Future<void> showOnce(
    BuildContext context, {
    required Object owner,
    required String id,
    required List<CoachStep> steps,
  }) async {
    if (await GuideStore.isDone(id)) return;
    if (!context.mounted) return;

    // Let the screen finish drawing so the targets have a position.
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    final overlay = Overlay.maybeOf(context);
    final anyTarget = steps.any(
      (s) => s.target == null || s.target!.currentContext != null,
    );
    if (overlay == null || !anyTarget) return;

    dismiss();
    _owner = owner;
    final entry = OverlayEntry(
      builder: (_) => _CoachOverlay(
        steps: steps,
        onClose: () {
          GuideStore.markDone(id);
          dismiss(owner: owner);
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Removes the tour. Call it from the screen's dispose().
  static void dismiss({Object? owner}) {
    if (owner != null && owner != _owner) return;
    final entry = _entry;
    _entry = null;
    _owner = null;
    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }
}

class _CoachOverlay extends StatefulWidget {
  final List<CoachStep> steps;
  final VoidCallback onClose;

  const _CoachOverlay({required this.steps, required this.onClose});

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> {
  int _index = -1; // -1 = preparing the first step
  Rect? _rect; // highlighted area (null = no highlight)
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(0));
  }

  bool _isAvailable(int i) {
    final t = widget.steps[i].target;
    return t == null || t.currentContext != null;
  }

  bool _hasMoreAfter(int i) {
    for (var j = i + 1; j < widget.steps.length; j++) {
      if (_isAvailable(j)) return true;
    }
    return false;
  }

  /// Shows the first available step starting at [from].
  /// Closes the tour when there is none left.
  Future<void> _go(int from) async {
    _busy = true;
    var i = from;
    while (i < widget.steps.length) {
      final target = widget.steps[i].target;

      if (target == null) {
        if (!mounted) return;
        setState(() {
          _index = i;
          _rect = null;
        });
        _busy = false;
        return;
      }

      final ctx = target.currentContext;
      if (ctx == null) {
        i++;
        continue;
      }

      // Scroll the target into view if the screen scrolls.
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final box = target.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) {
        i++;
        continue;
      }

      final topLeft = box.localToGlobal(Offset.zero);
      setState(() {
        _index = i;
        _rect = topLeft & box.size;
      });
      _busy = false;
      return;
    }

    if (mounted) widget.onClose();
  }

  void _next() {
    if (_busy || _index < 0) return;
    _go(_index + 1);
  }

  void _skip() {
    if (_busy) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (_index < 0) return const SizedBox.shrink();

    final pal = context.pal;
    final size = MediaQuery.sizeOf(context);
    final step = widget.steps[_index];
    final rect = _rect;
    final hole = rect?.inflate(8);
    final hasMore = _hasMoreAfter(_index);

    // Step counter ("2 of 5") counts only the steps that can be shown.
    final shown = [
      for (var i = 0; i < widget.steps.length; i++)
        if (_isAvailable(i)) i,
    ];
    final number = shown.indexOf(_index) + 1;

    final card = _card(
      pal: pal,
      title: context.tr(step.titleKey),
      body: context.tr(step.bodyKey),
      counter: context.tr(
        'tour_step',
        args: {'n': '$number', 'total': '${shown.length}'},
      ),
      hasMore: hasMore,
    );

    // The card goes below the highlight on the top half of the screen,
    // above it on the bottom half.
    final below = rect == null || rect.center.dy < size.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dim layer with the hole. It also blocks taps on the screen.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: hole == null
                  ? const CustomPaint(painter: _SpotlightPainter(null, 18))
                  : TweenAnimationBuilder<Rect?>(
                      tween: RectTween(end: hole),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, r, _) => CustomPaint(
                        painter: _SpotlightPainter(r, step.circle ? 999 : 18),
                      ),
                    ),
            ),
          ),

          if (hole == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: card,
                ),
              ),
            )
          else
            Positioned(
              left: 20,
              right: 20,
              top: below ? hole.bottom + 14 : null,
              bottom: below ? null : size.height - hole.top + 14,
              child: Align(
                alignment: below ? Alignment.topCenter : Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: card,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card({
    required AppPalette pal,
    required String title,
    required String body,
    required String counter,
    required bool hasMore,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: pal.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                counter,
                style: TextStyle(
                  color: pal.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: pal.text, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasMore)
                TextButton(
                  onPressed: _skip,
                  child: Text(
                    context.tr('tour_skip'),
                    style: TextStyle(
                      color: pal.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: hasMore ? _next : _skip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(context.tr(hasMore ? 'tour_next' : 'tour_done')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dark layer with a rounded hole and an orange outline around the hole.
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final double radius;

  const _SpotlightPainter(this.hole, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.78);
    final full = Path()..addRect(Offset.zero & size);

    final h = hole;
    if (h == null) {
      canvas.drawPath(full, dim);
      return;
    }

    final rrect = RRect.fromRectAndRadius(h, Radius.circular(radius));
    final cut = Path()..addRRect(rrect);
    canvas.drawPath(Path.combine(PathOperation.difference, full, cut), dim);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.hole != hole || old.radius != radius;
}
