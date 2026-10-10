import 'package:flutter/material.dart';

/// Palette — the "one year" paper-and-ink design language.
///
/// A light, warm-gray paper page; near-black ink for words; a single
/// electric-indigo accent that does all the talking (buttons, highlights,
/// doodles). Inset wells and panels are lavender-tinted greys; cards float
/// as white paper with soft shadows.
///
/// Values are compile-time constants; there is a single look.
class AppColors {
  AppColors._();

  // ---- Surfaces (light, stacked by elevation) ------------------------------
  /// The page. Warm paper grey.
  static const Color background = Color(0xFFDAD8DB);

  /// Cards, sheets, docks — white paper floating on the page.
  static const Color surface = Color(0xFFFDFDFE);

  /// Raised surfaces on top of [surface] (menus, hover blocks).
  static const Color surfaceRaised = Color(0xFFF1F0F3);

  /// The deepest inset wells (lavender inner panels, muted tiles).
  static const Color surfaceDeep = Color(0xFFD9D2EA);

  /// Solid white material.
  static const Color white = Color(0xFFFFFFFF);

  // ---- Text ------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF16141C);
  static const Color textSecondary = Color(0xFF4A4753);
  static const Color textMuted = Color(0xFF9B98A3);
  static const Color textDisabled = Color(0xFFBBB8C1);

  // ---- Hairlines & dividers ------------------------------------------------
  static const Color divider = Color(0xFFC9C7CD);
  static const Color dividerStrong = Color(0xFFA9A6B0);

  // ---- Accents ---------------------------------------------------------------
  /// The primary accent — electric indigo. Actions, highlighted words,
  /// doodle ink, the dot grid.
  static const Color accent = Color(0xFF1C00CB);
  static const Color accentDeep = Color(0xFF1400A8);
  static const Color onAccent = white;

  /// Soft indigo wash for chips, selected segments and glows.
  static const Color accentWash = Color(0xFFD5D0F4);

  /// Legacy "amber" slot — now a lighter indigo for eyebrow labels.
  static const Color amber = Color(0xFF3D2BD8);

  /// Success accents.
  static const Color success = Color(0xFF0E8A5F);

  /// Destructive red.
  static const Color danger = Color(0xFFE5484D);

  // ---- Scrim & overlays ----------------------------------------------------
  static const Color scrim = Color(0xAA000000);
  static const Color scrimDeep = Color(0xE6000000);

  // ---- Legacy aliases kept so older call sites compile ----------------------
  static const Color jetBlack = background;
  static const Color surfaceWhite = surface;
  static const Color surfaceMuted = surfaceRaised;
  static const Color neonLime = accent;
  static const Color softLilac = surfaceDeep;
  static const Color lilacLight = amber;
  static const Color lilacDark = accentDeep;
  static const Color activeGreen = success;
  static const Color alertOrange = amber;
  static const Color onDarkChrome = textSecondary;
  static const Color onAccentDark = onAccent;
  static const Color onCard = textPrimary;

  // ---- Shape tokens ---------------------------------------------------------
  static const double radiusCard = 20;
  static const double radiusPanel = 24;
  static const double radiusPill = 999;
  static const double radiusChip = 12;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 0, 16, 0);

  /// Soft paper shadow tuned for white cards over the warm-grey page.
  static List<BoxShadow> shadow({
    Color? color,
    double blur = 24,
    double y = 10,
    double alpha = 0.16,
  }) {
    return [
      BoxShadow(
        color: (color ?? const Color(0xFF2A2438)).withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }
}
