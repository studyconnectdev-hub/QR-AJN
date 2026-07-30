import 'package:flutter/material.dart';
import '../../core/models/scan_models.dart';
import '../../core/parsing/scan_parser.dart';
import '../../core/runtime/app_runtime.dart';
import '../../core/security/safe_scan_engine.dart';
import '../../core/services/firebase_bootstrap.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});
  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _controller = TextEditingController();
  SafetyAssessment? _assessment;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _inspect() {
    final rules = AppRuntime.rules.value;
    if (rules == null || _controller.text.trim().isEmpty) return;
    final payload = ScanParser.parse(_controller.text);
    setState(() => _assessment = SafeScanEngine(rules).analyze(payload));
  }

  Future<void> _enableAnalytics() async {
    final enabled = await FirebaseBootstrap.enableAnalyticsForSession();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabled ? 'Anonymous feature analytics enabled for this app session.' : 'Analytics could not be enabled.')));
  }

  Future<void> _enableNotifications() async {
    final enabled = await FirebaseBootstrap.enableNotifications();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enabled ? 'Security update notifications enabled.' : 'Notification permission was not granted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety & intelligence')),
      body: ValueListenableBuilder(
        valueListenable: AppRuntime.rules,
        builder: (context, rules, _) => ListView(children: [
          Card(child: ListTile(
            leading: Icon(FirebaseBootstrap.available ? Icons.cloud_done : Icons.cloud_off),
            title: Text(FirebaseBootstrap.status),
            subtitle: Text('Scanner and bundled safety logic work offline. Threat-rule version: ${rules?.version ?? 'loading'}'),
          )),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Manual SafeScan inspector', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _controller, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Paste a URL or UPI URI')),
              const SizedBox(height: 10),
              FilledButton(onPressed: _inspect, child: const Text('Inspect locally')),
              if (_assessment != null) ...[
                const SizedBox(height: 12),
                Text('${_assessment!.label} • ${_assessment!.score}/100', style: Theme.of(context).textTheme.titleLarge),
                ..._assessment!.warnings.map((warning) => Text('• $warning')),
              ],
            ]),
          )),
          Card(child: Column(children: [
            const ListTile(leading: Icon(Icons.download_for_offline), title: Text('Threat-rule updates'), subtitle: Text('Bundled offline rules merge with Remote Config and optional public Firestore rules.')),
            ListTile(leading: const Icon(Icons.verified), title: const Text('Trusted-business directory'), subtitle: Text('${rules?.trustedDomains.length ?? 0} exact trusted domains loaded in this session.')),
            const ListTile(leading: Icon(Icons.photo_library_rounded), title: Text('Gallery and shared-image scanning'), subtitle: Text('Gallery images use the system photo picker and are processed only for the current result.')),
            const ListTile(leading: Icon(Icons.accessibility_new), title: Text('Accessibility'), subtitle: Text('Material semantics, system text scaling, dark mode, haptics and multilingual navigation labels.')),
            const ListTile(leading: Icon(Icons.ad_units), title: Text('Optional advertisements'), subtitle: Text('Ads are not included or active. Add an approved SDK only after consent and Data Safety updates.')),
          ])),
          Card(child: Column(children: [
            SwitchListTile(
              value: FirebaseBootstrap.analyticsEnabled,
              onChanged: FirebaseBootstrap.analyticsEnabled || !FirebaseBootstrap.available ? null : (_) => _enableAnalytics(),
              secondary: const Icon(Icons.analytics_outlined),
              title: const Text('Anonymous analytics for this session'),
              subtitle: const Text('Off by default. Raw QR content, domains, UPI IDs and messages are never sent as Analytics parameters.'),
            ),
            SwitchListTile(
              value: FirebaseBootstrap.notificationsEnabled,
              onChanged: FirebaseBootstrap.notificationsEnabled || !FirebaseBootstrap.available ? null : (_) => _enableNotifications(),
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Security update notifications'),
              subtitle: const Text('Permission is requested only after you turn this on.'),
            ),
          ])),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await AppRuntime.refreshRules();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh public safety rules'),
            ),
          ),
        ]),
      ),
    );
  }
}
