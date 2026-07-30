import 'dart:async';
import 'package:flutter/services.dart';

class PlatformBridge {
  const PlatformBridge._();
  static const _channel = MethodChannel('private_safe_qr/platform');
  static final StreamController<String> _sharedImages = StreamController<String>.broadcast();
  static bool _initialized = false;

  static Stream<String> get sharedImages => _sharedImages.stream;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedImageAvailable' && call.arguments is String) {
        final path = (call.arguments as String).trim();
        if (path.isNotEmpty) _sharedImages.add(path);
      }
    });
  }

  static Future<String?> consumeSharedImage() async {
    try {
      return await _channel.invokeMethod<String>('consumeSharedImage');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> saveBytesToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      return await _channel.invokeMethod<String>('saveBytesToDownloads', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
      });
    } catch (_) {
      return null;
    }
  }
}
