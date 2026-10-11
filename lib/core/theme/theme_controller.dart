import 'package:flutter/material.dart';

/// The current look is fixed: pure-black surfaces with a single orange accent.
///
/// The controller remains because services call `load()`/`cycle()`; it is a
/// stable ChangeNotifier that never reports palette changes.
enum AppThemeId { creme }

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  AppThemeId _themeId = AppThemeId.creme;

  AppThemeId get themeId => _themeId;

  bool get isDark => true;
  Brightness get brightness => Brightness.dark;

  Future<void> load() async {
    try {
      // Nothing to restore — the look shipped with the app.
    } catch (_) {
      // ignore
    }
  }

  Future<void> select(AppThemeId id) async {
    _themeId = id;
  }

  Future<void> cycle() async {
    // No alternate looks in the design language.
  }
}
