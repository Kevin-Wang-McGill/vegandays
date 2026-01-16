import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/sanctuary_animal.dart';
import '../models/app_state.dart';
import '../services/app_state_service.dart';
import '../theme/tokens.dart';
import '../theme/responsive_sizing.dart';

class AnimalsPanelOverlay extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(AnimalType, int) onAnimalTap;
  final double screenPadding;
  final double sceneTop;
  final double sceneBottom;
  final double sceneCenterY;

  const AnimalsPanelOverlay({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onAnimalTap,
    required this.screenPadding,
    required this.sceneTop,
    required this.sceneBottom,
    required this.sceneCenterY,
  });

  @override
  State<AnimalsPanelOverlay> createState() => _AnimalsPanelOverlayState();
}

class _AnimalsPanelOverlayState extends State<AnimalsPanelOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280), // 240-300ms range
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0), // Start off-screen to the right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Open animation
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimalsPanelOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Calculate menu width: 190-220 (clamped)
  double _calculateMenuWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use a percentage of screen width, clamped to 190-220
    final calculatedWidth = screenWidth * 0.52;
    return calculatedWidth.clamp(190.0, 220.0);
  }

  /// Calculate menu height: based on scene area height, clamped to reasonable bounds
  double _calculateMenuHeight(BuildContext context) {
    // Use scene area height as reference, not full screen height
    final sceneHeight = widget.sceneBottom - widget.sceneTop;
    // Menu should be about 70-80% of scene height, but clamped to reasonable min/max
    final calculatedHeight = sceneHeight * 0.75;
    // Clamp to ensure menu fits comfortably in scene area with padding
    return calculatedHeight.clamp(300.0, sceneHeight - 24.0); // Min 300px, max sceneHeight - 24px padding
  }

  // Fixed display order: chicken → sheep → pig → cow (no fish)
  static const List<AnimalType> _displayOrder = [
    AnimalType.chicken,
    AnimalType.sheep,
    AnimalType.pig,
    AnimalType.cow,
  ];

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing(context);
    final state = AppStateService.instance.state;
    final animals = _displayOrder; // Use fixed display order instead of AnimalType.values
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;

    // Handle dimensions (standard screen baseline)
    const handleWidth = 32.0; // 30-34 range
    const handleHeight = 92.0; // 86-96 range

    // Menu dimensions
    final menuWidth = _calculateMenuWidth(context);
    final menuHeight = _calculateMenuHeight(context);

    // Menu position: flush to right edge when expanded, centered in scene area
    final menuRight = 0.0; // Flush to screen edge
    // Position menu centered in scene area (sceneCenterY is relative to SafeArea Stack)
    final menuTopFromSceneCenter = widget.sceneCenterY - menuHeight / 2;
    // Clamp to ensure menu stays within scene bounds with safe padding
    // Ensure at least 12px padding from top and bottom of scene area
    final minMenuTop = widget.sceneTop + 12.0;
    final maxMenuTop = widget.sceneBottom - menuHeight - 12.0;
    final clampedMenuTop = menuTopFromSceneCenter.clamp(
      minMenuTop,
      maxMenuTop,
    );

    // Handle position: changes based on expanded state
    // Collapsed: right edge, vertically centered in scene area
    // Expanded: left of menu (flush against menu), vertically centered relative to menu
    double handleTop;
    if (widget.isExpanded) {
      // When expanded: center handle relative to menu
      handleTop = clampedMenuTop + (menuHeight - handleHeight) / 2;
      // Ensure handle stays within scene bounds (safety check)
      handleTop = handleTop.clamp(
        widget.sceneTop,
        widget.sceneBottom - handleHeight,
      );
    } else {
      // When collapsed: center handle in scene area
      handleTop = widget.sceneCenterY - handleHeight / 2;
      // Ensure handle stays within scene bounds
      handleTop = handleTop.clamp(
        widget.sceneTop,
        widget.sceneBottom - handleHeight,
      );
    }
    
    final handleRight = widget.isExpanded
        ? menuWidth // Flush against menu left edge (handleRightEdge == menuLeftEdge)
        : 0.0; // Flush to right edge when collapsed

    return Stack(
      children: [
        // Full-screen transparent GestureDetector for tap-to-dismiss (NO blur/dim)
        if (widget.isExpanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggle, // Tap outside to close
              child: Container(
                color: Colors.transparent, // Transparent, no blur/dim
              ),
            ),
          ),
        // Menu (only visible when expanded, with blur/tint INSIDE menu only)
        if (widget.isExpanded)
          Positioned(
            right: menuRight,
            top: clampedMenuTop,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMenu(
                  context,
                  sizing,
                  state,
                  animals,
                  menuWidth,
                  menuHeight,
                ),
              ),
            ),
          ),
        // Toggle handle (always visible, animated position)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          right: handleRight,
          top: handleTop,
          child: _buildToggleHandle(context, sizing, handleWidth, handleHeight),
        ),
      ],
    );
  }

  Widget _buildToggleHandle(
    BuildContext context,
    ResponsiveSizing sizing,
    double width,
    double height,
  ) {
    // Use same glass tint family as menu
    final menuTint = const Color(0xFF0F1113).withOpacity(0.32);
    final handleTint = const Color(0xFF0F1113).withOpacity(0.28); // Slightly different opacity
    final borderColor = Colors.white.withOpacity(0.16); // Same as menu border

    if (widget.isExpanded) {
      // Expanded state: attached to menu
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: handleTint, // Match menu glass tint family
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(999), // Rounded left side
            bottomLeft: const Radius.circular(999),
            topRight: Radius.zero, // Flat right side (touching menu)
            bottomRight: Radius.zero,
          ),
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
            left: BorderSide(color: borderColor, width: 1),
            bottom: BorderSide(color: borderColor, width: 1),
            // No right border (touching menu, no seam)
          ),
          // No shadow on handle when expanded (menu casts shadow)
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(999),
            bottomLeft: const Radius.circular(999),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Same blur as menu
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(999),
                  bottomLeft: const Radius.circular(999),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.88), // 0.85-0.92 range
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Collapsed state: standalone pill
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: handleTint,
          borderRadius: BorderRadius.circular(999), // Full rounded pill
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(999),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.white.withOpacity(0.88),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMenu(
    BuildContext context,
    ResponsiveSizing sizing,
    AppState state,
    List<AnimalType> animals,
    double menuWidth,
    double menuHeight,
  ) {
    final menuTint = const Color(0xFF0F1113).withOpacity(0.32);
    final borderColor = Colors.white.withOpacity(0.16);

    return Container(
      width: menuWidth,
      height: menuHeight,
      decoration: BoxDecoration(
        color: menuTint, // Elegant glass tint
        borderRadius: BorderRadius.circular(28), // >= 28
        border: Border.all(
          color: borderColor, // Subtle light border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // 10-14 range, blur INSIDE menu only
          child: Container(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title (no X button)
                Padding(
                  padding: EdgeInsets.all(sizing.spacingL),
                  child: Text(
                    'Animals',
                    style: DesignTokens.panelTitleStyle(context).copyWith(
                      fontSize: sizing.panelTitleFontSize,
                      color: Colors.white.withOpacity(0.92), // Light text for dark background
                    ),
                  ),
                ),
                // Scrollable animal list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: sizing.spacingL),
                    shrinkWrap: false,
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animalType = animals[index];
                      final count = state.animalCounts[animalType] ?? 0;
                      return Padding(
                        padding: EdgeInsets.only(bottom: sizing.animalCardSpacing),
                        child: _AnimalCard(
                          animalType: animalType,
                          savedCount: count,
                          onTap: () => widget.onAnimalTap(animalType, count),
                          sizing: sizing,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: sizing.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final AnimalType animalType;
  final int savedCount;
  final VoidCallback onTap;
  final ResponsiveSizing sizing;

  // Size constants for badge and icon (enlarged)
  static const double kBadgeSize = 62.0; // Increased from 56 (+10.7%)
  static const double kIconSize = 46.0; // Increased from 42 (+9.5%)
  static const double kBadgeBorderRadius = 16.0; // Large rounded corners
  static const double kBadgeBlurSigma = 12.0; // Frosted glass blur
  static const double kBadgeColorOpacity = 0.48; // Deep warm charcoal opacity
  
  // Card padding constants (more relaxed)
  static const double kCardVerticalPadding = 16.0; // Increased vertical padding (was ~12)
  static const double kCardHorizontalPadding = 14.0; // Left padding
  static const double kCardRightPadding = 14.0; // Reduced right padding (was ~24)
  static const double kCardMinHeight = 88.0; // Increased min height (was ~72)
  static const double kTitleCostSpacing = 10.0; // Increased spacing between title and cost

  const _AnimalCard({
    required this.animalType,
    required this.savedCount,
    required this.onTap,
    required this.sizing,
  });


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white.withOpacity(0.06), // Very slightly light background
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // 18-22 range
        side: BorderSide(
          color: Colors.white.withOpacity(0.25), // Distinct white border, 1px, opacity 0.22-0.30
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kCardMinHeight, // Increased card height for more relaxed feel
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: kCardHorizontalPadding,
              right: kCardRightPadding, // Reduced right padding (was ~24)
              top: kCardVerticalPadding,
              bottom: kCardVerticalPadding,
            ),
            child: Row(
              children: [
                // Animal icon with dark frosted glass badge (square with large rounded corners, enlarged)
                SizedBox(
                  width: kBadgeSize, // Increased from 56 to 62
                  height: kBadgeSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kBadgeBorderRadius),
                    child: Stack(
                      children: [
                        // Backdrop blur (only inside badge)
                        BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: kBadgeBlurSigma,
                            sigmaY: kBadgeBlurSigma,
                          ),
                          child: Container(
                            width: kBadgeSize,
                            height: kBadgeSize,
                            color: const Color(0xFF1A1410).withOpacity(kBadgeColorOpacity),
                          ),
                        ),
                        // Subtle top highlight for depth
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Centered animal icon (further enlarged)
                        Center(
                          child: Image.asset(
                            animalType.assetPath,
                            width: kIconSize, // Increased from 42 to 46
                            height: kIconSize,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 14.0), // Spacing between badge and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
                    children: [
                      Text(
                        animalType.name,
                        style: DesignTokens.animalCardTitleStyle(context).copyWith(
                          color: Colors.white.withOpacity(0.92),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: kTitleCostSpacing), // Increased spacing for better rhythm
                      Row(
                        children: [
                          const Text(
                            '🫘',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(width: sizing.spacingXS),
                          Flexible(
                            child: Text(
                              formatCostForDisplay(animalType.cost),
                              style: DesignTokens.animalCardCostStyle(context).copyWith(
                                color: Colors.white.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Saved count badge (right-aligned, no info button)
                if (savedCount > 0) ...[
                  const SizedBox(width: 8.0), // Small gap before count badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sizing.spacingS + 2,
                      vertical: sizing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.secondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(sizing.spacingM),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$savedCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
