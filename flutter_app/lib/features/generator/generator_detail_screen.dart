import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart' as qr;
import 'package:share_plus/share_plus.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/platform_bridge.dart';
import '../../core/services/premium_service.dart';
import '../../core/widgets/gradient_qr_view.dart';
import '../premium/premium_screen.dart';
import 'generator_models.dart';

class GeneratorDetailScreen extends StatefulWidget {
  const GeneratorDetailScreen({super.key, required this.category});
  final GeneratorCategory category;

  @override
  State<GeneratorDetailScreen> createState() => _GeneratorDetailScreenState();
}

class _GeneratorDetailScreenState extends State<GeneratorDetailScreen> {
  late final List<TextEditingController> _controllers;
  final _caption = TextEditingController(text: 'SCAN WITH QR AJN');
  final _boundary = GlobalKey();
  QrPalette _palette = QrPalette.ocean;
  QrModuleShape _moduleShape = QrModuleShape.rounded;
  int _errorCorrection = qr.QrErrorCorrectLevel.H;
  bool _centerLogo = true;
  bool _transparent = false;
  double _margin = 14;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.category.fields.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _caption.dispose();
    super.dispose();
  }

  String get _payload => buildGeneratorPayload(widget.category.type, _controllers.map((item) => item.text).toList());

  List<Color> get _colors => switch (_palette) {
        QrPalette.ocean => const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        QrPalette.violet => const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        QrPalette.mint => const [Color(0xFF34D399), Color(0xFF0D9488)],
        QrPalette.sunset => const [Color(0xFFF59E0B), Color(0xFFF43F5E)],
        QrPalette.rose => const [Color(0xFFF472B6), Color(0xFFE11D48)],
        QrPalette.gold => const [Color(0xFFFACC15), Color(0xFFD97706)],
        QrPalette.midnight => const [Color(0xFF1E3A8A), Color(0xFF312E81)],
        QrPalette.mono => const [Color(0xFF111827), Color(0xFF475569)],
        QrPalette.aqua => const [Color(0xFF06B6D4), Color(0xFF22D3EE), Color(0xFF2563EB)],
        QrPalette.berry => const [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFFB7185)],
        QrPalette.forest => const [Color(0xFF14532D), Color(0xFF16A34A), Color(0xFF84CC16)],
        QrPalette.royal => const [Color(0xFF1D4ED8), Color(0xFF7C3AED), Color(0xFFF59E0B)],
      };

  int get _quality {
    final payload = _payload;
    if (payload.isEmpty) return 0;
    final bytes = utf8.encode(payload).length;
    var score = 100;
    if (bytes > 1800) {
      score -= 60;
    } else if (bytes > 1000) {
      score -= 38;
    } else if (bytes > 500) {
      score -= 20;
    } else if (bytes > 250) {
      score -= 8;
    }
    if (payload.startsWith('http://')) score -= 18;
    if (_centerLogo && _errorCorrection != qr.QrErrorCorrectLevel.H) score -= 16;
    if (_margin < 8) score -= 18;
    if (_transparent) score -= 4;
    if (widget.category.type == GeneratorType.upi && !RegExp(r'^[A-Za-z0-9._-]{2,}@[A-Za-z0-9.-]{2,}$').hasMatch(_controllers.first.text.trim())) score -= 45;
    return score.clamp(0, 100).toInt();
  }

  Future<Uint8List?> _pngBytes() async {
    final render = _boundary.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary) return null;
    final image = await render.toImage(pixelRatio: 4);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _savePng() async {
    await _runExport(() async {
      final bytes = await _pngBytes();
      if (bytes == null) throw StateError('QR preview is not ready.');
      final name = 'QR_AJN_${widget.category.type.name}_${DateTime.now().millisecondsSinceEpoch}.png';
      final saved = await PlatformBridge.saveBytesToDownloads(bytes: bytes, fileName: name, mimeType: 'image/png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved == null ? 'Could not save the PNG. Use Share instead.' : 'Saved to Downloads: $name')));
    });
  }

  Future<void> _sharePng() async {
    await _runExport(() async {
      final bytes = await _pngBytes();
      if (bytes == null) throw StateError('QR preview is not ready.');
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'QR_AJN_${widget.category.type.name}.png')],
        text: 'Created with QR AJN',
      ));
    });
  }

  Future<void> _savePdf() async {
    if (!await _requirePremium('PDF export')) return;
    await _runExport(() async {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: _payload, width: 320, height: 320),
              pw.SizedBox(height: 16),
              pw.Text(_caption.text.trim().isEmpty ? widget.category.title : _caption.text.trim()),
            ]),
          ),
        ),
      );
      final bytes = await document.save();
      final name = 'QR_AJN_${widget.category.type.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final saved = await PlatformBridge.saveBytesToDownloads(bytes: bytes, fileName: name, mimeType: 'application/pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved == null ? 'Could not save the PDF.' : 'Saved to Downloads: $name')));
    });
  }

  Future<void> _saveSvg() async {
    if (!await _requirePremium('SVG export')) return;
    await _runExport(() async {
      final code = qr.QrCode.fromData(data: _payload, errorCorrectLevel: _errorCorrection);
      final image = qr.QrImage(code);
      final count = image.moduleCount;
      final buffer = StringBuffer()
        ..writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $count $count" shape-rendering="crispEdges">')
        ..writeln('<rect width="100%" height="100%" fill="${_transparent ? 'none' : '#FFFFFF'}"/>')
        ..writeln('<g fill="${_hex(_colors.first)}">');
      for (var row = 0; row < count; row++) {
        for (var col = 0; col < count; col++) {
          if (image.isDark(row, col)) buffer.writeln('<rect x="$col" y="$row" width="1" height="1"/>');
        }
      }
      buffer.writeln('</g></svg>');
      final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
      final name = 'QR_AJN_${widget.category.type.name}_${DateTime.now().millisecondsSinceEpoch}.svg';
      final saved = await PlatformBridge.saveBytesToDownloads(bytes: bytes, fileName: name, mimeType: 'image/svg+xml');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved == null ? 'Could not save the SVG.' : 'Saved to Downloads: $name')));
    });
  }

  Future<void> _runExport(Future<void> Function() action) async {
    if (_payload.isEmpty || _quality < 25 || _busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await AdService.instance.showInterstitialAfterEligibleAction();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _requirePremium(String feature) async {
    if (PremiumService.instance.isPremium) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature is a Pro feature'),
        content: const Text('Upgrade to QR AJN Pro to remove ads and unlock professional export and design tools.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('View Premium')),
        ],
      ),
    );
    if (result == true && mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
    return PremiumService.instance.isPremium;
  }

  Future<void> _selectPalette(QrPalette palette) async {
    if (palette.index >= QrPalette.aqua.index && !PremiumService.instance.isPremium) {
      if (!await _requirePremium('Premium gradients')) return;
    }
    if (mounted) setState(() => _palette = palette);
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.category.colors.first.withValues(alpha: .10), Theme.of(context).colorScheme.surface, widget.category.colors.last.withValues(alpha: .10)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            _Header(category: widget.category),
            const SizedBox(height: 16),
            _Panel(
              title: 'Enter details',
              child: Column(
                children: [
                  for (var index = 0; index < widget.category.fields.length; index++) ...[
                    TextField(
                      controller: _controllers[index],
                      onChanged: (_) => setState(() {}),
                      maxLines: widget.category.type == GeneratorType.text || index == widget.category.fields.length - 1 && widget.category.fields[index].toLowerCase().contains('details') ? 4 : 1,
                      obscureText: widget.category.type == GeneratorType.wifi && index == 1,
                      keyboardType: _keyboard(index),
                      decoration: InputDecoration(labelText: widget.category.fields[index], prefixIcon: Icon(index == 0 ? widget.category.icon : Icons.edit_rounded)),
                    ),
                    if (index != widget.category.fields.length - 1) const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Customize QR',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Colour theme', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: QrPalette.values.map((palette) => _PaletteChip(
                      colors: _palettePreview(palette),
                      selected: _palette == palette,
                      locked: palette.index >= QrPalette.aqua.index && !PremiumService.instance.isPremium,
                      onTap: () => _selectPalette(palette),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<QrModuleShape>(
                    key: ValueKey(_moduleShape),
                    initialValue: _moduleShape,
                    decoration: const InputDecoration(labelText: 'Pattern shape', prefixIcon: Icon(Icons.grid_view_rounded)),
                    items: QrModuleShape.values.map((shape) => DropdownMenuItem(value: shape, child: Text(shape.name.toUpperCase()))).toList(),
                    onChanged: (value) => setState(() => _moduleShape = value ?? QrModuleShape.rounded),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_errorCorrection),
                    initialValue: _errorCorrection,
                    decoration: const InputDecoration(labelText: 'Error correction', prefixIcon: Icon(Icons.health_and_safety_outlined)),
                    items: const [
                      DropdownMenuItem(value: qr.QrErrorCorrectLevel.L, child: Text('Low')),
                      DropdownMenuItem(value: qr.QrErrorCorrectLevel.M, child: Text('Medium')),
                      DropdownMenuItem(value: qr.QrErrorCorrectLevel.Q, child: Text('Quartile')),
                      DropdownMenuItem(value: qr.QrErrorCorrectLevel.H, child: Text('High • recommended with logo')),
                    ],
                    onChanged: (value) => setState(() => _errorCorrection = value ?? qr.QrErrorCorrectLevel.H),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _caption, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Frame caption', prefixIcon: Icon(Icons.title_rounded))),
                  SwitchListTile(contentPadding: EdgeInsets.zero, value: _centerLogo, onChanged: (value) => setState(() => _centerLogo = value), title: const Text('QR AJN centre logo')),
                  SwitchListTile(contentPadding: EdgeInsets.zero, value: _transparent, onChanged: (value) async {
                    if (value && !await _requirePremium('Transparent background')) return;
                    if (mounted) setState(() => _transparent = value);
                  }, title: const Text('Transparent background')),
                  Text('Quiet-zone margin: ${_margin.round()} px', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(value: _margin, min: 4, max: 28, divisions: 12, onChanged: (value) => setState(() => _margin = value)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Preview & quality',
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _boundary,
                    child: Container(
                      color: _transparent ? Colors.transparent : Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (payload.isEmpty)
                            SizedBox(height: 280, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(widget.category.icon, size: 58, color: widget.category.colors.first), const SizedBox(height: 12), const Text('Enter valid details to preview')])) )
                          else
                            GradientQrView(
                              data: payload,
                              size: 280,
                              colors: _colors,
                              errorCorrectionLevel: _errorCorrection,
                              moduleShape: _moduleShape,
                              margin: _margin,
                              backgroundColor: _transparent ? Colors.transparent : Colors.white,
                              logo: _centerLogo ? const AssetImage('assets/images/app_logo.png') : null,
                            ),
                          if (_caption.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(_caption.text.trim(), style: TextStyle(color: _colors.first, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [Expanded(child: LinearProgressIndicator(value: _quality / 100, minHeight: 9, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 12), Text('$_quality/100', style: const TextStyle(fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 7),
                  Text(_quality >= 80 ? 'Excellent scan quality' : _quality >= 55 ? 'Good • test before printing' : 'Improve the content, contrast or error correction', textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: payload.isEmpty || _busy ? null : _savePng, icon: const Icon(Icons.download_rounded), label: const Text('Download PNG')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: payload.isEmpty || _busy ? null : _sharePng, icon: const Icon(Icons.share_rounded), label: const Text('Share'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: payload.isEmpty ? null : () => Clipboard.setData(ClipboardData(text: payload)).then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR content copied.')))), icon: const Icon(Icons.copy_rounded), label: const Text('Copy'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: payload.isEmpty || _busy ? null : _saveSvg, icon: const Icon(Icons.code_rounded), label: const Text('SVG Pro'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: payload.isEmpty || _busy ? null : _savePdf, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('PDF Pro'))),
            ]),
          ],
        ),
      ),
    );
  }

  TextInputType _keyboard(int index) {
    if (widget.category.type == GeneratorType.email && index == 0) return TextInputType.emailAddress;
    if ([GeneratorType.phone, GeneratorType.sms, GeneratorType.whatsapp].contains(widget.category.type) && index == 0) return TextInputType.phone;
    if (widget.category.type == GeneratorType.upi && index == 2) return const TextInputType.numberWithOptions(decimal: true);
    if (widget.category.type == GeneratorType.location && index < 2) return const TextInputType.numberWithOptions(decimal: true, signed: true);
    return TextInputType.url;
  }

  static List<Color> _palettePreview(QrPalette palette) => switch (palette) {
        QrPalette.ocean => const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        QrPalette.violet => const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        QrPalette.mint => const [Color(0xFF34D399), Color(0xFF0D9488)],
        QrPalette.sunset => const [Color(0xFFF59E0B), Color(0xFFF43F5E)],
        QrPalette.rose => const [Color(0xFFF472B6), Color(0xFFE11D48)],
        QrPalette.gold => const [Color(0xFFFACC15), Color(0xFFD97706)],
        QrPalette.midnight => const [Color(0xFF1E3A8A), Color(0xFF312E81)],
        QrPalette.mono => const [Color(0xFF111827), Color(0xFF475569)],
        QrPalette.aqua => const [Color(0xFF06B6D4), Color(0xFF22D3EE), Color(0xFF2563EB)],
        QrPalette.berry => const [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFFB7185)],
        QrPalette.forest => const [Color(0xFF14532D), Color(0xFF16A34A), Color(0xFF84CC16)],
        QrPalette.royal => const [Color(0xFF1D4ED8), Color(0xFF7C3AED), Color(0xFFF59E0B)],
      };

  static String _hex(Color color) => '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

class _Header extends StatelessWidget {
  const _Header({required this.category});
  final GeneratorCategory category;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: LinearGradient(colors: category.colors), borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: category.colors.last.withValues(alpha: .28), blurRadius: 24, offset: const Offset(0, 10))]),
        child: Row(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(18)), child: Icon(category.icon, color: Colors.white, size: 32)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(category.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(category.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .86), height: 1.35))])),
        ]),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: .94), borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), boxShadow: const [BoxShadow(color: Color(0x120F172A), blurRadius: 20, offset: Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 14), child]),
      );
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({required this.colors, required this.selected, required this.locked, required this.onTap});
  final List<Color> colors;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3), boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .25), blurRadius: 10)]),
          child: locked ? const Icon(Icons.lock_rounded, color: Colors.white, size: 18) : selected ? const Icon(Icons.check_rounded, color: Colors.white) : null,
        ),
      );
}
