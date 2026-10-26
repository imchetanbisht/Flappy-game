import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/level_config.dart';
import '../models/power_up.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import 'components/background_component.dart';
import 'components/bird_component.dart';
import 'components/cactus_spike_component.dart';
import 'components/ground_component.dart';
import 'components/particle_system.dart';
import 'components/pipe_pair_component.dart';
import 'components/rock_component.dart';
import 'components/snowball_component.dart';

class FlappyGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  final StorageService storage;
  final AudioService audio;
  final AdService adService;

  FlappyGame({
    required this.storage,
    required this.audio,
    AdService? adService,
  }) : adService = adService ?? AdService(storage, audio) {
    statusNotifier = ValueNotifier<GameStatus>(GameStatus.ready);
    scoreNotifier = ValueNotifier<int>(0);
    coinNotifier = ValueNotifier<int>(storage.coins);
    multiplierNotifier = ValueNotifier<int>(1);
    milestoneNotifier = ValueNotifier<int?>(null);
  }

  // ValueNotifiers for reactive UI without frame stutter
  late final ValueNotifier<GameStatus> statusNotifier;
  late final ValueNotifier<int> scoreNotifier;
  late final ValueNotifier<int> coinNotifier;
  late final ValueNotifier<int> multiplierNotifier;
  late final ValueNotifier<int?> milestoneNotifier;

  // Assets
  late ui.Image birdImage1;
  late ui.Image birdImage2;
  late ui.Image birdHurtImage;
  late ui.Image snowyFarImage;
  late ui.Image snowyMidImage;
  late ui.Image snowyNearImage;
  late ui.Image iceSpikeUpImage;
  late ui.Image iceSpikeDownImage;
  late ui.Image pipeImage;
  late ui.Image mountainBgImage;
  late ui.Image cactusImage;
  late ui.Image desertFarImage;
  late ui.Image desertCloudsImage;
  late ui.Image desertMidImage;
  late ui.Image desertNearImage;
  late ui.Image snowballImage;
  late ui.Image rockImage;
  late ui.Image cactusSpikeImage;

  // Components
  late BackgroundComponent background;
  late GroundComponent ground;
  late BirdComponent bird;
  late ParticleManager particles;

  // Game State
  GameStatus status = GameStatus.ready;

  // Distance in Meters Scoring
  double _distanceMetersAccumulator = 0.0;
  int score = 0; // Distance in meters (m)
  int sessionCoins = 0;
  int comboStreak = 0;
  bool hasRevivedThisRun = false;
  bool hasBeatenHighScoreThisRun = false;
  int initialHighScore = 0;

  // Progressive Difficulty
  EndlessDifficulty get difficulty => EndlessDifficulty(score);

  // Timers & Spawners
  double _pipeSpawnTimer = 0.0;
  double _snowballSpawnTimer = 0.0;
  double _nextSnowballInterval = 2.8;
  double _rockSpawnTimer = 0.0;
  double _nextRockInterval = 2.8;
  double _cactusSpikeSpawnTimer = 0.0;
  double _nextCactusSpikeInterval = 2.8;
  final Random _rnd = Random();
  double? _lastGapY;

  // Active Power-ups
  ActivePowerUp? activeSpeedBoost;

  bool get isReady => status == GameStatus.ready;
  bool get isPlaying => status == GameStatus.playing;
  bool get isPaused => status == GameStatus.paused;
  bool get isGameOver => status == GameStatus.gameOver;

  bool get isBirdShielded {
    if (!isLoaded) return false;
    try {
      return bird.isShielded;
    } catch (_) {
      return false;
    }
  }

  double get birdShieldRemaining {
    if (!isLoaded) return 0.0;
    try {
      return bird.shieldTimeRemaining;
    } catch (_) {
      return 0.0;
    }
  }

  double get groundY => size.y - 100.0;

  double get effectiveSpeed {
    final baseSpeed = difficulty.pipeSpeed;
    if (activeSpeedBoost != null && !activeSpeedBoost!.isExpired) {
      return baseSpeed * 1.55; // 55% speed increase during 10s thunder powerup!
    }
    return baseSpeed;
  }

  @override
  Color backgroundColor() => const Color(0xFF14141E);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Clear in-memory cached UI images so newly updated textures are always freshly loaded
    _imageCache.clear();

    // 1. Load image assets
    birdImage1 = await _loadUiImage('assets/images/penguin-1.png');
    birdImage2 = await _loadUiImage('assets/images/penguin-2.png');
    birdHurtImage = await _loadUiImage('assets/images/penguin-hurt.png');
    snowyFarImage = await _loadUiImage('assets/images/snowy_mountains_far.png');
    snowyMidImage = await _loadUiImage('assets/images/snowy_mountains_mid.png');
    snowyNearImage = await _loadUiImage('assets/images/snowy_trees_near.png');
    iceSpikeUpImage = await _loadUiImage('assets/images/ice_spike_up.png');
    iceSpikeDownImage = await _loadUiImage('assets/images/ice_spike_down.png');
    pipeImage = await _loadUiImage('assets/images/pipe.png');
    mountainBgImage = await _loadUiImage('assets/images/mountains-bg.png');
    cactusImage = await _loadUiImage('assets/images/cactus.png');
    desertFarImage = await _loadUiImage('assets/images/desert_mountains_far.png');
    desertCloudsImage = await _loadUiImage('assets/images/desert_clouds.png');
    desertMidImage = await _loadUiImage('assets/images/desert_mountains_mid.png');
    desertNearImage = await _loadUiImage('assets/images/desert_trees_near.png');
    snowballImage = await _loadUiImage('assets/images/snowball.png');
    rockImage = await _loadUiImage('assets/images/rock_round.png');
    cactusSpikeImage = await _loadUiImage('assets/images/cactus_spike.png');

    // 2. Initialize particle manager
    particles = ParticleManager();
    add(particles);

    // 3. Initialize background
    background = BackgroundComponent(
      size: size,
      scenery: storage.scenery,
      snowyFarImage: snowyFarImage,
      snowyMidImage: snowyMidImage,
      snowyNearImage: snowyNearImage,
      mountainBgImage: mountainBgImage,
      desertFarImage: desertFarImage,
      desertCloudsImage: desertCloudsImage,
      desertMidImage: desertMidImage,
      desertNearImage: desertNearImage,
      scrollSpeed: effectiveSpeed,
      theme: difficulty.theme,
    );
    add(background);

    // 4. Initialize ground
    ground = GroundComponent(
      position: Vector2(0, groundY),
      size: Vector2(size.x, 100.0),
      scrollSpeed: effectiveSpeed,
      scenery: storage.scenery,
      theme: difficulty.theme,
    );
    add(ground);

    // 5. Initialize player (Penguin)
    bird = BirdComponent(
      position: Vector2(size.x * 0.32, size.y * 0.45),
      frame1: birdImage1,
      frame2: birdImage2,
      hurtFrame: birdHurtImage,
    );
    add(bird);

    // Start in ready state
    resetGame();
  }

  static final Map<String, ui.Image> _imageCache = {};

  Future<ui.Image> _createFallbackRockImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 128, 96));
    final paint = Paint()..color = const Color(0xFF6D4C41);
    final highlightPaint = Paint()..color = const Color(0xFF8D6E63);
    final darkPaint = Paint()..color = const Color(0xFF4E342E);

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        final cx = col * 32.0 + 16.0;
        final cy = row * 32.0 + 16.0;
        canvas.drawCircle(Offset(cx, cy), 13.0, paint);
        canvas.drawCircle(Offset(cx - 3, cy - 3), 9.0, highlightPaint);
        canvas.drawCircle(Offset(cx + 4, cy + 4), 6.0, darkPaint);
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(128, 96);
  }

  Future<ui.Image> _createFallbackSnowballImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 32, 32));
    final paint = Paint()..color = Colors.white;
    final rimPaint = Paint()
      ..color = const Color(0xFFB3E5FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(const Offset(16.0, 16.0), 13.0, paint);
    canvas.drawCircle(const Offset(16.0, 16.0), 13.0, rimPaint);

    final picture = recorder.endRecording();
    return picture.toImage(32, 32);
  }

  Future<ui.Image> _createFallbackCactusSpikeImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 64, 64));
    final bodyPaint = Paint()..color = const Color(0xFF4B7A33);
    final highlightPaint = Paint()..color = const Color(0xFF689F38);
    final spikePaint = Paint()..color = const Color(0xFFFFEE8C);
    final outlinePaint = Paint()
      ..color = const Color(0xFF1B3B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const center = Offset(32.0, 32.0);
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2.0 * pi) / 8;
      final tip = Offset(center.dx + cos(angle) * 30.0, center.dy + sin(angle) * 30.0);
      final p1 = Offset(center.dx + cos(angle) * 16.0 + cos(angle + pi / 2) * 4.0,
                        center.dy + sin(angle) * 16.0 + sin(angle + pi / 2) * 4.0);
      final p2 = Offset(center.dx + cos(angle) * 16.0 + cos(angle - pi / 2) * 4.0,
                        center.dy + sin(angle) * 16.0 + sin(angle - pi / 2) * 4.0);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(tip.dx, tip.dy)..lineTo(p2.dx, p2.dy)..close();
      canvas.drawPath(path, spikePaint);
      canvas.drawPath(path, outlinePaint);
    }

    canvas.drawCircle(center, 18.0, bodyPaint);
    canvas.drawCircle(center, 18.0, outlinePaint);
    canvas.drawCircle(const Offset(28.0, 28.0), 10.0, highlightPaint);

    final picture = recorder.endRecording();
    return picture.toImage(64, 64);
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final cached = _imageCache[assetPath];
    if (cached != null) return cached;

    try {
      rootBundle.evict(assetPath);
      final byteData = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _imageCache[assetPath] = frame.image;
      return frame.image;
    } catch (e) {
      debugPrint('Warning: Unable to load asset "$assetPath": $e');
      if (assetPath.contains('rock')) {
        final fallback = await _createFallbackRockImage();
        _imageCache[assetPath] = fallback;
        return fallback;
      } else if (assetPath.contains('snowball')) {
        final fallback = await _createFallbackSnowballImage();
        _imageCache[assetPath] = fallback;
        return fallback;
      } else if (assetPath.contains('cactus_spike') || assetPath.contains('spike')) {
        final fallback = await _createFallbackCactusSpikeImage();
        _imageCache[assetPath] = fallback;
        return fallback;
      }
      rethrow;
    }
  }

  void resetGame() {
    _distanceMetersAccumulator = 0.0;
    score = 0;
    sessionCoins = 0;
    comboStreak = 0;
    hasRevivedThisRun = false;
    hasBeatenHighScoreThisRun = false;
    initialHighScore = storage.highScore;
    _lastGapY = null;
    milestoneNotifier.value = null;
    _pipeSpawnTimer = 0.0;
    _snowballSpawnTimer = 0.0;
    final minProj = difficulty.projectileMinInterval;
    final maxProj = difficulty.projectileMaxInterval;
    _nextSnowballInterval = minProj + _rnd.nextDouble() * (maxProj - minProj);
    _rockSpawnTimer = 0.0;
    _nextRockInterval = minProj + _rnd.nextDouble() * (maxProj - minProj);
    _cactusSpikeSpawnTimer = 0.0;
    _nextCactusSpikeInterval = minProj + _rnd.nextDouble() * (maxProj - minProj);
    activeSpeedBoost = null;
    _lastTapTime = 0;

    // Update notifiers
    scoreNotifier.value = 0;
    coinNotifier.value = storage.coins;
    multiplierNotifier.value = 1;

    // Remove existing pipes, snowballs, rocks, and cactus spikes
    children.whereType<PipePairComponent>().toList().forEach((p) => p.removeFromParent());
    children.whereType<SnowballComponent>().toList().forEach((s) => s.removeFromParent());
    children.whereType<RockComponent>().toList().forEach((r) => r.removeFromParent());
    children.whereType<CactusSpikeComponent>().toList().forEach((c) => c.removeFromParent());
    particles.clear();

    // Sync speeds and theme
    background.theme = difficulty.theme;
    background.scrollSpeed = effectiveSpeed;
    ground.theme = difficulty.theme;
    ground.scrollSpeed = effectiveSpeed;

    // Reset bird
    bird.reset(Vector2(size.x * 0.32, size.y * 0.45));

    // Update status and immediately notify UI
    status = GameStatus.ready;
    statusNotifier.value = GameStatus.ready;

    // Overlays
    overlays.remove('pause');
    overlays.remove('game_over');
    if (!overlays.isActive('hud')) {
      overlays.add('hud');
    }

    if (storage.musicEnabled) {
      audio.playBgm(force: true);
    }
  }

  void startGame() {
    if (status == GameStatus.ready) {
      // Start calculating distance strictly from 0m
      _distanceMetersAccumulator = 0.0;
      score = 0;
      scoreNotifier.value = 0;

      status = GameStatus.playing;
      // Immediately notify UI to remove 'Tap anywhere' prompt and reveal running score
      statusNotifier.value = GameStatus.playing;

      bird.flap();
      audio.playFlap();
      _pipeSpawnTimer = difficulty.spawnInterval * 0.6; // First obstacle arrives shortly
    }
  }

  // Quick double-tap tracking
  int _lastTapTime = 0;
  static const int _doubleTapThresholdMs = 300;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    final now = DateTime.now().millisecondsSinceEpoch;
    final isDoubleTap = (now - _lastTapTime) <= _doubleTapThresholdMs;
    _lastTapTime = now;

    if (status == GameStatus.ready) {
      startGame();
    } else if (status == GameStatus.playing) {
      bird.flap();
      audio.playFlap();

      // Quick double tap makes the penguin perform an acrobatic somersault flip
      if (isDoubleTap) {
        bird.doFlip();
        audio.triggerHeavyHaptic();
      }
    }
  }

  @override
  void update(double dt) {
    // Clamp delta time to avoid frame-skip stutter on Android
    final clampedDt = dt.clamp(0.0, 0.033);
    super.update(clampedDt);

    // FREEZE ALL GAMEPLAY on game over or pause!
    if (status != GameStatus.playing) return;

    // 1. Real-time distance in meters based on horizontal flight speed
    // 45 pixels = 1 meter (at 180 px/s, bird covers 4.0 m/s cleanly and steadily)
    final metersDelta = (effectiveSpeed * clampedDt) / 45.0;
    _distanceMetersAccumulator += metersDelta;
    final newScore = _distanceMetersAccumulator.toInt();
    if (newScore != score) {
      final oldTier = score ~/ 100;
      score = newScore;
      scoreNotifier.value = score;
      multiplierNotifier.value = difficulty.multiplier;

      final newTier = newScore ~/ 100;
      if (newTier > oldTier && newTier > 0) {
        on100MeterMilestoneReached(newTier * 100);
      }
    }

    // Check if player surpassed their high score during this run!
    if (initialHighScore > 0 && score > initialHighScore && !hasBeatenHighScoreThisRun) {
      hasBeatenHighScoreThisRun = true;
      audio.playLevelComplete();
      particles.spawnVictoryConfetti(bird.position, size);
    }

    // 2. Update active thunder speed boost
    if (activeSpeedBoost != null) {
      activeSpeedBoost!.remainingSeconds -= clampedDt;
      if (activeSpeedBoost!.isExpired) {
        activeSpeedBoost = null;
      }
    }

    // 3. Dynamic progressive theme and speeds
    background.theme = difficulty.theme;
    background.scrollSpeed = effectiveSpeed;
    ground.theme = difficulty.theme;
    ground.scrollSpeed = effectiveSpeed;

    // 4. Pipe Spawning based on dynamic difficulty
    _pipeSpawnTimer += clampedDt;
    if (_pipeSpawnTimer >= difficulty.spawnInterval) {
      _pipeSpawnTimer = 0.0;
      _spawnPipePair();
    }

    // 5. Projectiles: Snowballs (Snow), Rocks (Mountain), and Cactus Spikes (Desert)
    final minInterval = difficulty.projectileMinInterval;
    final maxInterval = difficulty.projectileMaxInterval;
    if (storage.scenery == 'ice') {
      _snowballSpawnTimer += clampedDt;
      if (_snowballSpawnTimer >= _nextSnowballInterval) {
        _snowballSpawnTimer = 0.0;
        _nextSnowballInterval = minInterval + _rnd.nextDouble() * (maxInterval - minInterval);
        _spawnSnowball();
      }
    } else if (storage.scenery == 'mountain') {
      _rockSpawnTimer += clampedDt;
      if (_rockSpawnTimer >= _nextRockInterval) {
        _rockSpawnTimer = 0.0;
        _nextRockInterval = minInterval + _rnd.nextDouble() * (maxInterval - minInterval);
        _spawnRock();
      }
    } else if (storage.scenery == 'desert') {
      _cactusSpikeSpawnTimer += clampedDt;
      if (_cactusSpikeSpawnTimer >= _nextCactusSpikeInterval) {
        _cactusSpikeSpawnTimer = 0.0;
        _nextCactusSpikeInterval = minInterval + _rnd.nextDouble() * (maxInterval - minInterval);
        _spawnCactusSpike();
      }
    }

    // 6. Check Ground Collision
    if (bird.position.y + BirdComponent.birdHeight / 2 >= groundY) {
      bird.position.y = groundY - BirdComponent.birdHeight / 2;
      triggerGameOver();
    }
  }

  void _spawnSnowball() {
    // Target the penguin's active flight altitude so the player actively dodges it
    final minTargetY = 90.0;
    final maxTargetY = groundY - 60.0;
    final targetY = (bird.position.y + (_rnd.nextDouble() * 100.0 - 50.0)).clamp(minTargetY, maxTargetY);

    // High cannon velocity: increases dynamically every 100 meters
    final snowballSpeed = effectiveSpeed + 370.0 + difficulty.projectileBonusSpeed + (_rnd.nextDouble() * 60.0);

    final snowball = SnowballComponent(
      position: Vector2(size.x + 35.0, targetY),
      snowballImage: snowballImage,
      speed: snowballSpeed,
    );
    add(snowball);

    // Frost muzzle blast at the cannon launch point on the right edge
    particles.spawnCannonMuzzleFlash(Vector2(size.x, targetY));
  }

  void onBirdSnowballCollision(SnowballComponent snowball) {
    if (status != GameStatus.playing) return;
    if (bird.isInvulnerable) return;

    snowball.removeFromParent();

    if (bird.isShielded) {
      bird.isShielded = false;
      bird.setInvulnerable(1.2);
      audio.playPowerup();
      particles.spawnFeatherBurst(bird.position, const Color(0xFF00E5FF));
      return;
    }

    triggerGameOver();
  }

  void _spawnRock() {
    // Target the penguin's active flight altitude so the player actively dodges it
    final minTargetY = 90.0;
    final maxTargetY = groundY - 60.0;
    final targetY = (bird.position.y + (_rnd.nextDouble() * 100.0 - 50.0)).clamp(minTargetY, maxTargetY);

    // High cannon velocity: rock boulder blasts across the screen with progressive speed
    final rockSpeed = effectiveSpeed + 370.0 + difficulty.projectileBonusSpeed + (_rnd.nextDouble() * 60.0);

    final rock = RockComponent(
      position: Vector2(size.x + 35.0, targetY),
      rockImage: rockImage,
      speed: rockSpeed,
    );
    add(rock);

    // Mountain rock launch muzzle blast on the right edge
    particles.spawnRockLaunchMuzzleFlash(Vector2(size.x, targetY));
  }

  void onBirdRockCollision(RockComponent rock) {
    if (status != GameStatus.playing) return;
    if (bird.isInvulnerable) return;

    rock.removeFromParent();

    if (bird.isShielded) {
      bird.isShielded = false;
      bird.setInvulnerable(1.2);
      audio.playPowerup();
      particles.spawnFeatherBurst(bird.position, const Color(0xFF8D6E63));
      return;
    }

    triggerGameOver();
  }

  void _spawnCactusSpike() {
    // Target the penguin's active flight altitude so the player actively dodges it
    final minTargetY = 90.0;
    final maxTargetY = groundY - 60.0;
    final targetY = (bird.position.y + (_rnd.nextDouble() * 100.0 - 50.0)).clamp(minTargetY, maxTargetY);

    // High cannon velocity: cactus spike ball blasts across the screen with progressive speed
    final spikeSpeed = effectiveSpeed + 370.0 + difficulty.projectileBonusSpeed + (_rnd.nextDouble() * 60.0);

    final spike = CactusSpikeComponent(
      position: Vector2(size.x + 35.0, targetY),
      spikeImage: cactusSpikeImage,
      speed: spikeSpeed,
    );
    add(spike);

    // Desert cactus thorn launch muzzle blast on the right edge
    particles.spawnDesertCactusMuzzleFlash(Vector2(size.x, targetY));
  }

  void onBirdCactusSpikeCollision(CactusSpikeComponent spike) {
    if (status != GameStatus.playing) return;
    if (bird.isInvulnerable) return;

    spike.removeFromParent();

    if (bird.isShielded) {
      bird.isShielded = false;
      bird.setInvulnerable(1.2);
      audio.playPowerup();
      particles.spawnFeatherBurst(bird.position, const Color(0xFF689F38));
      return;
    }

    triggerGameOver();
  }

  void _spawnPipePair() {
    final gap = difficulty.gapSize;
    final minGapY = 120.0 + gap / 2;
    final maxGapY = groundY - 80.0 - gap / 2;
    final safeRange = max(10.0, maxGapY - minGapY);

    double gapY;
    final tier = difficulty.tier;
    if (tier >= 1 && _lastGapY != null) {
      // After 100 meters, create vertical elevation variance to challenge reflexes
      final maxDelta = (70.0 + tier * 15.0).clamp(80.0, 180.0);
      final direction = _rnd.nextBool() ? 1.0 : -1.0;
      final proposedGapY = _lastGapY! + direction * (50.0 + _rnd.nextDouble() * maxDelta);
      gapY = proposedGapY.clamp(minGapY, maxGapY);
    } else {
      gapY = minGapY + _rnd.nextDouble() * safeRange;
    }
    _lastGapY = gapY;

    final pipePair = PipePairComponent(
      position: Vector2(size.x + 20, 0),
      scenery: storage.scenery,
      iceSpikeUpImage: iceSpikeUpImage,
      iceSpikeDownImage: iceSpikeDownImage,
      pipeImage: pipeImage,
      cactusImage: cactusImage,
      gapY: gapY,
      gapSize: gap,
      speed: effectiveSpeed,
      groundY: groundY,
    );
    add(pipePair);
  }

  void on100MeterMilestoneReached(int meters) {
    milestoneNotifier.value = meters;
    audio.triggerHeavyHaptic();
    particles.spawnVictoryConfetti(bird.position, size);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (milestoneNotifier.value == meters) {
        milestoneNotifier.value = null;
      }
    });
  }

  void onObstaclePassed() {
    if (status != GameStatus.playing) return;

    comboStreak++;
    storage.incrementPipes(1);
  }

  void onCoinCollected(Vector2 pos) {
    sessionCoins++;
    storage.addCoins(1);
    coinNotifier.value = storage.coins;
    audio.playCoin();
    particles.spawnCoinSparkle(pos);
  }

  void onPowerUpCollected(PowerUpType type, Vector2 pos) {
    audio.playPowerup();
    particles.spawnCoinSparkle(pos);

    if (type == PowerUpType.shield) {
      bird.activateShield(12.0);
    } else if (type == PowerUpType.speedBoost) {
      activeSpeedBoost = ActivePowerUp(
        type: PowerUpType.speedBoost,
        remainingSeconds: 10.0,
        totalSeconds: 10.0,
      );
    }
  }

  void onBirdPipeCollision() {
    if (status != GameStatus.playing) return;
    if (bird.isInvulnerable) return;

    if (bird.isShielded) {
      bird.isShielded = false;
      bird.setInvulnerable(1.2);
      audio.playPowerup();
      particles.spawnFeatherBurst(bird.position, const Color(0xFF00E5FF));
      return;
    }

    triggerGameOver();
  }

  void triggerGameOver() {
    if (status == GameStatus.gameOver) return;

    // Stop everything immediately!
    status = GameStatus.gameOver;
    statusNotifier.value = GameStatus.gameOver;

    audio.playPenguinDie();
    audio.pauseBgm();
    particles.spawnCollisionSmoke(bird.position);

    storage.incrementGames();
    storage.setHighScore(score);

    overlays.add('game_over');
  }

  void pauseGame() {
    if (status == GameStatus.playing) {
      status = GameStatus.paused;
      statusNotifier.value = GameStatus.paused;
      storage.setHighScore(score);
      audio.pauseBgm();
      overlays.add('pause');
    }
  }

  void resumeGame() {
    if (status == GameStatus.paused) {
      status = GameStatus.playing;
      statusNotifier.value = GameStatus.playing;
      if (storage.musicEnabled) {
        audio.resumeBgm();
      }
      overlays.remove('pause');
    }
  }

  void revivePlayer() {
    if (hasRevivedThisRun || status != GameStatus.gameOver) return;

    hasRevivedThisRun = true;
    status = GameStatus.playing;
    statusNotifier.value = GameStatus.playing;
    if (storage.musicEnabled) {
      audio.resumeBgm();
    }

    // Clear pipes close to bird
    final dangerRangeMin = bird.position.x - 100;
    final dangerRangeMax = bird.position.x + 240;

    for (final pipe in children.whereType<PipePairComponent>().toList()) {
      if (pipe.position.x > dangerRangeMin && pipe.position.x < dangerRangeMax) {
        pipe.removeFromParent();
      }
    }

    // Place bird back in middle and give invulnerability
    bird.reset(Vector2(size.x * 0.32, size.y * 0.45));
    bird.setInvulnerable(3.0);
    bird.activateShield(3.0);

    overlays.remove('game_over');
  }

  @override
  void onRemove() {
    statusNotifier.dispose();
    scoreNotifier.dispose();
    coinNotifier.dispose();
    multiplierNotifier.dispose();
    super.onRemove();
  }
}
