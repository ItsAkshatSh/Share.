import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'JetBrainsMono';

  /// Small secondary text style kept as an alias for older call sites.
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textSecondary,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get theme => build();

  static ThemeData build() {
    const primary = AppColors.accent;

    //
    // App text styles. Every style pins JetBrains Mono (bundled as a
    // variable-weight asset in pubspec.yaml) — no runtime font fetching.
    // The voice of the design language: monospace, sentence case, airy.
    //
    TextStyle t(
      double size, {
      FontWeight w = FontWeight.w500,
      double? ls,
      double? lh,
      Color? color,
    }) {
      return TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color ?? AppColors.textPrimary,
        letterSpacing: ls ?? 0,
        height: lh,
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.amber,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceRaised,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.dividerStrong,
        error: AppColors.danger,
      ),
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displayLarge: t(40, w: FontWeight.w800, ls: -1.2, lh: 1.15),
        displayMedium: t(30, w: FontWeight.w800, ls: -0.8, lh: 1.2),
        headlineLarge: t(24, w: FontWeight.w700, ls: -0.4, lh: 1.3),
        headlineMedium: t(20, w: FontWeight.w700, ls: -0.2, lh: 1.3),
        headlineSmall: t(17, w: FontWeight.w700, lh: 1.35),
        titleLarge: t(16, w: FontWeight.w700),
        titleMedium: t(14, w: FontWeight.w600),
        titleSmall: t(12.5, w: FontWeight.w600),
        bodyLarge: t(14, w: FontWeight.w500, lh: 1.55),
        bodyMedium:
            t(13, w: FontWeight.w500, lh: 1.55, color: AppColors.textSecondary),
        bodySmall:
            t(11, w: FontWeight.w500, lh: 1.5, color: AppColors.textMuted),
        labelLarge: t(14, w: FontWeight.w600),
        labelMedium:
            t(12, w: FontWeight.w600, color: AppColors.textSecondary),
        labelSmall:
            t(10, w: FontWeight.w600, ls: 0.6, color: AppColors.textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusChip),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(),
        showDragHandle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDeep.withValues(alpha: 0.55),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : AppColors.divider,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        circularTrackColor: AppColors.divider,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size(64, 54),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: fontFamily,
            letterSpacing: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(64, 54),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: fontFamily,
          ),
          side: const BorderSide(color: AppColors.dividerStrong, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Eyebrow label — small indigo caption used over titles.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const Eyebrow(this.text, {super.key, this.color = AppColors.amber});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color,
        height: 1.0,
      ),
    );
  }
}
