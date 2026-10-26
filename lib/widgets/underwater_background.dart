import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated underwater scene: gradient water, drifting light rays,
/// swimming fish (parallax by depth) and rising bubbles.
/// Put your screen content in [child]; it is drawn on top.
class UnderwaterBackground extends StatefulWidget {
  final Widget child;
  final int fishCount;
  final int bubbleCount;

  const UnderwaterBackground({
    super.key,
    required this.child,
    this.fishCount = 9,
    this.bubbleCount = 14,
  });

  @override
  State<UnderwaterBackground> createState() => _UnderwaterBackgroundState();
}

class _UnderwaterBackgroundState extends State<UnderwaterBackground>
    with SingleTickerProviderStateMixin {
  // Seconds since the scene started. The painter listens to this directly,
  // so only the painter repaints each frame (not the whole widget tree).
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late final List<_Fish> _fish;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(11); // fixed seed = same layout every launch

    const palette = [
      Color(0xFFFFB74D),
      Color(0xFFFF7043),
      Color(0xFFFFE082),
      Color(0xFF80DEEA),
      Color(0xFFFFFFFF),
    ];

    _fish = List.generate(widget.fishCount, (i) {
      final depth = rnd.nextDouble(); // 0 = far, 1 = near
      return _Fish(
        // golden-ratio spread so fish don't stack on the same lane
        y: 0.08 + 0.84 * ((i * 0.618034) % 1.0),
        startX: rnd.nextDouble(),
        speed: 12 + 28 * depth,
        length: 34 + 46 * depth,
        facingRight: rnd.nextBool(),
        phase: rnd.nextDouble() * math.pi * 2,
        depth: depth,
        color: palette[rnd.nextInt(palette.length)],
      );
    })..sort((a, b) => a.depth.compareTo(b.depth)); // far ones drawn first

    _bubbles = List.generate(widget.bubbleCount, (i) {
      return _Bubble(
        x: rnd.nextDouble(),
        start: rnd.nextDouble(),
        speed: 0.03 + rnd.nextDouble() * 0.05,
        radius: 2 + rnd.nextDouble() * 5,
        phase: rnd.nextDouble() * math.pi * 2,
      );
    });

    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
    })..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "remove animations" setting: scene stays still.
    _ticker.muted = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF69A4F2), Color(0xFF2F6FD0), Color(0xFF0D47A1)],
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _UnderwaterPainter(_time, _fish, _bubbles),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Fish {
  final double y; // 0..1 of height
  final double startX; // 0..1 of travel distance
  final double speed; // px per second
  final double length; // px
  final bool facingRight;
  final double phase;
  final double depth;
  final Color color;

  const _Fish({
    required this.y,
    required this.startX,
    required this.speed,
    required this.length,
    required this.facingRight,
    required this.phase,
    required this.depth,
    required this.color,
  });

  double get wagSpeed => 4 + speed * 0.08; // faster fish = faster tail
}

class _Bubble {
  final double x; // 0..1 of width
  final double start; // 0..1 starting progress
  final double speed; // progress per second
  final double radius;
  final double phase;

  const _Bubble({
    required this.x,
    required this.start,
    required this.speed,
    required this.radius,
    required this.phase,
  });
}

class _UnderwaterPainter extends CustomPainter {
  final ValueNotifier<double> time;
  final List<_Fish> fish;
  final List<_Bubble> bubbles;

  _UnderwaterPainter(this.time, this.fish, this.bubbles) : super(repaint: time);

