import 'package:flutter/material.dart';

/// Baseline dimensions for standard phone screens (iPhone 14/15 class)
class Breakpoints {
  // Standard phone baseline (iPhone 14/15: 390x844 logical pixels)
  static const double baselineWidth = 390.0;
  static const double baselineHeight = 844.0;

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

  /// Get scale factor relative to baseline width
  static double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Clamp scale between 0.85 and 1.15 to avoid extreme scaling
    final rawScale = width / baselineWidth;
    return rawScale.clamp(0.85, 1.15);
  }
}

