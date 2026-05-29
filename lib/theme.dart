import 'package:flutter/material.dart';

// ── Ocean colour palette ──────────────────────────────────
const kDeepOcean    = Color(0xFF062233); // darkest navy — scaffold bg
const kMidnightTide = Color(0xFF0A3D5C); // card surfaces
const kOceanBlue    = Color(0xFF0E6FA6); // interactive elements
const kReefBlue     = Color(0xFF1A9FD9); // highlights / progress
const kSeaFoam      = Color(0xFF5DD4F8); // light accent text
const kMist         = Color(0xFFEAF6FC); // lightest tint

// Semantic accents
const kSuccess  = Color(0xFF26C6A0); // seafoam green — completed
const kWarning  = Color(0xFFFFB830); // sand — streak
const kDanger   = Color(0xFFFF7B5C); // coral — missed / delete

// Backwards-compat alias used in older screens
const kPrimary = kReefBlue;

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:          kReefBlue,
        onPrimary:        Colors.white,
        secondary:        kSeaFoam,
        onSecondary:      kDeepOcean,
        surface:          isDark ? kMidnightTide : kMist,
        onSurface:        isDark ? Colors.white   : kDeepOcean,
        error:            kDanger,
        onError:          Colors.white,
        // M3 extras
        primaryContainer: kOceanBlue,
        onPrimaryContainer: Colors.white,
        surfaceContainerHighest: isDark ? const Color(0xFF083348) : const Color(0xFFD0EAF5),
      ),
      scaffoldBackgroundColor: isDark ? kDeepOcean : const Color(0xFF083A55),
      cardColor:               isDark ? kMidnightTide : const Color(0xFF0A3D5C),
      fontFamily: 'Roboto',
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  isDark ? kMidnightTide : const Color(0xFF083348),
        indicatorColor:   kOceanBlue.withOpacity(0.35),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSeaFoam),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: kSeaFoam.withOpacity(0.7)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:       isDark ? kDeepOcean : const Color(0xFF062233),
        elevation:             0,
        scrolledUnderElevation: 0,
        iconTheme:             const IconThemeData(color: kSeaFoam),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      dividerColor: kOceanBlue.withOpacity(0.3),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? kReefBlue : kMidnightTide),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kMidnightTide,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(color: kSeaFoam, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: kMidnightTide,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kSeaFoam),
      ),
    );
  }
}

// ── Utility helpers ───────────────────────────────────────
Color hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
  color: kMidnightTide,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: kOceanBlue.withOpacity(0.35), width: 0.5),
);

BoxDecoration surfaceDecoration() => BoxDecoration(
  color: const Color(0xFF083348),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: kOceanBlue.withOpacity(0.25), width: 0.5),
);
