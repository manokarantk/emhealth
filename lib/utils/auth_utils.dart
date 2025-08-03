import 'package:flutter/material.dart';
import '../services/token_service.dart';

class AuthUtils {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Handle token expiration and logout
  static Future<void> handleTokenExpiration(BuildContext context) async {
    try {
      // Clear all tokens
      await TokenService.clearTokens();
      
      // Show logout message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Error handling token expiration: $e');
    }
  }
  
  // Check if response indicates token expiration
  static bool isTokenExpiredResponse(Map<String, dynamic> response) {
    final statusCode = response['statusCode'] ?? response['code'];
    final message = response['message']?.toString().toLowerCase() ?? '';
    
    return statusCode == 401 || 
           message.contains('token expired') ||
           message.contains('unauthorized') ||
           message.contains('invalid token');
  }
  
  // Global logout function
  static Future<void> logout(BuildContext context) async {
    try {
      // Clear all tokens
      await TokenService.clearTokens();
      
      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }
} 