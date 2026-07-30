import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_models.dart';

class PaymentApp {
  const PaymentApp(this.id, this.label, this.packageName);
  final String id;
  final String label;
  final String packageName;
}

class ActionService {
  const ActionService._();
  static const _channel = MethodChannel('private_safe_qr/platform');

  static const knownPaymentApps = [
    PaymentApp('generic', 'Choose any UPI app', ''),
    PaymentApp('phonepe', 'PhonePe', 'com.phonepe.app'),
    PaymentApp('gpay', 'Google Pay', 'com.google.android.apps.nbu.paisa.user'),
    PaymentApp('paytm', 'Paytm', 'net.one97.paytm'),
    PaymentApp('bhim', 'BHIM', 'in.org.npci.upiapp'),
    PaymentApp('amazon', 'Amazon Pay', 'com.amazon.mShop.android.shopping'),
  ];

  static Future<List<PaymentApp>> availablePaymentApps() async {
    try {
      final installed = await _channel.invokeListMethod<Map<Object?, Object?>>('installedUpiApps');
      if (installed == null || installed.isEmpty) return knownPaymentApps;
      final knownByPackage = {
        for (final app in knownPaymentApps.where((item) => item.packageName.isNotEmpty)) app.packageName: app,
      };
      final dynamicApps = installed
          .map((item) {
            final packageName = '${item['package'] ?? ''}';
            return knownByPackage[packageName] ??
                PaymentApp(
                  packageName,
                  '${item['label'] ?? item['package'] ?? 'UPI app'}',
                  packageName,
                );
          })
          .where((item) => item.packageName.isNotEmpty)
          .toList();
      return [knownPaymentApps.first, ...dynamicApps];
    } catch (_) {
      return knownPaymentApps;
    }
  }

  static Future<bool> open(ScanPayload payload, {String? paymentPackage}) async {
    final value = payload.actionUri;
    if (value == null) return false;

    if (payload.type == ScanContentType.upi) {
      try {
        final opened = await _channel.invokeMethod<bool>('openUpi', {
              'uri': value,
              'package': paymentPackage ?? '',
            }) ??
            false;
        if (opened || paymentPackage == null || paymentPackage.isEmpty) return opened;
        return await _channel.invokeMethod<bool>('openUpi', {'uri': value, 'package': ''}) ?? false;
      } catch (_) {
        return false;
      }
    }

    if (payload.type == ScanContentType.appLink) {
      try {
        return await _channel.invokeMethod<bool>('openExternalUri', {'uri': value}) ?? false;
      } catch (_) {
        return false;
      }
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> copy(String value) => Clipboard.setData(ClipboardData(text: value));

  static Future<void> share(String value) async {
    await SharePlus.instance.share(ShareParams(text: value));
  }
}
