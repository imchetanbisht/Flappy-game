import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/power_up.dart';
import '../flappy_game.dart';
import 'bird_component.dart';
import 'coin_component.dart';
import 'power_up_component.dart';

class PipePairComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  final String scenery;
  final ui.Image? iceSpikeUpImage;
  final ui.Image? iceSpikeDownImage;
  final ui.Image? pipeImage;
  final ui.Image? cactusImage;
  final double gapY;
  final double gapSize;
  final double pipeWidth;
  final double speed;
  final double groundY;

  bool isScored = false;

  ShapeHitbox? _topHitbox;
  ShapeHitbox? _bottomHitbox;

  PipePairComponent({
    required Vector2 position,
    this.scenery = 'ice',
    this.iceSpikeUpImage,
    this.iceSpikeDownImage,
    this.pipeImage,
    this.cactusImage,
    required this.gapY,
    required this.gapSize,
    required this.speed,
    required this.groundY,
    this.pipeWidth = 72.0,
  }) : super(position: position, size: Vector2(pipeWidth, groundY));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final topPipeHeight = gapY - gapSize / 2;
    final bottomPipeTop = gapY + gapSize / 2;
    final bottomPipeHeight = groundY - bottomPipeTop;

    if (scenery == 'desert') {
      // Hitboxes for desert cactus obstacles
      if (topPipeHeight > 10) {
        _topHitbox = RectangleHitbox(
          position: Vector2(4, -150),
          size: Vector2(pipeWidth - 8, topPipeHeight + 150),
        );
        add(_topHitbox!);
      }

      if (bottomPipeHeight > 10) {
        _bottomHitbox = RectangleHitbox(
          position: Vector2(4, bottomPipeTop),
          size: Vector2(pipeWidth - 8, bottomPipeHeight + 50),
        );
        add(_bottomHitbox!);
      }
    } else if (scenery == 'mountain') {
      // Rectangular hitboxes for classic pipes, extending above screen & into ground
      if (topPipeHeight > 10) {
        _topHitbox = RectangleHitbox(
          position: Vector2(2, -150),
          size: Vector2(pipeWidth - 4, topPipeHeight + 150),
        );
        add(_topHitbox!);
      }

      if (bottomPipeHeight > 10) {
        _bottomHitbox = RectangleHitbox(
          position: Vector2(2, bottomPipeTop),
          size: Vector2(pipeWidth - 4, bottomPipeHeight + 50),
        );
        add(_bottomHitbox!);
      }
    } else {
      // Tapered hitboxes for upper ice spike (stalactite)
      if (topPipeHeight > 10) {
        _topHitbox = PolygonHitbox([
          Vector2(4, -50),
          Vector2(pipeWidth - 4, -50),
          Vector2(pipeWidth * 0.65, topPipeHeight),
          Vector2(pipeWidth * 0.35, topPipeHeight),
        ]);
        add(_topHitbox!);
      }

      // Tapered hitbox for lower ice spike (stalagmite)
      if (bottomPipeHeight > 10) {
        _bottomHitbox = PolygonHitbox([
          Vector2(pipeWidth * 0.35, bottomPipeTop),
          Vector2(pipeWidth * 0.65, bottomPipeTop),
          Vector2(pipeWidth - 4, groundY + 30),
          Vector2(4, groundY + 30),
        ]);
        add(_bottomHitbox!);
      }
    }

    // Spawn bonus coin or powerup inside the gap between obstacles
    _spawnCollectible();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BirdComponent) {
      game.onBirdPipeCollision();
    }
  }

  static final Paint _pipePaint = Paint()..filterQuality = FilterQuality.medium;

  void _spawnCollectible() {
    final rnd = Random();
    final powerupChance = game.difficulty.powerupSpawnRate;

    // In the beginning of the run (score < 80m), guarantee a coin in every gap
    // so players immediately see and collect coins without empty obstacles
    if (game.score < 80) {
      add(
        CoinComponent(
          position: Vector2(pipeWidth / 2, gapY),
        ),
      );
      return;
    }

    // Beyond 80m, roll for powerups; if no powerup rolled, always spawn a coin
    final roll = rnd.nextDouble();
    if (roll < powerupChance) {
      final powerType = rnd.nextBool() ? PowerUpType.shield : PowerUpType.speedBoost;
      add(
        PowerUpComponent(
          type: powerType,
          position: Vector2(pipeWidth / 2, gapY),
        ),
      );
    } else {
      add(
        CoinComponent(
          position: Vector2(pipeWidth / 2, gapY),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isPlaying) return;

    // Dynamically scrolls with game.effectiveSpeed (accelerates during speed boost)
    position.x -= game.effectiveSpeed * dt;

    // Check scoring: when bird passes obstacle center
    if (!isScored && position.x + pipeWidth / 2 < game.bird.position.x) {
      isScored = true;
      game.onObstaclePassed();
    }

    // Remove when completely off-screen
    if (position.x + pipeWidth < -60) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final topPipeHeight = gapY - gapSize / 2;
    final bottomPipeTop = gapY + gapSize / 2;
    final bottomPipeHeight = groundY - bottomPipeTop;

    final paint = _pipePaint;

    if (scenery == 'desert' && cactusImage != null) {
      final srcRect = Rect.fromLTWH(
        0,
        0,
        cactusImage!.width.toDouble(),
        cactusImage!.height.toDouble(),
      );
      final trunkSrc = Rect.fromLTWH(
        cactusImage!.width * 0.25,
        cactusImage!.height * 0.65,
        cactusImage!.width * 0.50,
        cactusImage!.height * 0.35,
      );

      // 1. UPPER CACTUS (Hanging downwards from canyon ceiling into gap)
      if (topPipeHeight > 0) {
        canvas.save();
        canvas.translate(0, topPipeHeight);
        canvas.scale(1.0, -1.0); // Flip vertically so spiky cactus head points downwards

        final headH = min(pipeWidth, topPipeHeight);

        // Cactus head facing gap
        canvas.drawImageRect(
          cactusImage!,
          srcRect,
          Rect.fromLTWH(0, 0, pipeWidth, headH),
          paint,
        );

        // Trunk extending up beyond top ceiling
        final trunkH = (topPipeHeight - headH) + 160.0;
        canvas.drawImageRect(
          cactusImage!,
          trunkSrc,
          Rect.fromLTWH(pipeWidth * 0.25, headH, pipeWidth * 0.50, trunkH),
          paint,
        );

        canvas.restore();
      }

      // 2. LOWER CACTUS (Rooted in desert sand reaching up to gap)
      if (bottomPipeHeight > 0) {
        final headH = min(pipeWidth, bottomPipeHeight);

        // Spiky cactus head at bottomPipeTop
        canvas.drawImageRect(
          cactusImage!,
          srcRect,
          Rect.fromLTWH(0, bottomPipeTop, pipeWidth, headH),
          paint,
        );

        // Trunk rooted firmly into the desert ground
        final trunkTopY = bottomPipeTop + headH;
        final trunkBottomY = groundY + 16.0;
        if (trunkBottomY > trunkTopY) {
          canvas.drawImageRect(
            cactusImage!,
            trunkSrc,
            Rect.fromLTWH(pipeWidth * 0.25, trunkTopY, pipeWidth * 0.50, trunkBottomY - trunkTopY),
            paint,
          );
        }
      }
    } else if (scenery == 'mountain' && pipeImage != null) {
      // Precise sliced sub-rectangles from pipe.png (199x242)
      // Top Cap: 0..44, Shaft: 44..198, Bottom Cap: 198..242
      const topCapSrc = Rect.fromLTWH(0, 0, 199, 44);
      const shaftSrc = Rect.fromLTWH(0, 44, 199, 154);
      const bottomCapSrc = Rect.fromLTWH(0, 198, 199, 44);

      // Proportional cap height so the rim is never stretched or distorted
      final capH = pipeWidth * (44.0 / 199.0); // ~16.0px

      // -------------------------------------------------------------
      // 1. UPPER PIPE (Extends seamlessly from above the screen down to topPipeHeight)
      // -------------------------------------------------------------
      if (topPipeHeight > 0) {
        final openingCapH = min(capH, topPipeHeight);

        // A. Smooth pipe shaft extending well above the screen (-160px) to opening cap
        final shaftTopY = -160.0;
        final shaftBottomY = topPipeHeight - openingCapH;
        if (shaftBottomY > shaftTopY) {
          canvas.drawImageRect(
            pipeImage!,
            shaftSrc,
            Rect.fromLTWH(0, shaftTopY, pipeWidth, shaftBottomY - shaftTopY),
            paint,
          );
        }

        // B. Opening Rim Cap facing downward towards the gap
        canvas.save();
        canvas.translate(0, topPipeHeight);
        canvas.scale(1.0, -1.0);
        canvas.drawImageRect(
          pipeImage!,
          topCapSrc,
          Rect.fromLTWH(0, 0, pipeWidth, openingCapH),
          paint,
        );
        canvas.restore();
      }

      // -------------------------------------------------------------
      // 2. LOWER PIPE (Anchored smoothly into the ground with exact matching look)
      // -------------------------------------------------------------
      if (bottomPipeHeight > 0) {
        if (bottomPipeHeight <= capH * 2.2) {
          // Compact pipe: draw natural full sprite with base slightly in ground
          canvas.drawImageRect(
            pipeImage!,
            const Rect.fromLTWH(0, 0, 199, 242),
            Rect.fromLTWH(0, bottomPipeTop, pipeWidth, bottomPipeHeight + 8),
            paint,
          );
        } else {
          // A. Opening Rim Cap at the top (facing gap)
          canvas.drawImageRect(
            pipeImage!,
            topCapSrc,
            Rect.fromLTWH(0, bottomPipeTop, pipeWidth, capH),
            paint,
          );

          // B. Base Cap sitting squarely on the ground line (extending into grass)
          canvas.drawImageRect(
            pipeImage!,
            bottomCapSrc,
            Rect.fromLTWH(0, groundY - capH, pipeWidth, capH + 12),
            paint,
          );

          // C. Smooth Middle Shaft connecting opening cap and base cap
          final shaftTopY = bottomPipeTop + capH;
          final shaftBottomY = groundY - capH;
          if (shaftBottomY > shaftTopY) {
            canvas.drawImageRect(
              pipeImage!,
              shaftSrc,
              Rect.fromLTWH(0, shaftTopY, pipeWidth, shaftBottomY - shaftTopY),
              paint,
            );
          }
        }
      }
    } else {
      // -------------------------------------------------------------
      // ICE SPIKES (Solidly attached at ceiling and snow ground)
      // -------------------------------------------------------------
      // 1. Draw Upper Ice Spike (stalactite extending from above screen down)
      if (topPipeHeight > 0 && iceSpikeDownImage != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          iceSpikeDownImage!.width.toDouble(),
          iceSpikeDownImage!.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(0, -50.0, pipeWidth, topPipeHeight + 50.0);
        canvas.drawImageRect(iceSpikeDownImage!, srcRect, dstRect, paint);
      }

      // 2. Draw Lower Ice Spike (stalagmite anchored deeply in the snow)
      if (bottomPipeHeight > 0 && iceSpikeUpImage != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          iceSpikeUpImage!.width.toDouble(),
          iceSpikeUpImage!.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(0, bottomPipeTop, pipeWidth, bottomPipeHeight + 25.0);
        canvas.drawImageRect(iceSpikeUpImage!, srcRect, dstRect, paint);
      }
    }
  }
}
