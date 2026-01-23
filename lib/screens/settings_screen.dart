import 'package:flutter/foundation.dart'; // iPad debug
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state_service.dart';
import '../models/diet_type.dart';
import '../models/sanctuary_animal.dart';
import '../theme/tokens.dart';
import '../theme/responsive_sizing.dart'; // iPad responsive fix
import '../widgets/debug_device_info.dart'; // iPad debug

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onReset;

  const SettingsScreen({super.key, this.onReset});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Legal & Support URLs
const String _privacyPolicyUrl = 'https://kevin-wang-mcgill.github.io/vegandays-legal/privacy.html';
const String _supportUrl = 'https://kevin-wang-mcgill.github.io/vegandays-legal/support.html';
const String _supportEmail = 'vegandaysapp@gmail.com';

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _dailyMeatController;

  @override
  void initState() {
    super.initState();
    final svc = AppStateService.instance;
    _nicknameController = TextEditingController(text: svc.nickname);
    _dailyMeatController = TextEditingController(text: svc.dailyMeatSavedGrams.toString());
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _dailyMeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateService.instance,
      builder: (context, _) {
        final svc = AppStateService.instance;
        final state = svc.state;

        final startDateLabel = state.startDate == null
            ? 'Not set'
            : DateFormat('MMMM d, yyyy').format(state.startDate!);

        final totalSpentBeans = _calculateTotalSpentBeans(state.animalCounts);

        // iPad responsive fix: add responsive sizing
        final sizing = ResponsiveSizing(context);
        
        return Scaffold(
          backgroundColor: DesignTokens.background,
          body: SafeArea(
            // iPad responsive fix: center content and constrain width on tablets
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: sizing.maxContentWidth),
                child: ListView(
              padding: EdgeInsets.all(sizing.screenPadding), // iPad responsive fix
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.foreground,
                        letterSpacing: -0.4,
                        fontSize: sizing.isTablet ? 32 : null, // iPad responsive fix
                      ),
                ),
                SizedBox(height: sizing.spacingXXL), // iPad responsive fix

                // 1) Profile
                _SectionCard(
                  title: 'Profile',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile photo: coming soon'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                            // iPad responsive fix: larger profile image on tablets
                            child: Container(
                              width: sizing.isTablet ? 160 : 128,
                              height: sizing.isTablet ? 160 : 128,
                              decoration: BoxDecoration(
                                color: DesignTokens.secondary.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                border: Border.all(color: DesignTokens.border, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                child: Image.asset(
                                  'assets/profile pic.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingL),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nickname',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: DesignTokens.foreground,
                                        fontSize: sizing.titleSmallFontSize, // iPad responsive
                                      ),
                                ),
                                const SizedBox(height: DesignTokens.spacingS),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nicknameController,
                                        textInputAction: TextInputAction.done,
                                        decoration: InputDecoration(
                                          hintText: 'Optional',
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(0.55),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                            borderSide: BorderSide(color: DesignTokens.border),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                            borderSide: BorderSide(color: DesignTokens.border),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                        style: TextStyle(color: DesignTokens.foreground.withOpacity(0.95)),
                                        onSubmitted: (v) async {
                                          await svc.updateNickname(v);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Nickname saved'),
                                              duration: Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: DesignTokens.spacingS),
                                    TextButton(
                                      onPressed: () async {
                                        await svc.updateNickname(_nicknameController.text);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Nickname saved'),
                                            duration: Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: DesignTokens.mutedText,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spacingL),
                      Text(
                        'Diet type',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.foreground,
                              fontSize: sizing.titleSmallFontSize, // iPad responsive
                            ),
                      ),
                      const SizedBox(height: DesignTokens.spacingS),
                      SegmentedButton<DietType>(
                        segments: const [
                          ButtonSegment(value: DietType.vegetarian, label: Text('Vegetarian')),
                          ButtonSegment(value: DietType.vegan, label: Text('Vegan')),
                        ],
                        selected: {svc.dietType},
                        style: ButtonStyle(
                          visualDensity: VisualDensity.standard,
                          tapTargetSize: MaterialTapTargetSize.padded,
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                            ),
                          ),
                        ),
                        onSelectionChanged: (value) async {
                          final selected = value.isEmpty ? null : value.first;
                          if (selected == null) return;
                          await svc.updateDietType(selected);
                        },
                      ),
                      const SizedBox(height: DesignTokens.spacingXL),
                      _RowAction(
                        title: 'Start date',
                        subtitle: startDateLabel,
                        onTap: () => _pickStartDate(context),
                      ),
                      const SizedBox(height: DesignTokens.spacingM),
                      Text(
                        'Changing the start date will recompute days, totals, and your bean balance (earned - spent).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.mutedText,
                              height: 1.35,
                              fontSize: sizing.bodySmallFontSize, // iPad responsive
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // 2) Impact calculation basis
                _SectionCard(
                  title: 'Impact calculation basis',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default daily save is based on USDA ERS availability: 227 lb/person/year (retail basis) → about 282 g/day.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.mutedText,
                              height: 1.5,
                              fontSize: sizing.bodyMediumFontSize, // iPad responsive
                            ),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),
                      Text(
                        'Sources:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.foreground,
                              fontSize: sizing.titleSmallFontSize, // iPad responsive
                            ),
                      ),
                      const SizedBox(height: DesignTokens.spacingS),
                      Text(
                        '• USDA Economic Research Service (ERS) — per-capita availability (disappearance) of red meat and poultry, retail basis.\n'
                        '• Meat yield data for animal exchanges: industry-standard carcass yield percentages and retail cut yield ranges.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.mutedText,
                              height: 1.4,
                              fontSize: sizing.bodySmallFontSize, // iPad responsive
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // 3) Customize save
                _SectionCard(
                  title: 'Customize save',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily meat saved (g/day)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.foreground,
                              fontSize: sizing.titleSmallFontSize, // iPad responsive
                            ),
                      ),
                      const SizedBox(height: DesignTokens.spacingS),
                      TextField(
                        controller: _dailyMeatController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'e.g. 282',
                          suffixText: 'g/day',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.55),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                            borderSide: BorderSide(color: DesignTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                            borderSide: BorderSide(color: DesignTokens.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: TextStyle(color: DesignTokens.foreground.withOpacity(0.95)),
                        onSubmitted: (_) => _saveDailyMeat(context),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _saveDailyMeat(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: DesignTokens.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingM),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await svc.resetDailyMeatSavedToDefault();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Restored default: 282 g/day'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DesignTokens.foreground,
                                side: BorderSide(color: DesignTokens.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Restore default'),
                            ),
                          ),
                        ],
                      ),
                      if (svc.dietType == DietType.vegan) ...[
                        const SizedBox(height: DesignTokens.spacingL),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: DesignTokens.secondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                            border: Border.all(color: DesignTokens.secondary.withOpacity(0.5), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.eco,
                                color: DesignTokens.primary,
                                size: 20,
                              ),
                              const SizedBox(width: DesignTokens.spacingS),
                              Expanded(
                                child: Text(
                                  'Vegan bonus: +20 beans/day for avoiding all animal products!',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: DesignTokens.foreground,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        fontSize: sizing.bodySmallFontSize, // iPad responsive
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: DesignTokens.spacingXL),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                          border: Border.all(color: DesignTokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Synced instantly',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DesignTokens.foreground,
                                    fontSize: sizing.titleSmallFontSize, // iPad responsive
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '1 bean = 1 gram. Your balance is recalculated as earned - spent.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DesignTokens.mutedText,
                                    height: 1.4,
                                    fontSize: sizing.bodySmallFontSize, // iPad responsive
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _KeyValue(
                              k: 'Impacted days',
                              v: '${state.impactedDays}',
                            ),
                            _KeyValue(
                              k: 'Total saved',
                              v: '${svc.totalSavedGrams} g  (= ${svc.totalSavedBeans} beans)',
                            ),
                            _KeyValue(
                              k: 'Spent (animals)',
                              v: '$totalSpentBeans beans',
                            ),
                            _KeyValue(
                              k: 'Beans balance',
                              v: '${state.beans}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // 4) Sources (expandable)
                _SectionCard(
                  title: 'Sources',
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                      title: Text(
                        'View sources',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.foreground,
                              fontSize: sizing.titleSmallFontSize, // iPad responsive
                            ),
                      ),
                      subtitle: Text(
                        'Daily save basis + animal cost assumptions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.mutedText,
                              height: 1.25,
                              fontSize: sizing.bodySmallFontSize, // iPad responsive
                            ),
                      ),
                      children: [
                        _SourceBlock(
                          title: 'Daily meat saved (default)',
                          lines: const [
                            'USDA ERS per-capita availability (disappearance), retail basis.',
                            '2026 forecast: 227 lb/person/year → about 282 g/day.',
                            'We use 1 bean = 1 g (no scaling).',
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SourceBlock(
                          title: 'Animal cost (low-end / minimum yield)',
                          lines: [
                            'We use conservative minimum yields to keep exchanges achievable.',
                            ...AnimalType.values.expand((t) sync* {
                              final info = t.sourceInfo;
                              yield '${t.name}: ${info.originalRange} → ${info.convertedGrams}';
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // 5) Reset Animals
                _SectionCard(
                  title: 'Reset Animals',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clear all redeemed animals and refund the beans spent on them.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.mutedText,
                              height: 1.4,
                              fontSize: sizing.bodySmallFontSize, // iPad responsive
                            ),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _showResetAnimalsDialog(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE57373),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reset animals'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // 6) Reset / Data
                _SectionCard(
                  title: 'Reset / Data',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This clears all local data on this device. No login, no cloud sync.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.mutedText,
                              height: 1.4,
                              fontSize: sizing.bodySmallFontSize, // iPad responsive
                            ),
                      ),
                      const SizedBox(height: DesignTokens.spacingL),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _showResetDialog(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reset all data'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: DesignTokens.spacingL),

                // 7) Privacy & Support
                _SectionCard(
                  title: 'Privacy & Support',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Privacy Policy
                      _RowAction(
                        title: 'Privacy Policy',
                        subtitle: 'View our privacy policy',
                        onTap: () => _launchUrl(_privacyPolicyUrl),
                      ),
                      const Divider(height: 24),
                      // Support
                      _RowAction(
                        title: 'Support',
                        subtitle: 'Get help and FAQs',
                        onTap: () => _launchUrl(_supportUrl),
                      ),
                      const Divider(height: 24),
                      // Email Support
                      _RowAction(
                        title: 'Email Support',
                        subtitle: _supportEmail,
                        onTap: () => _launchSupportEmail(),
                      ),
                      SizedBox(height: sizing.spacingL), // iPad responsive fix
                      // Privacy statement
                      Text(
                        'We do not collect or track personal data.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DesignTokens.mutedText.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              fontSize: sizing.bodySmallFontSize, // iPad responsive
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // 8) Debug Device Info (only in debug mode)
                if (kDebugMode) ...[
                  SizedBox(height: sizing.spacingL),
                  const DebugDeviceInfo(),
                ],
              ],
            ),
              ), // iPad responsive fix: close ConstrainedBox
            ), // iPad responsive fix: close Center
          ),
        );
      },
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final state = AppStateService.instance.state;
    final DateTime selectedDate = state.startDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      await AppStateService.instance.updateStartDate(picked);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date updated'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveDailyMeat(BuildContext context) async {
    final parsed = int.tryParse(_dailyMeatController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await AppStateService.instance.updateDailyMeatSavedGrams(parsed);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily save updated'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showResetAnimalsDialog(BuildContext context) async {
    final svc = AppStateService.instance;
    final totalSpent = _calculateTotalSpentBeans(svc.state.animalCounts);
    final totalAnimals = svc.state.animalCounts.values.fold<int>(0, (a, b) => a + b);
    
    if (totalAnimals == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No animals to reset'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset animals?'),
        content: Text(
          'This will remove all $totalAnimals animals from your sanctuary and refund $totalSpent beans.\n\n'
          'Your start date, nickname, and diet type will not be affected.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await svc.resetAnimals();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Animals reset, $totalSpent beans refunded'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• Start date\n'
          '• Nickname\n'
          '• Diet type\n'
          '• Custom daily save setting\n'
          '• All beans and animals\n\n'
          'You will return to the onboarding screen. This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppStateService.instance.resetData();
      if (mounted) {
        widget.onReset?.call();
      }
    }
  }

  int _calculateTotalSpentBeans(Map<AnimalType, int> counts) {
    var total = 0;
    for (final entry in counts.entries) {
      total += entry.value * entry.key.cost;
    }
    return total;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchSupportEmail() async {
    final uri = Uri.parse('mailto:$_supportEmail?subject=Vegan%20Days%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing(context); // iPad responsive
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DesignTokens.foreground,
                    letterSpacing: -0.2,
                    fontSize: sizing.titleLargeFontSize, // iPad responsive
                  ),
            ),
            const SizedBox(height: DesignTokens.spacingL),
            child,
          ],
        ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RowAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing(context); // iPad responsive
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.foreground,
                            fontSize: sizing.titleSmallFontSize, // iPad responsive
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.mutedText,
                            height: 1.2,
                            fontSize: sizing.bodySmallFontSize, // iPad responsive
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: DesignTokens.mutedText.withOpacity(0.9), size: sizing.isTablet ? 28 : 24), // iPad responsive
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String k;
  final String v;

  const _KeyValue({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing(context); // iPad responsive
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.mutedText,
                    height: 1.2,
                    fontSize: sizing.bodySmallFontSize, // iPad responsive
                  ),
            ),
          ),
          Text(
            v,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.foreground.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontSize: sizing.bodySmallFontSize, // iPad responsive
                ),
          ),
        ],
      ),
    );
  }
}

class _SourceBlock extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _SourceBlock({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final sizing = ResponsiveSizing(context); // iPad responsive
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.foreground,
                  fontSize: sizing.titleSmallFontSize, // iPad responsive
                ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.mutedText,
                          height: 1.35,
                          fontSize: sizing.bodySmallFontSize, // iPad responsive
                        ),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.mutedText,
                            height: 1.35,
                            fontSize: sizing.bodySmallFontSize, // iPad responsive
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

