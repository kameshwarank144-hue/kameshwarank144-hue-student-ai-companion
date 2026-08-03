// lib/app/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design-system definition for Student AI Companion.
///
/// Exposes a Material 3 [ThemeData] for both light and dark modes, built
/// around a premium glassmorphism aesthetic inspired by Apple, Nothing OS,
/// and OpenAI: soft frosted surfaces, indigo/cyan accents in light mode,
/// and neon cyan/purple highlights on AMOLED black in dark mode.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------
  // Seed colors
  // ---------------------------------------------------------------------

  static const Color _lightSeed = Color(0xFF4F5BFF); // indigo
  static const Color _lightAccent = Color(0xFF2FE0F5); // cyan

  static const Color _darkSeed = Color(0xFF8A6BFF); // neon purple
  static const Color _darkAccent = Color(0xFF3FF0E0); // neon cyan

  // ---------------------------------------------------------------------
  // Surface tokens
  // ---------------------------------------------------------------------

  static const Color _lightBackground = Color(0xFFF7F7FB); // soft white
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightGlassSurface = Color(0xCCFFFFFF); // frosted glass

  static const Color _darkBackground = Color(0xFF000000); // AMOLED black
  static const Color _darkSurface = Color(0xFF10101A); // deep navy
  static const Color _darkGlassSurface = Color(0x991A1A2E); // glass card

  // ---------------------------------------------------------------------
  // Shape tokens
  // ---------------------------------------------------------------------

  static const double _defaultRadius = 24.0;
  static final BorderRadius _defaultBorderRadius =
      BorderRadius.circular(_defaultRadius);

  // ---------------------------------------------------------------------
  // Public theme getters
  // ---------------------------------------------------------------------

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = _buildLightColorScheme();
    final TextTheme textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: _buildAppBarTheme(colorScheme, textTheme),
      cardTheme: _buildCardTheme(colorScheme, _lightGlassSurface),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme, textTheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme, textTheme),
      inputDecorationTheme:
          _buildInputDecorationTheme(colorScheme, _lightSurface),
      bottomNavigationBarTheme:
          _buildBottomNavigationBarTheme(colorScheme, _lightSurface),
      navigationBarTheme:
          _buildNavigationBarTheme(colorScheme, _lightSurface, textTheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme, textTheme),
      dialogTheme: _buildDialogTheme(colorScheme, _lightSurface, textTheme),
      dividerColor: colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = _buildDarkColorScheme();
    final TextTheme textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: _buildAppBarTheme(colorScheme, textTheme),
      cardTheme: _buildCardTheme(colorScheme, _darkGlassSurface),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme, textTheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme, textTheme),
      inputDecorationTheme:
          _buildInputDecorationTheme(colorScheme, _darkSurface),
      bottomNavigationBarTheme:
          _buildBottomNavigationBarTheme(colorScheme, _darkSurface),
      navigationBarTheme:
          _buildNavigationBarTheme(colorScheme, _darkSurface, textTheme),
      floatingActionButtonTheme: _buildFabTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme, textTheme),
      dialogTheme: _buildDialogTheme(colorScheme, _darkSurface, textTheme),
      dividerColor: colorScheme.onSurface.withValues(alpha: 0.10),
    );
  }

  // ---------------------------------------------------------------------
  // Color scheme builders
  // ---------------------------------------------------------------------

  static ColorScheme _buildLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _lightSeed,
      brightness: Brightness.light,
      secondary: _lightAccent,
      surface: _lightSurface,
    );
  }

  static ColorScheme _buildDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _darkSeed,
      brightness: Brightness.dark,
      secondary: _darkAccent,
      surface: _darkSurface,
    );
  }

  // ---------------------------------------------------------------------
  // Text theme builder
  // ---------------------------------------------------------------------
  // Poppins is used for prominent headings/titles; Inter carries body and
  // label text for maximum legibility at small sizes.

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final TextTheme base = Typography.material2021(
      platform: TargetPlatform.android,
    ).black;

    return base
        .copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 57,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: colorScheme.onSurface,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: colorScheme.onSurface,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: colorScheme.onSurface.withValues(alpha: 0.85),
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: colorScheme.onSurface,
          ),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );
  }

  // ---------------------------------------------------------------------
  // Component theme builders
  // ---------------------------------------------------------------------

  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  /// A frosted-glass style card: low elevation, soft translucent fill,
  /// hairline border, and generously rounded corners.
  static CardThemeData _buildCardTheme(
    ColorScheme colorScheme,
    Color glassSurface,
  ) {
    return CardThemeData(
      elevation: 0,
      color: glassSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: colorScheme.primary.withValues(alpha: 0.15),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: _defaultBorderRadius,
        side: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ).copyWith(
        shadowColor: WidgetStateProperty.all(
          colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme,
    Color surface,
  ) {
    final OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: colorScheme.onSurface.withValues(alpha: 0.10),
        width: 1,
      ),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
    ColorScheme colorScheme,
    Color surface,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(
    ColorScheme colorScheme,
    Color surface,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelLarge?.copyWith(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.5),
          );
        },
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.5),
          );
        },
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(
    ColorScheme colorScheme,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      focusElevation: 4,
      hoverElevation: 6,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
    );
  }

  static DialogThemeData _buildDialogTheme(
    ColorScheme colorScheme,
    Color surface,
    TextTheme textTheme,
  ) {
    return DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    );
  }
}

