import 'package:flutter/material.dart';
import '../../core/runtime/app_runtime.dart';
import '../../core/services/action_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/business_profile_service.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/premium_service.dart';
import '../../core/settings/app_settings.dart';
import '../business/business_profile_screen.dart';
import '../premium/premium_screen.dart';
import '../privacy/privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([settings, PremiumService.instance, AuthService.instance]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _AccountCard(
              onPremium: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
              onBusiness: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfileScreen())),
            ),
            const _Header('Scanner'),
            SwitchListTile(title: const Text('Scan sound'), secondary: const Icon(Icons.volume_up_outlined), value: settings.sound, onChanged: (value) => settings.setBool('sound', value)),
            SwitchListTile(title: const Text('Vibration'), secondary: const Icon(Icons.vibration_rounded), value: settings.vibration, onChanged: (value) => settings.setBool('vibration', value)),
            SwitchListTile(title: const Text('Automatic zoom'), subtitle: const Text('Helps find smaller and distant QR codes'), secondary: const Icon(Icons.zoom_in_map_rounded), value: settings.autoZoom, onChanged: (value) => settings.setBool('autoZoom', value)),
            const _Header('Redirects & payments'),
            SwitchListTile(title: const Text('Confirm external links'), subtitle: const Text('Show the destination before opening another app or website'), secondary: const Icon(Icons.open_in_new_rounded), value: settings.confirmExternalLinks, onChanged: (value) => settings.setBool('confirmExternalLinks', value)),
            SwitchListTile(title: const Text('Show full destination'), secondary: const Icon(Icons.link_rounded), value: settings.showFullDestination, onChanged: (value) => settings.setBool('showFullDestination', value)),
            SwitchListTile(title: const Text('Confirm every UPI payment'), secondary: const Icon(Icons.payments_outlined), value: settings.confirmPayments, onChanged: (value) => settings.setBool('confirmPayments', value)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: DropdownButtonFormField<String>(
                key: ValueKey(settings.preferredPaymentApp),
                initialValue: settings.preferredPaymentApp,
                decoration: const InputDecoration(labelText: 'Preferred payment app', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
                items: ActionService.knownPaymentApps.map((app) => DropdownMenuItem(value: app.id, child: Text(app.label))).toList(),
                onChanged: (value) { if (value != null) settings.setPreferredPaymentApp(value); },
              ),
            ),
            const _Header('Security'),
            SwitchListTile(title: const Text('SafeScan analysis'), subtitle: const Text('Inspect links, app links and payment requests before opening'), secondary: const Icon(Icons.shield_outlined), value: settings.safeScan, onChanged: (value) => settings.setBool('safeScan', value)),
            SwitchListTile(title: const Text('Block dangerous actions'), secondary: const Icon(Icons.block_rounded), value: settings.blockDangerous, onChanged: (value) => settings.setBool('blockDangerous', value)),
            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: const Text('Safety intelligence'),
              subtitle: Text('${FirebaseBootstrap.status}\nRules: ${AppRuntime.rules.value?.version ?? 'loading'}'),
              isThreeLine: true,
              trailing: IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: AppRuntime.refreshRules),
            ),
            const _Header('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) => settings.setTheme(selection.first),
              ),
            ),
            SwitchListTile(title: const Text('Reduce animations'), secondary: const Icon(Icons.motion_photos_off_outlined), value: settings.reduceMotion, onChanged: (value) => settings.setBool('reduceMotion', value)),
            const _Header('Privacy & diagnostics'),
            SwitchListTile(title: const Text('Optional Analytics'), subtitle: const Text('Never sends raw QR content'), secondary: const Icon(Icons.analytics_outlined), value: settings.analytics, onChanged: (value) async {
              if (value) await FirebaseBootstrap.enableAnalyticsForSession();
              await settings.setBool('analytics', value);
            }),
            ListTile(
              leading: const Icon(Icons.ad_units_outlined),
              title: const Text('Ad privacy choices'),
              subtitle: const Text('Review available Google advertising consent choices'),
              onTap: AdService.instance.showPrivacyOptions,
            ),
            ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('Security notifications'), subtitle: Text(FirebaseBootstrap.notificationsEnabled ? 'Enabled' : 'Off'), trailing: FilledButton.tonal(onPressed: FirebaseBootstrap.enableNotifications, child: const Text('Enable'))),
            ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy policy'), subtitle: const Text('No compulsory login and no automatic scan history'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
            if (AuthService.instance.signedIn)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Delete business account'),
                subtitle: const Text('Deletes the published profile and Firebase account'),
                onTap: () => _deleteBusinessAccount(context),
              ),
            const _Header('About'),
            const ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('QR AJN'), subtitle: Text('Version 5.0.0 • Build 50\nPackage: com.qr.ajn')),
          ],
        ),
      ),
    );
  }
}


Future<void> _deleteBusinessAccount(BuildContext context) async {
  final password = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete QR AJN account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This permanently removes your published business profile and sign-in account. Purchases remain managed by Google Play.'),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete permanently'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    password.dispose();
    return;
  }
  try {
    await BusinessProfileService.deleteMine();
    final deleted = await AuthService.instance.deleteAccount(password.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(deleted ? 'Account deleted.' : AuthService.instance.errorMessage ?? 'Account deletion failed.')),
    );
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
  } finally {
    password.dispose();
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onPremium, required this.onBusiness});
  final VoidCallback onPremium;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) {
    final premium = PremiumService.instance;
    final auth = AuthService.instance;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)]), borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x332563EB), blurRadius: 24, offset: Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(premium.isPremium ? '${premium.plan.toUpperCase()} active' : 'QR AJN Free', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
            Text(auth.signedIn ? auth.user?.email ?? 'Business account' : 'No business account signed in', style: TextStyle(color: Colors.white.withValues(alpha: .82))),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FilledButton.tonal(onPressed: onPremium, child: Text(premium.isPremium ? 'Manage plan' : 'View Premium'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.tonal(onPressed: onBusiness, child: const Text('Business Profile'))),
        ]),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
        child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: .8)),
      );
}
