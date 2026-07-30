import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF2563EB);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF8B5CF6),
      tertiary: const Color(0xFF14B8A6),
      surface: const Color(0xFFFBFDFF),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6FAFF),
      appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 0,
        color: Colors.white.withValues(alpha: .92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .92),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      primary: const Color(0xFF60A5FA),
      secondary: const Color(0xFFC4B5FD),
      tertiary: const Color(0xFF5EEAD4),
      surface: const Color(0xFF0B1325),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF07111F),
      appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 0,
        color: const Color(0xFF101B30).withValues(alpha: .94),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF101B30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF24324C))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF24324C))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
    );
  }
}
