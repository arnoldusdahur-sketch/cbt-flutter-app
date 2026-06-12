import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAccentColor = 'accent_color';

  final SharedPreferences _prefs;

  ThemeService(this._prefs);

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode) ?? 'system';
    switch (value) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_keyThemeMode, value);
  }

  Color getAccentColor() {
    final colorValue = _prefs.getInt(_keyAccentColor);
    if (colorValue == null) return const Color(0xFF02AB6C); // Default: brand green
    return Color(colorValue);
  }

  Future<void> saveAccentColor(Color color) async {
    await _prefs.setInt(_keyAccentColor, color.value);
  }
}
