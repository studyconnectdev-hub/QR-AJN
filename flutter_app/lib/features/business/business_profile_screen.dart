import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/business_profile_service.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/media_upload_service.dart';
import '../../core/services/premium_service.dart';
import '../premium/premium_screen.dart';
import 'business_analytics_screen.dart';
import 'dynamic_qr_manager_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{
    for (final key in _fieldKeys) key: TextEditingController(),
  };

  bool _register = false;
  bool _loading = false;
  bool _published = true;
  bool _obscurePassword = true;
  int _step = 0;
  String _template = 'professional';
  String _color = '#2563EB';

  static const List<String> _fieldKeys = <String>[
    'slug',
    'name',
    'title',
    'company',
    'coverUrl',
    'photoUrl',
    'logoUrl',
    'phone',
    'whatsapp',
    'email',
    'website',
    'address',
    'mapUrl',
    'services',
    'products',
    'priceList',
    'galleryUrls',
    'videoUrls',
    'brochureUrl',
    'upiId',
    'reviewUrl',
    'leadFormUrl',
    'appointmentUrl',
    'openingHours',
    'branches',
    'languages',
    'testimonials',
    'certifications',
    'offers',
    'socialLinks',
  ];

  static const List<(String, String)> _templates = <(String, String)>[
    ('professional', 'Individual professional'),
    ('employee', 'Company employee'),
    ('freelancer', 'Freelancer'),
    ('shop', 'Shop & catalogue'),
    ('restaurant', 'Restaurant & menu'),
    ('doctor', 'Doctor / clinic'),
    ('lawyer', 'Lawyer'),
    ('realestate', 'Real-estate agent'),
    ('teacher', 'Teacher'),
    ('student', 'Student portfolio'),
    ('event', 'Event organizer'),
    ('photographer', 'Photographer'),
    ('influencer', 'Influencer'),
    ('hotel', 'Hotel'),
    ('school', 'School'),
    ('emergency', 'Emergency profile'),
  ];

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    if (AuthService.instance.signedIn) {
      _load();
    }
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    _email.dispose();
    _password.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {});
    if (AuthService.instance.signedIn &&
        _fields['slug']!.text.trim().isEmpty) {
      _load();
    }
  }

  TextEditingController field(String key) => _fields[key]!;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await BusinessProfileService.loadMine();
      if (profile != null) {
        final values = <String, String>{
          'slug': profile.slug,
          'name': profile.name,
          'title': profile.title,
          'company': profile.company,
          'coverUrl': profile.coverUrl,
          'photoUrl': profile.photoUrl,
          'logoUrl': profile.logoUrl,
          'phone': profile.phone,
          'whatsapp': profile.whatsapp,
          'email': profile.email,
          'website': profile.website,
          'address': profile.address,
          'mapUrl': profile.mapUrl,
          'services': profile.services.join('\n'),
          'products': profile.products.join('\n'),
          'priceList': profile.priceList.join('\n'),
          'galleryUrls': profile.galleryUrls.join('\n'),
          'videoUrls': profile.videoUrls.join('\n'),
          'brochureUrl': profile.brochureUrl,
          'upiId': profile.upiId,
          'reviewUrl': profile.reviewUrl,
          'leadFormUrl': profile.leadFormUrl,
          'appointmentUrl': profile.appointmentUrl,
          'openingHours': profile.openingHours,
          'branches': profile.branchLocations.join('\n'),
          'languages': profile.languages.join('\n'),
          'testimonials': profile.testimonials.join('\n'),
          'certifications': profile.certifications.join('\n'),
          'offers': profile.offers.join('\n'),
          'socialLinks': profile.socialLinks.entries
              .map((entry) => '${entry.key}=${entry.value}')
              .join('\n'),
        };
        for (final entry in values.entries) {
          field(entry.key).text = entry.value;
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

  List<String> _lines(String key) => field(key)
      .text
      .split(RegExp(r'[\r\n]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  Map<String, String> _socialLinks() {
    final links = <String, String>{};
    for (final line in _lines('socialLinks')) {
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final platform = line.substring(0, separator).trim();
      final url = line.substring(separator + 1).trim();
      if (platform.isNotEmpty && url.isNotEmpty) links[platform] = url;
    }
    return links;
  }

  BusinessProfile get profile => BusinessProfile(
        slug: BusinessProfileService.normalizeSlug(field('slug').text),
        name: field('name').text.trim(),
        title: field('title').text.trim(),
        company: field('company').text.trim(),
        coverUrl: field('coverUrl').text.trim(),
        photoUrl: field('photoUrl').text.trim(),
        logoUrl: field('logoUrl').text.trim(),
        phone: field('phone').text.trim(),
        whatsapp: field('whatsapp').text.trim(),
        email: field('email').text.trim(),
        website: field('website').text.trim(),
        address: field('address').text.trim(),
        mapUrl: field('mapUrl').text.trim(),
        services: _lines('services'),
        products: _lines('products'),
        priceList: _lines('priceList'),
        galleryUrls: _lines('galleryUrls'),
        videoUrls: _lines('videoUrls'),
        brochureUrl: field('brochureUrl').text.trim(),
        upiId: field('upiId').text.trim(),
        reviewUrl: field('reviewUrl').text.trim(),
        leadFormUrl: field('leadFormUrl').text.trim(),
        appointmentUrl: field('appointmentUrl').text.trim(),
        openingHours: field('openingHours').text.trim(),
        branchLocations: _lines('branches'),
        languages: _lines('languages'),
        testimonials: _lines('testimonials'),
        certifications: _lines('certifications'),
        offers: _lines('offers'),
        socialLinks: _socialLinks(),
        template: _template,
        primaryColor: _color,
        published: _published,
      );

  Future<void> _authenticate() async {
    final auth = AuthService.instance;
    final ok = _register
        ? await auth.register(_email.text, _password.text)
        : await auth.signIn(_email.text, _password.text);
    if (!ok) _show(auth.errorMessage ?? 'Authentication failed.');
  }

  Future<void> _googleSignIn() async {
    final ok = await AuthService.instance.signInWithGoogle();
    if (!ok) {
      _show(AuthService.instance.errorMessage ?? 'Google Sign-In failed.');
    }
  }

  Future<void> _save() async {
    if (_published && !PremiumService.instance.isPremium) {
      final openPremium = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.workspace_premium_rounded),
          title: const Text('Premium required to publish'),
          content: const Text(
            'Draft and preview are free. Publishing on qrajn.online, dynamic QR management and business analytics require an active Pro or Business plan.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep draft'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('View Premium'),
            ),
          ],
        ),
      );
      if (openPremium == true && mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
        );
      }
      if (!PremiumService.instance.isPremium) return;
    }

    setState(() => _loading = true);
    try {
      await BusinessProfileService.save(profile);
      _show(
        _published
            ? 'Published: ${profile.publicUrl}'
            : 'Private draft saved.',
      );
    } catch (error) {
      _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload(
    String key,
    BusinessMediaKind kind, {
    List<String>? extensions,
  }) async {
    setState(() => _loading = true);
    try {
      final url = await MediaUploadService.pickAndUpload(
        kind: kind,
        allowedExtensions: extensions,
      );
      if (url != null && mounted) {
        setState(() => field(key).text = url);
        _show('Upload completed.');
      }
    } catch (error) {
      _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.available) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Connect the new Firebase project with the included one-command production setup before creating cloud profiles.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (!AuthService.instance.signedIn) return _authView(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR AJN Business Builder'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Dynamic QR',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const DynamicQrManagerScreen(),
              ),
            ),
            icon: const Icon(Icons.alt_route_rounded),
          ),
          IconButton(
            tooltip: 'Analytics',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const BusinessAnalyticsScreen(),
              ),
            ),
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: AuthService.instance.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                _BuilderProgress(step: _step),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: ListView(
                      key: ValueKey<int>(_step),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      children: <Widget>[
                        if (_step == 0) _identityStep(),
                        if (_step == 1) _actionsStep(),
                        if (_step == 2) _contentStep(),
                        if (_step == 3) _designAndPublishStep(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _step == 0 ? null : () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _step == 3
                          ? _save
                          : () => setState(() => _step++),
                      icon: Icon(
                        _step == 3
                            ? Icons.cloud_upload_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(_step == 3 ? 'Save & publish' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _identityStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _StepHeader(
            icon: Icons.badge_rounded,
            title: 'Identity and public address',
            subtitle:
                'Choose a template, business identity and memorable qrajn.online URL.',
          ),
          _templateSelector(),
          _field(
            'slug',
            'Profile URL',
            Icons.alternate_email_rounded,
            helper: '${AppConfig.publicDomain}/@your-name',
          ),
          _field('name', 'Name or business name', Icons.person_rounded),
          _field('title', 'Professional title', Icons.badge_outlined),
          _field('company', 'Company', Icons.business_rounded),
          _uploadField(
            'coverUrl',
            'Cover image',
            Icons.panorama_outlined,
            BusinessMediaKind.cover,
          ),
          _uploadField(
            'photoUrl',
            'Profile photo',
            Icons.account_circle_outlined,
            BusinessMediaKind.profilePhoto,
          ),
          _uploadField(
            'logoUrl',
            'Business logo',
            Icons.image_outlined,
            BusinessMediaKind.logo,
          ),
        ],
      );

  Widget _actionsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _StepHeader(
            icon: Icons.touch_app_rounded,
            title: 'Contact and action buttons',
            subtitle:
                'Build the call, message, directions, payment and booking workflow.',
          ),
          _field(
            'phone',
            'Phone',
            Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          _field(
            'whatsapp',
            'WhatsApp number',
            Icons.chat_rounded,
            keyboardType: TextInputType.phone,
          ),
          _field(
            'email',
            'Email',
            Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          _field(
            'website',
            'Website',
            Icons.language_rounded,
            keyboardType: TextInputType.url,
          ),
          _field('address', 'Address', Icons.location_on_outlined, lines: 3),
          _field(
            'mapUrl',
            'Map or directions URL',
            Icons.map_outlined,
            keyboardType: TextInputType.url,
          ),
          _field('upiId', 'UPI ID', Icons.currency_rupee_rounded),
          _field(
            'reviewUrl',
            'Google Review URL',
            Icons.rate_review_outlined,
            keyboardType: TextInputType.url,
          ),
          _field(
            'appointmentUrl',
            'Appointment or booking URL',
            Icons.calendar_month_outlined,
            keyboardType: TextInputType.url,
          ),
          _field(
            'leadFormUrl',
            'Lead form URL',
            Icons.assignment_ind_outlined,
            keyboardType: TextInputType.url,
          ),
        ],
      );

  Widget _contentStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _StepHeader(
            icon: Icons.dashboard_customize_outlined,
            title: 'Business content',
            subtitle:
                'Enter one item or URL per line. These sections become mobile-friendly cards.',
          ),
          _field(
            'services',
            'Services',
            Icons.design_services_outlined,
            lines: 5,
          ),
          _field(
            'products',
            'Products',
            Icons.inventory_2_outlined,
            lines: 5,
          ),
          _field(
            'priceList',
            'Price list',
            Icons.receipt_long_outlined,
            lines: 5,
          ),
          _field(
            'galleryUrls',
            'Gallery image URLs',
            Icons.photo_library_outlined,
            lines: 4,
          ),
          _field(
            'videoUrls',
            'Video URLs',
            Icons.video_library_outlined,
            lines: 4,
          ),
          _uploadField(
            'brochureUrl',
            'Brochure PDF',
            Icons.picture_as_pdf_outlined,
            BusinessMediaKind.brochure,
            extensions: const <String>['pdf'],
          ),
          _field(
            'openingHours',
            'Opening hours',
            Icons.schedule_outlined,
            lines: 4,
          ),
          _field(
            'branches',
            'Branch locations',
            Icons.account_tree_outlined,
            lines: 4,
          ),
          _field(
            'languages',
            'Languages',
            Icons.translate_rounded,
            lines: 3,
          ),
          _field(
            'testimonials',
            'Testimonials',
            Icons.format_quote_rounded,
            lines: 5,
          ),
          _field(
            'certifications',
            'Certifications',
            Icons.verified_outlined,
            lines: 4,
          ),
          _field('offers', 'Offers', Icons.local_offer_outlined, lines: 4),
          _field(
            'socialLinks',
            'Social links: platform=url',
            Icons.hub_outlined,
            lines: 6,
          ),
        ],
      );

  Widget _designAndPublishStep() {
    final value = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _StepHeader(
          icon: Icons.palette_outlined,
          title: 'Design, preview and publish',
          subtitle:
              'Review the mobile identity, QR destination and public visibility.',
        ),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(_color),
          initialValue: _color,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.palette_outlined),
            labelText: 'Primary colour',
          ),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: '#2563EB', child: Text('Ocean Blue')),
            DropdownMenuItem(value: '#7C3AED', child: Text('Royal Violet')),
            DropdownMenuItem(value: '#059669', child: Text('Emerald')),
            DropdownMenuItem(value: '#E11D48', child: Text('Rose')),
            DropdownMenuItem(value: '#EA580C', child: Text('Sunset')),
            DropdownMenuItem(value: '#111827', child: Text('Midnight')),
          ],
          onChanged: (selection) =>
              setState(() => _color = selection ?? '#2563EB'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _published,
          onChanged: (value) => setState(() => _published = value),
          title: const Text('Publish publicly'),
          subtitle: const Text(
            'When off, the profile remains an owner-only draft.',
          ),
        ),
        const SizedBox(height: 12),
        _ProfilePreview(profile: value),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: value.slug.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: value.publicUrl),
                        );
                        _show('Profile link copied.');
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy link'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: value.slug.isEmpty
                    ? null
                    : () => SharePlus.instance.share(
                          ShareParams(
                            text:
                                '${value.name}\n${value.publicUrl}',
                          ),
                        ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _templateSelector() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          key: ValueKey<String>(_template),
          initialValue: _template,
          decoration: const InputDecoration(
            labelText: 'Profile template',
            prefixIcon: Icon(Icons.dashboard_customize_outlined),
          ),
          items: _templates
              .map(
                (template) => DropdownMenuItem<String>(
                  value: template.$1,
                  child: Text(template.$2),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => _template = value ?? 'professional'),
        ),
      );

  Widget _field(
    String key,
    String label,
    IconData icon, {
    int lines = 1,
    String? helper,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: field(key),
          maxLines: lines,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            prefixIcon: Icon(icon),
            alignLabelWithHint: lines > 1,
          ),
        ),
      );

  Widget _uploadField(
    String key,
    String label,
    IconData icon,
    BusinessMediaKind kind, {
    List<String>? extensions,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: field(key),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: '$label URL',
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(
              tooltip: 'Upload $label',
              onPressed: () => _upload(
                key,
                kind,
                extensions: extensions,
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
            ),
          ),
        ),
      );

  Widget _authView(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Business Profile Sign In')),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFFF4FAFF),
                Color(0xFFFAF5FF),
                Color(0xFFF2FFF9),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: <Widget>[
              const SizedBox(height: 22),
              const Icon(
                Icons.badge_rounded,
                size: 78,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              Text(
                _register
                    ? 'Create your QR AJN business account'
                    : 'Manage your qrajn.online identity',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scanning and static QR generation never require login. Sign in only for cloud profiles, dynamic QR, leads and analytics.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed:
                    AuthService.instance.busy ? null : _googleSignIn,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Continue with Google'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    AuthService.instance.busy ? null : _authenticate,
                child: Text(_register ? 'Create account' : 'Sign in'),
              ),
              TextButton(
                onPressed: () => setState(() => _register = !_register),
                child: Text(
                  _register
                      ? 'Already have an account? Sign in'
                      : 'Create a new business account',
                ),
              ),
              TextButton(
                onPressed: _email.text.trim().isEmpty
                    ? null
                    : () async {
                        await AuthService.instance
                            .resetPassword(_email.text);
                        _show('Password reset email sent.');
                      },
                child: const Text('Forgot password?'),
              ),
              if (AuthService.instance.errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(AuthService.instance.errorMessage!),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _BuilderProgress extends StatelessWidget {
  const _BuilderProgress({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Identity', 'Actions', 'Content', 'Publish'];
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Row(
          children: List<Widget>.generate(labels.length, (index) {
            final active = index <= step;
            return Expanded(
              child: Column(
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          active ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFF0EA5E9),
              Color(0xFF6366F1),
              Color(0xFFEC4899),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.profile});
  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(profile.primaryColor);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 118,
            decoration: BoxDecoration(
              image: profile.coverUrl.isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(profile.coverUrl),
                      fit: BoxFit.cover,
                    ),
              gradient: profile.coverUrl.isEmpty
                  ? LinearGradient(
                      colors: <Color>[
                        color,
                        color.withValues(alpha: .7),
                      ],
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              children: <Widget>[
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        width: 86,
                        height: 86,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: profile.photoUrl.isEmpty
                            ? const Icon(Icons.person_rounded, size: 54)
                            : Image.network(
                                profile.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.person_rounded, size: 54),
                              ),
                      ),
                      const Spacer(),
                      Container(
                        width: 86,
                        height: 86,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: profile.slug.isEmpty
                            ? const Icon(Icons.qr_code_2_rounded, size: 55)
                            : QrImageView(
                                data: profile.publicUrl,
                                padding: EdgeInsets.zero,
                              ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Column(
                    children: <Widget>[
                      Text(
                        profile.name.isEmpty
                            ? 'Your business name'
                            : profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        <String>[profile.title, profile.company]
                            .where((value) => value.isNotEmpty)
                            .join(' • '),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        profile.publicUrl,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          if (profile.phone.isNotEmpty)
                            const Chip(label: Text('Call')),
                          if (profile.whatsapp.isNotEmpty)
                            const Chip(label: Text('WhatsApp')),
                          if (profile.email.isNotEmpty)
                            const Chip(label: Text('Email')),
                          if (profile.mapUrl.isNotEmpty)
                            const Chip(label: Text('Directions')),
                          if (profile.upiId.isNotEmpty)
                            const Chip(label: Text('UPI Pay')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
