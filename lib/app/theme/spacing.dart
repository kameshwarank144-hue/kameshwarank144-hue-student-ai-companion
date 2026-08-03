// lib/app/theme/spacing.dart

import 'package:flutter/widgets.dart';

/// Single source of truth for spacing, padding, margins, and layout gaps
/// used across Student AI Companion.
///
/// Follows a premium, restrained design-system scale in the spirit of
/// Apple's Human Interface Guidelines and Material 3 Expressive: a small
/// set of consistent step sizes reused everywhere rather than ad-hoc
/// magic numbers scattered through the UI.
class AppSpacing {
  AppSpacing._();

  // -----------------------------------------------------------------
  // Base spacing scale
  // -----------------------------------------------------------------

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  // -----------------------------------------------------------------
  // Vertical gaps
  // -----------------------------------------------------------------
  // Reusable SizedBox instances for spacing widgets in a Column.

  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);

  // -----------------------------------------------------------------
  // Horizontal gaps
  // -----------------------------------------------------------------
  // Reusable SizedBox instances for spacing widgets in a Row.

  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);
  static const SizedBox hXxl = SizedBox(width: xxl);

  // -----------------------------------------------------------------
  // Common paddings
  // -----------------------------------------------------------------

  /// Standard horizontal padding for a full page/screen body.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: xl,
  );

  /// Padding applied directly under the safe area for top-level screens.
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    lg,
    xxl,
    lg,
    xxl,
  );

  /// Interior padding for glass/elevated cards.
  static const EdgeInsets cardPadding = EdgeInsets.all(xl);

  /// Padding for draggable bottom sheets, with extra top spacing for the
  /// drag handle.
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(
    xl,
    sm,
    xl,
    xxl,
  );

  /// Padding for AlertDialog / custom dialog content.
  static const EdgeInsets dialogPadding = EdgeInsets.all(xxl);

  /// Padding inside text fields and other form inputs.
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Padding for a single row/tile in a list (tasks, reminders, chats).
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Padding around a titled section (e.g. "Today's Classes").
  static const EdgeInsets sectionPadding = EdgeInsets.only(
    top: xxl,
    bottom: md,
  );

  /// Padding inside small pill-shaped chips (filters, tags, categories).
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  // -----------------------------------------------------------------
  // Section helpers
  // -----------------------------------------------------------------

  /// Horizontal-only padding matching [pagePadding], useful when vertical
  /// spacing is already handled by a parent scroll view or Column gap.
  static const EdgeInsets pageHorizontalOnly = EdgeInsets.symmetric(
    horizontal: lg,
  );

  /// Standard gap between stacked cards/sections on a screen.
  static const SizedBox sectionGap = SizedBox(height: xxl);

  /// Standard gap between a section's title and its content.
  static const SizedBox sectionTitleGap = SizedBox(height: sm);

  /// Standard corner radius companion value for spacing-aware components
  /// that need to align padding with the app's default rounded shape.
  static const double defaultRadius = xxl;
}

