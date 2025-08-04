import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/intro_service.dart';
import '../services/token_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Check authentication and intro status, then navigate accordingly
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final isAuthenticated = await TokenService.isAuthenticated();
        final hasSeenIntro = await IntroService.hasSeenIntro();
        
        if (mounted) {
          if (isAuthenticated) {
            // User has valid auth token, go directly to homepage
            print('DEBUG: User is authenticated, navigating to homepage');
            Navigator.pushReplacementNamed(context, '/landing');
          } else if (hasSeenIntro) {
            // User has seen intro but not authenticated, go to login
            print('DEBUG: User has seen intro but not authenticated, navigating to login');
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            // User hasn't seen intro, show intro screen
            print('DEBUG: User hasn\'t seen intro, navigating to intro screen');
            Navigator.pushReplacementNamed(context, '/intro');
          }
        }
      } catch (e) {
        print('DEBUG: Error checking authentication/intro status: $e');
        // Fallback: show intro screen if there's an error
        if (mounted) {
          print('DEBUG: Fallback - navigating to intro screen');
      Navigator.pushReplacementNamed(context, '/intro');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                'EmHealth',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Health, Our Priority',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 