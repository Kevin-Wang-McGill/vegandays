import 'package:flutter/material.dart';
import '../onboarding_theme.dart';
import '../../../theme/responsive_sizing.dart'; // iPad responsive fix

/// Animated progress bar with celebration effect for Onboarding
class OnboardingProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final int currentStep; // 1, 2, or 3
  final VoidCallback? onCelebrationComplete;

  const OnboardingProgressBar({
    super.key,
    required this.progress,
    required this.currentStep,
    this.onCelebrationComplete,
  });

  @override
  State<OnboardingProgressBar> createState() => _OnboardingProgressBarState();
}

class _OnboardingProgressBarState extends State<OnboardingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late Animation<double> _celebrationOpacity;
  late Animation<double> _celebrationY;
  
  int _previousStep = 0;
  double _previousProgress = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _previousStep = widget.currentStep;
    _previousProgress = widget.progress;
    
    // Celebration animation controller
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );

    // Scale animation: 0.9 → 1.1 → 1.0
    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 0.5),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 0.5),
    ]).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOutCubic,
    ));

    // Opacity animation: 0 → 1 → 0
    _celebrationOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 0.4),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 0.6),
    ]).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOut,
    ));

    // Y offset animation: 0 → -4 → 0 (subtle float)
    _celebrationY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 0.5),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 0.5),
    ]).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOutCubic,
    ));

    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCelebrationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(OnboardingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger celebration when step increases (not on initial build or going back)
    if (_isInitialized && 
        widget.currentStep > oldWidget.currentStep && 
        widget.currentStep > _previousStep) {
      _playCelebration();
      _previousStep = widget.currentStep;
      _previousProgress = widget.progress;
    } else if (!_isInitialized) {
      // Mark as initialized after first build
      _isInitialized = true;
      _previousStep = widget.currentStep;
      _previousProgress = widget.progress;
    } else {
      _previousStep = widget.currentStep;
      _previousProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _playCelebration() {
    // Reset and play celebration animation
    _celebrationController.reset();
    _celebrationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // iPad responsive fix: add responsive sizing
    final sizing = ResponsiveSizing(context);
    final barHeight = sizing.isTablet ? 5.0 : 3.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: sizing.screenPadding, // iPad responsive fix
        vertical: sizing.spacingL,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${widget.currentStep}/3',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: OnboardingTheme.textSecondary,
                      fontSize: sizing.isTablet ? 16 : 13, // iPad responsive fix
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: sizing.spacingS), // iPad responsive fix
          // Animated progress bar with celebration overlay
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track (background) - iPad responsive fix: dynamic height
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: barHeight,
                      width: constraints.maxWidth,
                      color: OnboardingTheme.trackGreen,
                    ),
                  ),
                  // Animated fill - iPad responsive fix: dynamic height
                  TweenAnimationBuilder<double>(
                    key: ValueKey('progress_${widget.progress}'),
                    tween: Tween(begin: _previousProgress, end: widget.progress),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    onEnd: () {
                      // Update previous progress after animation completes
                      _previousProgress = widget.progress;
                    },
                    builder: (context, animatedProgress, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: barHeight, // iPad responsive fix
                          width: constraints.maxWidth * animatedProgress,
                          color: OnboardingTheme.primaryGreen,
                        ),
                      );
                    },
                  ),
                  // Celebration effect (small leaf/light at progress endpoint)
                  AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, child) {
                      if (_celebrationController.value == 0) {
                        return const SizedBox.shrink();
                      }
                      
                      final progressWidth = constraints.maxWidth * widget.progress;
                      final celebrationX = progressWidth - 6; // Center on progress endpoint
                      
                      return Positioned(
                        left: celebrationX,
                        top: -4 + _celebrationY.value,
                        child: Opacity(
                          opacity: _celebrationOpacity.value,
                          child: Transform.scale(
                            scale: _celebrationScale.value,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: OnboardingTheme.primaryGreen.withOpacity(0.75),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.eco,
                                size: 8,
                                color: OnboardingTheme.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

