import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/power_up.dart';
import '../flappy_game.dart';
import 'bird_component.dart';

class PowerUpComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  final PowerUpType type;
  double _animTime = 0.0;
  bool _collected = false;

  PowerUpComponent({
    required this.type,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(30, 30),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(radius: 15));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt * 4.0;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_collected) return;
    if (other is BirdComponent) {
      _collected = true;
      game.onPowerUpCollected(type, absolutePosition);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final floatY = sin(_animTime) * 3.0;
    final center = Offset(size.x / 2, size.y / 2 + floatY);

    final isShield = type == PowerUpType.shield;
    final mainColor = isShield ? const Color(0xFF00E5FF) : const Color(0xFFFFD600);
    final glowColor = isShield ? const Color(0x6600E5FF) : const Color(0x77FFD600);

    // Glowing outer aura
    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, glowPaint);

    // Core bubble
    final bubblePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, mainColor],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawCircle(center, 13, bubblePaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 13, borderPaint);

    // Icon in center
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    if (isShield) {
      // Draw shield crest
      final path = Path()
        ..moveTo(center.dx, center.dy - 6)
        ..lineTo(center.dx + 6, center.dy - 3)
        ..lineTo(center.dx + 4, center.dy + 4)
        ..lineTo(center.dx, center.dy + 7)
        ..lineTo(center.dx - 4, center.dy + 4)
        ..lineTo(center.dx - 6, center.dy - 3)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else {
      // Draw sharp golden lightning / thunder bolt
      final path = Path()
        ..moveTo(center.dx + 2, center.dy - 7)
        ..lineTo(center.dx - 4, center.dy)
        ..lineTo(center.dx + 1, center.dy)
        ..lineTo(center.dx - 2, center.dy + 7)
        ..lineTo(center.dx + 5, center.dy - 1)
        ..lineTo(center.dx, center.dy - 1)
        ..close();
      final fillPaint = Paint()
        ..color = const Color(0xFFFF6D00)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, iconPaint..strokeWidth = 1.2);
    }
  }
}
