// Basic widget tests for Vegan Days app
//
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vegan_days/main.dart';
import 'package:vegan_days/services/app_state_service.dart';

void main() {
  setUpAll(() async {
    // Initialize SharedPreferences mock
    SharedPreferences.setMockInitialValues({
      'start_date': '2024-01-01',
      'onboarding_completed': true,
      'diet_type': 'vegetarian',
      'daily_meat_saved_grams': 282,
    });
    await AppStateService.instance.initialize();
  });

  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // App should launch without throwing exceptions
    expect(tester.takeException(), isNull);
  });

  testWidgets('App shows splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Splash screen should show app name
    expect(find.text('Vegan Days'), findsOneWidget);
    
    // Allow pending timers to complete (splash animation)
    await tester.pump(const Duration(seconds: 2));
  });
}
