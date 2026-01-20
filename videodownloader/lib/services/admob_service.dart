import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static const String appId = 'ca-app-pub-3408903389045590~5719529565';

  // Banner Ad IDs
  static const String bannerAdId = 'ca-app-pub-3408903389045590/4406447894'; // video-player - 1

  // App Open Ad IDs
  static const String appOpenAdId = 'ca-app-pub-3408903389045590/8768364732'; // app-open-video-player-1

  // Interstitial Ad IDs
  static const String interstitialAdId = 'ca-app-pub-3408903389045590/6300331105'; // interstitial-video Player-1

  // Native Advanced Ad IDs
  static const String nativeAdvancedAdId = 'ca-app-pub-3408903389045590/7200310421'; // native advanced

  // Rewarded Interstitial Ad IDs (primary)
  static const String rewardedInterstitialAdId = 'ca-app-pub-3408903389045590/6225089737'; // rewarded-intestitial

  // Rewarded Interstitial Ad IDs (secondary)
  static const String rewardedInterstitialAdId2 = 'ca-app-pub-3408903389045590/3887751378'; // reward interstitial

  static BannerAd? _bannerAd;
  static AppOpenAd? _appOpenAd;
  static InterstitialAd? _interstitialAd;
  static RewardedInterstitialAd? _rewardedInterstitialAd;
  static NativeAd? _nativeAd;
  static bool _isAppOpenAdLoading = false;
  static bool _isInterstitialAdLoading = false;
  static bool _isRewardedInterstitialAdLoading = false;
  static bool _isNativeAdLoading = false;
  static DateTime? _lastAppOpenAdShown;
  static DateTime? _lastInterstitialAdShown;
  static DateTime? _lastBannerAdShown;
  static const int _appOpenAdCooldownSeconds = 30; // Show app-open ads every 30 seconds
  static const int _interstitialAdCooldownSeconds = 15; // Show interstitial ads every 15 seconds (very frequent!)
  static const int _bannerAdCooldownSeconds = 10; // Show banner ads every 10 seconds

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedInterstitialAd();
    loadNativeAd();
  }

  // Banner Ad Methods
  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
      ),
    );
  }

  // App Open Ad Methods
  static void loadAppOpenAd() {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;

    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: appOpenAdId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('App open ad loaded');
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('App open ad dismissed');
              _appOpenAd = null;
              loadAppOpenAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('App open ad failed to show: $error');
              _appOpenAd = null;
              loadAppOpenAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('App open ad failed to load: $error');
          _isAppOpenAdLoading = false;
        },
      ),
    );
  }

  static void showAppOpenAd() {
    if (_appOpenAd != null && _canShowAppOpenAd()) {
      _appOpenAd!.show();
      _appOpenAd = null;
      _lastAppOpenAdShown = DateTime.now();
    }
  }

  static bool _canShowAppOpenAd() {
    if (_lastAppOpenAdShown == null) return true;

    final now = DateTime.now();
    final timeSinceLastAd = now.difference(_lastAppOpenAdShown!);
    return timeSinceLastAd.inSeconds >= _appOpenAdCooldownSeconds;
  }

  static bool get isAppOpenAdAvailable => _appOpenAd != null && _canShowAppOpenAd();

  // Interstitial Ad Methods
  static void loadInterstitialAd() {
    if (_isInterstitialAdLoading || _interstitialAd != null) return;

    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Interstitial ad dismissed');
              _interstitialAd = null;
              loadInterstitialAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              _interstitialAd = null;
              loadInterstitialAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_interstitialAd != null && _canShowInterstitialAd()) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _lastInterstitialAdShown = DateTime.now();
    }
  }

  static bool _canShowInterstitialAd() {
    if (_lastInterstitialAdShown == null) return true;

    final now = DateTime.now();
    final timeSinceLastAd = now.difference(_lastInterstitialAdShown!);
    return timeSinceLastAd.inSeconds >= _interstitialAdCooldownSeconds;
  }

  static bool get isInterstitialAdAvailable => _interstitialAd != null && _canShowInterstitialAd();

  // Rewarded Interstitial Ad Methods
  static void loadRewardedInterstitialAd() {
    if (_isRewardedInterstitialAdLoading || _rewardedInterstitialAd != null) return;

    _isRewardedInterstitialAdLoading = true;
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Rewarded interstitial ad loaded');
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdLoading = false;
          _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Rewarded interstitial ad dismissed');
              _rewardedInterstitialAd = null;
              loadRewardedInterstitialAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Rewarded interstitial ad failed to show: $error');
              _rewardedInterstitialAd = null;
              loadRewardedInterstitialAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Rewarded interstitial ad failed to load: $error');
          _isRewardedInterstitialAdLoading = false;
        },
      ),
    );
  }

  static void showRewardedInterstitialAd({
    required Function(AdWithoutView, RewardItem) onUserEarnedReward,
    Function()? onAdDismissed,
  }) {
    if (_rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: onUserEarnedReward,
      );
      _rewardedInterstitialAd = null;
    }
  }

  static bool get isRewardedInterstitialAdAvailable => _rewardedInterstitialAd != null;

  // Native Ad Methods
  static void loadNativeAd() {
    if (_isNativeAdLoading || _nativeAd != null) return;

    _isNativeAdLoading = true;
    _nativeAd = NativeAd(
      adUnitId: nativeAdvancedAdId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('Native ad loaded');
          _isNativeAdLoading = false;
        },
        onAdFailedToLoad: (ad, error) {
          print('Native ad failed to load: $error');
          _isNativeAdLoading = false;
          ad.dispose();
          _nativeAd = null;
        },
        onAdOpened: (ad) {
          print('Native ad opened');
        },
        onAdClosed: (ad) {
          print('Native ad closed');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF1E1E1E),
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF3B82F6),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    )..load();
  }

  static NativeAd? getNativeAd() {
    return _nativeAd;
  }

  static bool get isNativeAdAvailable => _nativeAd != null;

  // Helper method to show interstitial ads more frequently
  static void showInterstitialAdIfAvailable() {
    if (isInterstitialAdAvailable) {
      showInterstitialAd();
    }
  }

  // Helper method to track banner ad display
  static void trackBannerAdDisplay() {
    _lastBannerAdShown = DateTime.now();
  }

  static bool get canShowBannerAd {
    if (_lastBannerAdShown == null) return true;
    final now = DateTime.now();
    final timeSinceLastAd = now.difference(_lastBannerAdShown!);
    return timeSinceLastAd.inSeconds >= _bannerAdCooldownSeconds;
  }

  // Dispose all ads
  static void dispose() {
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _nativeAd?.dispose();
  }
}