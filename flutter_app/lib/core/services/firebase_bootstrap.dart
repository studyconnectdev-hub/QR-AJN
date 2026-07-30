import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class FirebaseBootstrap {
  static bool available = false;
  static bool analyticsEnabled = false;
  static bool notificationsEnabled = false;
  static String status = 'Offline-only mode';

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      available = true;
      status = 'Firebase connected';
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _activateAppCheck();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      await _remoteConfig();
      await _restoreExistingNotificationPermission();
    } catch (error) {
      available = false;
      status = 'Offline-only mode: Firebase is not configured';
      debugPrint('Firebase optional initialization skipped: $error');
    }
  }

  static bool flag(String key, {required bool fallback}) {
    if (!available) return fallback;
    try {
      return FirebaseRemoteConfig.instance.getBool(key);
    } catch (_) {
      return fallback;
    }
  }

  static String text(String key, {String fallback = ''}) {
    if (!available) return fallback;
    try {
      final value = FirebaseRemoteConfig.instance.getString(key);
      return value.isEmpty ? fallback : value;
    } catch (_) {
      return fallback;
    }
  }

  static Future<bool> enableAnalyticsForSession() async {
    if (!available) return false;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      analyticsEnabled = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enableNotifications() async {
    if (!available) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        await FirebaseMessaging.instance.subscribeToTopic('security_updates');
        notificationsEnabled = true;
      }
      return granted;
    } catch (error) {
      debugPrint('FCM permission/subscription failed: $error');
      return false;
    }
  }

  static Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
    } catch (error) {
      debugPrint('App Check activation deferred: $error');
    }
  }

  static Future<void> _remoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 8),
      minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 6),
    ));
    await remoteConfig.setDefaults(const {
      'safescan_enabled': true,
      'community_reporting_enabled': true,
      'ads_enabled': true,
      'maintenance_message': '',
      'minimum_supported_version': '4.0.0',
      'blaze_api_base_url': '',
      'threat_rules_json': '',
      'trusted_domains_json': '',
      'public_domain': 'https://qrajn.online',
      'premium_monthly_id': 'qrajn_pro_monthly',
      'premium_yearly_id': 'qrajn_pro_yearly',
      'business_monthly_id': 'qrajn_business_monthly',
    });
    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {}
  }

  static Future<void> _restoreExistingNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        await FirebaseMessaging.instance.subscribeToTopic('security_updates');
        notificationsEnabled = true;
      }
    } catch (_) {}
  }
}
