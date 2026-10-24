import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_game.dart';
import 'bird_component.dart';

/// Snowball projectile shot from right to left across the screen in Snow scenery.
/// The player must dodge the snowball with the penguin; getting hit triggers Game Over.
class SnowballComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  final ui.Image snowballImage;
  final double speed;
  double _trailTimer = 0.0;

  SnowballComponent({
    required Vector2 position,
    required this.snowballImage,
    required this.speed,
  }) : super(
          position: position,
          size: Vector2(30, 30),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Circular hitbox matching the snowball body
    add(CircleHitbox(
      radius: 12.0,
      position: Vector2(3.0, 3.0),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    // High-speed cannon velocity and rapid rifling rotation
    position.x -= speed * dt;
    angle -= dt * 18.0;

    // Emits dense high-speed frost wake trail
    _trailTimer += dt;
    if (_trailTimer >= 0.025) {
      _trailTimer = 0.0;
      game.particles.spawnSnowballTrail(position);
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
      game.onBirdSnowballCollision(this);
    }
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  static final Paint _streakGlowPaint = Paint()
    ..color = const Color(0x3300E5FF)
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  static final Paint _streakCorePaint = Paint()
    ..color = const Color(0x99FFFFFF)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    // 1. Draw horizontal supersonic cannon speed lines trailing behind the snowball
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-angle); // Counter-rotate so speed lines point strictly horizontally backwards
    canvas.drawLine(const Offset(8.0, 0), const Offset(38.0, 0), _streakGlowPaint);
    canvas.drawLine(const Offset(8.0, 0), const Offset(32.0, 0), _streakCorePaint);
    canvas.restore();

    // 2. Draw spinning snowball sprite
    final src = Rect.fromLTWH(
      0,
      0,
      snowballImage.width.toDouble(),
      snowballImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(
      snowballImage,
      src,
      dst,
      _paint,
    );

    super.render(canvas);
  }
}
