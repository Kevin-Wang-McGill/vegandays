import 'package:flutter/material.dart';

/// Baseline dimensions for standard phone screens (iPhone 14/15 class)
class Breakpoints {
  // Standard phone baseline (iPhone 14/15: 390x844 logical pixels)
  static const double baselineWidth = 390.0;
  static const double baselineHeight = 844.0;
  
  // iPad responsive fix: threshold for tablet detection
  static const double tabletShortestSide = 600.0;

  // Screen size categories (minimal logic)
  static bool isCompact(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < baselineWidth * 0.9; // < 351px
  }

  static bool isStandard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= baselineWidth * 0.9 && width < baselineWidth * 1.3; // 351-507px
  }

  static bool isLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= baselineWidth * 1.3; // >= 507px
  }
  
  // iPad responsive fix: detect tablet by shortestSide
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= tabletShortestSide;
  }

  /// Get scale factor relative to baseline width
  /// iPad responsive fix: increased upper clamp for tablets
  static double getScaleFactor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final width = size.width;
    
    final rawScale = width / baselineWidth;
    
    // iPad responsive fix: use larger scale range for tablets
    if (shortestSide >= tabletShortestSide) {
      return rawScale.clamp(1.0, 1.5);
    }
    return rawScale.clamp(0.85, 1.15);
  }
}


