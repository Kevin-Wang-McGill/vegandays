import 'package:flutter/material.dart';
import 'breakpoints.dart';
import 'tokens.dart';

/// Responsive sizing helper tuned for standard phone screens
class ResponsiveSizing {
  final BuildContext context;
  final double scaleFactor;

  ResponsiveSizing(this.context)
      : scaleFactor = Breakpoints.getScaleFactor(context);

  // Header styles (tuned for standard: 390x844)
  TextStyle get headerSmallTextStyle => DesignTokens.headerSmallTextStyle(context);

  TextStyle get headerBigNumberStyle => DesignTokens.headerBigNumberStyle(context);

  // Panel width (tuned for standard: ~170-190 logical pixels)
  double get panelWidth {
    // Baseline: 180px on standard screens
    final baseWidth = 180.0;
    return (baseWidth * scaleFactor).clamp(160.0, 220.0);
  }

  // Spacing (tuned for standard screens)
  double get spacingXS => DesignTokens.spacingXS * scaleFactor;
  double get spacingS => DesignTokens.spacingS * scaleFactor;
  double get spacingM => DesignTokens.spacingM * scaleFactor;
  double get spacingL => DesignTokens.spacingL * scaleFactor;
  double get spacingXL => DesignTokens.spacingXL * scaleFactor;
  double get spacingXXL => DesignTokens.spacingXXL * scaleFactor;

  // Screen padding
  double get screenPadding => DesignTokens.screenPadding * scaleFactor;

  // Button height (tuned for standard: ~56px)
  double get buttonHeight {
    final baseHeight = 56.0;
    return (baseHeight * scaleFactor).clamp(52.0, 60.0);
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

  // Typography sizes
  double get headerSmallFontSize {
    final baseSize = 13.0;
    return (baseSize * scaleFactor).clamp(12.0, 14.0);
  }

  double get headerBigFontSize {
    final baseSize = 48.0;
    // Allow slightly more scaling for big numbers, but still clamped
    return (baseSize * scaleFactor).clamp(42.0, 54.0);
  }

  // Panel title font size
  double get panelTitleFontSize {
    final baseSize = 20.0;
    return (baseSize * scaleFactor).clamp(18.0, 22.0);
  }

  // Animal card sizes
  double get animalCardEmojiSize {
    final baseSize = 28.0;
    return (baseSize * scaleFactor).clamp(26.0, 32.0);
  }

  double get animalCardPadding {
    return spacingM;
  }

  double get animalCardSpacing {
    return spacingM;
  }
}

