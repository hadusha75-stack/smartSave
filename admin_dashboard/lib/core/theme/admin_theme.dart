import 'package:flutter/material.dart';

/// Admin dashboard theme — Material 3, deep blue seed.
class AdminTheme {
  AdminTheme._();

  static const Color seedColor = Color(0xFF1A237E); // deep blue

  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
        seedColor: seedColor, brightness: Brightness.light);
    return _build(cs);
  }

  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
        seedColor: seedColor, brightness: Brightness.dark);
    return _build(cs);
  }

  static ThemeData _build(ColorScheme cs) => ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
}
