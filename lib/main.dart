import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/profile_completion_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_page.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'widgets/notification_test_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  
  // Initialize Firebase notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('❌ Failed to initialize notifications: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmHealth',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/profile-completion': (context) => const ProfileCompletionScreen(),
        '/home': (context) => const HomeScreen(),
        '/landing': (context) => const LandingPage(),
        '/notification-test': (context) => const NotificationTestWidget(),
        // Add more routes as needed
      },
    );
  }
}
