import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  // Save authentication token
  static Future<void> saveToken(String token, {String? refreshToken, DateTime? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      
      if (expiry != null) {
        await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
      }
      
      print('DEBUG: TokenService - Token saved successfully');
    } catch (e) {
      print('DEBUG: TokenService - Error saving token: $e');
    }
  }
  
  // Get authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print('DEBUG: TokenService - Token retrieved: ${token != null ? 'Yes' : 'No'}');
      return token;
    } catch (e) {
      print('DEBUG: TokenService - Error getting token: $e');
      return null;
    }
  }
  
  // Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('DEBUG: TokenService - Error getting refresh token: $e');
      return null;
    }
  }
  
  // Check if token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_tokenExpiryKey);
      
      if (expiryString == null) return false; // No expiry set, assume valid
      
      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();
      
      return now.isAfter(expiry);
    } catch (e) {
      print('DEBUG: TokenService - Error checking token expiry: $e');
      return false; // Assume valid if error
    }
  }
  
  // Clear all tokens (logout)
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      print('DEBUG: TokenService - All tokens cleared');
    } catch (e) {
      print('DEBUG: TokenService - Error clearing tokens: $e');
    }
  }
  
  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      final isExpired = await isTokenExpired();
      return !isExpired;
    } catch (e) {
      print('DEBUG: TokenService - Error checking authentication: $e');
      return false;
    }
  }
} 