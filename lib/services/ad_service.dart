import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'audio_service.dart';
import 'storage_service.dart';

class AdService {
  // Production Real AdMob IDs (Used on Android / iOS mobile releases)
  static const String interstitialAdUnitId = 'ca-app-pub-1444309620070901/7520815569';
  static const String appId = 'ca-app-pub-1444309620070901~6314922983';

  final StorageService storage;
  final AudioService? audio;

  InterstitialAd? _interstitialAd;
  bool _isLoadingAd = false;
  bool _isInitialized = false;

  AdService(this.storage, [this.audio]);

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isAdReady => _interstitialAd != null;

  /// Initializes Google Mobile Ads SDK on supported platforms
  Future<void> init() async {
    if (!isSupportedPlatform || _isInitialized) return;
    try {
      debugPrint('AdService: Initializing Google Mobile Ads (AdMob) for Android/iOS...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService initialization error: $e');
    }
  }

  /// Preloads a real interstitial ad in background
  void loadInterstitialAd() {
    if (!isSupportedPlatform || _isLoadingAd || _interstitialAd != null) return;
    _isLoadingAd = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAd = false;
          _interstitialAd = ad;
          debugPrint('Real AdMob Interstitial Ad successfully loaded and cached.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingAd = false;
          _interstitialAd = null;
          debugPrint('Real AdMob Interstitial Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Shows the preloaded full-screen real interstitial ad and calls [onComplete] upon dismissal
  Future<void> showInterstitialAd({VoidCallback? onComplete}) async {
    final shouldResumeMusic = storage.musicEnabled;

    if (!isSupportedPlatform || _interstitialAd == null) {
      // If ad is not ready or platform is desktop/test, proceed seamlessly
      loadInterstitialAd();
      onComplete?.call();
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null; // Mark as consumed

    try {
      audio?.pauseBgm();
    } catch (_) {}

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Real AdMob Interstitial Ad presented on screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Real AdMob Interstitial Ad dismissed by user.');
        ad.dispose();
        if (shouldResumeMusic) {
          try {
            audio?.resumeBgm();
          } catch (_) {}
        }
        loadInterstitialAd(); // Immediately preload next ad
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('Real AdMob Interstitial Ad failed to show: ${error.message}');
        ad.dispose();
        if (shouldResumeMusic) {
          try {
            audio?.resumeBgm();
          } catch (_) {}
        }
        loadInterstitialAd(); // Immediately preload next ad
        onComplete?.call();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('Exception while presenting interstitial ad: $e');
      if (shouldResumeMusic) {
        try {
          audio?.resumeBgm();
        } catch (_) {}
      }
      loadInterstitialAd();
      onComplete?.call();
    }
  }

  /// Handles game session increment: shows an ad after every 3rd game or retry
  Future<void> handleGamePlayOrRetry({required VoidCallback onProceed}) async {
    await storage.incrementPlaySessionCount();
    if (storage.shouldShowPlayAd) {
      debugPrint('Ad Trigger: 3rd game session milestone reached (${storage.playSessionCount}). Showing ad.');
      await showInterstitialAd(onComplete: onProceed);
    } else {
      onProceed();
    }
  }

  /// Handles scenery unlock: shows full-screen ad whenever player unlocks scenery
  Future<void> handleSceneryUnlock({VoidCallback? onProceed}) async {
    debugPrint('Ad Trigger: Scenery unlocked with coins. Showing ad.');
    await showInterstitialAd(onComplete: onProceed);
  }
}
