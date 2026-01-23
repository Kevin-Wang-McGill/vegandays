// iPad Layout Tests
// 
// These tests verify that key pages render without overflow errors
// on tablet-sized screens (iPad Air 11", iPad Pro 11", iPad Pro 12.9")
//
// Run with: flutter test test/ipad_layout_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vegan_days/screens/home_screen.dart';
import 'package:vegan_days/screens/settings_screen.dart';
import 'package:vegan_days/screens/onboarding/onboarding_step1_start_date.dart';
import 'package:vegan_days/screens/onboarding/onboarding_step3_diet_type.dart';
import 'package:vegan_days/services/app_state_service.dart';

/// Test wrapper that provides MediaQuery with specific device size
Widget buildTestableWidget({
  required Widget child,
  required Size screenSize,
  EdgeInsets padding = EdgeInsets.zero,
  double textScaleFactor = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: screenSize,
      padding: padding,
      viewPadding: padding,
      textScaleFactor: textScaleFactor,
      devicePixelRatio: 2.0,
    ),
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Common device sizes for testing
class TestDeviceSizes {
  // Phone sizes
  static const Size iPhone14 = Size(390, 844);
  static const Size iPhone14ProMax = Size(430, 932);
  
  // Tablet sizes (iPad)
  static const Size iPadAir11Portrait = Size(820, 1180);
  static const Size iPadAir11Landscape = Size(1180, 820);
  static const Size iPadPro11Portrait = Size(834, 1194);
  static const Size iPadPro11Landscape = Size(1194, 834);
  static const Size iPadPro129Portrait = Size(1024, 1366);
  static const Size iPadPro129Landscape = Size(1366, 1024);
  
  // Safe area insets for iPad
  static const EdgeInsets iPadSafeArea = EdgeInsets.only(top: 24, bottom: 20);
  static const EdgeInsets iPadLandscapeSafeArea = EdgeInsets.only(left: 24, right: 20);
}

void main() {
  // Initialize SharedPreferences mock before all tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'start_date': '2024-01-01',
      'onboarding_completed': true,
      'diet_type': 'vegetarian',
      'daily_meat_saved_grams': 282,
    });
    await AppStateService.instance.initialize();
  });

  group('iPad Portrait Layout Tests', () {
    testWidgets('HomeScreen renders without overflow on iPad Air 11" Portrait', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      // Use pump with duration instead of pumpAndSettle (HomeScreen has continuous animations)
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify no overflow errors (test will fail if RenderFlex overflow occurs)
      expect(tester.takeException(), isNull);
      
      // Verify key UI elements are present
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('HomeScreen renders without overflow on iPad Pro 11" Portrait', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadPro11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(tester.takeException(), isNull);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('HomeScreen renders without overflow on iPad Pro 12.9" Portrait', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadPro129Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(tester.takeException(), isNull);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without overflow on iPad Air 11" Portrait', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const SettingsScreen(),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without overflow on iPad Pro 12.9" Portrait', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const SettingsScreen(),
          screenSize: TestDeviceSizes.iPadPro129Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('iPad Landscape Layout Tests', () {
    testWidgets('HomeScreen renders without overflow on iPad Air 11" Landscape', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadAir11Landscape,
          padding: TestDeviceSizes.iPadLandscapeSafeArea,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(tester.takeException(), isNull);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('HomeScreen renders without overflow on iPad Pro 11" Landscape', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadPro11Landscape,
          padding: TestDeviceSizes.iPadLandscapeSafeArea,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(tester.takeException(), isNull);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without overflow on iPad Pro 11" Landscape', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const SettingsScreen(),
          screenSize: TestDeviceSizes.iPadPro11Landscape,
          padding: TestDeviceSizes.iPadLandscapeSafeArea,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('iPad with Large Text Scale Factor Tests', () {
    testWidgets('HomeScreen renders without overflow with textScaleFactor 1.2', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
          textScaleFactor: 1.2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(tester.takeException(), isNull);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('HomeScreen renders without overflow with textScaleFactor 1.4', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const HomeScreen(),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
          textScaleFactor: 1.4,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      
      expect(tester.takeException(), isNull);
      expect(find.text('Check in'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders without overflow with textScaleFactor 1.4', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const SettingsScreen(),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
          textScaleFactor: 1.4,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Onboarding iPad Layout Tests', () {
    testWidgets('OnboardingStep1 renders without overflow on iPad', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OnboardingStep1StartDate(
            initialDate: DateTime.now(),
            onDateSelected: (_) {},
            onContinue: () {},
          ),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to Vegan Days'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('OnboardingStep3 renders without overflow on iPad', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OnboardingStep3DietType(
            onDietTypeChanged: (_) {},
            onContinue: () {},
            onBack: () {},
          ),
          screenSize: TestDeviceSizes.iPadAir11Portrait,
          padding: TestDeviceSizes.iPadSafeArea,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text("What's your diet type?"), findsOneWidget);
      expect(find.text('Vegetarian'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
    });

    testWidgets('OnboardingStep1 renders without overflow on iPad Landscape', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: OnboardingStep1StartDate(
            initialDate: DateTime.now(),
            onDateSelected: (_) {},
            onContinue: () {},
          ),
          screenSize: TestDeviceSizes.iPadAir11Landscape,
          padding: TestDeviceSizes.iPadLandscapeSafeArea,
        ),
      );
      await tester.pumpAndSettle();
      
      expect(tester.takeException(), isNull);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}

