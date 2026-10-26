import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import 'game_screen.dart';

/// Snowflake model for snowfall background
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

/// Dynamic snowfall custom painter
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

/// Exact authentic gameplay background scenery without obstacles:
/// Scrolls infinitely and seamlessly using an uninterrupted frame ticker
/// with multi-depth parallax and moving ground, without any hitches, resets, or loops.
class GameplaySceneryBackground extends StatefulWidget {
  final String scenery;
  final bool isPaused;

  const GameplaySceneryBackground({
    super.key,
    required this.scenery,
    this.isPaused = false,
  });

  @override
  State<GameplaySceneryBackground> createState() => _GameplaySceneryBackgroundState();
}

class _GameplaySceneryBackgroundState extends State<GameplaySceneryBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Exact continuous frame accumulators (Never reset to 0, completely seamless wrap)
  double _offsetFar = 0.0;
  double _offsetClouds = 0.0;
  double _offsetMid = 0.0;
  double _offsetNear = 0.0;
  double _offsetGround = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_lastElapsed == Duration.zero) {
        _lastElapsed = elapsed;
        return;
      }
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      // Ignore abnormal frame pause / resumes
      if (dt <= 0.0 || dt > 0.1) return;

      // Speeds matching in-game BackgroundComponent & GroundComponent:
      // Base game speed: 180 px/s
      // Far mountains: 180 * 0.08 = 14.4 px/s
      // Desert clouds: 12.0 px/s
      // Mid ridges: 180 * 0.18 = 32.4 px/s
      // Near trees: 180 * 0.30 = 54.0 px/s
      // Ground stripes: 180.0 px/s (24px pattern)
      setState(() {
        _offsetFar += 14.4 * dt;
        _offsetClouds += 12.0 * dt;
        _offsetMid += 32.4 * dt;
        _offsetNear += 54.0 * dt;
        _offsetGround = (_offsetGround + 180.0 * dt) % 24.0;
      });
    });
    if (!widget.isPaused) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant GameplaySceneryBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        if (_ticker.isActive) {
          _ticker.stop();
        }
      } else {
        _lastElapsed = Duration.zero;
        if (!_ticker.isActive) {
          _ticker.start();
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final isDesert = widget.scenery == 'desert';
        final isIce = widget.scenery == 'ice';

        // 1. Sky Gradient (Identical to in-game BackgroundComponent)
        final skyGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDesert
              ? const [
                  Color(0xFF8AAAE5),
                  Color(0xFFDEB5B7),
                  Color(0xFFFFD59E),
                ]
              : (isIce
                  ? const [
                      Color(0xFF4A90E2),
                      Color(0xFF87CEEB),
                      Color(0xFFE0F7FA),
                    ]
                  : const [
                      Color(0xFF42A5F5),
                      Color(0xFF90CAF9),
                      Color(0xFFE3F2FD),
                    ]),
        );

        // Ground dimensions matching in-game GroundComponent
        const groundHeight = 100.0;
        const grassHeight = 16.0;

        // Scenery layer proportions matching in-game BackgroundComponent
        final layerH = (isIce || isDesert) ? (screenH * 0.46) : (screenH * 0.52);
        final aspect = isDesert ? (640.0 / 360.0) : (isIce ? (576.0 / 324.0) : (807.0 / 400.0));
        final layerW = max(layerH * aspect, screenW);

        final groundTopColor = isDesert
            ? const Color(0xFFE2B062)
            : (isIce ? const Color(0xFFE0F7FA) : const Color(0xFF43A047));
        final groundBodyColor = isDesert
            ? const Color(0xFF9E5C32)
            : (isIce ? const Color(0xFF263238) : const Color(0xFF5D4037));

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Sky Gradient Background
            Container(
              decoration: BoxDecoration(gradient: skyGradient),
            ),

            // 2. Parallax Mountain / Forest / Desert Scenery Layers
            if (isDesert) ...[
              // Layer 1: Distant desert peaks
              _buildTiledLayer(
                assetPath: 'assets/images/desert_mountains_far.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0 + 14.0,
                offset: _offsetFar % layerW,
                screenW: screenW,
              ),
              // Layer 2: Drifting clouds
              _buildTiledLayer(
                assetPath: 'assets/images/desert_clouds.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0 + 45.0,
                offset: _offsetClouds % layerW,
                screenW: screenW,
              ),
              // Layer 3: Warm golden mountain dunes
              _buildTiledLayer(
                assetPath: 'assets/images/desert_mountains_mid.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0 + 4.0,
                offset: _offsetMid % layerW,
                screenW: screenW,
              ),
              // Layer 4: Near desert palms & trees
              _buildTiledLayer(
                assetPath: 'assets/images/desert_trees_near.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0,
                offset: _offsetNear % layerW,
                screenW: screenW,
              ),
            ] else if (isIce) ...[
              // Distant majestic snowy mountain peaks (Plan 4)
              _buildTiledLayer(
                assetPath: 'assets/images/snowy_mountains_far.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0 + 18.0,
                offset: _offsetFar % layerW,
                screenW: screenW,
              ),
              // Mid-distance mountain ridges & pine hills (Plan 3)
              _buildTiledLayer(
                assetPath: 'assets/images/snowy_mountains_mid.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0 + 6.0,
                offset: _offsetMid % layerW,
                screenW: screenW,
              ),
              // Near snowy pine slopes (Plan 2)
              _buildTiledLayer(
                assetPath: 'assets/images/snowy_trees_near.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 12.0,
                offset: _offsetNear % layerW,
                screenW: screenW,
              ),
            ] else ...[
              // Mountain scenery green alpine pass
              _buildTiledLayer(
                assetPath: 'assets/images/mountains-bg.png',
                layerWidth: layerW,
                layerHeight: layerH,
                bottom: groundHeight - 8.0,
                offset: _offsetFar % layerW,
                screenW: screenW,
              ),
            ],

            // 3. Ground Component (Matching in-game ground layout and moving stripes)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: groundHeight,
              child: CustomPaint(
                painter: _GroundPainter(
                  topColor: groundTopColor,
                  bodyColor: groundBodyColor,
                  grassHeight: grassHeight,
                  scrollOffset: _offsetGround,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTiledLayer({
    required String assetPath,
    required double layerWidth,
    required double layerHeight,
    required double bottom,
    required double offset,
    required double screenW,
  }) {
    return Positioned(
      bottom: bottom,
      left: 0,
      right: 0,
      height: layerHeight,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -offset,
              bottom: 0,
              width: layerWidth + 1.0,
              height: layerHeight,
              child: Image.asset(
                assetPath,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned(
              left: layerWidth - offset,
              bottom: 0,
              width: layerWidth + 1.0,
              height: layerHeight,
              child: Image.asset(
                assetPath,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (layerWidth * 2 - offset < screenW + 100)
              Positioned(
                left: (layerWidth * 2) - offset,
                bottom: 0,
                width: layerWidth + 1.0,
                height: layerHeight,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  final Color topColor;
  final Color bodyColor;
  final double grassHeight;
  final double scrollOffset;

  _GroundPainter({
    required this.topColor,
    required this.bodyColor,
    required this.grassHeight,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ground main body
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawRect(
      Rect.fromLTWH(0, grassHeight, size.width, size.height - grassHeight),
      bodyPaint,
    );

    // 2. Dirt stripes scrolling with ground
    final stripePaint = Paint()..color = Colors.black.withAlpha(22);
    for (double x = -scrollOffset; x < size.width + 24; x += 24) {
      canvas.drawRect(
        Rect.fromLTWH(x, grassHeight, 8, size.height - grassHeight),
        stripePaint,
      );
    }

    // 3. Grass/Snow top crust
    final topPaint = Paint()..color = topColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, grassHeight),
      topPaint,
    );

    // 4. Highlight stroke on top edge
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _GroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.topColor != topColor ||
        oldDelegate.bodyColor != bodyColor;
  }
}

class HomeScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final AdService adService;

  HomeScreen({
    super.key,
    required this.storage,
    required this.audio,
    AdService? adService,
  }) : adService = adService ?? AdService(storage, audio);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animation controllers for dynamic widgets & SwiftUI effects
  // Using lazy nullable controllers ensures hot-reload and state transitions never throw LateInitializationError.
  AnimationController? __floatController;
  AnimationController? __snowController;
  AnimationController? __pulseController;
  AnimationController? __shimmerController;
  AnimationController? __tiltController;

  void _ensureControllers() {
    __floatController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    __tiltController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    __snowController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    __pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    __shimmerController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  AnimationController get _floatController {
    _ensureControllers();
    return __floatController!;
  }

  AnimationController get _tiltController {
    _ensureControllers();
    return __tiltController!;
  }

  AnimationController get _snowController {
    _ensureControllers();
    return __snowController!;
  }

  AnimationController get _pulseController {
    _ensureControllers();
    return __pulseController!;
  }

  AnimationController get _shimmerController {
    _ensureControllers();
    return __shimmerController!;
  }

  Timer? _wingTimer;
  int _penguinFrame = 1;
  bool _isPlayPressed = false;
  bool _isSceneryPressed = false;
  bool _isNavigatedToGame = false;

  final List<SnowflakeData> _snowflakes = [];

  @override
  void reassemble() {
    super.reassemble();
    _ensureControllers();
  }

  @override
  void initState() {
    super.initState();
    _ensureControllers();
    _startWingTimer();
    _initSnowflakes();
    if (widget.storage.musicEnabled) {
      widget.audio.playBgm();
    }
  }

  void _startWingTimer() {
    _wingTimer?.cancel();
    _wingTimer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (mounted && !_isNavigatedToGame) {
        setState(() {
          _penguinFrame = (_penguinFrame == 1) ? 2 : 1;
        });
      }
    });
  }

  void _pauseHomeAnimations() {
    _wingTimer?.cancel();
    _wingTimer = null;
    __floatController?.stop();
    __tiltController?.stop();
    __snowController?.stop();
    __pulseController?.stop();
    __shimmerController?.stop();
  }

  void _resumeHomeAnimations() {
    _startWingTimer();
    __floatController?.repeat(reverse: true);
    __tiltController?.repeat(reverse: true);
    __snowController?.repeat();
    __pulseController?.repeat(reverse: true);
    __shimmerController?.repeat();
  }

  void _initSnowflakes() {
    final rnd = Random(42);
    _snowflakes.clear();
    for (int i = 0; i < 50; i++) {
      _snowflakes.add(
        SnowflakeData(
          x: rnd.nextDouble() * 500,
          y: rnd.nextDouble() * 900,
          radius: 1.2 + rnd.nextDouble() * 2.4,
          speed: 120.0 + rnd.nextDouble() * 190.0,
          swaySpeed: 0.7 + rnd.nextDouble() * 1.5,
          swayAmount: 14.0 + rnd.nextDouble() * 24.0,
          opacity: 0.25 + rnd.nextDouble() * 0.55,
        ),
      );
    }
  }

  @override
  void dispose() {
    _wingTimer?.cancel();
    __floatController?.dispose();
    __tiltController?.dispose();
    __snowController?.dispose();
    __pulseController?.dispose();
    __shimmerController?.dispose();
    super.dispose();
  }

  void _playGame() {
    widget.audio.triggerHaptic();
    widget.adService.handleGamePlayOrRetry(
      onProceed: () async {
        if (!mounted) return;
        setState(() {
          _isNavigatedToGame = true;
        });
        _pauseHomeAnimations();

        await Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) => GameScreen(
              storage: widget.storage,
              audio: widget.audio,
              adService: widget.adService,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );

        // Refresh high score, coins, and scenery upon returning to home screen
        if (mounted) {
          setState(() {
            _isNavigatedToGame = false;
          });
          _resumeHomeAnimations();
          if (widget.storage.musicEnabled) {
            widget.audio.playBgm(force: true);
          }
        }
      },
    );
  }

  void _openSceneryModal() {
    widget.audio.playClick();
    String tempSelected = widget.storage.scenery;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Scenery',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    final isUnlocked = widget.storage.isSceneryUnlocked(tempSelected);
                    final sceneryPrice = widget.storage.getSceneryPrice(tempSelected);
                    final playerCoins = widget.storage.coins;
                    final canAfford = playerCoins >= sceneryPrice;

                    final accentColor = tempSelected == 'ice'
                        ? const Color(0xFF00E5FF)
                        : (tempSelected == 'mountain'
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF9100));

                    final heroAsset = tempSelected == 'ice'
                        ? 'assets/images/snowy_bg.png'
                        : (tempSelected == 'mountain'
                            ? 'assets/images/mountains-bg.png'
                            : 'assets/images/desert_mountains_far.png');

                    final worldName = tempSelected == 'ice'
                        ? 'FROZEN TUNDRA'
                        : (tempSelected == 'mountain'
                            ? 'ALPINE PEAKS'
                            : 'SUNBAKED CANYON');

                    final worldObstacle = tempSelected == 'ice'
                        ? 'Razor Ice Spikes'
                        : (tempSelected == 'mountain'
                            ? 'Classic Retro Pipes'
                            : 'Giant Cacti');

                    final worldHazard = tempSelected == 'ice'
                        ? 'Snowballs'
                        : (tempSelected == 'mountain'
                            ? 'Boulders'
                            : 'Cactus Spikes');

                    final worldDesc = tempSelected == 'ice'
                        ? 'Glide through icy blizzards and dodge sharp stalactites!'
                        : (tempSelected == 'mountain'
                            ? 'Navigate classic pipes among pine summits!'
                            : 'Soar through blazing dunes and dodge cactus thorns!');

                    return Container(
                      width: 420,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.65),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.28),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF131D31),
                                  Color(0xFF0A0F1D),
                                  Color(0xFF0E1626),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. GAMING HEADER WITH TITLE, COIN BALANCE & 3D CLOSE BUTTON
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            accentColor.withValues(alpha: 0.35),
                                            accentColor.withValues(alpha: 0.12),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: accentColor.withValues(alpha: 0.8),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.public_rounded,
                                        color: accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'SELECT SCENERY',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16.0,
                                              letterSpacing: 1.4,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 6,
                                                  offset: Offset(1, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            'Choose or unlock game worlds',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.60),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Live player coin badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFFFD166),
                                          width: 1.2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33FFD166),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.monetization_on_rounded,
                                            color: Color(0xFFFFD166),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.storage.coins}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 3D Close button
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        widget.audio.playClick();
                                        Navigator.pop(dialogContext);
                                      },
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0xFFFF3366),
                                              Color(0xFFC2185B),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            width: 1.5,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x66FF3366),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // 2. PANORAMIC WORLD SHOWCASE WINDOW (Active Scenery Preview)
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.5),
                                      width: 1.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.22),
                                        blurRadius: 14,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.5),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Background Image
                                        Image.asset(
                                          heroAsset,
                                          fit: BoxFit.cover,
                                        ),
                                        // Gradient Dark Overlays for Razor Sharp Legibility
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.30),
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.88),
                                              ],
                                              stops: const [0.0, 0.4, 1.0],
                                            ),
                                          ),
                                        ),
                                        // Lock overlay in center if not unlocked
                                        if (!isUnlocked)
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.82),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(0xFFFFD166),
                                                  width: 1.6,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Color(0x66FFD166),
                                                    blurRadius: 12,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.lock_rounded,
                                                    color: Color(0xFFFFD166),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'LOCKED • $sceneryPrice COINS',
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFD166),
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 11,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        // Top Tag Pill
                                        Positioned(
                                          top: 8,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.75),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: accentColor,
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: accentColor,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: accentColor,
                                                        blurRadius: 6,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  worldName,
                                                  style: TextStyle(
                                                    color: accentColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 10,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Bottom Stats & Features Strip
                                        Positioned(
                                          left: 10,
                                          right: 10,
                                          bottom: 8,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: accentColor.withValues(alpha: 0.22),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                                                    ),
                                                    child: Text(
                                                      worldObstacle,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 9.5,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.55),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                                    ),
                                                    child: Text(
                                                      worldHazard,
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.9),
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 9.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                worldDesc,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // 3. WORLD CARDS (3 INTERACTIVE ARCADE TILES)
                                Row(
                                  children: [
                                    // 1. Ice Scenery (Default, Always Unlocked)
                                    Expanded(
                                      child: _buildSceneryCard(
                                        title: 'ICE SUMMIT',
                                        subtitle: 'Ice Spikes',
                                        badge: 'DEFAULT',
                                        imageAsset: 'assets/images/snowy_bg.png',
                                        isSelected: tempSelected == 'ice',
                                        isLocked: false,
                                        price: 0,
                                        accentColor: const Color(0xFF00E5FF),
                                        onTap: () {
                                          widget.audio.playClick();
                                          setModalState(() {
                                            tempSelected = 'ice';
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 2. Mountain Scenery (Locked: 800 Coins)
                                    Expanded(
                                      child: _buildSceneryCard(
                                        title: 'MOUNTAIN',
                                        subtitle: 'Classic Pipes',
                                        badge: 'PIPES',
                                        imageAsset: 'assets/images/mountains-bg.png',
                                        isSelected: tempSelected == 'mountain',
                                        isLocked: !widget.storage.isSceneryUnlocked('mountain'),
                                        price: StorageService.mountainUnlockPrice,
                                        accentColor: const Color(0xFF00E676),
                                        onTap: () {
                                          widget.audio.playClick();
                                          setModalState(() {
                                            tempSelected = 'mountain';
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 3. Desert Scenery (Locked: 1000 Coins)
                                    Expanded(
                                      child: _buildSceneryCard(
                                        title: 'DESERT',
                                        subtitle: 'Cactus',
                                        badge: 'CACTUS',
                                        imageAsset: 'assets/images/desert_mountains_far.png',
                                        isSelected: tempSelected == 'desert',
                                        isLocked: !widget.storage.isSceneryUnlocked('desert'),
                                        price: StorageService.desertUnlockPrice,
                                        accentColor: const Color(0xFFFF9100),
                                        onTap: () {
                                          widget.audio.playClick();
                                          setModalState(() {
                                            tempSelected = 'desert';
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // 4. 3D ARCADE ACTION BUTTON (SAVE / UNLOCK)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    widget.audio.playClick();
                                    if (!isUnlocked) {
                                      if (!canAfford) {
                                        widget.audio.triggerHaptic();
                                        return;
                                      }
                                      // Player pays coins to unlock scenery
                                      final success = await widget.storage.unlockScenery(tempSelected);
                                      if (success) {
                                        await widget.storage.setScenery(tempSelected);
                                        widget.audio.playPowerup();
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                        if (mounted) {
                                          setState(() {});
                                        }
                                        // Trigger real full-screen ad on scenery unlock
                                        await widget.adService.handleSceneryUnlock();
                                      }
                                      return;
                                    }

                                    // Scenery is already unlocked, normal save
                                    await widget.storage.setScenery(tempSelected);
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      gradient: !isUnlocked
                                          ? (canAfford
                                              ? const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Color(0xFFFFD166), Color(0xFFFF9100), Color(0xFFE65100)],
                                                )
                                              : const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                                                ))
                                          : LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: tempSelected == 'desert'
                                                  ? const [Color(0xFFFFB300), Color(0xFFE65100)]
                                                  : (tempSelected == 'mountain'
                                                      ? const [Color(0xFF00E676), Color(0xFF1B5E20)]
                                                      : const [Color(0xFF00E5FF), Color(0xFF0072FF)]),
                                            ),
                                      border: Border.all(
                                        color: !isUnlocked
                                            ? (canAfford ? const Color(0xFFFFD166) : Colors.white24)
                                            : Colors.white.withValues(alpha: 0.75),
                                        width: 1.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: !isUnlocked
                                              ? (canAfford ? const Color(0x66FFD166) : Colors.transparent)
                                              : accentColor.withValues(alpha: 0.45),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                        const BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Gloss shine line across the top edge
                                        Positioned(
                                          top: 2,
                                          left: 18,
                                          right: 18,
                                          height: 18,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(20),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.white.withValues(alpha: 0.40),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Button Text & Icon
                                        Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                !isUnlocked
                                                    ? (canAfford ? Icons.lock_open_rounded : Icons.lock_rounded)
                                                    : Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                !isUnlocked
                                                    ? (canAfford
                                                        ? 'UNLOCK FOR $sceneryPrice COINS'
                                                        : 'LOCKED • $sceneryPrice COINS')
                                                    : 'SAVE',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                  letterSpacing: 1.8,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black87,
                                                      blurRadius: 6,
                                                      offset: Offset(1, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSceneryCard({
    required String title,
    required String subtitle,
    required String badge,
    required String imageAsset,
    required bool isSelected,
    required bool isLocked,
    required int price,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : const Color(0xFF0D1424).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.18),
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.42),
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Thumbnail with checkmark & badge overlay
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageAsset,
                    width: double.infinity,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                // Locked dark vignette
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                // Lock price badge on top-left if locked
                if (isLocked)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xEE1E293B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFFD166),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFFFFD166),
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$price',
                            style: const TextStyle(
                              color: Color(0xFFFFD166),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selection indicator badge
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accentColor : Colors.black54,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor,
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isSelected ? Icons.check_rounded : Icons.circle_outlined,
                      size: 13,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
                // Category badge (DEFAULT, PIPES, CACTUS)
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.white24,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: isSelected ? accentColor : Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? accentColor : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                letterSpacing: 0.8,
                shadows: isSelected
                    ? [
                        Shadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 6),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIceScenery = widget.storage.scenery == 'ice';

    return TickerMode(
      enabled: !_isNavigatedToGame,
      child: Scaffold(
        backgroundColor: const Color(0xFF070D1B),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Moving Atmospheric Scenery Background (Identical to gameplay, infinite & seamless!)
            GameplaySceneryBackground(
              scenery: widget.storage.scenery,
              isPaused: _isNavigatedToGame,
            ),

            // 2. Ambient animated snowstorm particles (Active in Ice Scenery)
            if (isIceScenery && !_isNavigatedToGame)
              AnimatedBuilder(
                animation: _snowController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: SnowfallPainter(
                      flakes: _snowflakes,
                      progress: _snowController.value,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),

            // 3. Foreground UI Stack (SwiftUI Glassmorphism + Center Hero)
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ==============================================================
                  // TOP BAR: SwiftUI Frosted Glass Cards (Best Distance & Coins)
                  // ==============================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top-Left: Best Distance Card
                        _buildSwiftUiStatCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFFFD166),
                          glowColor: const Color(0xFFFFD166).withValues(alpha: 0.35),
                          label: 'BEST DISTANCE',
                          value: '${widget.storage.highScore}m',
                        ),

                        // Top-Right: Coins Card + Sound Toggle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSwiftUiStatCard(
                              icon: Icons.monetization_on_rounded,
                              iconColor: const Color(0xFFFFD166),
                              glowColor: const Color(0xFFFF9F1C).withValues(alpha: 0.35),
                              label: 'COINS',
                              value: '${widget.storage.coins}',
                            ),
                            const SizedBox(width: 10),

                            // SwiftUI Frosted Glass Audio Toggle
                            _buildSwiftUiAudioToggle(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ==============================================================
                  // CENTER HERO: Flipped Penguin (Faces Right!)
                  // ==============================================================
                  Center(
                    child: SizedBox(
                      width: 280,
                      height: 260,
                      child: Center(
                        // Animated Bobbing, Tilting & Flapping Penguin (FACING RIGHT)
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _floatController,
                            _tiltController,
                          ]),
                          builder: (context, child) {
                            final bobY = sin(_floatController.value * pi) * 14.0;
                            final tiltAngle = sin(_tiltController.value * 2 * pi) * 0.05;

                            return Transform.translate(
                              offset: Offset(0, -bobY),
                              child: Transform.rotate(
                                angle: tiltAngle,
                                child: child,
                              ),
                            );
                          },
                          child: Transform.flip(
                            flipX: true, // Flips horizontally so face points RIGHT!
                            child: Image.asset(
                              _penguinFrame == 1
                                  ? 'assets/images/penguin-1.png'
                                  : 'assets/images/penguin-2.png',
                              width: 130,
                              height: 100,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ==============================================================
                  // SWIFTUI CRAZY DYNAMIC "PLAY GAME" BUTTON WITH SHIMMER SWEEP
                  // ==============================================================
                  _buildSwiftUiPlayButton(),

                  const SizedBox(height: 14),

                  // ==============================================================
                  // SWIFTUI "CHANGE SCENERY" BUTTON
                  // ==============================================================
                  _buildSwiftUiSceneryButton(),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a SwiftUI button matching the exact style of the Play Game button
  Widget _buildSwiftUiSceneryButton() {
    final scenery = widget.storage.scenery;
    final isIce = scenery == 'ice';
    final isDesert = scenery == 'desert';

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shimmerController]),
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.035);
        final currentScale = _isSceneryPressed ? 0.94 : pulseScale;

        return Transform.scale(
          scale: currentScale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isSceneryPressed = true),
            onTapUp: (_) {
              setState(() => _isSceneryPressed = false);
              _openSceneryModal();
            },
            onTapCancel: () => setState(() => _isSceneryPressed = false),
            child: Container(
              width: 270,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  // Luminous ambient neon bloom matching Play Game button style
                  BoxShadow(
                    color: (isIce
                            ? const Color(0xFF0096C7)
                            : (isDesert
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32)))
                        .withValues(alpha: 0.50),
                    blurRadius: 26,
                    spreadRadius: 2,
                    offset: const Offset(0, 7),
                  ),
                  BoxShadow(
                    color: (isIce
                            ? const Color(0xFF00E5FF)
                            : (isDesert
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFF66BB6A)))
                        .withValues(alpha: 0.40),
                    blurRadius: 14,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Stack(
                    children: [
                      // Base vibrant SwiftUI gradient
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: isIce
                                ? const [
                                    Color(0xFF00E5FF),
                                    Color(0xFF0096C7),
                                    Color(0xFF023E8A),
                                  ]
                                : (isDesert
                                    ? const [
                                        Color(0xFFFFB74D),
                                        Color(0xFFF57C00),
                                        Color(0xFFD84315),
                                      ]
                                    : const [
                                        Color(0xFF66BB6A),
                                        Color(0xFF2E7D32),
                                        Color(0xFF1B5E20),
                                      ]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.6,
                          ),
                        ),
                      ),

                      // Dynamic Shimmer Light Sweep across button
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            final shimmerPos = _shimmerController.value;
                            return ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment(-2.0 + (shimmerPos * 4.0), -0.5),
                                  end: Alignment(-0.5 + (shimmerPos * 4.0), 0.5),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            );
                          },
                        ),
                      ),

                      // Button Content (Landscape/Sun/Snowflake Icon + Typography)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              child: Icon(
                                isIce
                                    ? Icons.ac_unit_rounded
                                    : (isDesert
                                        ? Icons.wb_sunny_rounded
                                        : Icons.landscape_rounded),
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'CHANGE SCENERY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds an authentic SwiftUI frosted glass stat pill card
  Widget _buildSwiftUiStatCard({
    required IconData icon,
    required Color iconColor,
    required Color glowColor,
    required String label,
    required String value,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF131C31).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with glowing container
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.16),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w700,
                      fontSize: 8.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a SwiftUI frosted glass circular music audio toggle
  Widget _buildSwiftUiAudioToggle() {
    final musicOn = widget.storage.musicEnabled;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final newMusicState = !widget.storage.musicEnabled;
            widget.audio.triggerHaptic();
            await widget.audio.setMusicEnabled(newMusicState);
            if (mounted) setState(() {});
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF131C31).withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: musicOn
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              musicOn
                  ? Icons.music_note_rounded
                  : Icons.music_off_rounded,
              color: musicOn
                  ? const Color(0xFF00E5FF)
                  : Colors.white54,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a SwiftUI style Play Button with animated dynamic shimmer sweep
  Widget _buildSwiftUiPlayButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shimmerController]),
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.035);
        final currentScale = _isPlayPressed ? 0.94 : pulseScale;

        return Transform.scale(
          scale: currentScale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isPlayPressed = true),
            onTapUp: (_) {
              setState(() => _isPlayPressed = false);
              _playGame();
            },
            onTapCancel: () => setState(() => _isPlayPressed = false),
            child: Container(
              width: 270,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  // Luminous ambient neon bloom
                  BoxShadow(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.50),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Stack(
                    children: [
                      // Base vibrant SwiftUI gradient
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF9F1C),
                              Color(0xFFFF5722),
                              Color(0xFFE63946),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.6,
                          ),
                        ),
                      ),

                      // Dynamic Shimmer Light Sweep across button
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, _) {
                            final shimmerPos = _shimmerController.value;
                            return ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment(-2.0 + (shimmerPos * 4.0), -0.5),
                                  end: Alignment(-0.5 + (shimmerPos * 4.0), 0.5),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.55),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            );
                          },
                        ),
                      ),

                      // Button Content (Play Icon + Typography)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'PLAY GAME',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
