// lib/app/theme/color_schemes.dart

import 'package:flutter/material.dart';

/// Static color definitions for Student AI Companion.
///
/// A futuristic, premium palette inspired by Apple, Nothing OS, OpenAI,
/// glassmorphism interfaces, and AMOLED displays. Provides a ready-to-use
/// [ColorScheme] for both light and dark modes, plus semantic helper
/// colors (success/warning/info/glass/orb-glow) not covered by Material's
/// default color roles.
class AppColorSchemes {
  AppColorSchemes._();

  // -----------------------------------------------------------------
  // Core Brand Colors
  // -----------------------------------------------------------------

  static const Color brandIndigo = Color(0xFF5B4DFF);
  static const Color brandPurple = Color(0xFF7C4DFF);
  static const Color brandCyan = Color(0xFF00E5FF);
  static const Color brandCoral = Color(0xFFFF6B5B);

  // -----------------------------------------------------------------
  // Light Scheme
  // -----------------------------------------------------------------

  static const Color _lightPrimary = Color(0xFF5B4DFF); // Indigo / Purple
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightPrimaryContainer = Color(0xFFE4E0FF);
  static const Color _lightOnPrimaryContainer = Color(0xFF1B0F8C);

  static const Color _lightSecondary = Color(0xFF00B8CC); // Cyan
  static const Color _lightOnSecondary = Color(0xFFFFFFFF);
  static const Color _lightSecondaryContainer = Color(0xFFCFF6FB);
  static const Color _lightOnSecondaryContainer = Color(0xFF00363D);

  static const Color _lightTertiary = Color(0xFF2FA65A);
  static const Color _lightOnTertiary = Color(0xFFFFFFFF);
  static const Color _lightTertiaryContainer = Color(0xFFD6F4E0);
  static const Color _lightOnTertiaryContainer = Color(0xFF0B3D1E);

  static const Color _lightError = Color(0xFFE24C4C); // Modern coral red
  static const Color _lightOnError = Color(0xFFFFFFFF);
  static const Color _lightErrorContainer = Color(0xFFFFDAD6);
  static const Color _lightOnErrorContainer = Color(0xFF410002);

