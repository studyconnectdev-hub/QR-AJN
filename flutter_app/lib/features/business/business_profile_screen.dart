import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/business_profile_service.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/premium_service.dart';
import '../premium/premium_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _controllers = List.generate(18, (_) => TextEditingController());
  bool _register = false;
  bool _loading = false;
  String _template = 'aurora';
  String _color = '#2563EB';
  bool _published = true;

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_authChanged);
    if (AuthService.instance.signedIn) _load();
  }

  void _authChanged() {
    if (mounted) setState(() {});
    if (AuthService.instance.signedIn && _controllers[0].text.isEmpty) _load();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_authChanged);
    _email.dispose();
    _password.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await BusinessProfileService.loadMine();
      if (profile != null) {
        final values = [
          profile.slug,
          profile.name,
          profile.title,
          profile.company,
          profile.photoUrl,
          profile.logoUrl,
          profile.phone,
          profile.whatsapp,
          profile.email,
          profile.website,
          profile.address,
          profile.mapUrl,
          profile.services,
          profile.products,
          profile.brochureUrl,
          profile.upiId,
          profile.appointmentUrl,
          profile.socialLinks.entries.map((entry) => '${entry.key}=${entry.value}').join('\n'),
        ];
        for (var index = 0; index < values.length; index++) {
          _controllers[index].text = values[index];
        }
        _template = profile.template;
        _color = profile.primaryColor;
        _published = profile.published;
      }
    } catch (error) {
      _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  BusinessProfile get _profile {
    final social = <String, String>{};
    for (final line in _controllers[17].text.split('\n')) {
      final index = line.indexOf('=');
      if (index > 0) social[line.substring(0, index).trim()] = line.substring(index + 1).trim();
    }
    return BusinessProfile(
      slug: BusinessProfileService.normalizeSlug(_controllers[0].text),
      name: _controllers[1].text.trim(),
      title: _controllers[2].text.trim(),
      company: _controllers[3].text.trim(),
      photoUrl: _controllers[4].text.trim(),
      logoUrl: _controllers[5].text.trim(),
      phone: _controllers[6].text.trim(),
      whatsapp: _controllers[7].text.trim(),
      email: _controllers[8].text.trim(),
      website: _controllers[9].text.trim(),
      address: _controllers[10].text.trim(),
      mapUrl: _controllers[11].text.trim(),
      services: _controllers[12].text.trim(),
      products: _controllers[13].text.trim(),
      brochureUrl: _controllers[14].text.trim(),
      upiId: _controllers[15].text.trim(),
      appointmentUrl: _controllers[16].text.trim(),
      socialLinks: social,
      template: _template,
      primaryColor: _color,
      published: _published,
    );
  }

  Future<void> _authenticate() async {
    final auth = AuthService.instance;
    final ok = _register
        ? await auth.register(_email.text, _password.text)
        : await auth.signIn(_email.text, _password.text);
    if (!ok && mounted) _show(auth.errorMessage ?? 'Authentication failed.');
  }

  Future<void> _save() async {
    if (_published && !PremiumService.instance.isPremium) {
      final openPremium = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.workspace_premium_rounded),
          title: const Text('Premium required to publish'),
          content: const Text(
            'You can prepare and preview the profile for free. An active QR AJN Pro or Business plan is required to publish it on qrajn.online.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep as draft')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('View Premium')),
          ],
        ),
      );
      if (openPremium == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
      }
      if (!PremiumService.instance.isPremium) return;
    }
    setState(() => _loading = true);
    try {
      if (_profile.name.isEmpty) throw StateError('Enter the profile name.');
      await BusinessProfileService.save(_profile);
      _show('Published: ${_profile.publicUrl}');
    } catch (error) {
      _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.available) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Connect Firebase using the included one-command setup before creating cloud business profiles.', textAlign: TextAlign.center))),
      );
    }
    if (!AuthService.instance.signedIn) return _authView(context);
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('qrajn.online Business Profile'),
        actions: [IconButton(onPressed: AuthService.instance.signOut, icon: const Icon(Icons.logout_rounded), tooltip: 'Sign out')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const _Section('Public profile URL'),
                _field(0, 'Profile URL', Icons.alternate_email_rounded, helper: '${AppConfig.publicDomain}/@your-name'),
                const _Section('Identity'),
                _field(1, 'Name', Icons.person_rounded),
                _field(2, 'Professional title', Icons.badge_outlined),
                _field(3, 'Company', Icons.business_rounded),
                _field(4, 'Profile photo URL', Icons.account_circle_outlined),
                _field(5, 'Logo URL', Icons.image_outlined),
                const _Section('Contact actions'),
                _field(6, 'Phone', Icons.phone_rounded),
                _field(7, 'WhatsApp', Icons.chat_rounded),
                _field(8, 'Email', Icons.email_rounded),
                _field(9, 'Website', Icons.language_rounded),
                _field(10, 'Address', Icons.location_on_outlined, lines: 2),
                _field(11, 'Map URL', Icons.map_outlined),
                const _Section('Business content'),
                _field(12, 'Services (one per line)', Icons.design_services_outlined, lines: 4),
                _field(13, 'Products (one per line)', Icons.inventory_2_outlined, lines: 4),
                _field(14, 'Brochure URL', Icons.description_outlined),
                _field(15, 'UPI ID', Icons.currency_rupee_rounded),
                _field(16, 'Appointment URL', Icons.calendar_month_outlined),
                _field(17, 'Social links: platform=url', Icons.hub_outlined, lines: 5),
                const _Section('Template'),
                DropdownButtonFormField<String>(
                  key: ValueKey(_template),
                  initialValue: _template,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.dashboard_customize_outlined), labelText: 'Profile template'),
                  items: const [
                    DropdownMenuItem(value: 'aurora', child: Text('Aurora Professional')),
                    DropdownMenuItem(value: 'minimal', child: Text('Minimal Business')),
                    DropdownMenuItem(value: 'restaurant', child: Text('Restaurant & Menu')),
                    DropdownMenuItem(value: 'portfolio', child: Text('Portfolio & Creator')),
                    DropdownMenuItem(value: 'store', child: Text('Shop & Catalogue')),
                  ],
                  onChanged: (value) => setState(() => _template = value ?? 'aurora'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _color,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.palette_outlined), labelText: 'Primary colour'),
                  items: const [
                    DropdownMenuItem(value: '#2563EB', child: Text('Ocean Blue')),
                    DropdownMenuItem(value: '#7C3AED', child: Text('Royal Violet')),
                    DropdownMenuItem(value: '#059669', child: Text('Emerald')),
                    DropdownMenuItem(value: '#E11D48', child: Text('Rose')),
                    DropdownMenuItem(value: '#EA580C', child: Text('Sunset')),
                  ],
                  onChanged: (value) => setState(() => _color = value ?? '#2563EB'),
                ),
                SwitchListTile(
                  value: _published,
                  onChanged: (value) => setState(() => _published = value),
                  title: const Text('Public profile'),
                  subtitle: const Text('Anyone with the QR or link can view the published profile.'),
                ),
                const SizedBox(height: 16),
                _ProfilePreview(profile: profile),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: _save, icon: const Icon(Icons.cloud_upload_rounded), label: const Text('Publish profile')),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: profile.slug.isEmpty ? null : () => Clipboard.setData(ClipboardData(text: profile.publicUrl)).then((_) => _show('Profile link copied.')),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy profile link'),
                ),
                OutlinedButton.icon(
                  onPressed: profile.slug.isEmpty ? null : () => SharePlus.instance.share(ShareParams(text: profile.publicUrl)),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share profile'),
                ),
              ],
            ),
    );
  }

  Widget _authView(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Business Profile Sign In')),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Icon(Icons.badge_rounded, size: 74, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text(_register ? 'Create QR AJN business account' : 'Sign in to manage your profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded))),
            const SizedBox(height: 16),
            FilledButton(onPressed: AuthService.instance.busy ? null : _authenticate, child: Text(_register ? 'Create account' : 'Sign in')),
            TextButton(onPressed: () => setState(() => _register = !_register), child: Text(_register ? 'Already have an account? Sign in' : 'Create a new business account')),
            TextButton(onPressed: _email.text.trim().isEmpty ? null : () => AuthService.instance.resetPassword(_email.text).then((_) => _show('Password reset email sent.')), child: const Text('Forgot password?')),
          ],
        ),
      );

  Widget _field(int index, String label, IconData icon, {int lines = 1, String? helper}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _controllers[index],
          maxLines: lines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: label, helperText: helper, prefixIcon: Icon(icon)),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      );
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.profile});
  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(profile.primaryColor);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: .72)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .28), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: profile.publicUrl.endsWith('/@')
                ? const Icon(Icons.qr_code_2_rounded, size: 58)
                : QrImageView(data: profile.publicUrl, padding: EdgeInsets.zero),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile.name.isEmpty ? 'Your business name' : profile.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              Text([profile.title, profile.company].where((value) => value.isNotEmpty).join(' • '), style: TextStyle(color: Colors.white.withValues(alpha: .82))),
              const SizedBox(height: 8),
              Text(profile.publicUrl, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
            ]),
          ),
        ],
      ),
    );
  }

  static Color _parseColor(String value) {
    final clean = value.replaceAll('#', '');
    final parsed = int.tryParse(clean, radix: 16) ?? 0x2563EB;
    return Color(0xFF000000 | parsed);
  }
}
