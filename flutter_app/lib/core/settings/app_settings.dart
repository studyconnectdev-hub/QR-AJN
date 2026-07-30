import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  bool sound = true;
  bool vibration = true;
  bool autoZoom = true;
  bool safeScan = true;
  bool blockDangerous = true;
  bool confirmPayments = true;
  bool confirmExternalLinks = true;
  bool showFullDestination = true;
  bool reduceMotion = false;
  bool analytics = false;
  String preferredPaymentApp = 'generic';
  ThemeMode themeMode = ThemeMode.system;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    sound = preferences.getBool('sound') ?? true;
    vibration = preferences.getBool('vibration') ?? true;
    autoZoom = preferences.getBool('autoZoom') ?? true;
    safeScan = preferences.getBool('safeScan') ?? true;
    blockDangerous = preferences.getBool('blockDangerous') ?? true;
    confirmPayments = preferences.getBool('confirmPayments') ?? true;
    confirmExternalLinks = preferences.getBool('confirmExternalLinks') ?? true;
    showFullDestination = preferences.getBool('showFullDestination') ?? true;
    reduceMotion = preferences.getBool('reduceMotion') ?? false;
    analytics = preferences.getBool('analytics') ?? false;
    preferredPaymentApp = preferences.getString('preferredPaymentApp') ?? 'generic';
    final themeIndex = (preferences.getInt('themeMode') ?? 0).clamp(0, 2).toInt();
    themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setBool(String key, bool value) async {
    switch (key) {
      case 'sound':
        sound = value;
        break;
      case 'vibration':
        vibration = value;
        break;
      case 'autoZoom':
        autoZoom = value;
        break;
      case 'safeScan':
        safeScan = value;
        break;
      case 'blockDangerous':
        blockDangerous = value;
        break;
      case 'confirmPayments':
        confirmPayments = value;
        break;
      case 'confirmExternalLinks':
        confirmExternalLinks = value;
        break;
      case 'showFullDestination':
        showFullDestination = value;
        break;
      case 'reduceMotion':
        reduceMotion = value;
        break;
      case 'analytics':
        analytics = value;
        break;
    }
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  Future<void> setTheme(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('themeMode', value.index);
  }

  Future<void> setPreferredPaymentApp(String value) async {
    preferredPaymentApp = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('preferredPaymentApp', value);
  }

  Future<void> resetPrivacySettings() async {
    safeScan = true;
    blockDangerous = true;
    confirmPayments = true;
    confirmExternalLinks = true;
    showFullDestination = true;
    preferredPaymentApp = 'generic';
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    for (final key in const [
      'safeScan',
      'blockDangerous',
      'confirmPayments',
      'confirmExternalLinks',
      'showFullDestination',
      'preferredPaymentApp',
    ]) {
      await preferences.remove(key);
    }
  }
}
