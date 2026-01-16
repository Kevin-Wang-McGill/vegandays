import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_state_service.dart';
import 'constants/prefs_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStateService.instance.initialize();
  runApp(const MyApp());
}

/// Precache splash image to avoid loading delay
Future<void> precacheSplashImage(BuildContext context) async {
  await precacheImage(const AssetImage('assets/APP_Icon.png'), context);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vegan Days',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito', // Local font (no CDN requests)
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFED845E),
          secondary: const Color(0xFFCDE4DD),
          surface: const Color(0xFFFAF8F4),
          background: const Color(0xFFF1F6F9),
          error: const Color(0xFFD32F2F),
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF533D2D),
          onSurface: const Color(0xFF533D2D),
          onBackground: const Color(0xFF533D2D),
          outline: const Color(0xFFD9E3E8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F6F9),
        cardTheme: CardThemeData(
          color: const Color(0xFFFAF8F4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        // Typography with Nunito - light and airy feel
        textTheme: const TextTheme(
          // Display styles (largest)
          displayLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
          displayMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, letterSpacing: -0.25, height: 1.2),
          displaySmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.2),
          // Headline styles
          headlineLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.3),
          headlineMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.3),
          headlineSmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.3),
          // Title styles
          titleLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, letterSpacing: 0.15, height: 1.4),
          titleMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.4),
          titleSmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
          // Body styles (main content)
          bodyLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5),
          bodyMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.5),
          bodySmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.5),
          // Label styles (buttons, captions)
          labelLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4),
          labelMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.4),
          labelSmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.4),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 64.0,
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            return const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            return const IconThemeData(
              size: 22.0,
            );
          }),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _hasOnboarded = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // Check new onboarding key first, fallback to legacy key for migration
    final hasOnboarded = prefs.getBool(PrefsKeys.onboardingCompleted) ?? 
                        prefs.getBool(PrefsKeys.hasOnboarded) ?? 
                        false;
    if (mounted) {
      setState(() {
        _hasOnboarded = hasOnboarded;
      });
    }
  }

  void _refreshOnboarding() {
    _checkOnboarding();
  }

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen first
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    if (!_hasOnboarded) {
      return OnboardingFlow(
        onComplete: () async {
          // Onboarding completion is handled in OnboardingFlow
          // Just refresh the state here
          await AppStateService.instance.initialize();
          if (mounted) {
            setState(() {
              _hasOnboarded = true;
            });
          }
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          SettingsScreen(
            onReset: () {
              _refreshOnboarding();
            },
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 64.0, // Reduced from default ~80px, but still >= 48dp per tab
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          height: 64.0, // Explicit height
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22.0), // Reduced from default 24
              selectedIcon: Icon(Icons.home, size: 22.0),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, size: 22.0),
              selectedIcon: Icon(Icons.settings, size: 22.0),
              label: 'Settings',
            ),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }
}

