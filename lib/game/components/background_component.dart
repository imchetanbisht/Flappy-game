import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/level_config.dart';
import '../flappy_game.dart';

class Snowflake {
  double x;
  double y;
  final double radius;
  final double fallSpeed;
  final double driftSpeed;
  final double opacity;

  Snowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.fallSpeed,
    required this.driftSpeed,
    required this.opacity,
  });
}

class BackgroundComponent extends PositionComponent
    with HasGameReference<FlappyGame> {
  EnvironmentTheme _theme;
  final String scenery;
  final ui.Image snowyFarImage;
  final ui.Image snowyMidImage;
  final ui.Image snowyNearImage;
  final ui.Image? mountainBgImage;
  final ui.Image? desertFarImage;
  final ui.Image? desertCloudsImage;
  final ui.Image? desertMidImage;
  final ui.Image? desertNearImage;

  double _offsetFar = 0.0;
  double _offsetMid = 0.0;
  double _offsetNear = 0.0;
  double _offsetClouds = 0.0;
  double scrollSpeed;

  final List<Snowflake> _snowflakes = [];

  // Cached shaders and paints to prevent GC allocations in render loop
  Shader? _cachedSkyShader;
  late Paint _skyPaint;
  late Paint _layerPaint;
  late Paint _snowPaint;

  BackgroundComponent({
    required Vector2 size,
    this.scenery = 'ice',
    required this.snowyFarImage,
    required this.snowyMidImage,
    required this.snowyNearImage,
    this.mountainBgImage,
    this.desertFarImage,
    this.desertCloudsImage,
    this.desertMidImage,
    this.desertNearImage,
    required this.scrollSpeed,
    EnvironmentTheme theme = EnvironmentTheme.alpineDay,
  })  : _theme = theme,
        super(size: size) {
    if (scenery == 'ice') {
      _initSnowflakes();
    }
    _rebuildPaints();
  }

  set theme(EnvironmentTheme newTheme) {
    if (_theme != newTheme) {
      _theme = newTheme;
      _cachedSkyShader = null;
      _rebuildPaints();
    }
  }

  EnvironmentTheme get theme => _theme;

  void _initSnowflakes() {
    final rnd = Random(5678);
    _snowflakes.clear();
    for (int i = 0; i < 35; i++) {
      _snowflakes.add(Snowflake(
        x: rnd.nextDouble() * 600,
        y: rnd.nextDouble() * 800,
        radius: 1.0 + rnd.nextDouble() * 1.8,
        fallSpeed: 25.0 + rnd.nextDouble() * 45.0,
        driftSpeed: 5.0 + rnd.nextDouble() * 15.0,
        opacity: 0.35 + rnd.nextDouble() * 0.55,
      ));
    }
  }

  void _rebuildPaints() {
    _skyPaint = Paint();
    _layerPaint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = null;

    _snowPaint = Paint()..color = Colors.white;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // FREEZE completely on game over or pause!
    if (!game.isPlaying) return;

    final layerWidth = _calculateLayerWidth();

    // Multi-depth parallax scrolling
    _offsetFar = (_offsetFar + (scrollSpeed * 0.08) * dt) % layerWidth;
    _offsetMid = (_offsetMid + (scrollSpeed * 0.18) * dt) % layerWidth;
    _offsetNear = (_offsetNear + (scrollSpeed * 0.30) * dt) % layerWidth;
    _offsetClouds = (_offsetClouds + 12.0 * dt) % layerWidth;

    // Drifting snowflakes only for ice scenery
    if (scenery == 'ice') {
      for (final flake in _snowflakes) {
        flake.y += flake.fallSpeed * dt;
        if (flake.y > size.y) {
          flake.y = -10.0;
          flake.x = Random().nextDouble() * size.x;
        }
        flake.x -= (scrollSpeed * 0.12 + flake.driftSpeed) * dt;
        if (flake.x < -10.0) {
          flake.x = size.x + 10.0;
        }
      }
    }
  }

  double _calculateLayerHeight() => size.y * 0.46;

  double _calculateLayerWidth() {
    final height = _calculateLayerHeight();
    final aspectWidth = height * (scenery == 'desert' ? (640.0 / 360.0) : (576.0 / 324.0));
    return max(aspectWidth, size.x);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Sky Gradient (Using cached shader)
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    _cachedSkyShader ??= LinearGradient(
      colors: scenery == 'desert'
          ? const [Color(0xFF8AAAE5), Color(0xFFDEB5B7), Color(0xFFFFD59E)]
          : (scenery == 'mountain'
              ? const [Color(0xFF42A5F5), Color(0xFF90CAF9), Color(0xFFE3F2FD)]
              : _theme.skyGradient),
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    _skyPaint.shader = _cachedSkyShader;
    canvas.drawRect(rect, _skyPaint);

    final groundY = game.groundY;

    if (scenery == 'desert' && desertFarImage != null) {
      // Desert Scenery: 4-layer parallax golden dunes, clouds & palms
      final layerH = _calculateLayerHeight();
      final layerW = _calculateLayerWidth();
      final layerY = groundY - layerH + 12;

      // Layer 1: Distant desert peaks
      _drawTiledLayer(canvas, desertFarImage!, _offsetFar, layerY - 14, layerW, layerH);

      // Layer 2: Clouds drifting across the desert sky
      if (desertCloudsImage != null) {
        _drawTiledLayer(canvas, desertCloudsImage!, _offsetClouds, layerY - 45, layerW, layerH);
      }

      // Layer 3: Warm golden mountain dunes
      if (desertMidImage != null) {
        _drawTiledLayer(canvas, desertMidImage!, _offsetMid, layerY - 4, layerW, layerH);
      }

      // Layer 4: Near desert palms & trees
      if (desertNearImage != null) {
        _drawTiledLayer(canvas, desertNearImage!, _offsetNear, layerY, layerW, layerH);
      }
    } else if (scenery == 'mountain' && mountainBgImage != null) {
      // Mountain Scenery: Parallax scrolling green mountain backdrop
      final layerH = size.y * 0.52;
      final aspectW = layerH * (mountainBgImage!.width / mountainBgImage!.height);
      final layerW = max(aspectW, size.x);
      final layerY = groundY - layerH + 8;

      _drawTiledLayer(canvas, mountainBgImage!, _offsetFar, layerY, layerW, layerH);
    } else {
      // Ice Scenery: Multi-layered snowy alpine peaks
      final layerH = _calculateLayerHeight();
      final layerW = _calculateLayerWidth();
      final layerY = groundY - layerH + 12;

      // Layer 1: Distant majestic snowy mountain peaks (Plan 4)
      _drawTiledLayer(canvas, snowyFarImage, _offsetFar, layerY - 18, layerW, layerH);

      // Layer 2: Mid-distance mountain ridges & pine hills (Plan 3)
      _drawTiledLayer(canvas, snowyMidImage, _offsetMid, layerY - 6, layerW, layerH);

      // Layer 3: Near snowy pine slopes (Plan 2)
      _drawTiledLayer(canvas, snowyNearImage, _offsetNear, layerY, layerW, layerH);

      // Gently falling snow crystals
      for (final flake in _snowflakes) {
        _snowPaint.color = Colors.white.withValues(alpha: flake.opacity);
        canvas.drawCircle(Offset(flake.x, flake.y), flake.radius, _snowPaint);
      }
    }
  }

  void _drawTiledLayer(
    Canvas canvas,
    ui.Image img,
    double offset,
    double y,
    double width,
    double height,
  ) {
    final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    double startX = -offset;
    while (startX < size.x) {
      final destRect = Rect.fromLTWH(startX, y, width, height);
      canvas.drawImageRect(img, srcRect, destRect, _layerPaint);
      startX += width - 0.5; // Slight overlap avoids subpixel seam lines
    }
  }
}
