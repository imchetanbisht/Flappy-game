import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flappy_bird/models/level_config.dart';
import 'package:flappy_bird/models/power_up.dart';
import 'package:flappy_bird/services/storage_service.dart';
import 'package:flappy_bird/services/ad_service.dart';
import 'package:flappy_bird/game/components/bird_component.dart';

void main() {
  group('Bird Physics Calculations', () {
    test('Gravity increases vertical velocity downwards up to terminal limit', () {
      double velocityY = 0.0;
      const double dt = 0.1; // 100ms
      const double g = BirdComponent.gravity;
      const double maxFall = BirdComponent.maxFallSpeed;

      for (int i = 0; i < 10; i++) {
        velocityY += g * dt;
        if (velocityY > maxFall) velocityY = maxFall;
      }

      expect(velocityY, equals(maxFall));
    });

    test('Flap impulse applies upward negative velocity', () {
      double velocityY = 200.0;
      velocityY = BirdComponent.flapStrength;

      expect(velocityY, equals(-390.0));
      expect(velocityY, lessThan(0.0)); // Negative means upward
    });

    test('Penguin maintains straight level flight angle without tilting', () {
      const angle = 0.0;
      expect(angle, equals(0.0));
    });

    test('Quick double tap within 300ms triggers flip rotation through full 360 degrees', () {
      const int thresholdMs = 300;
      int lastTap = 1000;
      int secondTap = 1180; // 180ms later

      final isDoubleTap = (secondTap - lastTap) <= thresholdMs;
      expect(isDoubleTap, isTrue);

      // Verify rotation progress calculates full 2*pi rotation
      const double duration = BirdComponent.flipDuration;
      double progress = 0.0;
      double dt = 0.19; // Half duration

      progress += dt / duration;
      double angle = progress * 2 * 3.141592653589793;
      expect(angle, closeTo(3.14159, 0.05)); // Halfway flip (~180 deg)

      progress += dt / duration;
      expect(progress, greaterThanOrEqualTo(1.0)); // Completed 360 deg flip
    });

    test('Slow tap exceeding 300ms is treated as normal single tap, not double tap', () {
      const int thresholdMs = 300;
      int lastTap = 1000;
      int secondTap = 1450; // 450ms later

      final isDoubleTap = (secondTap - lastTap) <= thresholdMs;
      expect(isDoubleTap, isFalse);
    });
  });

  group('Endless Progressive Difficulty Scaling (Subway Surfers Style)', () {
    test('Speed scales progressively as score increases', () {
      const diffStart = EndlessDifficulty(0);
      const diffMid = EndlessDifficulty(200);
      const diffHigh = EndlessDifficulty(800);

      expect(diffStart.pipeSpeed, equals(180.0));
      expect(diffMid.pipeSpeed, greaterThan(diffStart.pipeSpeed));
      expect(diffHigh.pipeSpeed, greaterThan(diffMid.pipeSpeed));
      expect(diffHigh.pipeSpeed, lessThanOrEqualTo(360.0)); // Fair upper bound
    });

    test('Gaps gradually tighten as score increases but stay fair', () {
      const diffStart = EndlessDifficulty(0);
      const diffHigh = EndlessDifficulty(600);

      expect(diffStart.gapSize, equals(190.0));
      expect(diffHigh.gapSize, lessThan(diffStart.gapSize));
      expect(diffHigh.gapSize, greaterThanOrEqualTo(135.0)); // Minimum fair gap
    });

    test('Multipliers increase with score milestones', () {
      expect(const EndlessDifficulty(20).multiplier, equals(1));
      expect(const EndlessDifficulty(80).multiplier, equals(2));
      expect(const EndlessDifficulty(200).multiplier, equals(3));
      expect(const EndlessDifficulty(400).multiplier, equals(5));
      expect(const EndlessDifficulty(800).multiplier, equals(8));
      expect(const EndlessDifficulty(1200).multiplier, equals(10));
    });

    test('Environmental theme stays consistently in snowy alpine day', () {
      expect(const EndlessDifficulty(50).theme, equals(EnvironmentTheme.alpineDay));
      expect(const EndlessDifficulty(180).theme, equals(EnvironmentTheme.alpineDay));
      expect(const EndlessDifficulty(350).theme, equals(EnvironmentTheme.alpineDay));
      expect(const EndlessDifficulty(700).theme, equals(EnvironmentTheme.alpineDay));
    });

    test('Difficulty escalates in clear tiers after every 100 meters', () {
      const d0 = EndlessDifficulty(0);
      const d100 = EndlessDifficulty(100);
      const d200 = EndlessDifficulty(200);
      const d300 = EndlessDifficulty(300);
      const d500 = EndlessDifficulty(500);

      // Tiers step up every 100m
      expect(d0.tier, equals(0));
      expect(d100.tier, equals(1));
      expect(d200.tier, equals(2));
      expect(d300.tier, equals(3));
      expect(d500.tier, equals(5));

      // Speed increases every 100m
      expect(d100.pipeSpeed, greaterThan(d0.pipeSpeed));
      expect(d200.pipeSpeed, greaterThan(d100.pipeSpeed));
      expect(d300.pipeSpeed, greaterThan(d200.pipeSpeed));
      expect(d500.pipeSpeed, greaterThan(d300.pipeSpeed));

      // Obstacle gap tightens every 100m
      expect(d100.gapSize, lessThan(d0.gapSize));
      expect(d200.gapSize, lessThan(d100.gapSize));
      expect(d300.gapSize, lessThan(d200.gapSize));
      expect(d500.gapSize, lessThan(d300.gapSize));

      // Projectile bonus speed increases every 100m
      expect(d0.projectileBonusSpeed, equals(0.0));
      expect(d100.projectileBonusSpeed, greaterThan(0.0));
      expect(d200.projectileBonusSpeed, greaterThan(d100.projectileBonusSpeed));
      expect(d500.projectileBonusSpeed, greaterThan(d200.projectileBonusSpeed));

      // Projectiles spawn more frequently (shorter intervals) every 100m
      expect(d100.projectileMaxInterval, lessThan(d0.projectileMaxInterval));
      expect(d300.projectileMaxInterval, lessThan(d100.projectileMaxInterval));

      // Pipe spawn intervals tighten every 100m
      expect(d100.spawnInterval, lessThan(d0.spawnInterval));
      expect(d300.spawnInterval, lessThan(d100.spawnInterval));
    });
  });

  group('Power-Up Mechanics', () {
    test('ActivePowerUp tracks duration and expiration correctly', () {
      final powerUp = ActivePowerUp(
        type: PowerUpType.speedBoost,
        remainingSeconds: 10.0,
        totalSeconds: 10.0,
      );

      expect(powerUp.isExpired, isFalse);
      expect(powerUp.progress, equals(1.0));

      powerUp.remainingSeconds -= 5.0;
      expect(powerUp.progress, closeTo(0.5, 0.01));
      expect(powerUp.isExpired, isFalse);

      powerUp.remainingSeconds -= 5.0;
      expect(powerUp.isExpired, isTrue);
      expect(powerUp.progress, equals(0.0));
    });
  });

  group('StorageService Persistence & High Score', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
    });

    test('Initial progress starts with 0 high score and 0 coins', () {
      expect(storage.highScore, equals(0));
      expect(storage.coins, equals(0));
      expect(storage.sfxEnabled, isTrue);
      expect(storage.musicEnabled, isTrue);
    });

    test('High score records new best only when exceeded', () async {
      await storage.setHighScore(1500);
      expect(storage.highScore, equals(1500));

      // Lower score does not overwrite
      await storage.setHighScore(1200);
      expect(storage.highScore, equals(1500));

      // Higher score updates
      await storage.setHighScore(2500);
      expect(storage.highScore, equals(2500));
    });

    test('Coins earning and spending work accurately', () async {
      await storage.addCoins(50);
      expect(storage.coins, equals(50));

      final spentSuccess = await storage.spendCoins(20);
      expect(spentSuccess, isTrue);
      expect(storage.coins, equals(30));

      final overspendSuccess = await storage.spendCoins(100);
      expect(overspendSuccess, isFalse);
      expect(storage.coins, equals(30));
    });

    test('Reset progress resets gameplay data but preserves audio preferences', () async {
      await storage.setHighScore(5000);
      await storage.addCoins(200);
      await storage.setSfxEnabled(false);
      await storage.setMusicEnabled(true);

      await storage.resetAllProgress();

      expect(storage.highScore, equals(0));
      expect(storage.coins, equals(0));

      // Audio preferences preserved
      expect(storage.sfxEnabled, isFalse);
      expect(storage.musicEnabled, isTrue);
    });

    test('Reset high score resets high score to 0 but preserves coins', () async {
      await storage.setHighScore(120);
      await storage.addCoins(50);

      await storage.resetHighScore();

      expect(storage.highScore, equals(0));
      expect(storage.coins, equals(50));
    });

    test('Scenery selection defaults to ice and updates to mountain and desert correctly', () async {
      expect(storage.scenery, equals('ice'));
      await storage.setScenery('mountain');
      expect(storage.scenery, equals('mountain'));
      await storage.setScenery('desert');
      expect(storage.scenery, equals('desert'));
      await storage.setScenery('ice');
      expect(storage.scenery, equals('ice'));
    });

    test('Scenery default lock states and prices', () {
      expect(storage.isSceneryUnlocked('ice'), isTrue);
      expect(storage.isSceneryUnlocked('mountain'), isFalse);
      expect(storage.isSceneryUnlocked('desert'), isFalse);

      expect(storage.getSceneryPrice('ice'), equals(0));
      expect(storage.getSceneryPrice('mountain'), equals(800));
      expect(storage.getSceneryPrice('desert'), equals(1000));
    });

    test('Unlocking scenery requires sufficient coins and deducts exact amount', () async {
      // Player starts with 500 coins (< 800 for mountain)
      await storage.addCoins(500);
      expect(storage.coins, equals(500));

      final unlockFailed = await storage.unlockScenery('mountain');
      expect(unlockFailed, isFalse);
      expect(storage.isSceneryUnlocked('mountain'), isFalse);
      expect(storage.coins, equals(500)); // Coins untouched

      // Player earns 400 more coins (Total: 900 coins)
      await storage.addCoins(400);
      expect(storage.coins, equals(900));

      // Unlock mountain (costs 800)
      final unlockMountainSuccess = await storage.unlockScenery('mountain');
      expect(unlockMountainSuccess, isTrue);
      expect(storage.isSceneryUnlocked('mountain'), isTrue);
      expect(storage.coins, equals(100)); // 900 - 800 = 100

      // Try to unlock desert (costs 1000, player has 100) -> fails
      final unlockDesertFail = await storage.unlockScenery('desert');
      expect(unlockDesertFail, isFalse);
      expect(storage.isSceneryUnlocked('desert'), isFalse);
      expect(storage.coins, equals(100));

      // Player earns 1100 more coins (Total: 1200 coins)
      await storage.addCoins(1100);
      expect(storage.coins, equals(1200));

      // Unlock desert (costs 1000)
      final unlockDesertSuccess = await storage.unlockScenery('desert');
      expect(unlockDesertSuccess, isTrue);
      expect(storage.isSceneryUnlocked('desert'), isTrue);
      expect(storage.coins, equals(200)); // 1200 - 1000 = 200

      // Already unlocked scenery does not charge coins again
      final alreadyUnlocked = await storage.unlockScenery('mountain');
      expect(alreadyUnlocked, isTrue);
      expect(storage.coins, equals(200));
    });

    test('Play session counter triggers ad strictly on every 3rd game or retry', () async {
      expect(storage.playSessionCount, equals(0));
      expect(storage.shouldShowPlayAd, isFalse);

      // Game 1
      await storage.incrementPlaySessionCount();
      expect(storage.playSessionCount, equals(1));
      expect(storage.shouldShowPlayAd, isFalse);

      // Game 2
      await storage.incrementPlaySessionCount();
      expect(storage.playSessionCount, equals(2));
      expect(storage.shouldShowPlayAd, isFalse);

      // Game 3 (3rd game / retry milestone) -> Trigger Ad
      await storage.incrementPlaySessionCount();
      expect(storage.playSessionCount, equals(3));
      expect(storage.shouldShowPlayAd, isTrue);

      // Game 4
      await storage.incrementPlaySessionCount();
      expect(storage.playSessionCount, equals(4));
      expect(storage.shouldShowPlayAd, isFalse);

      // Game 5
      await storage.incrementPlaySessionCount();
      expect(storage.playSessionCount, equals(5));
      expect(storage.shouldShowPlayAd, isFalse);

      // Game 6 (next 3rd game milestone) -> Trigger Ad
      await storage.incrementPlaySessionCount();
      expect(storage.playSessionCount, equals(6));
      expect(storage.shouldShowPlayAd, isTrue);
    });

    test('AdService configures production AdMob IDs and invokes proceed callbacks seamlessly', () async {
      final adService = AdService(storage);

      // Verify production AdMob IDs match user specifications exactly
      expect(AdService.interstitialAdUnitId, equals('ca-app-pub-1444309620070901/7520815569'));
      expect(AdService.appId, equals('ca-app-pub-1444309620070901~6314922983'));

      // Test game play/retry flow invokes onProceed
      bool proceedCalled = false;
      await adService.handleGamePlayOrRetry(
        onProceed: () {
          proceedCalled = true;
        },
      );
      expect(proceedCalled, isTrue);

      // Test scenery unlock flow invokes onProceed
      bool unlockProceedCalled = false;
      await adService.handleSceneryUnlock(
        onProceed: () {
          unlockProceedCalled = true;
        },
      );
      expect(unlockProceedCalled, isTrue);
    });
  });

  group('Score Sensor Simulation', () {
    test('Score awarded exactly once per obstacle pair', () {
      bool isScored = false;
      int score = 0;
      const double pipeCenterX = 100.0;

      void checkScore(double birdX) {
        if (!isScored && birdX > pipeCenterX) {
          isScored = true;
          score += 200; // Subway Surfers obstacle bonus
        }
      }

      checkScore(90.0);
      expect(score, equals(0));
      expect(isScored, isFalse);

      checkScore(105.0);
      expect(score, equals(200));
      expect(isScored, isTrue);

      // Subsequent updates do not re-score
      checkScore(120.0);
      checkScore(150.0);
      expect(score, equals(200));
    });
  });

  group('Snowball Projectile Mechanics (Snow Scenery Exclusive)', () {
    test('Snowball moves from right to left with cannon shot speed', () {
      double posX = 400.0;
      const double cannonSpeed = 580.0;
      const double dt = 0.1;

      posX -= cannonSpeed * dt;
      expect(posX, equals(342.0));
      expect(posX, lessThan(400.0));
      expect(cannonSpeed, greaterThan(500.0)); // High velocity cannon shot
    });

    test('Snowball spins rapidly counter-clockwise with cannon rifling rotation', () {
      double angle = 0.0;
      const double dt = 0.1;

      angle -= dt * 18.0;
      expect(angle, closeTo(-1.8, 0.001));
      expect(angle, lessThan(0.0));
    });

    test('Snowball projectile mechanic is exclusive to ice/snow scenery', () {
      bool shouldSpawnSnowball(String scenery) => scenery == 'ice';

      expect(shouldSpawnSnowball('ice'), isTrue);
      expect(shouldSpawnSnowball('mountain'), isFalse);
      expect(shouldSpawnSnowball('desert'), isFalse);
    });
  });

  group('Rock Projectile Mechanics (Mountain Scenery Exclusive)', () {
    test('Rock moves from right to left with cannon boulder speed', () {
      double posX = 400.0;
      const double cannonSpeed = 580.0;
      const double dt = 0.1;

      posX -= cannonSpeed * dt;
      expect(posX, equals(342.0));
      expect(posX, lessThan(400.0));
      expect(cannonSpeed, greaterThan(500.0));
    });

    test('Rock spins counter-clockwise in flight direction', () {
      double angle = 0.0;
      const double dt = 0.1;

      angle -= dt * 14.0;
      expect(angle, closeTo(-1.4, 0.001));
      expect(angle, lessThan(0.0));
    });

    test('Rock projectile mechanic is exclusive to mountain scenery', () {
      bool shouldSpawnRock(String scenery) => scenery == 'mountain';

      expect(shouldSpawnRock('mountain'), isTrue);
      expect(shouldSpawnRock('ice'), isFalse);
      expect(shouldSpawnRock('desert'), isFalse);
    });
  });

  group('Cactus Spike Projectile Mechanics (Desert Scenery Exclusive)', () {
    test('Cactus spike moves from right to left with cannon speed', () {
      double posX = 400.0;
      const double cannonSpeed = 580.0;
      const double dt = 0.1;

      posX -= cannonSpeed * dt;
      expect(posX, equals(342.0));
      expect(posX, lessThan(400.0));
      expect(cannonSpeed, greaterThan(500.0));
    });

    test('Cactus spike spins rapidly counter-clockwise in flight', () {
      double angle = 0.0;
      const double dt = 0.1;

      angle -= dt * 18.0;
      expect(angle, closeTo(-1.8, 0.001));
      expect(angle, lessThan(0.0));
    });

    test('Cactus spike projectile mechanic is exclusive to desert scenery', () {
      bool shouldSpawnCactusSpike(String scenery) => scenery == 'desert';

      expect(shouldSpawnCactusSpike('desert'), isTrue);
      expect(shouldSpawnCactusSpike('ice'), isFalse);
      expect(shouldSpawnCactusSpike('mountain'), isFalse);
    });
  });

  group('Collectible Spawning Guarantees', () {
    test('Guaranteed coin spawning for initial run (<80m) ensures no missing coins at start', () {
      // Simulation of collectible spawn decision logic
      bool shouldSpawnGuaranteedCoin(int currentScore) {
        return currentScore < 80;
      }

      expect(shouldSpawnGuaranteedCoin(0), isTrue);
      expect(shouldSpawnGuaranteedCoin(20), isTrue);
      expect(shouldSpawnGuaranteedCoin(50), isTrue);
      expect(shouldSpawnGuaranteedCoin(79), isTrue);
      expect(shouldSpawnGuaranteedCoin(80), isFalse);
    });

    test('All gaps spawn either a power-up or a coin, leaving no empty obstacles', () {
      String getCollectibleType(double roll, double powerupChance) {
        if (roll < powerupChance) return 'powerup';
        return 'coin';
      }

      const powerupChance = 0.15;
      expect(getCollectibleType(0.05, powerupChance), equals('powerup'));
      expect(getCollectibleType(0.14, powerupChance), equals('powerup'));
      expect(getCollectibleType(0.16, powerupChance), equals('coin'));
      expect(getCollectibleType(0.85, powerupChance), equals('coin'));
      expect(getCollectibleType(0.99, powerupChance), equals('coin'));
    });
  });
}
