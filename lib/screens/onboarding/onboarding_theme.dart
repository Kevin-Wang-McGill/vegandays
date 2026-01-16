import 'package:flutter/material.dart';

/// Onboarding-specific green theme tokens
/// Soft, muted, low saturation, low contrast, healing aesthetic
class OnboardingTheme {
  // Yellow-tinted emerald green colors (spring leaf green, vibrant but still low saturation)
  /// Main accent color for CTAs - yellow-tinted emerald green, more like spring leaves
  /// Updated: shifted hue from teal/cyan towards yellow-green (warmer, more vibrant)
  static const Color primaryGreen = Color(0xFF7ECB85); // Yellow-tinted emerald green (spring leaf green, was #7FD4B0 teal-green)
  
  /// Muted version for hover/pressed states or subtle backgrounds
  static const Color primaryGreenMuted = Color(0xFFA8E4B8); // Lighter, more muted yellow-green
  
  /// Darker version for better contrast when needed
  static const Color primaryGreenDark = Color(0xFF6BB87A); // Deeper yellow-green
  
  /// Track/outline color for progress bar and borders
  static const Color trackGreen = Color(0xFFD4F0D4); // Very light yellow-green tint
  
  /// Surface tint for subtle glass-like effects (very low opacity)
  static const Color surfaceTint = Color(0xFFE8F8E8); // Extremely light yellow-green tint
  
  // Neutral colors (for text and UI elements)
  /// Primary text color (dark brown, high readability)
  static const Color textPrimary = Color(0xFF533D2D);
  
  /// Secondary text color (muted gray)
  static const Color textSecondary = Color(0xFF627884);
  
  /// Divider/border color (neutral gray)
  static const Color divider = Color(0xFFD9E3E8);
  
  /// Background color (light warm white)
  static const Color background = Color(0xFFF1F6F9);
  
  /// Card/surface color (warm off-white)
  static const Color surface = Color(0xFFFAF8F4);
  
  /// White for contrast
  static const Color white = Colors.white;
  
  // Interactive states
  /// Disabled button background
  static const Color disabledBackground = Color(0xFFE4EDF1);
  
  /// Disabled button text
  static const Color disabledText = Color(0xFF627884);
  
  /// Pressed state (slightly darker, ~8-10% darker than primaryGreen)
  static const Color primaryGreenPressed = Color(0xFF6BB87A); // Pressed: darker version of yellow-green primary
  
  /// Hover state (very slight darkening, ~3-5% darker than primaryGreen)
  static const Color primaryGreenHover = Color(0xFF75C88A); // Hover: subtle darkening of yellow-green
  
  /// Selected state background (very subtle tint)
  static Color selectedBackground = primaryGreen.withOpacity(0.08);
  
  /// Date picker theme for Onboarding Step1
  /// Creates a localized theme that only affects the date picker dialog
  static ThemeData getDatePickerTheme(BuildContext context) {
    final baseTheme = Theme.of(context);
    
    return baseTheme.copyWith(
      // ColorScheme: Use green as primary
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryGreen,
        secondary: primaryGreenMuted,
        surface: surface, // Warm off-white background
        onPrimary: white,
        onSurface: textPrimary,
        outline: divider,
      ),
      // Dialog theme: Soft rounded corners, warm background
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Consistent with Onboarding cards
        ),
        elevation: 0, // Flat, no shadow
      ),
      // Date picker theme (Material3)
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: Colors.transparent,
        headerForegroundColor: textPrimary,
        headerHeadlineStyle: baseTheme.textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headerHelpStyle: baseTheme.textTheme.bodySmall?.copyWith(
          color: textSecondary,
        ),
        // Day cell styles
        dayStyle: baseTheme.textTheme.bodyMedium?.copyWith(
          color: textPrimary,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return white; // Selected day: white text on green background
          }
          if (states.contains(WidgetState.disabled)) {
            return textSecondary.withOpacity(0.3);
          }
          return textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen; // Selected day: green background
          }
          return Colors.transparent;
        }),
        // Today style: subtle green border or light green background
        todayForegroundColor: WidgetStateProperty.all(primaryGreen),
        todayBackgroundColor: WidgetStateProperty.all(selectedBackground), // Very subtle green tint
        // Year/month picker styles
        yearStyle: baseTheme.textTheme.bodyLarge?.copyWith(
          color: textPrimary,
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return white;
          }
          return textPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        // Range selection (if used)
        rangeSelectionBackgroundColor: selectedBackground,
        rangeSelectionOverlayColor: WidgetStateProperty.all(primaryGreen.withOpacity(0.1)),
        // Divider
        dividerColor: divider.withOpacity(0.5), // Very light divider
        // Shape
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Slightly rounded day cells
        ),
      ),
      // Text button theme for OK/Cancel buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: baseTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(48, 48), // Ensure >= 48dp tap target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Elevated button theme for OK button (if used)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

