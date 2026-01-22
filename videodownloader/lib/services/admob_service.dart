import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Video Player Pro - All Format
  static const String appId = 'ca-app-pub-3408903389045590~3476269948';

  // Banner Ad ID
  static const String bannerAdId = 'ca-app-pub-3408903389045590/9020240664';

  // App Open Ad ID
  static const String appOpenAdId = 'ca-app-pub-3408903389045590/6338237008';

  // Interstitial Ad ID
  static const String interstitialAdId = 'ca-app-pub-3408903389045590/3308092448';

  // Native Reward Ad ID
  static const String nativeRewardAdId = 'ca-app-pub-3408903389045590/1388506110';

  // Rewarded Ad ID
  static const String rewardedAdId = 'ca-app-pub-3408903389045590/9926128227';

  static BannerAd? _bannerAd;
  static AppOpenAd? _appOpenAd;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static NativeAd? _nativeAd;
  static bool _isAppOpenAdLoading = false;
  static bool _isInterstitialAdLoading = false;
  static bool _isRewardedAdLoading = false;
  static bool _isNativeAdLoading = false;
  static DateTime? _lastAppOpenAdShown;
  static DateTime? _lastInterstitialAdShown;
  static DateTime? _lastBannerAdShown;
  static DateTime? _lastRewardedAdShown;
  static const int _appOpenAdCooldownSeconds = 45; // Show app-open ads every 45 seconds
  static const int _interstitialAdCooldownSeconds = 60; // Show interstitial ads every 60 seconds (very frequent!)
  static const int _bannerAdCooldownSeconds = 0; // Show banner ads always (no cooldown)
  static const int _rewardedAdCooldownSeconds = 30; // Show reward ads every 30 seconds

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
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

  // Rewarded Ad Methods
  static void loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) return;

    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Rewarded ad dismissed');
              _rewardedAd = null;
              loadRewardedAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Rewarded ad failed to show: $error');
              _rewardedAd = null;
              loadRewardedAd(); // Load next ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isRewardedAdLoading = false;
          // Retry loading after 5 seconds
          Future.delayed(const Duration(seconds: 5), loadRewardedAd);
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(AdWithoutView, RewardItem) onUserEarnedReward,
    Function()? onAdDismissed,
  }) {
    if (_rewardedAd != null && _canShowRewardedAd()) {
      _rewardedAd!.show(
        onUserEarnedReward: onUserEarnedReward,
      );
      _lastRewardedAdShown = DateTime.now();
      _rewardedAd = null;
    }
  }

  static bool _canShowRewardedAd() {
    if (_lastRewardedAdShown == null) return true;

    final now = DateTime.now();
    final timeSinceLastAd = now.difference(_lastRewardedAdShown!);
    return timeSinceLastAd.inSeconds >= _rewardedAdCooldownSeconds;
  }

  static bool get isRewardedAdAvailable => _rewardedAd != null && _canShowRewardedAd();

  // Native Ad Methods
  static void loadNativeAd() {
    if (_isNativeAdLoading || _nativeAd != null) return;

    _isNativeAdLoading = true;
    _nativeAd = NativeAd(
      adUnitId: nativeRewardAdId,
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
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
  }
}