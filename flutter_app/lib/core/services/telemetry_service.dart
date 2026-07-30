import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_bootstrap.dart';

class TelemetryService {
  const TelemetryService._();
  static Future<void> event(String name, {Map<String, Object>? parameters}) async {
    if (!FirebaseBootstrap.available || !FirebaseBootstrap.analyticsEnabled) return;
    try { await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters); } catch (_) {}
  }
}
