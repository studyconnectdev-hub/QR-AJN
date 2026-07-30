import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/dynamic_link_service.dart';
import '../../core/services/premium_service.dart';
import '../premium/premium_screen.dart';

class DynamicQrManagerScreen extends StatefulWidget {
  const DynamicQrManagerScreen({super.key});

  @override
  State<DynamicQrManagerScreen> createState() =>
      _DynamicQrManagerScreenState();
}

class _DynamicQrManagerScreenState extends State<DynamicQrManagerScreen> {
  bool _loading = true;
  List<DynamicQrLink> _links = const <DynamicQrLink>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      _links = await DynamicLinkService.loadMine();
    } catch (error) {
      _show('$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([DynamicQrLink? existing]) async {
    if (!PremiumService.instance.isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
      );
      if (!PremiumService.instance.isPremium || !mounted) return;
    }

    final result = await showModalBottomSheet<DynamicQrLink>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DynamicLinkEditor(existing: existing),
    );
    if (result == null) return;

    try {
      await DynamicLinkService.save(result);
      await _reload();
      _show('Dynamic QR saved.');
    } catch (error) {
      _show('$error');
    }
  }

  Future<void> _delete(DynamicQrLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete dynamic QR?'),
        content: Text('Delete “${link.title}”? The printed QR will stop working.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DynamicLinkService.delete(link.code);
    await _reload();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Dynamic QR Manager'),
          actions: <Widget>[
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.add_link_rounded),
          label: const Text('New dynamic QR'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _links.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _links.length,
                    itemBuilder: (context, index) {
                      final link = _links[index];
                      return _DynamicLinkCard(
                        link: link,
                        onEdit: () => _edit(link),
                        onDelete: () => _delete(link),
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: link.publicUrl),
                          );
                          _show('Dynamic QR link copied.');
                        },
                        onShare: () => SharePlus.instance.share(
                          ShareParams(
                            text: '${link.title}\n${link.publicUrl}',
                          ),
                        ),
                      );
                    },
                  ),
      );
}

class _DynamicLinkCard extends StatelessWidget {
  const _DynamicLinkCard({
    required this.link,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onShare,
  });

  final DynamicQrLink link;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 98,
                height: 98,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  data: link.publicUrl,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            link.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(link.active ? 'ACTIVE' : 'PAUSED'),
                        ),
                      ],
                    ),
                    Text(
                      link.publicUrl,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      link.destination,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${link.scanCount} scans'
                      '${link.maximumScans == null ? '' : ' • limit ${link.maximumScans}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Wrap(
                      spacing: 4,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: onCopy,
                          icon: const Icon(Icons.copy_rounded),
                        ),
                        IconButton(
                          tooltip: 'Share',
                          onPressed: onShare,
                          icon: const Icon(Icons.share_rounded),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _DynamicLinkEditor extends StatefulWidget {
  const _DynamicLinkEditor({this.existing});
  final DynamicQrLink? existing;

  @override
  State<_DynamicLinkEditor> createState() => _DynamicLinkEditorState();
}

class _DynamicLinkEditorState extends State<_DynamicLinkEditor> {
  late final TextEditingController _title;
  late final TextEditingController _destination;
  late final TextEditingController _android;
  late final TextEditingController _ios;
  late final TextEditingController _desktop;
  late final TextEditingController _fallback;
  late final TextEditingController _maximumScans;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final link = widget.existing;
    _title = TextEditingController(text: link?.title ?? '');
    _destination = TextEditingController(text: link?.destination ?? '');
    _android = TextEditingController(text: link?.androidDestination ?? '');
    _ios = TextEditingController(text: link?.iosDestination ?? '');
    _desktop = TextEditingController(text: link?.desktopDestination ?? '');
    _fallback = TextEditingController(text: link?.fallbackDestination ?? '');
    _maximumScans = TextEditingController(
      text: link?.maximumScans?.toString() ?? '',
    );
    _active = link?.active ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _destination.dispose();
    _android.dispose();
    _ios.dispose();
    _desktop.dispose();
    _fallback.dispose();
    _maximumScans.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              widget.existing == null ? 'Create dynamic QR' : 'Edit dynamic QR',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _field(_title, 'Title', Icons.title_rounded),
            _field(
              _destination,
              'Default HTTPS destination',
              Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              _android,
              'Android destination (optional)',
              Icons.android_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              _ios,
              'iPhone destination (optional)',
              Icons.phone_iphone_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              _desktop,
              'Desktop destination (optional)',
              Icons.desktop_windows_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              _fallback,
              'Fallback destination (optional)',
              Icons.alt_route_rounded,
              keyboardType: TextInputType.url,
            ),
            _field(
              _maximumScans,
              'Maximum scans (optional)',
              Icons.speed_rounded,
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (value) => setState(() => _active = value),
              title: const Text('Active'),
              subtitle: const Text('Pause to stop redirects without deleting the QR.'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final maximum = int.tryParse(_maximumScans.text.trim());
                Navigator.pop(
                  context,
                  DynamicQrLink(
                    code: widget.existing?.code ?? '',
                    title: _title.text,
                    destination: _destination.text,
                    androidDestination: _android.text,
                    iosDestination: _ios.text,
                    desktopDestination: _desktop.text,
                    fallbackDestination: _fallback.text,
                    active: _active,
                    maximumScans: maximum,
                    scanCount: widget.existing?.scanCount ?? 0,
                    expiresAt: widget.existing?.expiresAt,
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save dynamic QR'),
            ),
          ],
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.alt_route_rounded, size: 78),
              const SizedBox(height: 16),
              Text(
                'Create your first editable QR destination',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'The printed QR keeps the same qrajn.online link while you update its destination.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
