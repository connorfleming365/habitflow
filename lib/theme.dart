import 'package:flutter/material.dart';

const kPrimary  = Color(0xFF7C6AF7);
const kSuccess  = Color(0xFF4CAF82);
const kWarning  = Color(0xFFF59E0B);

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F2FF),
    cardColor: Colors.white,
    fontFamily: 'Roboto',
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFEDE9FF),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F2FF),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF12101F),
    cardColor: const Color(0xFF1E1B35),
    fontFamily: 'Roboto',
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF1E1B35),
      indicatorColor: Color(0xFF2D2650),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF12101F),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFFF0EEFF),
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
  );
}

// ── Utility ──────────────────────────────────────────────
Color hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).cardColor,
  borderRadius: BorderRadius.circular(18),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.07),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ],
);
