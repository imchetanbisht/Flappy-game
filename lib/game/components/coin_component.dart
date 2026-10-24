import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_game.dart';
import 'bird_component.dart';

class CoinComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  double _animTime = 0.0;
  bool _collected = false;

  CoinComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(28, 28),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(radius: 14));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;
    _animTime += dt * 5.0;

    // Real-time proximity pickup check (ensures reliable collection in world coordinates)
    if (game.isPlaying) {
      final birdPos = game.bird.position;
      final coinPos = absolutePosition;
      final distance = (coinPos - birdPos).length;
      if (distance < 26.0) {
        _collected = true;
        game.onCoinCollected(coinPos);
        removeFromParent();
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_collected) return;
    if (other is BirdComponent) {
      _collected = true;
      game.onCoinCollected(absolutePosition);
      removeFromParent();
    }
  }

  static final Paint _coinPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(0, 0, 28, 28));

  static final Paint _borderPaint = Paint()
    ..color = const Color(0xFFE65100)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _innerPaint = Paint()
    ..color = const Color(0xFFFFE082)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final spin = cos(_animTime).abs().clamp(0.15, 1.0);
    final width = size.x * spin;
    final height = size.y;

    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: width,
      height: height,
    );

    canvas.drawOval(rect, _coinPaint);
    canvas.drawOval(rect, _borderPaint);

    // Inner star or emboss
    if (spin > 0.4) {
      final innerRect = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: width * 0.55,
        height: height * 0.55,
      );
      canvas.drawOval(innerRect, _innerPaint);
    }
  }
}
