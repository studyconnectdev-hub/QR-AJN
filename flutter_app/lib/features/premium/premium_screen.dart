import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/premium_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = PremiumService.instance;
    return AnimatedBuilder(
      animation: premium,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('QR AJN Premium')),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4FAFF), Color(0xFFFAF5FF), Color(0xFFF2FFF9)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [BoxShadow(color: Color(0x442563EB), blurRadius: 26, offset: Offset(0, 12))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
                    const SizedBox(height: 14),
                    Text(
                      premium.isPremium ? 'Premium is active' : 'Create, publish and grow without limits',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      premium.isPremium
                          ? '${premium.plan.toUpperCase()} plan • ${premium.serverVerified ? 'Server verified' : 'Purchase received'}'
                          : 'Remove ads, unlock professional exports, advanced templates and QR AJN business tools.',
                      style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _Benefits(),
              const SizedBox(height: 18),
              if (!premium.storeAvailable)
                const _Notice(
                  icon: Icons.info_outline_rounded,
                  text: 'Google Play products appear here after the app is uploaded to Play Console and the subscription IDs are created.',
                ),
              for (final product in premium.products)
                _PlanCard(
                  title: _titleFor(product.id),
                  subtitle: _subtitleFor(product.id),
                  price: product.price,
                  highlighted: product.id == AppConfig.premiumYearlyId,
                  onTap: premium.loading ? null : () => premium.buy(product),
                ),
              if (premium.products.isEmpty) ...[
                _PlanCard(
                  title: 'QR AJN Pro Monthly',
                  subtitle: 'No ads, advanced designer and premium exports',
                  price: 'Configure ${AppConfig.premiumMonthlyId}',
                  onTap: null,
                ),
                _PlanCard(
                  title: 'QR AJN Pro Yearly',
                  subtitle: 'Best value for professional creators',
                  price: 'Configure ${AppConfig.premiumYearlyId}',
                  highlighted: true,
                  onTap: null,
                ),
                _PlanCard(
                  title: 'QR AJN Business Monthly',
                  subtitle: 'Profiles, dynamic QR, leads and analytics',
                  price: 'Configure ${AppConfig.businessMonthlyId}',
                  onTap: null,
                ),
                _PlanCard(
                  title: 'QR AJN Business Yearly',
                  subtitle: 'Best value for businesses and teams',
                  price: 'Configure ${AppConfig.businessYearlyId}',
                  highlighted: true,
                  onTap: null,
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: premium.loading ? null : premium.restore,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore purchases'),
              ),
              if (premium.message != null) ...[
                const SizedBox(height: 12),
                _Notice(icon: Icons.receipt_long_outlined, text: premium.message!),
              ],
              if (!AuthService.instance.signedIn) ...[
                const SizedBox(height: 12),
                const _Notice(
                  icon: Icons.cloud_outlined,
                  text: 'Sign in from Business Profile to synchronize server-verified premium access across devices.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _titleFor(String id) {
    if (id == AppConfig.premiumMonthlyId) return 'QR AJN Pro Monthly';
    if (id == AppConfig.premiumYearlyId) return 'QR AJN Pro Yearly';
    if (id == AppConfig.businessYearlyId) return 'QR AJN Business Yearly';
    return 'QR AJN Business Monthly';
  }

  static String _subtitleFor(String id) {
    if (AppConfig.isBusinessProduct(id)) {
      return AppConfig.isYearlyProduct(id)
          ? 'Best value • business profiles, dynamic QR, leads and analytics'
          : 'Business profiles, dynamic QR, leads and analytics';
    }
    if (id == AppConfig.premiumYearlyId) {
      return 'Best value • all Pro features for one year';
    }
    return 'No ads and complete professional QR designer';
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: const Column(
          children: [
            _Benefit(Icons.block_rounded, 'Remove all QR AJN ads'),
            _Benefit(Icons.palette_outlined, 'Premium gradients, patterns and templates'),
            _Benefit(Icons.picture_as_pdf_outlined, 'High-resolution PNG, SVG and PDF export'),
            _Benefit(Icons.badge_outlined, 'Publish qrajn.online business profiles'),
            _Benefit(Icons.alt_route_rounded, 'Editable dynamic QR destinations'),
            _Benefit(Icons.analytics_outlined, 'Business analytics when Blaze is enabled'),
          ],
        ),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [Icon(icon, color: const Color(0xFF2563EB)), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.subtitle, required this.price, this.highlighted = false, this.onTap});
  final String title;
  final String subtitle;
  final String price;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: highlighted ? const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)]) : null,
          color: highlighted ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: highlighted ? const Color(0xFF8B5CF6) : Theme.of(context).colorScheme.outlineVariant, width: highlighted ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                  if (highlighted) const Chip(label: Text('BEST VALUE')),
                ]),
                const SizedBox(height: 5),
                Text(subtitle),
                const SizedBox(height: 8),
                Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
              ]),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: onTap, child: Text(onTap == null ? 'Setup' : 'Choose')),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [Icon(icon), const SizedBox(width: 10), Expanded(child: Text(text))]),
      );
}