  // Fish drawn in a unit space: length 1, nose at +x, centered on (0, 0).
  static final Path _body = Path()
    ..moveTo(0.5, 0)
    ..cubicTo(0.32, -0.30, -0.08, -0.32, -0.30, -0.07)
    ..lineTo(-0.30, 0.07)
    ..cubicTo(-0.08, 0.32, 0.32, 0.30, 0.5, 0)
    ..close();
  static final Path _tail = Path()
    ..moveTo(0.02, 0)
    ..lineTo(-0.24, -0.20)
    ..quadraticBezierTo(-0.15, 0, -0.24, 0.20)
    ..close();
  static final Path _dorsal = Path()
    ..moveTo(0.14, -0.27)
    ..quadraticBezierTo(0.02, -0.52, -0.14, -0.22)
    ..close();
  static final Path _belly = Path()
    ..addOval(const Rect.fromLTWH(-0.12, 0.04, 0.5, 0.16));

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    _paintRays(canvas, size, t);
    for (final f in fish) {
      _paintFish(canvas, size, f, t);
    }
    _paintBubbles(canvas, size, t);
  }

  void _paintRays(Canvas canvas, Size size, double t) {
    final paint = Paint();
    final rayHeight = size.height * 0.8;
    for (var i = 0; i < 4; i++) {
      final sway = math.sin(t * 0.25 + i * 1.7) * 24;
      final x = size.width * (0.05 + i * 0.3) + sway;
      final strength = 0.10 + 0.05 * math.sin(t * 0.4 + i);
      final rect = Rect.fromLTWH(x - 230, 0, 290, rayHeight);
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: strength),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 56, 0)
        ..lineTo(x - 110, rayHeight)
        ..lineTo(x - 230, rayHeight)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _paintFish(Canvas canvas, Size size, _Fish f, double t) {
    const margin = 140.0; // let fish fully leave the screen before wrapping
    final travel = size.width + margin * 2;
    final dir = f.facingRight ? 1.0 : -1.0;
    final x = ((f.startX * travel + dir * f.speed * t) % travel) - margin;
    final y = f.y * size.height + math.sin(t * 0.9 + f.phase) * 8;
    final wag = math.sin(t * f.wagSpeed + f.phase) * 0.42;
    final pitch = math.sin(t * 0.7 + f.phase) * 0.06;
    final alpha = 0.22 + 0.33 * f.depth; // far fish are fainter

    final basePaint = Paint()..color = f.color.withValues(alpha: alpha);
    final darkPaint = Paint()
      ..color = Color.lerp(
        f.color,
        Colors.black,
        0.18,
      )!.withValues(alpha: alpha);
    final lightPaint = Paint()
      ..color = Color.lerp(
        f.color,
        Colors.white,
        0.45,
      )!.withValues(alpha: alpha * 0.8);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(pitch);
    canvas.scale(f.length * dir, f.length); // negative x flips the fish

    // Tail pivots at the back of the body
    canvas.save();
    canvas.translate(-0.28, 0);
    canvas.rotate(wag);
    canvas.drawPath(_tail, darkPaint);
    canvas.restore();

    canvas.drawPath(_dorsal, darkPaint);
    canvas.drawPath(_body, basePaint);
    canvas.drawPath(_belly, lightPaint);

    // Eye
    final eyeAlpha = math.min(1.0, alpha + 0.35);
    canvas.drawCircle(
      const Offset(0.30, -0.06),
      0.045,
      Paint()..color = Colors.white.withValues(alpha: eyeAlpha),
    );
    canvas.drawCircle(
      const Offset(0.31, -0.06),
      0.022,
      Paint()..color = const Color(0xFF1B2430).withValues(alpha: eyeAlpha),
    );

    canvas.restore();
  }

  void _paintBubbles(Canvas canvas, Size size, double t) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint();
    for (final b in bubbles) {
      final progress = (b.start + t * b.speed) % 1.0; // 0 bottom -> 1 top
      final y = size.height * (1 - progress);
      final x = b.x * size.width + math.sin(t * 1.1 + b.phase) * 10;
      final fade = progress > 0.85 ? (1 - progress) / 0.15 : 1.0;
      stroke.color = Colors.white.withValues(alpha: 0.35 * fade);
      fill.color = Colors.white.withValues(alpha: 0.08 * fade);
      canvas.drawCircle(Offset(x, y), b.radius, fill);
      canvas.drawCircle(Offset(x, y), b.radius, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _UnderwaterPainter old) => false;
}
