import 'package:flutter/material.dart';

/// Design tokens for the app
class DesignTokens {
  // Colors
  static const Color background = Color(0xFFF1F6F9);
  static const Color card = Color(0xFFFAF8F4);
  static const Color primary = Color(0xFFED845E);
  static const Color foreground = Color(0xFF533D2D);
  static const Color secondary = Color(0xFFCDE4DD);
  static const Color muted = Color(0xFFE4EDF1);
  static const Color mutedText = Color(0xFF627884);
  static const Color accent = Color(0xFFF9DC86);
  static const Color border = Color(0xFFD9E3E8);
  static const Color bean = Color(0xFFF5C73D);

  // Border Radius
  static const double radiusSmall = 16.0;
  static const double radiusMedium = 24.0;
  static const double radiusLarge = 32.0;
  static const double radiusPill = 32.0;

  // Shadows
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowButton => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowPill => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Spacing (tuned for standard screens: 390x844)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // Screen padding (standard screens)
  static const double screenPadding = 20.0;

  // Typography (tuned for standard screens)
  static TextStyle headerSmallTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600, // semi-bold
          fontSize: 13.0, // tuned for standard screens
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 6,
              offset: const Offset(0, 0),
            ),
            Shadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 8,
              offset: const Offset(0, 0),
            ),
          ],
        ) ??
        const TextStyle();
  }

  static TextStyle headerBigNumberStyle(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall?.copyWith(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800, // Extra bold for emphasis
          color: primary,
          fontSize: 48.0, // tuned for standard screens
        ) ??
        const TextStyle();
  }

  static TextStyle panelTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: foreground,
          fontSize: 20.0, // tuned for standard screens
        ) ??
        const TextStyle();
  }

  static TextStyle animalCardTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: foreground,
          fontSize: 16.0, // tuned for standard screens
        ) ??
        const TextStyle();
  }

  static TextStyle animalCardCostStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: mutedText,
          fontSize: 13.0, // tuned for standard screens
        ) ??
        const TextStyle();
  }

  // Opacity values
  static const double panelOpacity = 0.9;
  static const double pillOpacity = 0.95;
  static const double hintOpacity = 0.95;
}

