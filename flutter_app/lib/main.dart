import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/runtime/app_runtime.dart';
import 'core/settings/app_settings.dart';
import 'core/services/ad_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/platform_bridge.dart';
import 'core/services/premium_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformBridge.initialize();
  await FirebaseBootstrap.initialize();
  await AppRuntime.initialize();
  await AppSettings.instance.load();
  await AuthService.instance.initialize();
  await PremiumService.instance.initialize();
  runApp(const PrivateSafeQrApp());
  unawaited(AdService.instance.initialize());
}
