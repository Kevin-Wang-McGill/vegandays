import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'onboarding_theme.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportHeight > 0 ? viewportHeight - 48 : 0,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.eco,
                    size: 80,
                    color: OnboardingTheme.primaryGreen,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Vegan Days',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: OnboardingTheme.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'When did you start your plant-based journey?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: OnboardingTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 60),
                  FilledButton(
                    onPressed: widget.onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: OnboardingTheme.primaryGreen,
                      foregroundColor: OnboardingTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

