import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/level_config.dart';
import '../flappy_game.dart';

class GroundComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  double scrollSpeed;
  double _scrollOffset = 0.0;
  EnvironmentTheme _theme;
  final String scenery;

  // Cached paints to prevent allocations in render loop
  late Paint _groundPaint;
  late Paint _grassPaint;
  late Paint _stripePaint;
  late Paint _highlightPaint;

  GroundComponent({
    required Vector2 position,
    required Vector2 size,
    required this.scrollSpeed,
    this.scenery = 'ice',
    EnvironmentTheme theme = EnvironmentTheme.alpineDay,
  })  : _theme = theme,
        super(position: position, size: size) {
    add(RectangleHitbox(size: Vector2(size.x, 15), position: Vector2.zero()));
    _updatePaints();
  }

  set theme(EnvironmentTheme newTheme) {
    if (_theme != newTheme) {
      _theme = newTheme;
      _updatePaints();
    }
  }

  EnvironmentTheme get theme => _theme;

  void _updatePaints() {
    final topColor = scenery == 'desert'
        ? const Color(0xFFE2B062) // Warm golden sand crust for desert
        : (scenery == 'mountain'
            ? const Color(0xFF43A047) // Lush grassy top for mountain pass
            : _theme.groundTopColor); // Crisp snowy crust for ice scenery

    final bodyColor = scenery == 'desert'
        ? const Color(0xFF9E5C32) // Warm terracotta earth for desert
        : (scenery == 'mountain'
            ? const Color(0xFF5D4037) // Earthy dirt body for mountain pass
            : _theme.groundBodyColor); // Permafrost stone for ice scenery

    _groundPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    _grassPaint = Paint()
      ..color = topColor
      ..style = PaintingStyle.fill;
    _stripePaint = Paint()
      ..color = Colors.black.withAlpha(22)
      ..style = PaintingStyle.fill;
    _highlightPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // FREEZE on game over or pause!
    if (!game.isPlaying) return;

    _scrollOffset = (_scrollOffset + scrollSpeed * dt) % 24.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    const grassHeight = 16.0;

    // 1. Draw main ground body
    canvas.drawRect(
      Rect.fromLTWH(0, grassHeight, size.x, size.y - grassHeight),
      _groundPaint,
    );

    // 2. Draw stripes on dirt body without allocating Path objects each frame
    for (double x = -_scrollOffset; x < size.x + 24; x += 24) {
      canvas.drawRect(
        Rect.fromLTWH(x, grassHeight, 8, size.y - grassHeight),
        _stripePaint,
      );
    }

    // 3. Draw grass top strip
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, grassHeight),
      _grassPaint,
    );

    // 4. Highlight top edge
    canvas.drawLine(const Offset(0, 1), Offset(size.x, 1), _highlightPaint);
  }
}
