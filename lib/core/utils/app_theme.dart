import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:eventease/core/utils/ee_design_tokens.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color accentColor = Color(0xFFF59E0B); // Amber

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF1F2937); // Dark Gray
  static const Color textSecondaryColor = Color(0xFF6B7280); // Medium Gray

  // Surface Colors
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color backgroundColor = Color(0xFFF9FAFB); // Light Gray
  static const Color cardColor = Color(0xFFF9FAFB); // Light Gray for cards

  // Status Colors
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber

  // Border Colors
  static const Color borderColor = Color(0xFFE5E7EB); // Light Gray

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EEDesignTokens.radiusLg),
          side: const BorderSide(color: borderColor),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: EEDesignTokens.displayLarge.copyWith(color: textPrimaryColor),
        headlineMedium: EEDesignTokens.headlineMedium.copyWith(color: textPrimaryColor),
        titleLarge: EEDesignTokens.titleLarge.copyWith(color: textPrimaryColor),
        bodyLarge: EEDesignTokens.bodyLarge.copyWith(color: textPrimaryColor),
        bodyMedium: EEDesignTokens.bodyMedium.copyWith(color: textSecondaryColor),
        labelLarge: GoogleFonts.inter(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EEDesignTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF111827), // Dark background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937), // Dark surface
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1F2937),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EEDesignTokens.radiusLg),
          side: const BorderSide(color: Color(0xFF374151)),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: EEDesignTokens.displayLarge.copyWith(color: Colors.white),
        headlineMedium: EEDesignTokens.headlineMedium.copyWith(color: Colors.white),
        titleLarge: EEDesignTokens.titleLarge.copyWith(color: Colors.white),
        bodyLarge: EEDesignTokens.bodyLarge.copyWith(color: Colors.white),
        bodyMedium: EEDesignTokens.bodyMedium.copyWith(color: const Color(0xFFD1D5DB)),
        labelLarge: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151)), // Dark border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFD1D5DB)),
        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF1F2937),
        background: Color(0xFF111827),
        error: errorColor,
      ),
    );
  }
}
