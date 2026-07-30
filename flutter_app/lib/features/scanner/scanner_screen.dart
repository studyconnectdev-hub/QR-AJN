import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/models/scan_models.dart';
import '../../core/parsing/scan_parser.dart';
import '../../core/runtime/app_runtime.dart';
import '../../core/security/safe_scan_engine.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/platform_bridge.dart';
import '../../core/services/telemetry_service.dart';
import '../../core/settings/app_settings.dart';
import '../result/result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.active});
  final bool active;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _controller;
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  bool _paused = false;
  double _zoom = .12;
  StreamSubscription<String>? _sharedImageSubscription;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 650,
      returnImage: false,
      autoZoom: AppSettings.instance.autoZoom,
    );
    _sharedImageSubscription = PlatformBridge.sharedImages.listen((path) => unawaited(_analyzeImage(path)));
    unawaited(_consumeSharedImage());
  }

  @override
  void didUpdateWidget(covariant ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active && !_paused) unawaited(_controller.start());
    if (!widget.active && oldWidget.active) unawaited(_controller.stop());
  }

  @override
  void dispose() {
    _sharedImageSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _consumeSharedImage() async {
    final path = await PlatformBridge.consumeSharedImage();
    if (path != null) await _analyzeImage(path);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _paused || capture.barcodes.isEmpty) return;
    final valid = capture.barcodes.where((barcode) {
      final raw = barcode.rawValue ?? barcode.displayValue;
      return raw != null && raw.trim().isNotEmpty;
    }).toList();
    if (valid.isEmpty) return;
    final barcode = valid.length == 1 ? valid.first : await _chooseBarcode(valid);
    if (barcode == null) return;
    final raw = barcode.rawValue ?? barcode.displayValue;
    if (raw == null || raw.trim().isEmpty) return;
    await _handleRaw(raw, barcode.format.name);
  }

  Future<Barcode?> _chooseBarcode(List<Barcode> barcodes) async {
    await _controller.stop();
    if (!mounted) return null;
    final selected = await showModalBottomSheet<Barcode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Text('Choose the QR code to open', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Multiple codes are visible. QR AJN will process only the one you select.'),
            const SizedBox(height: 12),
            for (var index = 0; index < barcodes.length; index++)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text((barcodes[index].displayValue ?? barcodes[index].rawValue ?? 'QR code').replaceAll('\n', ' '), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(barcodes[index].format.name),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => Navigator.pop(context, barcodes[index]),
                ),
              ),
          ],
        ),
      ),
    );
    if (mounted && widget.active && !_paused && selected == null) await _controller.start();
    return selected;
  }

  Future<void> _setZoom(double value) async {
    setState(() => _zoom = value);
    try {
      await _controller.setZoomScale(value);
    } catch (_) {}
  }

  Future<void> _handleRaw(String raw, String format) async {
    if (_busy) return;
    _busy = true;
    try {
      final payload = ScanParser.parse(raw, format: format);
      if (AppSettings.instance.vibration) HapticFeedback.mediumImpact();
      if (AppSettings.instance.sound) await SystemSound.play(SystemSoundType.click);
      await TelemetryService.event(
        'scan_completed',
        parameters: {'content_type': payload.type.name, 'source': 'scanner'},
      );
      await _openResult(payload);
    } finally {
      _busy = false;
    }
  }

  Future<void> _openResult(ScanPayload payload) async {
    await _controller.stop();
    final rules = AppRuntime.rules.value;
    final safeScanEnabled = AppSettings.instance.safeScan && FirebaseBootstrap.flag('safescan_enabled', fallback: true);
    final assessment = !safeScanEnabled
        ? const SafetyAssessment(
            score: 75,
            level: RiskLevel.safe,
            reasons: ['SafeScan is disabled in Settings or Remote Config.'],
          )
        : rules == null
            ? const SafetyAssessment(
                score: 75,
                level: RiskLevel.safe,
                reasons: ['Offline safety rules are loading.'],
              )
            : SafeScanEngine(rules).analyze(payload);
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(payload: payload, assessment: assessment),
        ),
      );
    }
    if (mounted && widget.active && !_paused) await _controller.start();
  }

  Future<void> _gallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) await _analyzeImage(image.path);
  }

  Future<void> _analyzeImage(String path) async {
    if (_busy) return;
    try {
      final capture = await _controller.analyzeImage(path);
      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code or barcode was found in this image.')),
          );
        }
        return;
      }
      final barcode = capture.barcodes.first;
      final raw = barcode.rawValue ?? barcode.displayValue;
      if (raw != null && raw.trim().isNotEmpty) await _handleRaw(raw, barcode.format.name);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image scan failed: $error')),
        );
      }
    }
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _controller.start();
    } else {
      await _controller.stop();
    }
    if (mounted) setState(() => _paused = !_paused);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            tapToFocus: true,
            errorBuilder: (context, error) => _CameraError(
              message: error.errorDetails?.message ?? error.errorCode.name,
              onGallery: _gallery,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0xAA07111F), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xCC07111F),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x5567E8F9)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 19),
                      SizedBox(width: 8),
                      Text('SafeScan active • Nothing is saved', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ScannerFrame(reduceMotion: AppSettings.instance.reduceMotion, paused: _paused),
          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: _ScannerControls(
              paused: _paused,
              zoom: _zoom,
              onZoom: _setZoom,
              onFlash: _controller.toggleTorch,
              onGallery: _gallery,
              onSwitch: _controller.switchCamera,
              onPause: _togglePause,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onGallery});
  final String message;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_outlined, size: 68),
                const SizedBox(height: 16),
                Text('Camera unavailable', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: onGallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Scan from Gallery')),
              ],
            ),
          ),
        ),
      );
}

