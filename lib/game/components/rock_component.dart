import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_game.dart';
import 'bird_component.dart';

/// Rock projectile shot from right to left across the screen in Mountain scenery.
/// The player must dodge the rock with the penguin; getting hit triggers Game Over.
class RockComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  final ui.Image rockImage;
  final double speed;
  double _trailTimer = 0.0;
  double _animTimer = 0.0;

  RockComponent({
    required Vector2 position,
    required this.rockImage,
    required this.speed,
  }) : super(
          position: position,
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Circular hitbox matching the rock boulder body
    add(CircleHitbox(
      radius: 13.0,
      position: Vector2(3.0, 3.0),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    // High-speed cannon velocity and rotation
    position.x -= speed * dt;
    angle -= dt * 14.0;
    _animTimer += dt;

    // Emits dense mountain dust / rock chip trail
    _trailTimer += dt;
    if (_trailTimer >= 0.025) {
      _trailTimer = 0.0;
      game.particles.spawnRockTrail(position);
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
      game.onBirdRockCollision(this);
    }
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  static final Paint _streakGlowPaint = Paint()
    ..color = const Color(0x33BCAAA4)
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round;

  static final Paint _streakCorePaint = Paint()
    ..color = const Color(0x99D7CCC8)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    // 1. Draw horizontal cannon supersonic speed lines trailing behind the rock
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-angle); // Counter-rotate so speed lines point strictly horizontally backwards (+x)
    canvas.drawLine(const Offset(8.0, 0), const Offset(38.0, 0), _streakGlowPaint);
    canvas.drawLine(const Offset(8.0, 0), const Offset(32.0, 0), _streakCorePaint);
    canvas.restore();

    // 2. Draw rolling rock boulder sprite from spritesheet (128x96, 4 cols x 3 rows of 32x32 frames)
    final frame = ((_animTimer * 18.0).toInt()) % 12;
    final col = frame % 4;
    final row = frame ~/ 4;
    final src = Rect.fromLTWH(col * 32.0, row * 32.0, 32.0, 32.0);
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawImageRect(
      rockImage,
      src,
      dst,
      _paint,
    );

    super.render(canvas);
  }
}
