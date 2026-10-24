import 'package:flutter/material.dart';

enum EnvironmentTheme {
  alpineDay,
  sunsetGlow,
  midnightStars,
  cyberNeon,
}

class EndlessDifficulty {
  final int score; // Distance in meters (m)

  const EndlessDifficulty(this.score);

  /// Current 100-meter difficulty tier:
  /// Stage 0: 0-99m (Introductory)
  /// Stage 1: 100-199m (Moderate)
  /// Stage 2: 200-299m (Challenging)
  /// Stage 3: 300-399m (Intense)
  /// Stage 4: 400-499m (Expert)
  /// Stage 5+: 500m+ (Master / Insane)
  int get tier => score ~/ 100;

  /// Progressive speed scaling with distinct tier increases every 100 meters:
  /// 0-99m: starts at 180 px/s
  /// 100m: jumps to ~208 px/s
  /// 200m: jumps to ~236 px/s
  /// 300m: jumps to ~264 px/s
  /// 400m: jumps to ~292 px/s
  /// 500m+: 320 to 360 px/s max.
  double get pipeSpeed {
    final stages = score ~/ 100;
    final progressWithinStage = (score % 100) / 100.0;
    final stageSpeed = 180.0 + (stages * 28.0) + (progressWithinStage * 4.0);
    return stageSpeed.clamp(180.0, 360.0);
  }

  /// Progressive gap narrowing every 100 meters:
  /// 0-99m: 190.0 px (wide & comfortable)
  /// 100-199m: ~178 px
  /// 200-299m: ~167 px
  /// 300-399m: ~156 px
  /// 400-499m: ~145 px
  /// 500m+: down to 135 px (tightest fair gap)
  double get gapSize {
    final stages = score ~/ 100;
    final progressWithinStage = (score % 100) / 100.0;
    final stageGap = 190.0 - (stages * 11.0) - (progressWithinStage * 2.0);
    return stageGap.clamp(135.0, 190.0);
  }

  /// Spawn interval adjusted so obstacles (pipes, spikes, cacti) arrive closer together
  /// and significantly more frequently after each 100-meter milestone:
  /// 0-99m: ~2.1s
  /// 100-199m: ~1.6s
  /// 200-299m: ~1.2s
  /// 300-399m: ~0.95s
  /// 400-499m: ~0.77s
  /// 500m+: ~0.60s
  double get spawnInterval {
    final stages = score ~/ 100;
    final progressWithinStage = (score % 100) / 100.0;
    final desiredDistance = (380.0 - (stages * 42.0) - (progressWithinStage * 8.0)).clamp(185.0, 380.0);
    final interval = desiredDistance / pipeSpeed;
    return interval.clamp(0.60, 2.2);
  }

  /// Projectiles (snowballs, rocks, cactus spikes) spawn faster as 100m stages advance:
  /// 0-99m: 2.0s - 3.0s
  /// 100-199m: 1.78s - 2.70s
  /// 200-299m: 1.56s - 2.40s
  /// 300-399m: 1.34s - 2.10s
  /// 500m+: 0.8s - 1.5s
  double get projectileMinInterval {
    final stages = score ~/ 100;
    return (2.0 - (stages * 0.22)).clamp(0.75, 2.0);
  }

  double get projectileMaxInterval {
    final stages = score ~/ 100;
    return (3.0 - (stages * 0.30)).clamp(1.2, 3.0);
  }

  /// Projectiles fly faster across the screen after each 100 meters
  double get projectileBonusSpeed {
    final stages = score ~/ 100;
    return (stages * 35.0).clamp(0.0, 220.0);
  }

  /// Power-up spawn rate: slightly scarcer at higher tiers to reward genuine skill
  double get powerupSpawnRate {
    final stages = score ~/ 100;
    return (0.22 - (stages * 0.02)).clamp(0.08, 0.22);
  }

  double get coinSpawnRate => 0.65;

  // Rank multiplier badges based on meters milestone
  int get multiplier {
    if (score < 50) return 1;
    if (score < 150) return 2;
    if (score < 300) return 3;
    if (score < 500) return 5;
    if (score < 1000) return 8;
    return 10;
  }

  // Keep the snowy winter atmosphere constant throughout the entire game!
  EnvironmentTheme get theme => EnvironmentTheme.alpineDay;
}

extension ThemeVisuals on EnvironmentTheme {
  List<Color> get skyGradient {
    switch (this) {
      case EnvironmentTheme.alpineDay:
        return const [Color(0xFF64B5F6), Color(0xFFBBDEFB), Color(0xFFE3F2FD)];
      case EnvironmentTheme.sunsetGlow:
        return const [Color(0xFFE65100), Color(0xFFFFB74D), Color(0xFFFFE0B2)];
      case EnvironmentTheme.midnightStars:
        return const [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)];
      case EnvironmentTheme.cyberNeon:
        return const [Color(0xFF240046), Color(0xFF3C096C), Color(0xFF7B2CBF)];
    }
  }

  Color get groundTopColor {
    switch (this) {
      case EnvironmentTheme.alpineDay:
        return const Color(0xFFFFFFFF); // Crisp snowy crust
      case EnvironmentTheme.sunsetGlow:
        return const Color(0xFFFFEBEE); // Sunset-kissed snow
      case EnvironmentTheme.midnightStars:
        return const Color(0xFFE2E8F0); // Moonlit snow
      case EnvironmentTheme.cyberNeon:
        return const Color(0xFF80DEEA); // Neon ice crust
    }
  }

  Color get groundBodyColor {
    switch (this) {
      case EnvironmentTheme.alpineDay:
        return const Color(0xFF5A7285); // Permafrost slate/stone
      case EnvironmentTheme.sunsetGlow:
        return const Color(0xFF6D4C41);
      case EnvironmentTheme.midnightStars:
        return const Color(0xFF1E293B);
      case EnvironmentTheme.cyberNeon:
        return const Color(0xFF16003B);
    }
  }
}