  static const Color _lightBackground = Color(0xFFF6F6FA); // Soft gray-white
  static const Color _lightSurface = Color(0xFFFDFDFF); // Frosted white
  static const Color _lightOnSurface = Color(0xFF1A1B22);
  static const Color _lightOnSurfaceVariant = Color(0xFF5B5D6B);
  static const Color _lightOutline = Color(0xFF8D8F9C);
  static const Color _lightOutlineVariant = Color(0xFFDCDDE6);
  static const Color _lightShadow = Color(0xFF000000); // Shadow-friendly
  static const Color _lightScrim = Color(0xFF000000);
  static const Color _lightInverseSurface = Color(0xFF2E2F38);
  static const Color _lightOnInverseSurface = Color(0xFFF2F1F9);
  static const Color _lightInversePrimary = Color(0xFFC3BAFF);
  static const Color _lightSurfaceTint = Color(0xFF5B4DFF);

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: _lightPrimary,
    onPrimary: _lightOnPrimary,
    primaryContainer: _lightPrimaryContainer,
    onPrimaryContainer: _lightOnPrimaryContainer,
    secondary: _lightSecondary,
    onSecondary: _lightOnSecondary,
    secondaryContainer: _lightSecondaryContainer,
    onSecondaryContainer: _lightOnSecondaryContainer,
    tertiary: _lightTertiary,
    onTertiary: _lightOnTertiary,
    tertiaryContainer: _lightTertiaryContainer,
    onTertiaryContainer: _lightOnTertiaryContainer,
    error: _lightError,
    onError: _lightOnError,
    errorContainer: _lightErrorContainer,
    onErrorContainer: _lightOnErrorContainer,
    surface: _lightSurface,
    onSurface: _lightOnSurface,
    onSurfaceVariant: _lightOnSurfaceVariant,
    outline: _lightOutline,
    outlineVariant: _lightOutlineVariant,
    shadow: _lightShadow,
    scrim: _lightScrim,
    inverseSurface: _lightInverseSurface,
    onInverseSurface: _lightOnInverseSurface,
    inversePrimary: _lightInversePrimary,
    surfaceTint: _lightSurfaceTint,
  );

  // -----------------------------------------------------------------
  // Dark Scheme
  // -----------------------------------------------------------------

  static const Color darkBackground = Color(0xFF050816);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceContainer = Color(0xFF111827);

  static const Color _darkPrimary = Color(0xFF7C4DFF);
  static const Color _darkOnPrimary = Color(0xFF1B0F5C);
  static const Color _darkPrimaryContainer = Color(0xFF3A2A99);
  static const Color _darkOnPrimaryContainer = Color(0xFFE4E0FF);

  static const Color _darkSecondary = Color(0xFF00E5FF);
  static const Color _darkOnSecondary = Color(0xFF003339);
  static const Color _darkSecondaryContainer = Color(0xFF004E5C);
  static const Color _darkOnSecondaryContainer = Color(0xFFB8F5FF);

  static const Color _darkTertiary = Color(0xFF4ADE80);
  static const Color _darkOnTertiary = Color(0xFF0A3A1E);
  static const Color _darkTertiaryContainer = Color(0xFF155B32);
  static const Color _darkOnTertiaryContainer = Color(0xFFC3F7D6);

  static const Color _darkError = Color(0xFFFF6B6B);
  static const Color _darkOnError = Color(0xFF4A0E0E);
  static const Color _darkErrorContainer = Color(0xFF6B1F1F);
  static const Color _darkOnErrorContainer = Color(0xFFFFDAD6);

  static const Color _darkOnSurface = Color(0xFFF3F4F9); // High contrast
  static const Color _darkOnSurfaceVariant = Color(0xFFB4B7C9);
  static const Color _darkOutline = Color(0xFF8B8FA3);
  static const Color _darkOutlineVariant = Color(0xFF2A2E42);
  static const Color _darkShadow = Color(0xFF000000);
  static const Color _darkScrim = Color(0xFF000000);
  static const Color _darkInverseSurface = Color(0xFFF3F4F9);
  static const Color _darkOnInverseSurface = Color(0xFF1A1B22);
  static const Color _darkInversePrimary = Color(0xFF5B4DFF);
  static const Color _darkSurfaceTint = Color(0xFF7C4DFF);

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: _darkPrimary,
    onPrimary: _darkOnPrimary,
    primaryContainer: _darkPrimaryContainer,
    onPrimaryContainer: _darkOnPrimaryContainer,
    secondary: _darkSecondary,
    onSecondary: _darkOnSecondary,
    secondaryContainer: _darkSecondaryContainer,
    onSecondaryContainer: _darkOnSecondaryContainer,
    tertiary: _darkTertiary,
    onTertiary: _darkOnTertiary,
    tertiaryContainer: _darkTertiaryContainer,
    onTertiaryContainer: _darkOnTertiaryContainer,
    error: _darkError,
    onError: _darkOnError,
    errorContainer: _darkErrorContainer,
    onErrorContainer: _darkOnErrorContainer,
    surface: darkSurface,
    onSurface: _darkOnSurface,
    onSurfaceVariant: _darkOnSurfaceVariant,
    outline: _darkOutline,
    outlineVariant: _darkOutlineVariant,
    shadow: _darkShadow,
    scrim: _darkScrim,
    inverseSurface: _darkInverseSurface,
    onInverseSurface: _darkOnInverseSurface,
    inversePrimary: _darkInversePrimary,
    surfaceTint: _darkSurfaceTint,
  );

  // -----------------------------------------------------------------
  // Semantic Colors
  // -----------------------------------------------------------------
  // Roles not covered by Material's default ColorScheme: status colors
  // for feedback states, glass-surface tints for glassmorphism cards,
  // and orb-glow accents used by the animated AI companion orb.

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF38BDF8);

  static const Color glassLight = Color(0xCCFFFFFF); // frosted white glass
  static const Color glassDark = Color(0x991A1A2E); // frosted navy glass

  static const Color orbGlowPurple = Color(0xFF9B6BFF);
  static const Color orbGlowCyan = Color(0xFF3FF0E0);
}

