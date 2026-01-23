import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_theme.dart';
import '../../theme/responsive_sizing.dart'; // iPad responsive fix

/// Step 2: Nickname input
class OnboardingStep2Nickname extends StatefulWidget {
  final String? initialNickname;
  final ValueChanged<String?> onNicknameChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const OnboardingStep2Nickname({
    super.key,
    this.initialNickname,
    required this.onNicknameChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<OnboardingStep2Nickname> createState() => _OnboardingStep2NicknameState();
}

class _OnboardingStep2NicknameState extends State<OnboardingStep2Nickname> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  static const int _maxLength = 24;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialNickname ?? '';
    _controller.addListener(_onTextChanged);
    widget.onNicknameChanged(_controller.text.trim().isEmpty ? null : _controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onNicknameChanged(_controller.text.trim().isEmpty ? null : _controller.text.trim());
  }

  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  void _handleContinue() {
    _unfocus();
    widget.onContinue();
  }

  void _handleBack() {
    _unfocus();
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    // iPad responsive fix: add responsive sizing
    final sizing = ResponsiveSizing(context);
    // Get keyboard height for bottom padding
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardHeight = viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _unfocus,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: sizing.screenPadding, // iPad responsive fix
              right: sizing.screenPadding,
              top: sizing.screenPadding,
              bottom: sizing.screenPadding + keyboardHeight,
            ),
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
                    Icons.person_outline,
                    size: sizing.largeIconSize, // iPad responsive fix
                    color: OnboardingTheme.primaryGreen,
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  Text(
                    'What should we call you?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: OnboardingTheme.textPrimary,
                          fontSize: sizing.isTablet ? 32 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingL), // iPad responsive fix
                  Text(
                    'Enter a nickname (optional)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: OnboardingTheme.textSecondary,
                          fontSize: sizing.isTablet ? 18 : null, // iPad responsive fix
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sizing.spacingXXL), // iPad responsive fix
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: _maxLength,
                    cursorColor: OnboardingTheme.primaryGreen,
                    decoration: InputDecoration(
                      hintText: 'Your nickname',
                      hintStyle: TextStyle(
                        color: OnboardingTheme.textSecondary.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: OnboardingTheme.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: OnboardingTheme.divider,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: OnboardingTheme.divider,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: OnboardingTheme.primaryGreen,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      counterText: '', // Hide counter
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: OnboardingTheme.textPrimary,
                        ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleContinue(),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_maxLength),
                    ],
                  ),
                  const Spacer(), // iPad responsive fix
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleBack,
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
      ),
    );
  }
}

