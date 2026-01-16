import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'onboarding_step1_start_date.dart';
import 'onboarding_step2_nickname.dart';
import 'onboarding_step3_diet_type.dart';
import 'onboarding_impact_summary.dart';
import 'onboarding_theme.dart';
import 'widgets/onboarding_progress_bar.dart';
import '../../constants/prefs_keys.dart';
import '../../services/app_state_service.dart';
import '../../models/diet_type.dart';

/// Onboarding flow container managing 3 steps with progress bar
class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  // Step data
  DateTime? _startDate;
  String? _nickname;
  DietType? _dietType;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Step3 complete - navigate to Impact Summary
      _navigateToImpactSummary();
    }
  }

  void _navigateToImpactSummary() {
    if (_dietType == null || _startDate == null) {
      return; // Should not happen
    }
    
    // Save startDate to prefs before navigating (so Impact Summary can read it)
    _saveStartDateToPrefs();
    
    // Navigate to Impact Summary page
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnboardingImpactSummary(
          dietType: _dietType!,
          startDate: _startDate!, // Pass startDate directly
          onComplete: _completeOnboarding,
        ),
      ),
    );
  }

  Future<void> _saveStartDateToPrefs() async {
    if (_startDate == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.startDate,
      DateFormat('yyyy-MM-dd').format(DateTime(_startDate!.year, _startDate!.month, _startDate!.day)),
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_startDate == null || _dietType == null) {
      return; // Should not happen, but safety check
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Save onboarding data (if not already saved in Impact Summary)
    await prefs.setBool(PrefsKeys.onboardingCompleted, true);
    await prefs.setString(
      PrefsKeys.startDate,
      DateFormat('yyyy-MM-dd').format(DateTime(_startDate!.year, _startDate!.month, _startDate!.day)),
    );
    if (_nickname != null && _nickname!.trim().isNotEmpty) {
      await prefs.setString(PrefsKeys.nickname, _nickname!.trim());
    }
    await prefs.setString(PrefsKeys.dietType, _dietType!.storageKey);
    
    // Initialize app state with start date
    await AppStateService.instance.initializeOnboarding(_startDate!);
    
    // Complete onboarding and navigate to Home (clears Onboarding stack)
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar and step indicator
            _buildProgressBar(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  OnboardingStep1StartDate(
                    initialDate: _startDate ?? DateTime.now(),
                    onDateSelected: (date) {
                      _startDate = date;
                    },
                    onContinue: _goToNextStep,
                  ),
                  OnboardingStep2Nickname(
                    initialNickname: _nickname,
                    onNicknameChanged: (nickname) {
                      _nickname = nickname;
                    },
                    onContinue: _goToNextStep,
                    onBack: _goToPreviousStep,
                  ),
                  OnboardingStep3DietType(
                    initialDietType: _dietType,
                    onDietTypeChanged: (dietType) {
                      _dietType = dietType;
                    },
                    onContinue: _goToNextStep, // Changed: now goes to Impact Summary first
                    onBack: _goToPreviousStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / 3;
    
    return OnboardingProgressBar(
      progress: progress,
      currentStep: _currentStep + 1, // 1-based for display
    );
  }
}

