import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);
  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('te'), Locale('hi')];
  static const delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) => Localizations.of<AppStrings>(context, AppStrings)!;

  static const _values = <String, Map<String, String>>{
    'en': {'scan': 'Scan', 'create': 'Create', 'tools': 'Safety', 'privacy': 'Privacy', 'gallery': 'Gallery', 'flash': 'Flash'},
    'te': {'scan': 'స్కాన్', 'create': 'సృష్టించు', 'tools': 'భద్రత', 'privacy': 'గోప్యత', 'gallery': 'గ్యాలరీ', 'flash': 'ఫ్లాష్'},
    'hi': {'scan': 'स्कैन', 'create': 'बनाएं', 'tools': 'सुरक्षा', 'privacy': 'गोपनीयता', 'gallery': 'गैलरी', 'flash': 'फ्लैश'},
  };

  String _get(String key) => (_values[locale.languageCode] ?? _values['en']!)[key] ?? _values['en']![key]!;
  String get scan => _get('scan');
  String get create => _get('create');
  String get tools => _get('tools');
  String get privacy => _get('privacy');
  String get gallery => _get('gallery');
  String get flash => _get('flash');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any((item) => item.languageCode == locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
