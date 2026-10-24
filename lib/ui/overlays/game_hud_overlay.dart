import 'package:flutter/material.dart';
import '../../game/flappy_game.dart';
import '../../models/game_state.dart';

class GameHudOverlay extends StatefulWidget {
  final FlappyGame game;

  const GameHudOverlay({super.key, required this.game});

  @override
  State<GameHudOverlay> createState() => _GameHudOverlayState();
}

class _GameHudOverlayState extends State<GameHudOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return SafeArea(
      child: SizedBox.expand(
        child: Stack(
          children: [
          // 1. TOP-LEFT: HIGH-CONTRAST REAL-TIME RUNNING METER PILL
          Positioned(
            top: 14,
            left: 16,
            child: IgnorePointer(
              child: ValueListenableBuilder<int>(
                valueListenable: game.scoreNotifier,
                builder: (context, score, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // High-contrast arcade pill badge visible on any background
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xEE12172A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD166),
                            width: 1.6,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66FFD166),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              color: Color(0xFFFFD166),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'm',
                              style: TextStyle(
                                color: Color(0xFFFFD166),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // New High Score Real-time Celebration Banner
                      if (game.hasBeatenHighScoreThisRun)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x88FFB703), blurRadius: 8),
                            ],
                          ),
                          child: const Text(
                            'NEW HIGH SCORE!',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. TOP-RIGHT: GLOWING PAUSE BUTTON
          Positioned(
            top: 14,
            right: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                game.audio.playClick();
                game.pauseGame();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xEE1E1E2C),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD166), width: 1.6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66FFD166),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: Color(0xFFFFD166),
                  size: 24,
                ),
              ),
            ),
          ),

          // 3. ACTIVE POWERUP BADGES (Left Side Below Live Meter)
          Positioned(
            top: 70,
            left: 16,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: game.scoreNotifier,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (game.isBirdShielded)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xDD006064),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E5FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'SHIELD (${game.birdShieldRemaining.ceil()}s)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (game.activeSpeedBoost != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65100), Color(0xFFFF9100)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD600), width: 1.2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x77FFD600), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, color: Color(0xFFFFEA00), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'THUNDER SPEED (${game.activeSpeedBoost!.remainingSeconds.ceil()}s)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),


          // 5. CENTER PROMPT: TAP ANYWHERE TO FLY (Only in Ready State)
          Positioned.fill(
            child: ValueListenableBuilder<GameStatus>(
              valueListenable: game.statusNotifier,
              builder: (context, currentStatus, _) {
                if (currentStatus != GameStatus.ready) {
                  return const SizedBox.shrink();
                }

                return IgnorePointer(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final offset = _pulseController.value * 12.0;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.translate(
                              offset: Offset(0, -offset),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white54, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black54, blurRadius: 16),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.touch_app_rounded,
                                  size: 46,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(180),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: const Text(
                                'TAP ANYWHERE TO FLY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
  }
}
