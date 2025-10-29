import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/intro_service.dart';
import '../services/token_service.dart';
import '../services/location_service.dart';

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

    // Initialize location and check authentication/intro status, then navigate accordingly
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        // Initialize location service and get stored location
        final locationService = LocationService();
        
        // Check if we have stored location, if not, try to get it
        final storedLocation = await locationService.getStoredLocation();
        if (storedLocation == null) {
          print('📍 SplashScreen: No stored location found, attempting to get current location...');
          try {
            await locationService.getAndStoreLocation(context);
            print('📍 SplashScreen: Location initialized successfully');
          } catch (e) {
            print('📍 SplashScreen: Failed to initialize location: $e');
            // Continue without location - user can update it later
          }
        } else {
          print('📍 SplashScreen: Using stored location: $storedLocation');
        }
        
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
    // Make the logo bigger and ensure it's centered in the screen
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: SizedBox.expand(
            child: Center(
              child: Container(
                width: 200, // Increased size for bigger logo
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/applogo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 