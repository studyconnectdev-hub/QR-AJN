import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import 'firebase_bootstrap.dart';
import 'premium_service.dart';

class AdService extends ChangeNotifier {
  AdService._();
  static final AdService instance = AdService._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool initialized = false;
  int _eligibleActions = 0;

  bool get enabled =>
      AppConfig.adsEnabled &&
      !PremiumService.instance.isPremium &&
      FirebaseBootstrap.flag('ads_enabled', fallback: true);

  Future<void> initialize() async {
    if (kIsWeb || initialized) return;
    try {
      final canRequestAds = await _requestConsent();
      if (!canRequestAds) {
        debugPrint('AdMob is waiting for consent.');
        return;
      }
      await MobileAds.instance.initialize();
      initialized = true;
      notifyListeners();
      await Future.wait([loadInterstitial(), loadRewarded()]);
    } catch (error) {
      debugPrint('AdMob initialization skipped: $error');
      notifyListeners();
    }
  }

  Future<bool> _requestConsent() async {
    final completer = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) debugPrint('Consent form: ${formError.message}');
          final allowed = await ConsentInformation.instance.canRequestAds();
          if (!completer.isCompleted) completer.complete(allowed);
        });
      },
      (formError) {
        debugPrint('Consent information: ${formError.message}');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => false,
    );
  }

  Future<void> showPrivacyOptions() async {
    if (kIsWeb) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) debugPrint('Privacy options: ${formError.message}');
      });
    } catch (error) {
      debugPrint('Privacy options unavailable: $error');
    }
  }

  BannerAd? createBanner() {
    if (!enabled || !initialized) return null;
    return BannerAd(
      size: AdSize.banner,
      adUnitId: AppConfig.androidBannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
        },
      ),
    );
  }

  Future<void> loadInterstitial() async {
    if (!enabled || !initialized || _interstitial != null) return;
    await InterstitialAd.load(
      adUnitId: AppConfig.androidInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => debugPrint('Interstitial failed: $error'),
      ),
    );
  }

  Future<void> showInterstitialAfterEligibleAction() async {
    if (!enabled) return;
    _eligibleActions += 1;
    if (_eligibleActions % 4 != 0) return;
    final ad = _interstitial;
    if (ad == null) {
      await loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadInterstitial());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(loadInterstitial());
      },
    );
    ad.show();
  }

  Future<void> loadRewarded() async {
    if (!enabled || !initialized || _rewarded != null) return;
    await RewardedAd.load(
      adUnitId: AppConfig.androidRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) => debugPrint('Rewarded failed: $error'),
      ),
    );
  }

  Future<bool> showRewarded() async {
    if (!enabled) return true;
    final ad = _rewarded;
    if (ad == null) {
      await loadRewarded();
      return false;
    }
    final completer = Completer<bool>();
    var earned = false;
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadRewarded());
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        unawaited(loadRewarded());
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }
}
