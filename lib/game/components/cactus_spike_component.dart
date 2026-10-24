import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_game.dart';
import 'bird_component.dart';

/// Cactus spike projectile shot from right to left across the screen in Desert scenery.
/// The player must dodge the spinning cactus needle ball; getting hit triggers Game Over.
class CactusSpikeComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  final ui.Image spikeImage;
  final double speed;
  double _trailTimer = 0.0;

  CactusSpikeComponent({
    required Vector2 position,
    required this.spikeImage,
    required this.speed,
  }) : super(
          position: position,
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Circular hitbox matching the prickly cactus thorn ball
    add(CircleHitbox(
      radius: 13.0,
      position: Vector2(3.0, 3.0),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    // High-speed cannon velocity and rapid spin
    position.x -= speed * dt;
    angle -= dt * 18.0;

    // Emits dense desert sand and thorn dust trail
    _trailTimer += dt;
    if (_trailTimer >= 0.025) {
      _trailTimer = 0.0;
      game.particles.spawnCactusSpikeTrail(position);
    }

    // Clean up when safely off screen past the left edge
    if (position.x < -size.x - 40) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BirdComponent) {
      game.onBirdCactusSpikeCollision(this);
    }
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  static final Paint _streakGlowPaint = Paint()
    ..color = const Color(0x33FFB74D)
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  static final Paint _streakCorePaint = Paint()
    ..color = const Color(0x99FFF59D)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    // 1. Draw horizontal supersonic cannon speed lines trailing behind the cactus spike (+x)
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-angle); // Counter-rotate so speed lines point strictly horizontally backwards
    canvas.drawLine(const Offset(8.0, 0), const Offset(38.0, 0), _streakGlowPaint);
    canvas.drawLine(const Offset(8.0, 0), const Offset(32.0, 0), _streakCorePaint);
    canvas.restore();

    // 2. Draw spinning cactus spike ball sprite (64x64 scaled to 32x32)
    final src = Rect.fromLTWH(
      0,
      0,
      spikeImage.width.toDouble(),
      spikeImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(
      spikeImage,
      src,
      dst,
      _paint,
    );

    super.render(canvas);
  }
}
