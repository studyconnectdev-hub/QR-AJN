class AppConfig {
  const AppConfig._();

  static const appName = 'QR AJN';
  static const packageName = 'com.qr.ajn';
  static const versionName = '5.0.0';
  static const buildNumber = 50;

  static const publicDomain = String.fromEnvironment(
    'QR_AJN_DOMAIN',
    defaultValue: 'https://qrajn.online',
  );

  static const adsEnabled =
      bool.fromEnvironment('ADS_ENABLED', defaultValue: true);
  static const useTestAds =
      bool.fromEnvironment('USE_TEST_ADS', defaultValue: true);

  static const androidBannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const androidInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const androidRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const premiumMonthlyId = String.fromEnvironment(
    'PREMIUM_MONTHLY_ID',
    defaultValue: 'qrajn_pro_monthly',
  );
  static const premiumYearlyId = String.fromEnvironment(
    'PREMIUM_YEARLY_ID',
    defaultValue: 'qrajn_pro_yearly',
  );
  static const businessMonthlyId = String.fromEnvironment(
    'BUSINESS_MONTHLY_ID',
    defaultValue: 'qrajn_business_monthly',
  );
  static const businessYearlyId = String.fromEnvironment(
    'BUSINESS_YEARLY_ID',
    defaultValue: 'qrajn_business_yearly',
  );

  static const premiumProductIds = <String>{
    premiumMonthlyId,
    premiumYearlyId,
    businessMonthlyId,
    businessYearlyId,
  };

  static bool isBusinessProduct(String productId) =>
      productId == businessMonthlyId || productId == businessYearlyId;

  static bool isYearlyProduct(String productId) =>
      productId == premiumYearlyId || productId == businessYearlyId;
}
