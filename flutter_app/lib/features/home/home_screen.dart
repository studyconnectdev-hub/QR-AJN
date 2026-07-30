import 'package:flutter/material.dart';
import '../../core/settings/app_settings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onScan,
    required this.onGenerate,
    required this.onSettings,
  });

  final VoidCallback onScan;
  final VoidCallback onGenerate;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = AppSettings.instance.reduceMotion;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? const [Color(0xFF07111F), Color(0xFF0B1731), Color(0xFF121B3B)]
                : const [Color(0xFFF4FAFF), Color(0xFFFAF5FF), Color(0xFFF1FFF8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'qr-ajn-logo',
                      child: Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Color(0x1A2563EB), blurRadius: 18)],
                        ),
                        child: Image.asset('assets/images/app_logo.png'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('QR AJN', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(999)),
                              child: const Text('V4.0', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                            ),
                          ]),
                          Text('Private scanner • Professional QR creator', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(onPressed: onSettings, tooltip: 'Settings', icon: const Icon(Icons.settings_rounded)),
                  ],
                ),
                const Spacer(),
                _Entrance(
                  enabled: !reducedMotion,
                  delay: 0,
                  child: _HeroCard(
                    title: 'Scan QR',
                    subtitle: 'Fast camera and gallery scanning with automatic zoom, target selection and safe action preview.',
                    buttonLabel: 'Open Scanner',
                    icon: Icons.qr_code_scanner_rounded,
                    colors: const [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    onTap: onScan,
                  ),
                ),
                const SizedBox(height: 18),
                _Entrance(
                  enabled: !reducedMotion,
                  delay: 100,
                  child: _HeroCard(
                    title: 'Create QR',
                    subtitle: 'Choose from 30 categories, customize gradients and patterns, preview quality, download and share.',
                    buttonLabel: 'Open Generator',
                    icon: Icons.qr_code_2_rounded,
                    colors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    onTap: onGenerate,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: .82), borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.colorScheme.outlineVariant)),
                  child: const Row(children: [
                    Icon(Icons.shield_rounded, color: Color(0xFF059669)),
                    SizedBox(width: 10),
                    Expanded(child: Text('No compulsory login • No automatic scan history • External actions require confirmation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Entrance extends StatelessWidget {
  const _Entrance({required this.child, required this.enabled, required this.delay});
  final Widget child;
  final bool enabled;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child)),
      child: child,
    );
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.title, required this.subtitle, required this.buttonLabel, required this.icon, required this.colors, required this.onTap});
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: pressed ? .975 : 1,
          duration: const Duration(milliseconds: 130),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: widget.colors.last.withValues(alpha: .35), blurRadius: 30, offset: const Offset(0, 14))],
            ),
            child: Row(children: [
              Container(width: 76, height: 76, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(24)), child: Icon(widget.icon, color: Colors.white, size: 42)),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(widget.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .88), height: 1.35)),
                const SizedBox(height: 15),
                Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(widget.buttonLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), const SizedBox(width: 7), const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)])),
              ])),
            ]),
          ),
        ),
      );
}
