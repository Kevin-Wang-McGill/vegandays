import 'package:flutter/material.dart';
import '../../models/diet_type.dart';
import 'onboarding_theme.dart';
import '../../theme/responsive_sizing.dart'; // iPad responsive fix

/// Step 3: Diet type selection
class OnboardingStep3DietType extends StatefulWidget {
  final DietType? initialDietType;
  final ValueChanged<DietType> onDietTypeChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const OnboardingStep3DietType({
    super.key,
    this.initialDietType,
    required this.onDietTypeChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<OnboardingStep3DietType> createState() => _OnboardingStep3DietTypeState();
}

class _OnboardingStep3DietTypeState extends State<OnboardingStep3DietType> {
  DietType? _selectedDietType;

  @override
  void initState() {
    super.initState();
    _selectedDietType = widget.initialDietType ?? DietType.vegetarian; // Default to vegetarian
    widget.onDietTypeChanged(_selectedDietType!);
  }

  void _selectDietType(DietType type) {
    setState(() {
      _selectedDietType = type;
    });
    widget.onDietTypeChanged(type);
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
                  Icon(
                    Icons.restaurant_menu,
                    size: sizing.largeIconSize, // iPad responsive fix
                    color: OnboardingTheme.primaryGreen,
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  Text(
                    'What\'s your diet type?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: OnboardingTheme.textPrimary,
                          fontSize: sizing.isTablet ? 32 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingL), // iPad responsive fix
                  Text(
                    'Select your plant-based diet preference',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: OnboardingTheme.textSecondary,
                          fontSize: sizing.isTablet ? 18 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  _buildDietTypeOption(
                    context,
                    DietType.vegetarian,
                    'Vegetarian',
                    'No meat, but may include eggs and dairy',
                    Icons.eco,
                    null,
                    sizing, // iPad responsive fix
                  ),
                  SizedBox(height: sizing.spacingL), // iPad responsive fix
                  _buildDietTypeOption(
                    context,
                    DietType.vegan,
                    'Vegan',
                    'No animal products at all',
                    Icons.eco,
                    '+20 beans/day bonus',
                    sizing, // iPad responsive fix
                  ),
                  const Spacer(), // iPad responsive fix
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: OnboardingTheme.textPrimary,
                            side: const BorderSide(
                              color: OnboardingTheme.divider,
                              width: 1,
                            ),
                            padding: EdgeInsets.symmetric(vertical: sizing.isTablet ? 20 : 16), // iPad responsive fix
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: TextStyle(
                              fontSize: sizing.isTablet ? 18 : 16, // iPad responsive fix
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: sizing.spacingL), // iPad responsive fix
                      Expanded(
                        child: FilledButton(
                          onPressed: _selectedDietType != null ? widget.onContinue : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: OnboardingTheme.primaryGreen,
                            foregroundColor: OnboardingTheme.white,
                            disabledBackgroundColor: OnboardingTheme.disabledBackground,
                            disabledForegroundColor: OnboardingTheme.disabledText,
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
                            'Complete',
                            style: TextStyle(
                              fontSize: sizing.isTablet ? 18 : 16, // iPad responsive fix
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildDietTypeOption(
    BuildContext context,
    DietType type,
    String title,
    String description,
    IconData icon,
    String? bonusText,
    ResponsiveSizing sizing, // iPad responsive fix
  ) {
    final isSelected = _selectedDietType == type;
    
    return Card(
      child: InkWell(
        onTap: () => _selectDietType(type),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? OnboardingTheme.primaryGreen
                  : OnboardingTheme.divider,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? OnboardingTheme.selectedBackground
                : OnboardingTheme.white,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? OnboardingTheme.primaryGreen
                      : OnboardingTheme.divider,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? OnboardingTheme.white : OnboardingTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: OnboardingTheme.textPrimary,
                              ),
                        ),
                        if (bonusText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: OnboardingTheme.primaryGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              bonusText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: OnboardingTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: OnboardingTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: OnboardingTheme.primaryGreen,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

