import 'package:flutter/material.dart';
import 'breakpoints.dart';
import 'tokens.dart';

/// Responsive sizing helper tuned for standard phone screens
/// iPad responsive fix: added tablet-aware sizing
class ResponsiveSizing {
  final BuildContext context;
  final double scaleFactor;
  final bool isTablet; // iPad responsive fix

  ResponsiveSizing(this.context)
      : scaleFactor = Breakpoints.getScaleFactor(context),
        isTablet = Breakpoints.isTablet(context);

  // Header styles (tuned for standard: 390x844)
  TextStyle get headerSmallTextStyle => DesignTokens.headerSmallTextStyle(context);

  TextStyle get headerBigNumberStyle => DesignTokens.headerBigNumberStyle(context);

  // iPad responsive fix: panel width with tablet support
  double get panelWidth {
    final baseWidth = 180.0;
    // iPad responsive fix: allow wider panels on tablets
    final maxWidth = isTablet ? 320.0 : 220.0;
    return (baseWidth * scaleFactor).clamp(160.0, maxWidth);
  }

  // Spacing (tuned for standard screens)
  double get spacingXS => DesignTokens.spacingXS * scaleFactor;
  double get spacingS => DesignTokens.spacingS * scaleFactor;
  double get spacingM => DesignTokens.spacingM * scaleFactor;
  double get spacingL => DesignTokens.spacingL * scaleFactor;
  double get spacingXL => DesignTokens.spacingXL * scaleFactor;
  double get spacingXXL => DesignTokens.spacingXXL * scaleFactor;

  // Screen padding - iPad responsive fix: larger padding on tablets
  double get screenPadding {
    final base = DesignTokens.screenPadding * scaleFactor;
    return isTablet ? base * 1.5 : base;
  }

  // Button height - iPad responsive fix: larger buttons on tablets
  double get buttonHeight {
    final baseHeight = 56.0;
    final maxHeight = isTablet ? 72.0 : 60.0;
    return (baseHeight * scaleFactor).clamp(52.0, maxHeight);
  }

  // Header spacing
  double get headerSpacing => spacingXS;

  // Panel positioning (tuned for standard screens)
  double get panelTopOffset {
    // Position below header + spacing
    return 120.0 * scaleFactor;
  }

  double get panelBottomOffset {
    // Position above button + spacing
    return 100.0 * scaleFactor;
  }

  // Typography sizes - iPad responsive fix: larger fonts on tablets
  double get headerSmallFontSize {
    final baseSize = 13.0;
    final maxSize = isTablet ? 18.0 : 14.0;
    return (baseSize * scaleFactor).clamp(12.0, maxSize);
  }

  double get headerBigFontSize {
    final baseSize = 48.0;
    final maxSize = isTablet ? 72.0 : 54.0;
    return (baseSize * scaleFactor).clamp(42.0, maxSize);
  }

  // Panel title font size
  double get panelTitleFontSize {
    final baseSize = 20.0;
    final maxSize = isTablet ? 28.0 : 22.0;
    return (baseSize * scaleFactor).clamp(18.0, maxSize);
  }

  // Animal card sizes - iPad responsive fix
  double get animalCardEmojiSize {
    final baseSize = 28.0;
    final maxSize = isTablet ? 40.0 : 32.0;
    return (baseSize * scaleFactor).clamp(26.0, maxSize);
  }

  double get animalCardPadding {
    return spacingM;
  }

  double get animalCardSpacing {
    return spacingM;
  }
  
  // iPad responsive fix: max content width for centering on large screens
  double get maxContentWidth {
    return isTablet ? 600.0 : double.infinity;
  }
  
  // iPad responsive fix: icon sizes for splash/onboarding
  double get largeIconSize {
    final baseSize = 80.0;
    return isTablet ? 120.0 : baseSize;
  }
  
  double get splashIconSize {
    final baseSize = 112.0;
    return isTablet ? 160.0 : baseSize;
  }
  
  // iPad responsive fix: responsive font sizes for Settings and general use
  double get titleSmallFontSize => isTablet ? 18.0 : 14.0;
  double get titleMediumFontSize => isTablet ? 20.0 : 16.0;
  double get titleLargeFontSize => isTablet ? 26.0 : 22.0;
  double get bodySmallFontSize => isTablet ? 16.0 : 13.0;
  double get bodyMediumFontSize => isTablet ? 18.0 : 14.0;
  double get headlineMediumFontSize => isTablet ? 36.0 : 28.0;
}


