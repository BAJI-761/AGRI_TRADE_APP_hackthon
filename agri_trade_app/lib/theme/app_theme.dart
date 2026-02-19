import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium design system for AgriTrade
/// 
/// Palette rationale:
/// - Primary: Deep emerald (#0A6847) — nature, trust, agriculture
/// - Secondary: Warm gold (#F2A93B) — harvest, prosperity
/// - Accent: Ocean teal (#0E8388) — technology, freshness
class AppTheme {
  // ──────────────────────────────────────────────
  // PRIMARY PALETTE — Emerald Green
  // ──────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF0A6847);
  static const Color primaryGreenLight = Color(0xFF16A34A);
  static const Color primaryGreenDark = Color(0xFF064E3B);
  static const Color primaryGreenSurface = Color(0xFFD1FAE5);

  // ──────────────────────────────────────────────
  // SECONDARY PALETTE — Warm Gold
  // ──────────────────────────────────────────────
  static const Color secondaryAmber = Color(0xFFF2A93B);
  static const Color secondaryAmberLight = Color(0xFFFBD38D);
  static const Color secondaryAmberDark = Color(0xFFD97706);

  // ──────────────────────────────────────────────
  // ACCENT PALETTE — Ocean Teal
  // ──────────────────────────────────────────────
  static const Color accentBlue = Color(0xFF0E8388);
  static const Color accentBlueLight = Color(0xFF5EEAD4);
  static const Color accentBlueDark = Color(0xFF065F6B);

  // ──────────────────────────────────────────────
  // NEUTRAL PALETTE
  // ──────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0FDF4);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7FBF8);
  static const Color surfaceCard = Color(0xFFFAFDFB);

  // ──────────────────────────────────────────────
  // TEXT COLORS
  // ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = textPrimary;

  // ──────────────────────────────────────────────
  // SEMANTIC COLORS
  // ──────────────────────────────────────────────
  static const Color successGreen = Color(0xFF22C55E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);

  // ──────────────────────────────────────────────
  // GRADIENTS
  // ──────────────────────────────────────────────
  static List<Color> get primaryGradient => [
    primaryGreenDark,
    primaryGreen,
    const Color(0xFF15803D),
  ];

  static List<Color> get secondaryGradient => [
    secondaryAmberDark,
    secondaryAmber,
    secondaryAmberLight,
  ];

  static List<Color> get backgroundGradient => [
    primaryGreenDark,
    primaryGreen,
    const Color(0xFF15803D),
    const Color(0xFFBBF7D0),
  ];

  static List<Color> get premiumGradient => [
    const Color(0xFF064E3B),
    const Color(0xFF0A6847),
    const Color(0xFF0E8388),
  ];

  static List<Color> get sunsetGradient => [
    const Color(0xFFD97706),
    const Color(0xFFF2A93B),
    const Color(0xFFFBD38D),
  ];

  // ──────────────────────────────────────────────
  // TEXT STYLES (Google Fonts)
  // ──────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ──────────────────────────────────────────────
  // CARD & SURFACE DECORATIONS
  // ──────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: primaryGreen.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Glassmorphism card — frosted translucent effect
  static BoxDecoration get glassCard => BoxDecoration(
    color: surfaceWhite.withOpacity(0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: surfaceWhite.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryGreen.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Glassmorphism card on dark/gradient backgrounds
  static BoxDecoration get glassCardOnDark => BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
  );

  /// Elevated card with colored accent
  static BoxDecoration accentCard(Color color) => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color.withOpacity(0.15), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // ──────────────────────────────────────────────
  // BUTTON STYLES
  // ──────────────────────────────────────────────
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryGreen,
    foregroundColor: textOnPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    textStyle: buttonText,
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryGreenSurface,
    foregroundColor: primaryGreen,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    textStyle: buttonText,
  );

  // ──────────────────────────────────────────────
  // INPUT DECORATION
  // ──────────────────────────────────────────────
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: surfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primaryGreen.withOpacity(0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: primaryGreen.withOpacity(0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryGreen, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );

  // ──────────────────────────────────────────────
  // GRADIENT DECORATIONS
  // ──────────────────────────────────────────────
  static BoxDecoration get gradientHeaderDecoration => primaryGradientDecoration;

  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: premiumGradient,
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

  // ──────────────────────────────────────────────
  // ICON CONTAINER
  // ──────────────────────────────────────────────
  static Widget iconContainer({
    required IconData icon,
    required Color color,
    double size = 48,
    double iconSize = 24,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  // ──────────────────────────────────────────────
  // MATERIAL 3 THEME DATA
  // ──────────────────────────────────────────────
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
        outline: const Color(0xFFCBD5E1),
        outlineVariant: const Color(0xFFE2E8F0),
        shadow: Colors.black.withOpacity(0.08),
        scrim: Colors.black.withOpacity(0.4),
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
        iconTheme: const IconThemeData(color: textOnPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceWhite,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryGreen.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle: GoogleFonts.inter(color: textTertiary),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryAmber,
        foregroundColor: textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: primaryGreenSurface,
        selectedColor: primaryGreen.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryGreen,
        size: 24,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 34, fontWeight: FontWeight.w800,
          color: textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: textPrimary, letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: textPrimary, letterSpacing: -0.2,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: textPrimary, letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: textPrimary, letterSpacing: 0,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: textPrimary, letterSpacing: 0,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500,
          color: textPrimary, letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal,
          color: textPrimary, letterSpacing: 0.15,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal,
          color: textPrimary, letterSpacing: 0.1,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal,
          color: textSecondary, letterSpacing: 0.2,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: textPrimary, letterSpacing: 0.1,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        indicatorColor: primaryGreenSurface,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
