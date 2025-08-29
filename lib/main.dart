import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/profile_completion_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_page.dart';
import 'theme/app_theme.dart';
import 'widgets/notification_test_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await SharedPreferences.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmHealth',
      theme: AppTheme.lightTheme.copyWith(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
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
