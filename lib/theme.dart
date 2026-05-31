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
  /// Dark navy ocean theme (default)
  static ThemeData get deepOcean => _buildDark();

  /// Light sky-blue "Sea Mist" theme
  static ThemeData get seaMist => _buildSeaMist();

  // Aliases so any remaining references compile
  static ThemeData get light => _buildSeaMist();
  static ThemeData get dark  => _buildDark();

  static ThemeData _buildDark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary:    kReefBlue,
      onPrimary:  Colors.white,
      secondary:  kSeaFoam,
      onSecondary: kDeepOcean,
      surface:    kMidnightTide,
      onSurface:  Colors.white,
      error:      kDanger,
      onError:    Colors.white,
      primaryContainer: kOceanBlue,
      onPrimaryContainer: Colors.white,
      surfaceContainerHighest: Color(0xFF083348),
    ),
    scaffoldBackgroundColor: kDeepOcean,
    cardColor: kMidnightTide,
    fontFamily: 'Roboto',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kMidnightTide,
      indicatorColor:  kOceanBlue.withOpacity(0.35),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSeaFoam),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: kSeaFoam.withOpacity(0.7)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kDeepOcean,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: kSeaFoam),
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 22,
        fontWeight: FontWeight.w800, letterSpacing: -0.5,
      ),
    ),
    dividerColor: Color(0x4D0E6FA6),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? kReefBlue : kMidnightTide),
    ),
    dialogTheme: DialogTheme(
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

  static ThemeData _buildSeaMist() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary:    kReefBlue,
      onPrimary:  Colors.white,
      secondary:  kOceanBlue,
      onSecondary: Colors.white,
      surface:    Colors.white,
      onSurface:  kDeepOcean,
      error:      kDanger,
      onError:    Colors.white,
      primaryContainer: kReefBlue.withOpacity(0.12),
      onPrimaryContainer: kDeepOcean,
      surfaceContainerHighest: const Color(0xFFD0E8F5),
    ),
    scaffoldBackgroundColor: const Color(0xFFEAF5FB),
    cardColor: Colors.white,
    fontFamily: 'Roboto',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kReefBlue.withOpacity(0.15),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kOceanBlue),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: kOceanBlue.withOpacity(0.8)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kReefBlue,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 22,
        fontWeight: FontWeight.w800, letterSpacing: -0.5,
      ),
    ),
    dividerColor: Color(0x330E6FA6),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? kReefBlue : const Color(0xFFCCE4F0)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(color: kDeepOcean, fontSize: 18, fontWeight: FontWeight.w700),
      contentTextStyle: const TextStyle(color: kMidnightTide, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kMidnightTide,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kOceanBlue),
    ),
  );
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