class _ScannerControls extends StatelessWidget {
  const _ScannerControls({
    required this.paused,
    required this.zoom,
    required this.onZoom,
    required this.onFlash,
    required this.onGallery,
    required this.onSwitch,
    required this.onPause,
  });

  final bool paused;
  final double zoom;
  final ValueChanged<double> onZoom;
  final VoidCallback onFlash;
  final VoidCallback onGallery;
  final VoidCallback onSwitch;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xE607111F), Color(0xE6101E3A)]),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x4467E8F9)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              paused ? 'Scanner paused' : 'Align one QR code inside the frame',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 19),
                Expanded(child: Slider(value: zoom, min: 0, max: 1, onChanged: onZoom)),
                const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 19),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ControlButton(icon: Icons.flash_on_rounded, label: 'Flash', colors: const [Color(0xFFF59E0B), Color(0xFFF97316)], onTap: onFlash),
                _ControlButton(icon: Icons.photo_library_rounded, label: 'Gallery', colors: const [Color(0xFF06B6D4), Color(0xFF2563EB)], onTap: onGallery),
                _ControlButton(icon: Icons.cameraswitch_rounded, label: 'Switch', colors: const [Color(0xFF10B981), Color(0xFF14B8A6)], onTap: onSwitch),
                _ControlButton(
                  icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: paused ? 'Resume' : 'Pause',
                  colors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  onTap: onPause,
                ),
              ],
            ),
          ],
        ),
      );
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.colors, required this.onTap});
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .35), blurRadius: 12)],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class _ScannerFrame extends StatefulWidget {
  const _ScannerFrame({required this.reduceMotion, required this.paused});
  final bool reduceMotion;
  final bool paused;

  @override
  State<_ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<_ScannerFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ScannerFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.reduceMotion || widget.paused) {
      _animation.stop();
      _animation.value = .5;
    } else if (!_animation.isAnimating) {
      _animation.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Center(
          child: SizedBox(
            width: 284,
            height: 284,
            child: Stack(
              children: [
                CustomPaint(size: const Size.square(284), painter: _CornerPainter(paused: widget.paused)),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => Positioned(
                    left: 24,
                    right: 24,
                    top: 24 + (_animation.value * 233),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFF38BDF8), Color(0xFFA78BFA), Colors.transparent]),
                        boxShadow: const [BoxShadow(color: Color(0xFF38BDF8), blurRadius: 16)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.paused});
  final bool paused;

  @override
  void paint(Canvas canvas, Size size) {
    final color = paused ? const Color(0xFF94A3B8) : const Color(0xFF67E8F9);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const length = 54.0;
    const inset = 5.0;
    final path = Path()
      ..moveTo(inset, length)
      ..lineTo(inset, inset + 18)
      ..quadraticBezierTo(inset, inset, inset + 18, inset)
      ..lineTo(length, inset)
      ..moveTo(size.width - length, inset)
      ..lineTo(size.width - inset - 18, inset)
      ..quadraticBezierTo(size.width - inset, inset, size.width - inset, inset + 18)
      ..lineTo(size.width - inset, length)
      ..moveTo(inset, size.height - length)
      ..lineTo(inset, size.height - inset - 18)
      ..quadraticBezierTo(inset, size.height - inset, inset + 18, size.height - inset)
      ..lineTo(length, size.height - inset)
      ..moveTo(size.width - length, size.height - inset)
      ..lineTo(size.width - inset - 18, size.height - inset)
      ..quadraticBezierTo(size.width - inset, size.height - inset, size.width - inset, size.height - inset - 18)
      ..lineTo(size.width - inset, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => oldDelegate.paused != paused;
}
