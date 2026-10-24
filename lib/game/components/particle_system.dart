import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double radius;
  double maxLife;
  double life;

  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
    required this.maxLife,
  }) : life = maxLife;

  bool get isDead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 380 * dt; // Gravity
    life -= dt;
  }
}

class ParticleManager extends Component {
  final List<GameParticle> _particles = [];
  final Random _rnd = Random();

  // Single shared paint to eliminate all GC allocations in render loop
  static final Paint _sharedPaint = Paint()..style = PaintingStyle.fill;

  void spawnFeatherBurst(Vector2 pos, Color birdColor) {
    if (_particles.length > 25) return; // Prevent particle build-up on rapid taps

    for (int i = 0; i < 3; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 50 + _rnd.nextDouble() * 80;
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 40,
          color: birdColor,
          radius: 3.0 + _rnd.nextDouble() * 2.0,
          maxLife: 0.35 + _rnd.nextDouble() * 0.25,
        ),
      );
    }
  }

  void spawnFlipTrail(Vector2 pos) {
    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFF80D8FF),
      Colors.white,
    ];
    for (int i = 0; i < 6; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 40 + _rnd.nextDouble() * 90;
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed - 50,
          vy: sin(angle) * speed,
          color: colors[_rnd.nextInt(colors.length)],
          radius: 2.5 + _rnd.nextDouble() * 2.0,
          maxLife: 0.35 + _rnd.nextDouble() * 0.25,
        ),
      );
    }
  }

  void spawnSnowballTrail(Vector2 pos) {
    if (_particles.length > 45) return;
    for (int i = 0; i < 2; i++) {
      final offsetX = 8.0 + _rnd.nextDouble() * 10.0;
      final offsetY = (_rnd.nextDouble() - 0.5) * 6.0;
      _particles.add(
        GameParticle(
          x: pos.x + offsetX,
          y: pos.y + offsetY,
          vx: 90.0 + _rnd.nextDouble() * 80.0,
          vy: (_rnd.nextDouble() - 0.5) * 25.0,
          color: _rnd.nextBool() ? Colors.white : const Color(0xFFB3E5FC),
          radius: 2.0 + _rnd.nextDouble() * 1.8,
          maxLife: 0.20 + _rnd.nextDouble() * 0.12,
        ),
      );
    }
  }

  void spawnCannonMuzzleFlash(Vector2 pos) {
    for (int i = 0; i < 12; i++) {
      final angle = pi - (_rnd.nextDouble() * 0.7 - 0.35); // Blast cone pointing into field (left)
      final speed = 140.0 + _rnd.nextDouble() * 220.0;
      final color = _rnd.nextBool() ? Colors.white : const Color(0xFF80D8FF);
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
          radius: 3.0 + _rnd.nextDouble() * 2.5,
          maxLife: 0.25 + _rnd.nextDouble() * 0.15,
        ),
      );
    }
  }

  void spawnRockTrail(Vector2 pos) {
    if (_particles.length > 45) return;
    final rockShades = [
      const Color(0xFF8D6E63),
      const Color(0xFFBCAAA4),
      const Color(0xFF757575),
      const Color(0xFFA1887F),
    ];
    for (int i = 0; i < 2; i++) {
      final offsetX = 8.0 + _rnd.nextDouble() * 10.0;
      final offsetY = (_rnd.nextDouble() - 0.5) * 6.0;
      _particles.add(
        GameParticle(
          x: pos.x + offsetX,
          y: pos.y + offsetY,
          vx: 90.0 + _rnd.nextDouble() * 80.0,
          vy: (_rnd.nextDouble() - 0.5) * 25.0,
          color: rockShades[_rnd.nextInt(rockShades.length)],
          radius: 2.0 + _rnd.nextDouble() * 1.8,
          maxLife: 0.20 + _rnd.nextDouble() * 0.12,
        ),
      );
    }
  }

  void spawnRockLaunchMuzzleFlash(Vector2 pos) {
    final rockColors = [
      const Color(0xFFBCAAA4),
      const Color(0xFF8D6E63),
      const Color(0xFF6D4C41),
      const Color(0xFFFFCC80),
    ];
    for (int i = 0; i < 12; i++) {
      final angle = pi - (_rnd.nextDouble() * 0.7 - 0.35); // Blast cone pointing into field (left)
      final speed = 140.0 + _rnd.nextDouble() * 220.0;
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: rockColors[_rnd.nextInt(rockColors.length)],
          radius: 3.0 + _rnd.nextDouble() * 2.5,
          maxLife: 0.25 + _rnd.nextDouble() * 0.15,
        ),
      );
    }
  }

  void spawnCactusSpikeTrail(Vector2 pos) {
    if (_particles.length > 45) return;
    final cactusShades = [
      const Color(0xFF689F38),
      const Color(0xFFFFF59D),
      const Color(0xFFFFB74D),
      const Color(0xFF8BC34A),
    ];
    for (int i = 0; i < 2; i++) {
      final offsetX = 8.0 + _rnd.nextDouble() * 10.0;
      final offsetY = (_rnd.nextDouble() - 0.5) * 6.0;
      _particles.add(
        GameParticle(
          x: pos.x + offsetX,
          y: pos.y + offsetY,
          vx: 90.0 + _rnd.nextDouble() * 80.0,
          vy: (_rnd.nextDouble() - 0.5) * 25.0,
          color: cactusShades[_rnd.nextInt(cactusShades.length)],
          radius: 1.8 + _rnd.nextDouble() * 1.6,
          maxLife: 0.20 + _rnd.nextDouble() * 0.12,
        ),
      );
    }
  }

  void spawnDesertCactusMuzzleFlash(Vector2 pos) {
    final desertColors = [
      const Color(0xFFFFB74D),
      const Color(0xFFFFF176),
      const Color(0xFF689F38),
      const Color(0xFFFF7043),
    ];
    for (int i = 0; i < 12; i++) {
      final angle = pi - (_rnd.nextDouble() * 0.7 - 0.35); // Blast cone pointing into field (left)
      final speed = 140.0 + _rnd.nextDouble() * 220.0;
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: desertColors[_rnd.nextInt(desertColors.length)],
          radius: 3.0 + _rnd.nextDouble() * 2.5,
          maxLife: 0.25 + _rnd.nextDouble() * 0.15,
        ),
      );
    }
  }

  void spawnCoinSparkle(Vector2 pos) {
    for (int i = 0; i < 6; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 70 + _rnd.nextDouble() * 120;
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: const Color(0xFFFFD166),
          radius: 2.5 + _rnd.nextDouble() * 2.5,
          maxLife: 0.45 + _rnd.nextDouble() * 0.3,
        ),
      );
    }
  }

  void spawnCollisionSmoke(Vector2 pos) {
    for (int i = 0; i < 10; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 80 + _rnd.nextDouble() * 150;
      final shade = _rnd.nextBool() ? const Color(0xFFFF5252) : const Color(0xFFFFA726);
      _particles.add(
        GameParticle(
          x: pos.x,
          y: pos.y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: shade,
          radius: 3.5 + _rnd.nextDouble() * 3.0,
          maxLife: 0.5 + _rnd.nextDouble() * 0.3,
        ),
      );
    }
  }

  void spawnVictoryConfetti(Vector2 center, Vector2 screenSize) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFF06D6A0),
      const Color(0xFF118AB2),
      const Color(0xFFEF476F),
      const Color(0xFF9D4EDD),
    ];
    for (int i = 0; i < 25; i++) {
      final posX = _rnd.nextDouble() * screenSize.x;
      final posY = center.y + (_rnd.nextDouble() - 0.5) * 80;
      final speedY = -120 - _rnd.nextDouble() * 180;
      final speedX = (_rnd.nextDouble() - 0.5) * 150;
      _particles.add(
        GameParticle(
          x: posX,
          y: posY,
          vx: speedX,
          vy: speedY,
          color: colors[_rnd.nextInt(colors.length)],
          radius: 3.5 + _rnd.nextDouble() * 2.5,
          maxLife: 1.2 + _rnd.nextDouble() * 0.8,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(dt);
      if (_particles[i].isDead) {
        _particles.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final p in _particles) {
      if (p.isDead) continue;
      final progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      _sharedPaint.color = p.color.withAlpha((progress * 255).toInt());
      canvas.drawCircle(Offset(p.x, p.y), p.radius * progress, _sharedPaint);
    }
  }

  void clear() {
    _particles.clear();
  }
}
