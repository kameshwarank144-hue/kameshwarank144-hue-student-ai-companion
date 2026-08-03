// lib/app/theme/radii.dart

import 'package:flutter/material.dart';

/// Centralized radius and shape design system for Student AI Companion.
///
/// A premium, soft, futuristic scale inspired by Apple, Nothing OS, and
/// Material 3 Expressive, tuned for glassmorphism-friendly surfaces
/// throughout the app.
class AppRadii {
  AppRadii._();

  // -----------------------------------------------------------------
  // Base Radius Scale
  // -----------------------------------------------------------------

  static const double none = 0;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double pill = 999;
  static const double full = 9999;

  // -----------------------------------------------------------------
  // BorderRadius Helpers
  // -----------------------------------------------------------------

  static const BorderRadius radiusXs =
      BorderRadius.all(Radius.circular(xs));

  static const BorderRadius radiusSm =
      BorderRadius.all(Radius.circular(sm));

  static const BorderRadius radiusMd =
      BorderRadius.all(Radius.circular(md));

  static const BorderRadius radiusLg =
      BorderRadius.all(Radius.circular(lg));

  static const BorderRadius radiusXl =
      BorderRadius.all(Radius.circular(xl));

  static const BorderRadius radiusXxl =
      BorderRadius.all(Radius.circular(xxl));

  static const BorderRadius radiusRound =
      BorderRadius.all(Radius.circular(full));

  // -----------------------------------------------------------------
  // Premium Component Radii
  // -----------------------------------------------------------------

  // Cards
  static const BorderRadius card =
      BorderRadius.all(Radius.circular(24));

  // Glass Cards
  static const BorderRadius glassCard =
      BorderRadius.all(Radius.circular(28));

  // Bottom Sheets
  static const BorderRadius bottomSheet =
      BorderRadius.vertical(
        top: Radius.circular(32),
      );

  // Dialogs
  static const BorderRadius dialog =
      BorderRadius.all(Radius.circular(28));

  // Input Fields
  static const BorderRadius input =
      BorderRadius.all(Radius.circular(20));

  // Buttons
  static const BorderRadius button =
      BorderRadius.all(Radius.circular(18));

  // Floating AI Orb
  static const BorderRadius orb =
      BorderRadius.all(Radius.circular(full));

  // Navigation Bar
  static const BorderRadius navigationBar =
      BorderRadius.vertical(
        top: Radius.circular(28),
      );

  // Chips
  static const BorderRadius chip =
      BorderRadius.all(Radius.circular(999));

  // -----------------------------------------------------------------
  // ShapeBorder Helpers
  // -----------------------------------------------------------------

  // Card Shape
  static final RoundedRectangleBorder cardShape =
      RoundedRectangleBorder(borderRadius: card);

  // Button Shape
  static final RoundedRectangleBorder buttonShape =
      RoundedRectangleBorder(borderRadius: button);

  // Dialog Shape
  static final RoundedRectangleBorder dialogShape =
      RoundedRectangleBorder(borderRadius: dialog);

  // Input Shape
  static final RoundedRectangleBorder inputShape =
      RoundedRectangleBorder(borderRadius: input);

  // Navigation Bar Shape
  static final RoundedRectangleBorder navigationBarShape =
      RoundedRectangleBorder(borderRadius: navigationBar);

  // -----------------------------------------------------------------
  // Glassmorphism Helpers
  // -----------------------------------------------------------------

  // Frosted Panel
  static const BorderRadius frostedPanel =
      BorderRadius.all(Radius.circular(30));

  // AI Chat Bubble
  static const BorderRadius chatBubble =
      BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(8),
      );

  // User Chat Bubble
  static const BorderRadius userChatBubble =
      BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(22),
      );
}

