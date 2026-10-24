import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_game.dart';

class BirdComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  final ui.Image frame1;
  final ui.Image frame2;
  final ui.Image? hurtFrame;

  // Physics constants
  static const double flapStrength = -390.0;
  static const double gravity = 1080.0;
  static const double maxFallSpeed = 580.0;
  static const double birdWidth = 44.0;
  static const double birdHeight = 62.0;

  double velocityY = 0.0;
  double _animTimer = 0.0;
  bool _useFrame1 = true;
  double _readyBobTime = 0.0;
  int _lastParticleTime = 0;

  bool isShielded = false;
  double shieldTimeRemaining = 0.0;
  bool isInvulnerable = false;
  double _invulnerableTimer = 0.0;

  // Acrobatic flip animation
  bool isFlipping = false;
  double _flipProgress = 0.0;
  static const double flipDuration = 0.38;

  late CircleHitbox _hitbox;

  BirdComponent({
    required Vector2 position,
    required this.frame1,
    required this.frame2,
    this.hurtFrame,
  }) : super(
          position: position,
          size: Vector2(birdWidth, birdHeight),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Circular hitbox centered perfectly on the penguin body
    _hitbox = CircleHitbox(
      radius: 18,
      position: Vector2(size.x / 2 - 18, size.y / 2 - 18),
    );
    add(_hitbox);
  }

  void flap() {
    velocityY = flapStrength;
    _animTimer = 0.0;
    _useFrame1 = false; // Trigger wing flap

    // Throttle feather burst to avoid stutter during rapid clicking
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastParticleTime > 180) {
      _lastParticleTime = now;
      game.particles.spawnFeatherBurst(position, const Color(0xFF4FC3F7));
    }
  }

  void doFlip() {
    isFlipping = true;
    _flipProgress = 0.0;
    game.particles.spawnFlipTrail(position);
  }

  void reset(Vector2 newPos) {
    position = newPos;
    velocityY = 0.0;
    angle = 0.0;
    _readyBobTime = 0.0;
    isShielded = false;
    isInvulnerable = false;
    _invulnerableTimer = 0.0;
    _lastParticleTime = 0;
    isFlipping = false;
    _flipProgress = 0.0;
  }

  void activateShield(double duration) {
    isShielded = true;
    shieldTimeRemaining = duration;
  }

  void setInvulnerable(double duration) {
    isInvulnerable = true;
    _invulnerableTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update invulnerability & shield timers
    if (isInvulnerable) {
      _invulnerableTimer -= dt;
      if (_invulnerableTimer <= 0) {
        isInvulnerable = false;
      }
    }

    if (isShielded) {
      shieldTimeRemaining -= dt;
      if (shieldTimeRemaining <= 0) {
        isShielded = false;
      }
    }

    if (game.isReady) {
      // Bob up and down smoothly while waiting, keeping angle level
      _readyBobTime += dt * 3.5;
      position.y += sin(_readyBobTime) * 0.7;
      angle = 0.0;

      // Flap wings gently
      _animTimer += dt;
      if (_animTimer >= 0.2) {
        _useFrame1 = !_useFrame1;
        _animTimer = 0.0;
      }
      return;
    }

    if (!game.isPlaying) return;

    // Apply gravity and terminal velocity
    velocityY += gravity * dt;
    if (velocityY > maxFallSpeed) {
      velocityY = maxFallSpeed;
    }
    position.y += velocityY * dt;

    // Prevent flying above the top boundary
    if (position.y < birdHeight / 2) {
      position.y = birdHeight / 2;
      if (velocityY < 0) velocityY = 0;
    }

    // Handle front somersault flip animation while moving
    if (isFlipping) {
      _flipProgress += dt / flipDuration;
      if (_flipProgress >= 1.0) {
        isFlipping = false;
        _flipProgress = 0.0;
        angle = 0.0;
      } else {
        // Full 360-degree rotation (2*pi radians) in forward flight direction
        angle = _flipProgress * 2 * pi;
      }
    } else {
      // Keep penguin flying straight horizontally at all times when not flipping
      angle = 0.0;
    }

    // Wing flap animation: flaps faster when rising or flying at high speeds across 100m milestones
    final tier = game.difficulty.tier;
    final flapBoost = (tier * 0.015).clamp(0.0, 0.07);
    final frameInterval = velocityY < 0
        ? (0.08 - flapBoost * 0.5).clamp(0.04, 0.08)
        : (0.18 - flapBoost).clamp(0.09, 0.18);
    _animTimer += dt;
    if (_animTimer >= frameInterval) {
      _useFrame1 = !_useFrame1;
      _animTimer = 0.0;
    }
  }

  static final Paint _glowPaint = Paint()
    ..color = const Color(0x3300E5FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  static final Paint _shieldPaint = Paint()
    ..color = const Color(0x5500E5FF)
    ..style = PaintingStyle.fill;

  static final Paint _shieldBorderPaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..strokeWidth = 2.4
    ..style = PaintingStyle.stroke;

  static final Paint _spritePaint = Paint();

  @override
  void render(Canvas canvas) {
    // Invulnerability flicker
    if (isInvulnerable && (_invulnerableTimer * 10).toInt() % 2 == 0) {
      return;
    }

    // 1. Perfectly Centered Shield Bubble
    if (isShielded) {
      final pulse = (sin(DateTime.now().millisecondsSinceEpoch / 120) * 0.08) + 0.95;
      final center = Offset(size.x / 2, size.y / 2);
      final shieldRadius = (size.y * 0.58) * pulse;

      // Outer glow
      canvas.drawCircle(center, shieldRadius + 3, _glowPaint);

      // Inner translucent bubble
      canvas.drawCircle(center, shieldRadius, _shieldPaint);

      // Bright energetic border
      canvas.drawCircle(center, shieldRadius, _shieldBorderPaint);
    }

    // 2. Draw Penguin Sprite FLIPPED HORIZONTALLY so it faces forward (right)
    final currentImage = (game.isGameOver && hurtFrame != null)
        ? hurtFrame!
        : (_useFrame1 ? frame1 : frame2);

    final srcRect = Rect.fromLTWH(
      0,
      0,
      currentImage.width.toDouble(),
      currentImage.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.save();
    // Flip across horizontal center of bird
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(-1.0, 1.0); // Invert X axis so beak faces forward to the right
    canvas.translate(-size.x / 2, -size.y / 2);

    canvas.drawImageRect(currentImage, srcRect, dstRect, _spritePaint);
    canvas.restore();

    super.render(canvas);
  }
}
