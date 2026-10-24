import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class AudioService {
  final StorageService storage;

  // Dedicated independent audio channels
  // Dual alternating flap players to eliminate stutter and never clip each other
  final AudioPlayer _flapPlayer1 = AudioPlayer();
  final AudioPlayer _flapPlayer2 = AudioPlayer();
  final AudioPlayer _coinPlayer = AudioPlayer();
  final AudioPlayer _scorePlayer = AudioPlayer();
  final AudioPlayer _hitPlayer = AudioPlayer();
  final AudioPlayer _penguinDiePlayer = AudioPlayer();
  final AudioPlayer _fanfarePlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  AudioPlayer _bgmPlayer = AudioPlayer();

  int _lastFlapTime = 0;
  int _flapToggle = 0;

  static final AudioContext _mixAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioService(this.storage) {
    _initPlayers();
  }

  void _initPlayers() {
    try {
      AudioPlayer.global.setAudioContext(_mixAudioContext).catchError((_) {});
    } catch (_) {}

    for (final player in [
      _flapPlayer1,
      _flapPlayer2,
      _coinPlayer,
      _scorePlayer,
      _hitPlayer,
      _penguinDiePlayer,
      _fanfarePlayer,
      _clickPlayer,
      _bgmPlayer,
    ]) {
      try {
        player.setAudioContext(_mixAudioContext).catchError((_) {});
        player.setReleaseMode(ReleaseMode.stop).catchError((_) {});
      } catch (_) {}
    }
    try {
      _bgmPlayer.setReleaseMode(ReleaseMode.loop).catchError((_) {});
    } catch (_) {}
  }

  bool get isSfxEnabled => storage.sfxEnabled;
  bool get isMusicEnabled => storage.musicEnabled;
  bool get isHapticsEnabled => storage.hapticsEnabled;

  void triggerHaptic() {
    if (!isHapticsEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void triggerHeavyHaptic() {
    if (!isHapticsEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Safely plays an audio asset on the given player, resetting previous playback
  /// and falling back to a one-shot AudioPlayer instance if an error occurs.
  void _safePlay(AudioPlayer player, String assetPath, {double volume = 1.0}) {
    if (!isSfxEnabled) return;

    try {
      player.stop().then((_) {
        return player.play(
          AssetSource(assetPath),
          volume: volume,
          ctx: _mixAudioContext,
        );
      }).catchError((e) {
        debugPrint('AudioService safePlay error for $assetPath: $e');
        _playFallback(assetPath, volume);
      });
    } catch (e) {
      debugPrint('AudioService exception for $assetPath: $e');
      _playFallback(assetPath, volume);
    }
  }

  void _playFallback(String assetPath, double volume) {
    try {
      final fallback = AudioPlayer();
      fallback.setAudioContext(_mixAudioContext).catchError((_) {});
      fallback.play(AssetSource(assetPath), volume: volume, ctx: _mixAudioContext).then((_) {
        fallback.onPlayerComplete.listen((_) {
          fallback.dispose();
        });
      }).catchError((_) {
        fallback.dispose();
      });
    } catch (_) {}
  }

  /// Highly-optimized flap sound designed for rapid clicking without stutter.
  /// Uses dual alternating players, avoids native vibration thread locks,
  /// and does not block the UI isolate with RPC overhead.
  void playFlap() {
    if (!isSfxEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle audio RPCs slightly so platform channel is never saturated
    if (now - _lastFlapTime < 130) return;
    _lastFlapTime = now;

    final player = (_flapToggle++ % 2 == 0) ? _flapPlayer1 : _flapPlayer2;
    player.play(AssetSource('audio/flap.wav'), volume: 0.65, ctx: _mixAudioContext).catchError((_) {});
  }

  void playCoin() {
    if (!isSfxEnabled) return;
    triggerHaptic();
    _safePlay(_coinPlayer, 'audio/coin.wav', volume: 1.0);
  }

  void playScore() {
    if (!isSfxEnabled) return;
    triggerHaptic();
    _safePlay(_scorePlayer, 'audio/score.wav', volume: 0.85);
  }

  void playHit() {
    if (!isSfxEnabled) return;
    triggerHeavyHaptic();
    _safePlay(_hitPlayer, 'audio/hit.wav', volume: 1.0);
  }

  void playPenguinDie() {
    if (!isSfxEnabled) return;
    triggerHeavyHaptic();
    // Play both the physical hit impact and the penguin vocalization
    _safePlay(_hitPlayer, 'audio/hit.wav', volume: 0.9);
    _safePlay(_penguinDiePlayer, 'audio/penguin_die.wav', volume: 1.0);
  }

  void playPowerup() {
    if (!isSfxEnabled) return;
    triggerHaptic();
    _safePlay(_fanfarePlayer, 'audio/powerup.wav', volume: 1.0);
  }

  void playLevelComplete() {
    if (!isSfxEnabled) return;
    triggerHeavyHaptic();
    _safePlay(_fanfarePlayer, 'audio/complete.wav', volume: 1.0);
  }

  void playClick() {
    if (!isSfxEnabled) return;
    triggerHaptic();
    _safePlay(_clickPlayer, 'audio/click.wav', volume: 0.7);
  }

  Future<void> playBgm({double volume = 0.40, bool force = false}) async {
    if (!isMusicEnabled) return;
    try {
      if (!force) {
        if (_bgmPlayer.state == PlayerState.playing) return;
        if (_bgmPlayer.state == PlayerState.paused) {
          await _bgmPlayer.resume().catchError((_) {});
          if (_bgmPlayer.state == PlayerState.playing) return;
        }
      }
      await _bgmPlayer.setAudioContext(_mixAudioContext).catchError((_) {});
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop).catchError((_) {});
      await _bgmPlayer.play(
        AssetSource('audio/bgm.wav'),
        volume: volume,
        ctx: _mixAudioContext,
      ).catchError((e) async {
        debugPrint('AudioService playBgm error: $e - reinitializing player');
        try {
          await _bgmPlayer.dispose().catchError((_) {});
        } catch (_) {}
        _bgmPlayer = AudioPlayer();
        await _bgmPlayer.setAudioContext(_mixAudioContext).catchError((_) {});
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop).catchError((_) {});
        await _bgmPlayer.play(
          AssetSource('audio/bgm.wav'),
          volume: volume,
          ctx: _mixAudioContext,
        ).catchError((_) {});
      });
    } catch (e) {
      debugPrint('AudioService playBgm exception: $e');
    }
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer.pause().catchError((_) {});
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!isMusicEnabled) return;
    await playBgm(force: true);
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.pause().catchError((_) {});
      await _bgmPlayer.seek(Duration.zero).catchError((_) {});
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool enabled) async {
    await storage.setMusicEnabled(enabled);
    if (enabled) {
      await playBgm(force: true);
    } else {
      await pauseBgm();
    }
  }

  Future<void> stopAll() async {
    try {
      await _flapPlayer1.stop().catchError((_) {});
      await _flapPlayer2.stop().catchError((_) {});
      await _coinPlayer.stop().catchError((_) {});
      await _scorePlayer.stop().catchError((_) {});
      await _hitPlayer.stop().catchError((_) {});
      await _penguinDiePlayer.stop().catchError((_) {});
      await _fanfarePlayer.stop().catchError((_) {});
      await _clickPlayer.stop().catchError((_) {});
      await _bgmPlayer.stop().catchError((_) {});
    } catch (_) {}
  }

  void dispose() {
    for (final player in [
      _flapPlayer1,
      _flapPlayer2,
      _coinPlayer,
      _scorePlayer,
      _hitPlayer,
      _penguinDiePlayer,
      _fanfarePlayer,
      _clickPlayer,
      _bgmPlayer,
    ]) {
      try {
        player.dispose().catchError((_) {});
      } catch (_) {}
    }
  }
}
