// lib/app/theme/text_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Student AI Companion.
///
/// Poppins is used for display, headline, and title styles to give the
/// app a distinctive, premium voice. Inter carries body and label text
/// for maximum legibility at small sizes. Provides a complete Material 3
/// [TextTheme] for both light and dark modes.
class AppTextThemes {
  AppTextThemes._();

  // -----------------------------------------------------------------
  // Light theme text colors
  // -----------------------------------------------------------------

  static const Color _lightPrimaryText = Color(0xFF0F172A);
  static const Color _lightSecondaryText = Color(0xFF475569);
  static const Color _lightMutedText = Color(0xFF64748B);

  // -----------------------------------------------------------------
  // Dark theme text colors
  // -----------------------------------------------------------------

  static const Color _darkPrimaryText = Color(0xFFF8FAFC);
  static const Color _darkSecondaryText = Color(0xFFCBD5E1);
  static const Color _darkMutedText = Color(0xFF94A3B8);

  // -----------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------

  static TextTheme lightTextTheme() {
    return _buildTextTheme(
      primaryText: _lightPrimaryText,
      secondaryText: _lightSecondaryText,
      mutedText: _lightMutedText,
    );
  }

  static TextTheme darkTextTheme() {
    return _buildTextTheme(
      primaryText: _darkPrimaryText,
      secondaryText: _darkSecondaryText,
      mutedText: _darkMutedText,
    );
  }

  // -----------------------------------------------------------------
  // Shared builder
  // -----------------------------------------------------------------

  static TextTheme _buildTextTheme({
    required Color primaryText,
    required Color secondaryText,
    required Color mutedText,
  }) {
    // Base heading style shared by every display/headline/title variant;
    // each size below only needs to copyWith the properties that differ.
    final TextStyle headingBase = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      color: primaryText,
    );

    // Base body/label style shared by every body/label variant.
    final TextStyle bodyBase = GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      color: primaryText,
    );

    return TextTheme(
      // ---------------------------------------------------------------
      // Display
      // ---------------------------------------------------------------
      displayLarge: headingBase.copyWith(
        fontSize: 57,
        letterSpacing: -0.5,
        height: 1.12,
      ),
      displayMedium: headingBase.copyWith(
        fontSize: 45,
        letterSpacing: -0.3,
        height: 1.16,
      ),
      displaySmall: headingBase.copyWith(
        fontSize: 36,
        letterSpacing: -0.2,
        height: 1.2,
      ),

      // ---------------------------------------------------------------
      // Headlines
      // ---------------------------------------------------------------
      headlineLarge: headingBase.copyWith(
        fontSize: 32,
        letterSpacing: -0.2,
        height: 1.22,
      ),
      headlineMedium: headingBase.copyWith(
        fontSize: 28,
        letterSpacing: -0.1,
        height: 1.26,
      ),
      headlineSmall: headingBase.copyWith(
        fontSize: 24,
        letterSpacing: 0,
        height: 1.3,
      ),

      // ---------------------------------------------------------------
      // Titles
      // ---------------------------------------------------------------
      titleLarge: headingBase.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: 0,
        height: 1.3,
      ),
      titleMedium: headingBase.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: headingBase.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.4,
      ),

      // ---------------------------------------------------------------
      // Body
      // ---------------------------------------------------------------
      bodyLarge: bodyBase.copyWith(
        fontSize: 16,
        letterSpacing: 0.15,
        height: 1.5,
        color: primaryText,
      ),
      bodyMedium: bodyBase.copyWith(
        fontSize: 14,
        letterSpacing: 0.15,
        height: 1.5,
        color: secondaryText,
      ),
      bodySmall: bodyBase.copyWith(
        fontSize: 12,
        letterSpacing: 0.2,
        height: 1.45,
        color: mutedText,
      ),

      // ---------------------------------------------------------------
      // Labels
      // ---------------------------------------------------------------
      labelLarge: bodyBase.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.4,
        color: primaryText,
      ),
      labelMedium: bodyBase.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.3,
        height: 1.35,
        color: secondaryText,
      ),
      labelSmall: bodyBase.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.4,
        height: 1.3,
        color: mutedText,
      ),
    );
  }
}

