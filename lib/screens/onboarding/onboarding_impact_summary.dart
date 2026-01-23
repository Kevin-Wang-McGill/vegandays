import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'onboarding_theme.dart';
import '../../models/diet_type.dart';
import '../../constants/prefs_keys.dart';
import '../../services/app_state_service.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/responsive_sizing.dart'; // iPad responsive fix

/// Impact Summary page shown after Onboarding Step3
/// Displays daily meat saved (grams) and equivalent beans/day
class OnboardingImpactSummary extends StatefulWidget {
  final DietType dietType;
  final DateTime startDate; // Pass startDate directly from OnboardingFlow
  final VoidCallback onComplete;

  const OnboardingImpactSummary({
    super.key,
    required this.dietType,
    required this.startDate,
    required this.onComplete,
  });

  @override
  State<OnboardingImpactSummary> createState() => _OnboardingImpactSummaryState();
}

class _OnboardingImpactSummaryState extends State<OnboardingImpactSummary>
    with SingleTickerProviderStateMixin {
  // Constants: USDA ERS 2026 forecast
  static const int _defaultMeatGramsPerDay = 282; // 227 lb/year → 282 g/day
  static const int _defaultBeansPerDay = 282; // beans/day = grams/day (no division)
  static const int _veganBonusBeansPerDay = 20; // Vegan bonus: +20 beans/day

  late AnimationController _celebrationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  int _dailyMeatGrams = _defaultMeatGramsPerDay;
  int _impactedDays = 1;
  int _totalSavedGrams = _defaultMeatGramsPerDay;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Celebration animation: fade + slide up
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Trigger celebration on mount
    _celebrationController.forward();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use startDate passed from OnboardingFlow (guaranteed non-null)
    final startDate = widget.startDate;
    
    // Load dailyMeatSavedGrams (fallback to default)
    _dailyMeatGrams = prefs.getInt(PrefsKeys.dailyMeatSavedGrams) ?? _defaultMeatGramsPerDay;
    
    // Calculate impactedDays (same logic as AppStateService)
    // Normalize to local midnight, ignore time components
    final startMidnight = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final diff = todayMidnight.difference(startMidnight);
    
    // impactedDays = dateDiffInDays(startDate, today) + 1
    // Clamp to >= 1 to avoid negative values (if user somehow selected future date)
    _impactedDays = (diff.inDays + 1).clamp(1, double.infinity).toInt();
    
    // Calculate total saved
    _totalSavedGrams = _impactedDays * _dailyMeatGrams;
    
    // Debug logging (only in debug mode)
    assert(() {
      print('[Impact Summary] startDate: ${startDate.toIso8601String()}');
      print('[Impact Summary] startMidnight: ${startMidnight.toIso8601String()}');
      print('[Impact Summary] todayMidnight: ${todayMidnight.toIso8601String()}');
      print('[Impact Summary] diff.inDays: ${diff.inDays}');
      print('[Impact Summary] impactedDays: $_impactedDays');
      print('[Impact Summary] dailyMeatGrams: $_dailyMeatGrams');
      print('[Impact Summary] totalSavedGrams: $_totalSavedGrams');
      return true;
    }());
    
    _isDataLoaded = true;
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    // Debug: confirm button is tapped
    debugPrint('[Impact Summary] Continue button tapped');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save impact summary data first
      await prefs.setInt(PrefsKeys.dailyMeatSavedGrams, _defaultMeatGramsPerDay);
      await prefs.setInt(PrefsKeys.dailyBeansPerDay, _defaultBeansPerDay);
      
      // Ensure onboarding data is saved (if not already)
      await prefs.setBool(PrefsKeys.onboardingCompleted, true);
      await prefs.setString(
        PrefsKeys.startDate,
        DateFormat('yyyy-MM-dd').format(DateTime(
          widget.startDate.year,
          widget.startDate.month,
          widget.startDate.day,
        )),
      );
      await prefs.setString(PrefsKeys.dietType, widget.dietType.storageKey);
      
      debugPrint('[Impact Summary] All data saved to prefs');
      
      // Initialize app state with start date (this will use the newly saved dailyBeansPerDay)
      await AppStateService.instance.initializeOnboarding(widget.startDate);
      
      debugPrint('[Impact Summary] App state initialized');
      
      // Navigate directly to MainScreen and clear navigation stack
      // This ensures user cannot go back to Onboarding
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
      
      debugPrint('[Impact Summary] Navigation to MainScreen completed');
    } catch (e) {
      debugPrint('[Impact Summary] Error during continue: $e');
      // Even if there's an error, try to navigate to avoid blocking user
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // iPad responsive fix: add responsive sizing
    final sizing = ResponsiveSizing(context);
    
    return Scaffold(
      backgroundColor: OnboardingTheme.background, // Match Onboarding background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            return SingleChildScrollView(
              padding: EdgeInsets.all(sizing.screenPadding), // iPad responsive fix
              // iPad responsive fix: center and constrain content
              child: Center(
                child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportHeight > 0 ? viewportHeight - sizing.screenPadding * 2 : 0,
                  maxWidth: sizing.maxContentWidth, // iPad responsive fix
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  // Celebration animation: icon with fade + slide
                  AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, -_slideAnimation.value),
                          child: Icon(
                            Icons.eco,
                            size: sizing.isTablet ? 96 : 64, // iPad responsive fix
                            color: OnboardingTheme.primaryGreen,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: sizing.spacingL), // iPad responsive fix
                  Text(
                    'Your Impact',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: OnboardingTheme.textPrimary,
                          letterSpacing: -0.5,
                          fontSize: sizing.isTablet ? 36 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingXXL * 1.5), // iPad responsive fix
                  // Main content with animated numbers
                  AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, -_slideAnimation.value * 0.5),
                          child: Column(
                            children: [
                              // Daily meat saved - improved hierarchy
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_dailyMeatGrams',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: OnboardingTheme.primaryGreen,
                                          fontSize: sizing.isTablet ? 72 : 56, // iPad responsive fix
                                          height: 1.0,
                                        ),
                                  ),
                                  SizedBox(width: sizing.spacingXS), // iPad responsive fix
                                  Text(
                                    'g',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: OnboardingTheme.primaryGreen,
                                          fontSize: sizing.isTablet ? 40 : 32, // iPad responsive fix
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: sizing.spacingM), // iPad responsive fix
                              Text(
                                'of meat per day',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: OnboardingTheme.textSecondary.withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'as a ${widget.dietType.displayName}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: OnboardingTheme.textSecondary.withOpacity(0.7),
                                      height: 1.4,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                              // Equals beans - refined module
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '= ',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: OnboardingTheme.textSecondary.withOpacity(0.4),
                                          fontWeight: FontWeight.w300,
                                          fontSize: sizing.isTablet ? 28 : null, // iPad responsive fix
                                        ),
                                  ),
                                  Text(
                                    '${_defaultBeansPerDay + (widget.dietType == DietType.vegan ? _veganBonusBeansPerDay : 0)}',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: OnboardingTheme.primaryGreen,
                                          fontSize: sizing.isTablet ? 64 : 48, // iPad responsive fix
                                          height: 1.0,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'beans/day',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: OnboardingTheme.textSecondary.withOpacity(0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                  if (widget.dietType == DietType.vegan) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: OnboardingTheme.primaryGreen.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+20',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: OnboardingTheme.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Total saved (new)
                              Text(
                                'You have totally saved $_totalSavedGrams g of meat as a ${widget.dietType.displayName} — = ${_totalSavedGrams + (widget.dietType == DietType.vegan ? _impactedDays * _veganBonusBeansPerDay : 0)} beans${widget.dietType == DietType.vegan ? ' (including vegan bonus)' : ''}.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: OnboardingTheme.textSecondary.withOpacity(0.75),
                                      height: 1.4,
                                      fontSize: 13,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  Text(
                    'You can customize this later in Settings based on your daily diet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: OnboardingTheme.textSecondary.withOpacity(0.75),
                          height: 1.5,
                          fontSize: sizing.isTablet ? 18 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: sizing.spacingM), // iPad responsive fix
                    child: Text(
                      'Sources available in Settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: OnboardingTheme.textSecondary.withOpacity(0.7),
                            fontSize: sizing.isTablet ? 14 : 12, // iPad responsive fix
                            height: 1.2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Continue button - iPad responsive fix
                  FilledButton(
                    onPressed: _handleContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: OnboardingTheme.primaryGreen,
                      foregroundColor: OnboardingTheme.white,
                      padding: EdgeInsets.symmetric(vertical: sizing.isTablet ? 20 : 16), // iPad responsive fix
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return OnboardingTheme.primaryGreenPressed;
                        }
                        if (states.contains(WidgetState.hovered)) {
                          return OnboardingTheme.primaryGreenHover;
                        }
                        return null;
                      }),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: sizing.isTablet ? 18 : 16, // iPad responsive fix
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: sizing.spacingL), // iPad responsive fix
                    ],
                  ),
                ),
                ), // iPad responsive fix: close ConstrainedBox
              ), // iPad responsive fix: close Center
            );
          },
        ),
      ),
    );
  }
}

