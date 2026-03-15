import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color accentYellow = Color(0xFFFFD93D);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF4776E6), Color(0xFF8E54E2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientDark = LinearGradient(
    colors: [Color(0xFF3254A3), Color(0xFF6A3FA9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color brandBlue = Color(0xFF4776E6);
  static const Color brandPurple = Color(0xFF8E54E2);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryOrange,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
      brightness: Brightness.light,
      primary: primaryOrange,
      secondary: primaryGreen,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryOrange,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
      brightness: Brightness.dark,
      primary: primaryOrange,
      secondary: primaryGreen,
      surface: const Color(0xFF16213E),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF16213E),
      shadowColor: const Color(0x4D000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF16213E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
    ),
  );
}
