import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/flappy_game.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../overlays/game_hud_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  final StorageService storage;
  final AudioService audio;
  final AdService adService;

  GameScreen({
    super.key,
    required this.storage,
    required this.audio,
    AdService? adService,
  }) : adService = adService ?? AdService(storage, audio);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late FlappyGame _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = FlappyGame(
      storage: widget.storage,
      audio: widget.audio,
      adService: widget.adService,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_game.isPlaying) {
        _game.pauseGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_game.isPlaying,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_game.isPlaying) {
          _game.pauseGame();
        }
      },
      child: Scaffold(
        body: GameWidget<FlappyGame>(
          game: _game,
          overlayBuilderMap: {
            'hud': (context, game) => GameHudOverlay(game: game),
            'pause': (context, game) => PauseOverlay(game: game),
            'game_over': (context, game) => GameOverOverlay(game: game),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}
