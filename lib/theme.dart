import 'package:flutter/material.dart';

// ── Semantic accents (theme-independent) ─────────────────
const kSuccess = Color(0xFF26C6A0); // green — completed
const kWarning = Color(0xFFFFB830); // amber — streak
const kDanger  = Color(0xFFFF7B5C); // red-orange — missed / delete

// ── Wave painter colours (always ocean-blue visuals) ──────
const kWaveDeep  = Color(0xFF0E6FA6);
const kWaveMid   = Color(0xFF1A9FD9);
const kWaveLight = Color(0xFF5DD4F8);

// ── Coral Tide palette ────────────────────────────────────
const kCoralPrimary = Color(0xFFFF6B6B); // coral/salmon — accents, fills, borders (not text)
const kCoralNavy    = Color(0xFF1E3A5F); // deep navy — text
const kCoralMid     = Color(0xFF35618A); // darkened navy-blue — subtext, legible on white
const kCoralBg      = Color(0xFFFFF8F5); // warm off-white
const kCoralCard    = Color(0xFFFFFFFF); // white card
const kCoralSurface = Color(0xFFFFE4D9); // warm peach surface
const kCoralDivider = Color(0xFFFFD6CC); // light coral divider

// Legible variants of the shared semantic accents, for use as TEXT on
// Coral Tide's white/off-white backgrounds — kWarning/kDanger/kCoralPrimary
// were tuned for the dark Deep Abyss background and are too washed out to
// read comfortably as body text on white.
const kCoralWarningText = Color(0xFFAD6B00); // deep amber
const kCoralDangerText  = Color(0xFFC23B32); // deep red
const kCoralPrimaryText = Color(0xFFD9483E); // deep coral, for button labels

/// Picks the Coral Tide-legible variant of [warning color] when the active
/// theme is light, otherwise the standard (already-legible-on-dark) colour.
Color warningTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light ? kCoralWarningText : kWarning;

Color dangerTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light ? kCoralDangerText : kDanger;

// ── Deep Abyss palette ────────────────────────────────────
const kAbyssBg      = Color(0xFF1A1025); // darkest purple-black
const kAbyssCard    = Color(0xFF251535); // card surface
const kAbyssSurface = Color(0xFF3D2A5A); // lighter surface
const kAbyssCyan    = Color(0xFF26D0CE); // primary cyan/aquamarine
const kAbyssViolet  = Color(0xFFC4B5FD); // secondary violet
const kAbyssText    = Color(0xFFF0E6FF); // primary text (lavender-white)
const kAbyssMuted   = Color(0xFFB8A9D9); // secondary text
const kAbyssDivider = Color(0x553D2A5A); // subtle divider

// Backwards-compat alias — screens should prefer Theme.of(context).colorScheme.primary
const kPrimary = kCoralPrimary;

// ── Splash screen legacy colours (splash_screen.dart only) ──
// Retained so the video splash doesn't need changes per user request.
const kDeepOcean    = Color(0xFF062233);
const kMidnightTide = Color(0xFF0A3D5C);
const kOceanBlue    = Color(0xFF0E6FA6);
const kReefBlue     = Color(0xFF1A9FD9);
const kSeaFoam      = Color(0xFF5DD4F8);
const kMist         = Color(0xFFEAF6FC);

class AppTheme {
  static ThemeData get coralTide => _buildCoralTide();
  static ThemeData get deepAbyss => _buildDeepAbyss();

  // Aliases so any remaining old references compile
  static ThemeData get light => _buildCoralTide();
  static ThemeData get dark  => _buildDeepAbyss();

  static ThemeData _buildCoralTide() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary:             kCoralPrimary,
      onPrimary:           Colors.white,
      secondary:           kCoralMid,
      onSecondary:         Colors.white,
      surface:             kCoralCard,
      onSurface:           kCoralNavy,
      error:               kDanger,
      onError:             Colors.white,
      primaryContainer:    Color(0xFFFFE4E4),
      onPrimaryContainer:  kCoralNavy,
      surfaceContainerHighest: kCoralSurface,
    ),
    scaffoldBackgroundColor: kCoralBg,
    cardColor: kCoralCard,
    fontFamily: 'Outfit',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCoralCard,
      indicatorColor: kCoralPrimary.withOpacity(0.15),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: kCoralNavy),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: kCoralNavy.withOpacity(0.65)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCoralNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit', color: Colors.white, fontSize: 22,
        fontWeight: FontWeight.w800, letterSpacing: -0.5,
      ),
    ),
    dividerColor: kCoralDivider,
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? kCoralPrimary : kCoralDivider),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: kCoralCard,
      titleTextStyle: const TextStyle(
          fontFamily: 'Outfit', color: kCoralNavy, fontSize: 18, fontWeight: FontWeight.w700),
      contentTextStyle: const TextStyle(fontFamily: 'Outfit', color: kCoralMid, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kCoralNavy,
      contentTextStyle: TextStyle(fontFamily: 'Outfit', color: Colors.white),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kCoralPrimaryText),
    ),
  );

  static ThemeData _buildDeepAbyss() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary:             kAbyssCyan,
      onPrimary:           kAbyssBg,
      secondary:           kAbyssViolet,
      onSecondary:         kAbyssBg,
      surface:             kAbyssCard,
      onSurface:           kAbyssText,
      error:               kDanger,
      onError:             Colors.white,
      primaryContainer:    kAbyssSurface,
      onPrimaryContainer:  kAbyssText,
      surfaceContainerHighest: kAbyssSurface,
    ),
    scaffoldBackgroundColor: kAbyssBg,
    cardColor: kAbyssCard,
    fontFamily: 'Outfit',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kAbyssCard,
      indicatorColor: kAbyssCyan.withOpacity(0.25),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: kAbyssViolet),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: kAbyssViolet.withOpacity(0.8)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kAbyssBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: kAbyssCyan),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit', color: kAbyssText, fontSize: 22,
        fontWeight: FontWeight.w800, letterSpacing: -0.5,
      ),
    ),
    dividerColor: kAbyssDivider,
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? kAbyssCyan : kAbyssSurface),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: kAbyssCard,
      titleTextStyle: const TextStyle(
          fontFamily: 'Outfit', color: kAbyssText, fontSize: 18, fontWeight: FontWeight.w700),
      contentTextStyle: const TextStyle(fontFamily: 'Outfit', color: kAbyssViolet, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kAbyssCard,
      contentTextStyle: TextStyle(fontFamily: 'Outfit', color: kAbyssText),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kAbyssCyan),
    ),
  );
}

// ── Utility helpers ───────────────────────────────────────
Color hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).cardColor,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
);

BoxDecoration surfaceDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
);
