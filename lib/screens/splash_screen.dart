import 'package:flutter/material.dart';
import '../theme/responsive_sizing.dart'; // iPad responsive fix

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();

    // Fade-out animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imageLoaded) {
      _imageLoaded = true;
      // Precache image first, then start timer
      precacheImage(const AssetImage('assets/APP_Icon.png'), context).then((_) {
        if (mounted) {
          // Wait, then fade out, then navigate
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              _fadeController.forward().then((_) {
                if (mounted) {
                  widget.onComplete();
                }
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // iPad responsive fix: add responsive sizing
    final sizing = ResponsiveSizing(context);
    final iconSize = sizing.splashIconSize;
    final fontSize = sizing.isTablet ? 32.0 : 24.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon - iPad responsive fix: dynamic size
              Image.asset(
                'assets/APP_Icon.png',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading APP_Icon.png: $error');
                  return Container(
                    width: iconSize,
                    height: iconSize,
                    color: Colors.grey[200],
                    child: Icon(Icons.error, size: iconSize * 0.4),
                  );
                },
              ),
              SizedBox(height: sizing.spacingXL), // iPad responsive fix
              // App Name - iPad responsive fix: dynamic font size
              Text(
                'Vegan Days',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900, // Extra bold
                  color: const Color(0xFF533D2D),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
