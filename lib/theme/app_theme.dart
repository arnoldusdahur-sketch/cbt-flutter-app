import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color brandGreen = Color(0xFF02AB6C);
  static const Color brandGreenDark = Color(0xFF02945D);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Preset accent colors to choose from
  static const List<Map<String, dynamic>> accentPresets = [
    {'name': 'Hijau OTWASN', 'color': Color(0xFF02AB6C)},
    {'name': 'Biru Samudra', 'color': Color(0xFF0EA5E9)},
    {'name': 'Ungu Elegan', 'color': Color(0xFF8B5CF6)},
    {'name': 'Oranye Energi', 'color': Color(0xFFF97316)},
    {'name': 'Merah Berani', 'color': Color(0xFFEF4444)},
    {'name': 'Pink Modern', 'color': Color(0xFFEC4899)},
    {'name': 'Kuning Emas', 'color': Color(0xFFEAB308)},
    {'name': 'Teal Sejuk', 'color': Color(0xFF14B8A6)},
  ];

  static ThemeData lightTheme(Color accentColor) {
    final colorScheme = ColorScheme.light(
      primary: accentColor,
      secondary: accentColor.withOpacity(0.7),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: slate800,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: slate50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: slate800,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Colors.black12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? accentColor : Colors.grey[400]),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? accentColor.withOpacity(0.3) : Colors.grey[200]),
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    final colorScheme = ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor.withOpacity(0.7),
      surface: slate800,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: slate900,
      appBarTheme: AppBarTheme(
        backgroundColor: slate800,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: const CardThemeData(
        color: slate800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Colors.white12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? accentColor : Colors.grey[600]),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? accentColor.withOpacity(0.3) : Colors.grey[800]),
      ),
    );
  }
}
