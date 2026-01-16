import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Image.asset(
                'assets/APP_Icon.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading APP_Icon.png: $error');
                  return Container(
                    width: 112,
                    height: 112,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, size: 48),
                  );
                },
              ),
              const SizedBox(height: 20),
              // App Name
              Text(
                'Vegan Days',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
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
