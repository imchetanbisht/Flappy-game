import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyHighScore = 'flappy_high_score';
  static const String _keyCoins = 'flappy_coins';
  static const String _keySfxEnabled = 'flappy_sfx_enabled';
  static const String _keyMusicEnabled = 'flappy_music_enabled';
  static const String _keyHapticsEnabled = 'flappy_haptics_enabled';
  static const String _keyTotalPipes = 'flappy_total_pipes';
  static const String _keyTotalGames = 'flappy_total_games';
  static const String _keyScenery = 'flappy_scenery';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- High Score ---
  int get highScore => _prefs.getInt(_keyHighScore) ?? 0;

  Future<bool> setHighScore(int score) async {
    if (score > highScore) {
      return await _prefs.setInt(_keyHighScore, score);
    }
    return false;
  }

  Future<void> resetHighScore() async {
    await _prefs.setInt(_keyHighScore, 0);
  }

  // --- Coins ---
  int get coins => _prefs.getInt(_keyCoins) ?? 0;

  Future<void> addCoins(int amount) async {
    final current = coins;
    await _prefs.setInt(_keyCoins, current + amount);
  }

  Future<bool> spendCoins(int amount) async {
    final current = coins;
    if (current >= amount) {
      await _prefs.setInt(_keyCoins, current - amount);
      return true;
    }
    return false;
  }

  // --- Settings ---
  bool get sfxEnabled => _prefs.getBool(_keySfxEnabled) ?? true;
  Future<void> setSfxEnabled(bool value) async => await _prefs.setBool(_keySfxEnabled, value);

  bool get musicEnabled => _prefs.getBool(_keyMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool value) async => await _prefs.setBool(_keyMusicEnabled, value);

  bool get hapticsEnabled => _prefs.getBool(_keyHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool value) async => await _prefs.setBool(_keyHapticsEnabled, value);

  static const int mountainUnlockPrice = 800;
  static const int desertUnlockPrice = 1000;
  static const String _keyUnlockedMountain = 'flappy_unlocked_mountain';
  static const String _keyUnlockedDesert = 'flappy_unlocked_desert';

  // --- Scenery Selection & Unlocking ---
  String get scenery => _prefs.getString(_keyScenery) ?? 'ice';
  Future<void> setScenery(String value) async => await _prefs.setString(_keyScenery, value);

  int getSceneryPrice(String sceneryKey) {
    if (sceneryKey == 'mountain') return mountainUnlockPrice;
    if (sceneryKey == 'desert') return desertUnlockPrice;
    return 0; // 'ice' is default and free
  }

  bool isSceneryUnlocked(String sceneryKey) {
    if (sceneryKey == 'ice') return true; // Snow/ice is default and always unlocked
    if (sceneryKey == 'mountain') return _prefs.getBool(_keyUnlockedMountain) ?? false;
    if (sceneryKey == 'desert') return _prefs.getBool(_keyUnlockedDesert) ?? false;
    return false;
  }

  Future<bool> unlockScenery(String sceneryKey) async {
    if (isSceneryUnlocked(sceneryKey)) return true;
    final price = getSceneryPrice(sceneryKey);
    if (price <= 0) return true;

    if (coins >= price) {
      final success = await spendCoins(price);
      if (success) {
        if (sceneryKey == 'mountain') {
          await _prefs.setBool(_keyUnlockedMountain, true);
        } else if (sceneryKey == 'desert') {
          await _prefs.setBool(_keyUnlockedDesert, true);
        }
        return true;
      }
    }
    return false;
  }

  // --- Lifetime Stats ---
  int get totalPipes => _prefs.getInt(_keyTotalPipes) ?? 0;
  Future<void> incrementPipes(int count) async => await _prefs.setInt(_keyTotalPipes, totalPipes + count);

  int get totalGames => _prefs.getInt(_keyTotalGames) ?? 0;
  Future<void> incrementGames() async => await _prefs.setInt(_keyTotalGames, totalGames + 1);

  // --- Ad Display Counters (Every 3rd Game / Retry) ---
  static const String _keyPlaySessionCount = 'flappy_play_session_count';
  int get playSessionCount => _prefs.getInt(_keyPlaySessionCount) ?? 0;
  Future<int> incrementPlaySessionCount() async {
    final next = playSessionCount + 1;
    await _prefs.setInt(_keyPlaySessionCount, next);
    return next;
  }
  bool get shouldShowPlayAd => (playSessionCount > 0 && playSessionCount % 3 == 0);

  // --- Reset Progress ---
  Future<void> resetAllProgress() async {
    final sfx = sfxEnabled;
    final music = musicEnabled;
    final haptics = hapticsEnabled;

    await _prefs.clear();

    await setSfxEnabled(sfx);
    await setMusicEnabled(music);
    await setHapticsEnabled(haptics);
  }
}
