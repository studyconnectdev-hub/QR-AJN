import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/l10n/app_strings.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ad_banner_slot.dart';
import 'features/generator/generator_screen.dart';
import 'features/home/home_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/settings/settings_screen.dart';

class PrivateSafeQrApp extends StatelessWidget {
  const PrivateSafeQrApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AppSettings.instance,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'QR AJN',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppSettings.instance.themeMode,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        ),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  void select(int value) => setState(() => index = value);

  Future<bool> exitDialog() async {
    if (index != 0) {
      setState(() => index = 0);
      return false;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shield_outlined),
        title: const Text('Exit QR AJN?'),
        content: const Text('Temporary scan information will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Exit')),
        ],
      ),
    );
    if (result == true) SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => exitDialog(),
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: index,
                  children: [
                    HomeScreen(
                      onScan: () => select(1),
                      onGenerate: () => select(2),
                      onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                    ScannerScreen(active: index == 1),
                    GeneratorScreen(onHome: () => select(0)),
                  ],
                ),
              ),
              if (index != 1) const AdBannerSlot(),
            ],
          ),
          bottomNavigationBar: _GradientBottomNavigation(selectedIndex: index, onSelected: select),
        ),
      );
}

class _GradientBottomNavigation extends StatelessWidget {
  const _GradientBottomNavigation({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.qr_code_scanner_rounded, 'Scanner'),
    (Icons.qr_code_2_rounded, 'Generator'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xF20B1325) : const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: dark ? const Color(0x3348CAE4) : const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x260F172A), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Row(
          children: List.generate(_items.length, (itemIndex) {
            final selected = itemIndex == selectedIndex;
            final item = _items[itemIndex];
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(itemIndex),
                borderRadius: BorderRadius.circular(19),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    gradient: selected ? const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1), Color(0xFFEC4899)]) : null,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(item.$1, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 3),
                    Text(item.$2, style: TextStyle(color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: selected ? FontWeight.w900 : FontWeight.w700, fontSize: 11)),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
