import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key});

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_sync);
    AdService.instance.addListener(_sync);
    _sync();
  }

  void _sync() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    if (!AdService.instance.enabled || !AdService.instance.initialized) {
      if (mounted) setState(() {});
      return;
    }
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AppConfig.androidBannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _ad = ad;
    ad.load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PremiumService.instance.removeListener(_sync);
    AdService.instance.removeListener(_sync);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null || PremiumService.instance.isPremium) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Container(
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surface,
        width: double.infinity,
        height: ad.size.height.toDouble(),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
