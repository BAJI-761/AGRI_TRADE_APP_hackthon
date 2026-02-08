import 'package:flutter/material.dart';

/// Professional color theme for AgriTrade app
/// Based on color theory principles:
/// - Primary: Deep forest green (nature, growth, agriculture)
/// - Secondary: Warm amber (harvest, energy, warmth)
/// - Accent: Trust blue (technology, reliability)
/// - Complementary color scheme for visual harmony
class AppTheme {
  // Primary Colors - Forest Green Palette
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep forest green
  static const Color primaryGreenLight = Color(0xFF4CAF50); // Medium green
  static const Color primaryGreenDark = Color(0xFF1B5E20); // Dark green
  
  // Secondary Colors - Warm Amber/Orange Palette
  static const Color secondaryAmber = Color(0xFFFF8C42); // Harvest orange
  static const Color secondaryAmberLight = Color(0xFFFFB366); // Light amber
  static const Color secondaryAmberDark = Color(0xFFFF6B35); // Dark orange
  
  // Accent Colors - Trust Blue
  static const Color accentBlue = Color(0xFF1565C0); // Trust blue
  static const Color accentBlueLight = Color(0xFF42A5F5); // Light blue
  static const Color accentBlueDark = Color(0xFF0D47A1); // Dark blue
  
  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF8F9FA); // Off-white
  static const Color backgroundDark = Color(0xFF212121); // Dark surface
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Dark gray
  static const Color textSecondary = Color(0xFF757575); // Medium gray
  static const Color textTertiary = Color(0xFF9E9E9E); // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on colored bg
  
  // Semantic Colors
  static const Color successGreen = Color(0xFF388E3C);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Gradient Colors
  static List<Color> get primaryGradient => [
    primaryGreenDark,
    primaryGreen,
    primaryGreenLight,
  ];
  
  static List<Color> get secondaryGradient => [
    secondaryAmberDark,
    secondaryAmber,
    secondaryAmberLight,
  ];
  
  static List<Color> get backgroundGradient => [
    primaryGreenDark,
    primaryGreen,
    primaryGreenLight,
    Color(0xFFE8F5E9), // Very light green
  ];
  
  // Modern Material 3 Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryGreen,
        onPrimary: textOnPrimary,
        secondary: secondaryAmber,
        onSecondary: textOnPrimary,
        tertiary: accentBlue,
        onTertiary: textOnPrimary,
        error: errorRed,
        onError: textOnPrimary,
        surface: surfaceWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceLight,
        onSurfaceVariant: textSecondary,
        outline: Color(0xFFBDBDBD),
        outlineVariant: Color(0xFFE0E0E0),
        shadow: Colors.black.withOpacity(0.1),
        scrim: Colors.black.withOpacity(0.5),
        inverseSurface: backgroundDark,
        onInverseSurface: textOnPrimary,
        inversePrimary: primaryGreenLight,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: backgroundLight,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryGreen,
        foregroundColor: textOnPrimary,
        iconTheme: IconThemeData(color: textOnPrimary),
        titleTextStyle: TextStyle(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceWhite,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textOnPrimary,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: BorderSide(color: primaryGreen, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textTertiary),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryAmber,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primaryGreen.withOpacity(0.2),
        labelStyle: TextStyle(color: textPrimary),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: primaryGreen,
        size: 24,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  
  // Helper methods for gradients
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: primaryGradient,
    ),
  );
  
  static BoxDecoration get secondaryGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: secondaryGradient,
    ),
  );
  
  static BoxDecoration get backgroundGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: backgroundGradient,
    ),
  );
}

