import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget home;

  const SplashScreen({super.key, required this.home});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _logoScale;
  late Animation<Offset> _textSlide;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Main intro animation
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeIn,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.elasticOut),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );

    // Continuous wave animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _introController.forward();

    // Navigate to home screen after 4 seconds
    _navigationTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => widget.home));
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _introController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Blue and cyan gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF061B78),
                  Color(0xFF063BA8),
                  Color(0xFF008EDB),
                  Color(0xFF00D4E8),
                ],
                stops: [0.0, 0.40, 0.75, 1.0],
              ),
            ),
          ),

          // 2. Glowing background effect
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Positioned(
                top: 100,
                right: -60 + 20 * math.sin(_waveController.value * 2 * math.pi),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.20),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 3. Animated bottom waves
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 250,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(painter: WavePainter(_waveController.value));
              },
            ),
          ),

          // 4. Center logo and branding
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Original ISDAAI logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.25),
                            blurRadius: 45,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo/logo_isdaai.png',
                        width: 230,
                        height: 230,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Animated ISDAAI text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Isda',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'AI',
                                  style: TextStyle(color: Color(0xFF00E5FF)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'SMART FISH FRESHNESS DETECTION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Loading indicator
          Positioned(
            bottom: 45,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 90,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _waveController.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00E5FF),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'INITIALIZING ISDAAI...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM ANIMATED WAVE PAINTER
// ==========================================

class WavePainter extends CustomPainter {
  final double progress;

  WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * math.pi;

    _drawWave(
      canvas,
      size,
      phase,
      0.35,
      0.30,
      const Color(0xFF00E5FF).withOpacity(0.35),
    );

    _drawWave(
      canvas,
      size,
      phase + 1.5,
      0.50,
      0.48,
      const Color(0xFF00BFFF).withOpacity(0.35),
    );

    _drawWave(
      canvas,
      size,
      phase + 3.0,
      0.65,
      0.65,
      const Color(0xFF003BBD).withOpacity(0.55),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double phase,
    double baseline,
    double amplitude,
    Color color,
  ) {
    final path = Path();

    path.moveTo(0, size.height * baseline);

    for (double x = 0; x <= size.width; x += 5) {
      final y =
          size.height * baseline +
          math.sin((x / size.width * 2 * math.pi) + phase) *
              size.height *
              0.12 *
              amplitude;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
