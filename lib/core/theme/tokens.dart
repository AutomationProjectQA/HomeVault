import 'package:flutter/material.dart';

/// Design tokens — single source of truth for the visual language.
/// Screens never hardcode colors, spacing, or radii; they use these.
abstract final class AppColors {
  // Brand — deep vault teal with a warm amber accent.
  static const Color primary = Color(0xFF0F5F5A);
  static const Color primaryDark = Color(0xFF0A403C);
  static const Color accent = Color(0xFFF59E0B);

  // Surfaces (light)
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);

  // Reminder / task status — the smart-color system from the product spec.
  static const Color statusCritical = Color(0xFFDC2626); // due today / overdue
  static const Color statusWarning = Color(0xFFEA580C); // due this week
  static const Color statusUpcoming = Color(0xFFCA8A04); // upcoming
  static const Color statusDone = Color(0xFF16A34A); // completed

  // Text
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get sheet => const BorderRadius.vertical(top: Radius.circular(lg));
}

abstract final class AppElevation {
  /// Soft shadow used on cards — premium feel, never harsh Material elevation.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
