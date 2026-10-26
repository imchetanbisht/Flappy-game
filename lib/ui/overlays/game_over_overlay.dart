import 'package:flutter/material.dart';
import '../../game/flappy_game.dart';
import '../theme/game_theme.dart';
import '../widgets/arcade_button.dart';
import '../widgets/glowing_badge.dart';

class GameOverOverlay extends StatelessWidget {
  final FlappyGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isNewBest = game.score > 0 && game.score >= game.storage.highScore;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: GameTheme.glassCardDecoration(borderColor: const Color(0xFFEF476F)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text('GAME OVER', style: GameTheme.arcadeTitle(fontSize: 32, color: const Color(0xFFEF476F))),
            const SizedBox(height: 18),

            // Score Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Current Score (Distance in meters)
                  Column(
                    children: [
                      const Text(
                        'DISTANCE',
                        style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.score}m',
                        style: GameTheme.numberBadge(fontSize: 32, color: Colors.white),
                      ),
                    ],
                  ),

                  // Divider
                  Container(width: 1.2, height: 44, color: Colors.white24),

                  // High Score (Best Distance in meters)
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'BEST',
                            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          if (isNewBest) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD166),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.storage.highScore}m',
                        style: GameTheme.numberBadge(fontSize: 32, color: GameTheme.gold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Coins earned badge
            GlowingBadge(
              icon: Icons.monetization_on_rounded,
              label: '+${game.sessionCoins} COINS EARNED',
              iconColor: GameTheme.gold,
              backgroundColor: Colors.black.withAlpha(100),
              fontSize: 14,
            ),
            const SizedBox(height: 22),

            // Retry Button: immediately returns to ready state to flap again!
            ArcadeButton(
              text: 'TAP TO RETRY',
              icon: Icons.replay_rounded,
              gradient: GameTheme.buttonOrangeGradient,
              shadowColor: const Color(0xFFB54502),
              onPressed: () {
                game.audio.playClick();
                game.adService.handleGamePlayOrRetry(
                  onProceed: () {
                    game.resetGame();
                  },
                );
              },
            ),
            const SizedBox(height: 12),

            // Home Button
            ArcadeButton(
              text: 'HOME',
              icon: Icons.home_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF3A0CA3), Color(0xFF4361EE)],
              ),
              shadowColor: const Color(0xFF1E1B4B),
              onPressed: () {
                game.audio.playClick();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
