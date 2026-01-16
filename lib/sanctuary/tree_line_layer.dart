import 'package:flutter/material.dart';
import 'sanctuary_assets.dart';

/// Tree line layer for mid-ground - creates a row of trees with rhythm
class TreeLineLayer extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final double grassH;
  final double horizonBottom;
  final String treeAssetPath;

  const TreeLineLayer({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.grassH,
    required this.horizonBottom,
    this.treeAssetPath = SanctuaryAssets.tree01,
  });

  @override
  Widget build(BuildContext context) {
    final w = screenWidth;
    final h = screenHeight;
    
    // Base bottom position for trees (above grass and wavy strip, on horizon)
    // Trees are positioned on the horizon, above the grass layers
    final baseBottom = grassH - 0.07 * h;
    
    // Define trees with three size categories (all sizes increased by 150% total - 100% then 50%)
    // Order: small trees (back) -> medium trees (middle) -> large trees (front)
    // In Stack, draw back to front so front trees appear on top
    final trees = <_TreeData>[
      // Small trees (3) - farthest from bottom (background), left tree extends to screen edge
      _TreeData(x: -0.1 * w, width: 0.27 * w, bottom: baseBottom + 0.02 * h, scale: 0.9, opacity: 0.90),
      _TreeData(x: 0.3 * w, width: 0.24 * w, bottom: baseBottom + 0.03 * h, scale: 0.92, opacity: 0.88),
      _TreeData(x: 0.5 * w, width: 0.30 * w, bottom: baseBottom + 0.02 * h, scale: 0.95, opacity: 0.91),
      
      // Medium trees (3) - middle layer, left tree extends to screen edge
      _TreeData(x: 0.12 * w, width: 0.39 * w, bottom: baseBottom, scale: 0.95, opacity: 0.92),
      _TreeData(x: 0.35 * w, width: 0.36 * w, bottom: baseBottom, scale: 1.0, opacity: 0.98),
      _TreeData(x: 0.6 * w, width: 0.42 * w, bottom: baseBottom, scale: 0.98, opacity: 0.95),
      
      // Large trees (2) - closest to bottom (foreground), left tree extends to screen edge
      _TreeData(x: -0.11 * w, width: 0.567 * w, bottom: baseBottom - 0.05 * h, scale: 1.0, opacity: 0.95),
      _TreeData(x: 0.68 * w, width: 0.5355 * w, bottom: baseBottom - 0.03 * h, scale: 1.05, opacity: 1.0),
    ];
    
    return Stack(
      children: trees.map((tree) {
        // Allow trees to extend beyond screen edges for natural forest effect
        final clampedX = tree.x.clamp(-0.15 * w, w - tree.width * 0.5);
        
        return Positioned(
          left: clampedX,
          bottom: tree.bottom,
          child: Opacity(
            opacity: tree.opacity,
            child: Transform.scale(
              scale: tree.scale,
              child: Image.asset(
                treeAssetPath,
                width: tree.width,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Internal data class for tree properties
class _TreeData {
  final double x;
  final double width;
  final double bottom;
  final double scale;
  final double opacity;

  const _TreeData({
    required this.x,
    required this.width,
    required this.bottom,
    required this.scale,
    required this.opacity,
  });
}

