import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../theme/game_theme.dart';
import 'home_screen.dart';

class SnowflakeData {
  double x;
  double y;
  final double radius;
  final double speed;
  final double swaySpeed;
  final double swayAmount;
  final double opacity;

  SnowflakeData({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.swaySpeed,
    required this.swayAmount,
    required this.opacity,
  });
}

class SnowfallPainter extends CustomPainter {
  final List<SnowflakeData> flakes;
  final double progress;

  SnowfallPainter({required this.flakes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final f in flakes) {
      final currentY = (f.y + f.speed * progress) % size.height;
      final sway = sin(progress * f.swaySpeed * 2 * pi) * f.swayAmount;
      final currentX = (f.x + sway) % size.width;

      paint.color = Colors.white.withValues(alpha: f.opacity);
      canvas.drawCircle(Offset(currentX, currentY), f.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SnowfallPainter oldDelegate) => true;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _flightController;
  late AnimationController _snowController;
  late AnimationController _introController;
  late Animation<double> _popScaleAnimation;
  late Animation<double> _popOpacityAnimation;
  Timer? _splashTimer;

  final List<SnowflakeData> _snowflakes = [];

  @override
  void initState() {
    super.initState();

    // 1. Flight Bobbing & Wing Flap Controller
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // 2. Continuous Snowfall Controller
    _snowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 3. Sequenced Intro Controller: Sudden text pop-up at ~350ms
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _popScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.32, 1.0, curve: Curves.elasticOut),
      ),
    );

    _popOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.32, 0.60, curve: Curves.easeIn),
      ),
    );

    _initSnowflakes();
    _introController.forward();
    _initGame();
  }

  void _initSnowflakes() {
    final rnd = Random(42);
    _snowflakes.clear();
    for (int i = 0; i < 55; i++) {
      _snowflakes.add(
        SnowflakeData(
          x: rnd.nextDouble() * 500,
          y: rnd.nextDouble() * 900,
          radius: 1.2 + rnd.nextDouble() * 2.4,
          speed: 150.0 + rnd.nextDouble() * 220.0,
          swaySpeed: 0.8 + rnd.nextDouble() * 1.5,
          swayAmount: 15.0 + rnd.nextDouble() * 25.0,
          opacity: 0.35 + rnd.nextDouble() * 0.55,
        ),
      );
    }
  }

  Future<void> _initGame() async {
    final storage = await StorageService.init();
    final audio = AudioService(storage);
    final adService = AdService(storage, audio);
    await adService.init();

    if (!mounted) return;
    _splashTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomeScreen(storage: storage, audio: audio, adService: adService),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _flightController.dispose();
    _snowController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1426),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Atmospheric Snowy Scenery Backdrop
          Image.asset(
            'assets/images/snowy_bg.png',
            fit: BoxFit.cover,
            color: Colors.black.withAlpha(90),
            colorBlendMode: BlendMode.darken,
          ),

          // Deep Blue Radial Frost Glow Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.15,
                colors: [
                  Color(0x3300E5FF),
                  Color(0xBB0B1426),
                  Color(0xF0070D1A),
                ],
              ),
            ),
          ),

          // 2. Animated Falling Snowflakes Layer
          AnimatedBuilder(
            animation: _snowController,
            builder: (context, child) {
              return CustomPaint(
                painter: SnowfallPainter(
                  flakes: _snowflakes,
                  progress: _snowController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 3. Center Stage: Flying Penguin + Suddenly Popping Title Below
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Hero Flying Penguin in Center
                  AnimatedBuilder(
                    animation: _flightController,
                    builder: (context, child) {
                      final bob = sin(_flightController.value * pi) * 14.0;
                      // Wing flap cycle alternating frames
                      final isWingUp = (_flightController.value * 5).toInt() % 2 == 0;

                      return Transform.translate(
                        offset: Offset(0, -bob),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x6600E5FF),
                                blurRadius: 45,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scaleX: -1, // Face forward (right)
                            child: Image.asset(
                              isWingUp
                                  ? 'assets/images/penguin-1.png'
                                  : 'assets/images/penguin-2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // 4. Sudden Punchy Pop-Up Title Right Below Penguin
                  AnimatedBuilder(
                    animation: _introController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _popScaleAnimation.value,
                        child: Opacity(
                          opacity: _popOpacityAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0B1426),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withAlpha(180),
                          width: 2.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x7700E5FF),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FLAPPY ',
                            style: GameTheme.arcadeTitle(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'PENGUIN',
                            style: GameTheme.arcadeTitle(
                              fontSize: 36,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 5. Sleek Ice Cyan Loading Indicator
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Color(0x3300E5FF),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
