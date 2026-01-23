import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'onboarding_theme.dart';
import '../../theme/responsive_sizing.dart'; // iPad responsive fix

/// Step 1: Start Date selection
class OnboardingStep1StartDate extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onContinue;

  const OnboardingStep1StartDate({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    required this.onContinue,
  });

  @override
  State<OnboardingStep1StartDate> createState() => _OnboardingStep1StartDateState();
}

class _OnboardingStep1StartDateState extends State<OnboardingStep1StartDate> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    widget.onDateSelected(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      // Inject localized green theme only for this date picker
      builder: (context, child) {
        return Theme(
          data: OnboardingTheme.getDatePickerTheme(context),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateSelected(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // iPad responsive fix: add responsive sizing
    final sizing = ResponsiveSizing(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        return SingleChildScrollView(
          padding: EdgeInsets.all(sizing.screenPadding), // iPad responsive fix
          // iPad responsive fix: center and constrain content on tablets
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
                  Icon(
                    Icons.eco,
                    size: sizing.largeIconSize, // iPad responsive fix
                    color: OnboardingTheme.primaryGreen,
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  Text(
                    'Welcome to Vegan Days',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: OnboardingTheme.textPrimary,
                          fontSize: sizing.isTablet ? 32 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingL), // iPad responsive fix
                  Text(
                    'When did you start your plant-based journey?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: OnboardingTheme.textSecondary,
                          fontSize: sizing.isTablet ? 18 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  Card(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: OnboardingTheme.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: OnboardingTheme.textPrimary,
                                      ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: OnboardingTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(), // iPad responsive fix: push button to bottom
                  FilledButton(
                    onPressed: widget.onContinue,
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
    );
  }
}

