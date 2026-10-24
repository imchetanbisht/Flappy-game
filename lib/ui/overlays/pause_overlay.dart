import 'package:flutter/material.dart';
import '../../game/flappy_game.dart';
import '../theme/game_theme.dart';
import '../widgets/arcade_button.dart';

class PauseOverlay extends StatefulWidget {
  final FlappyGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: GameTheme.glassCardDecoration(borderColor: const Color(0xFF00B4D8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAUSED', style: GameTheme.arcadeTitle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              'Distance: ${game.score}m • Best: ${game.storage.highScore}m',
              style: GameTheme.arcadeSubtitle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Sound and Music Quick Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggle(
                  icon: game.storage.sfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  label: 'SFX',
                  enabled: game.storage.sfxEnabled,
                  onTap: () async {
                    await game.storage.setSfxEnabled(!game.storage.sfxEnabled);
                    game.audio.playClick();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 20),
                _buildToggle(
                  icon: game.storage.musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                  label: 'Music',
                  enabled: game.storage.musicEnabled,
                  onTap: () async {
                    await game.audio.setMusicEnabled(!game.storage.musicEnabled);
                    game.audio.playClick();
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Resume Button
            ArcadeButton(
              text: 'RESUME',
              icon: Icons.play_arrow_rounded,
              gradient: GameTheme.buttonGreenGradient,
              shadowColor: const Color(0xFF023E8A),
              onPressed: () {
                game.audio.playClick();
                game.resumeGame();
              },
            ),
            const SizedBox(height: 14),

            // Restart Button
            ArcadeButton(
              text: 'RESTART',
              icon: Icons.refresh_rounded,
              gradient: GameTheme.buttonOrangeGradient,
              shadowColor: const Color(0xFFB54502),
              onPressed: () {
                game.audio.playClick();
                game.resetGame();
              },
            ),
            const SizedBox(height: 14),

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

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0x3300B4D8) : Colors.black38,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: enabled ? const Color(0xFF00B4D8) : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? const Color(0xFF00E5FF) : Colors.white54, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
