import 'package:flutter/material.dart';
import '../services/app_state_service.dart';
import '../models/sanctuary_animal.dart';
import '../sanctuary/sanctuary_scene.dart';
import '../widgets/sparkles_effect.dart';
import '../widgets/animals_panel_overlay.dart';
import '../theme/tokens.dart';
import '../theme/responsive_sizing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCheckingIn = false;
  bool _isAnimalsPanelExpanded = false;

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateService.instance,
      builder: (context, _) {
        final svc = AppStateService.instance;
        final state = svc.state;
        final canCheckIn = svc.canCheckIn();
        final sizing = ResponsiveSizing(context);
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final safeArea = mediaQuery.padding;
        final nickname = svc.nickname;

        // Calculate scene area (Sanctuary scene visible area)
        // Note: All coordinates are relative to SafeArea + padding Stack
        // Header block height (estimated: header text + spacing + beans pill area)
        const headerBlockHeight = 130.0; // 120-140 range, tuned for standard screens
    
        // Bottom navigation bar height (reduced compact NavigationBar)
        const tabBarHeight = 64.0; // Reduced from 80.0 for lighter feel
        final checkInButtonHeight = sizing.buttonHeight;
        final buttonSpacing = 16.0; // Spacing between button and tab bar
    
        // Stack height: available height after SafeArea and padding
        // Stack is inside SafeArea > Padding, so:
        // Stack height = screenHeight - safeArea.top - safeArea.bottom - 2 * screenPadding
        final stackHeight = screenSize.height - safeArea.top - safeArea.bottom - 2 * sizing.screenPadding;
    
        // Scene boundaries (relative to SafeArea + padding Stack)
        // Top: below header block
        final sceneTop = headerBlockHeight;
        // Bottom: above button + tab bar
        // Note: button is positioned at bottom: 0 of Stack, so we need to account for its height
        final sceneBottom = stackHeight - (tabBarHeight + checkInButtonHeight + buttonSpacing);
        final sceneCenterY = (sceneTop + sceneBottom) / 2;

        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: Stack(
            children: [
              // 全屏背景：Sanctuary 场景
              Positioned.fill(
                child: SanctuaryScene(),
              ),
              // 前景层：所有 UI 组件
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(sizing.screenPadding),
                  child: Stack(
                    children: [
                      // 左上角 Header
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname.isNotEmpty ? 'Hi, $nickname' : "You've made a difference for",
                              style: sizing.headerSmallTextStyle,
                            ),
                            if (nickname.isNotEmpty) ...[
                              SizedBox(height: sizing.headerSpacing * 0.5),
                              Text(
                                "You've made a difference for",
                                style: sizing.headerSmallTextStyle.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: DesignTokens.foreground.withOpacity(0.85),
                                ),
                              ),
                            ],
                            SizedBox(height: sizing.headerSpacing),
                            Text(
                              '${state.impactedDays} days',
                              style: sizing.headerBigNumberStyle,
                            ),
                          ],
                        ),
                      ),
                      // 右上角 Beans Pill
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _buildBeansPill(context, state.beans, canCheckIn, sizing),
                      ),
                      // 可折叠的 Animals 面板
                      AnimalsPanelOverlay(
                        isExpanded: _isAnimalsPanelExpanded,
                        onToggle: () {
                          setState(() {
                            _isAnimalsPanelExpanded = !_isAnimalsPanelExpanded;
                          });
                        },
                        onAnimalTap: (animalType, count) {
                          _showAnimalBottomSheet(context, animalType, count);
                        },
                        screenPadding: sizing.screenPadding,
                        sceneTop: sceneTop,
                        sceneBottom: sceneBottom,
                        sceneCenterY: sceneCenterY,
                      ),
                      // 底部 Check in 按钮和动物数量提示
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10.0, // Increased bottom inset by 10px (8-14px range)
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Check in 按钮
                            SizedBox(
                              width: double.infinity,
                              height: sizing.buttonHeight,
                              child: FilledButton(
                                onPressed: canCheckIn && !_isCheckingIn ? _handleCheckIn : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: DesignTokens.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: DesignTokens.muted,
                                  disabledForegroundColor: DesignTokens.mutedText,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.2),
                                ),
                                child: Text(
                                  canCheckIn ? 'Check in' : 'You showed up today',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // 动物数量提示
                            SizedBox(height: 9.0), // 8-10px spacing below button
                            Text(
                              'You have saved ${state.animalCounts.values.fold<int>(0, (a, b) => a + b)} animals.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 13.5, // ~13-14 range
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.foreground.withOpacity(0.9),
                                    height: 1.2,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBeansPill(
    BuildContext context,
    int beans,
    bool showHint,
    ResponsiveSizing sizing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: sizing.spacingL,
            vertical: sizing.spacingS,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(DesignTokens.pillOpacity),
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: DesignTokens.shadowPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🫘',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: sizing.spacingS),
              Text(
                '$beans',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: DesignTokens.foreground,
                    ),
              ),
            ],
          ),
        ),
        if (beans < 20 && showHint) ...[
          SizedBox(height: sizing.spacingS),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            onEnd: () {
              if (mounted) {
                setState(() {});
              }
            },
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizing.spacingS,
                    vertical: sizing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(DesignTokens.panelOpacity),
                    borderRadius: BorderRadius.circular(sizing.spacingM),
                  ),
                  child: Text(
                    'Check in to earn beans',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.mutedText,
                          fontSize: 10,
                        ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isCheckingIn = true;
    });

    final success = await AppStateService.instance.checkIn();
    if (success && mounted) {
      setState(() {
        _isCheckingIn = false;
      });

      // 显示 Toast
      final sizing = ResponsiveSizing(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for showing up today.'),
          backgroundColor: DesignTokens.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sizing.spacingM),
          ),
        ),
      );

      // 显示 Sparkles 动效
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => const SparklesEffect(),
      );

      _refresh();
    } else {
      setState(() {
        _isCheckingIn = false;
      });
    }
  }

  void _showAnimalBottomSheet(
    BuildContext context,
    AnimalType animalType,
    int savedCount,
  ) {
    final state = AppStateService.instance.state;
    final canExchange = AppStateService.instance.canExchange(animalType);
    final sizing = ResponsiveSizing(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusLarge),
            topRight: Radius.circular(DesignTokens.radiusLarge),
          ),
        ),
        padding: EdgeInsets.all(sizing.spacingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: sizing.spacingXXL),
            Image.asset(
              animalType.assetPath,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            SizedBox(height: sizing.spacingL),
            Text(
              animalType.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.foreground,
                  ),
            ),
            SizedBox(height: sizing.spacingXXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Saved',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.mutedText,
                          ),
                    ),
                    SizedBox(height: sizing.spacingXS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizing.spacingL,
                        vertical: sizing.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.secondary,
                        borderRadius: BorderRadius.circular(sizing.spacingL),
                      ),
                      child: Text(
                        '$savedCount',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.foreground,
                            ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Cost',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.mutedText,
                          ),
                    ),
                    SizedBox(height: sizing.spacingXS),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizing.spacingL,
                        vertical: sizing.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.bean.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(sizing.spacingL),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🫘',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(width: sizing.spacingXS),
                          Text(
                            formatCostForDisplay(animalType.cost),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: DesignTokens.foreground,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: sizing.spacingXXL),
            if (!canExchange)
              Padding(
                padding: EdgeInsets.only(bottom: sizing.spacingL),
                child: Text(
                  'Not enough beans yet. Check in tomorrow to earn more.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignTokens.mutedText,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Source explanation text
            Padding(
              padding: EdgeInsets.only(bottom: sizing.spacingM),
              child: Text(
                'Based on ${animalType.yieldSource}, one ${animalType.name.toLowerCase()} yields about ${formatCostDetailed(animalType.cost)} g edible meat = ${formatCostDetailed(animalType.cost)} beans.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.mutedText.withOpacity(0.85),
                      fontSize: 11,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canExchange ? () => _handleExchange(animalType) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DesignTokens.muted,
                  disabledForegroundColor: DesignTokens.mutedText,
                  padding: EdgeInsets.symmetric(vertical: sizing.spacingL),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  ),
                ),
                child: const Text(
                  'Bring home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExchange(AnimalType animalType) async {
    final success = await AppStateService.instance.exchangeAnimal(animalType);
    if (success && mounted) {
      Navigator.of(context).pop();
      _refresh();
    }
  }
}
