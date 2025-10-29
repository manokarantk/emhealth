import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _introSeenKey = 'intro_seen';
  static const String _cartItemsKey = 'cart_items';
  static const String _userLocationKey = 'user_location';
  static const String _userProfileKey = 'user_profile';
  static const String _storageFileName = 'app_storage.json';
  
  // Try SharedPreferences first, fallback to file storage
  static Future<bool> hasSeenIntro() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_introSeenKey);
      if (hasSeen != null) {
        print('DEBUG: StorageService - Using SharedPreferences, hasSeenIntro: $hasSeen');
        return hasSeen;
      }
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed: $e');
    }
    
    // Fallback to file storage
    try {
      final hasSeen = await _readFromFile(_introSeenKey);
      print('DEBUG: StorageService - Using file storage, hasSeenIntro: $hasSeen');
      return hasSeen == true;
    } catch (e) {
      print('DEBUG: StorageService - File storage failed: $e');
      return false; // Default to showing intro
    }
  }
  
  static Future<void> markIntroAsSeen() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introSeenKey, true);
      print('DEBUG: StorageService - Marked intro as seen in SharedPreferences');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
      // Fallback to file storage
      try {
        await _writeToFile(_introSeenKey, true);
        print('DEBUG: StorageService - Marked intro as seen in file storage');
      } catch (e) {
        print('DEBUG: StorageService - File storage also failed: $e');
      }
    }
  }
  
  static Future<void> resetIntro() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_introSeenKey);
      print('DEBUG: StorageService - Reset intro in SharedPreferences');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
    }
    
    // Also reset in file storage
    try {
      await _writeToFile(_introSeenKey, false);
      print('DEBUG: StorageService - Reset intro in file storage');
    } catch (e) {
      print('DEBUG: StorageService - File storage reset failed: $e');
    }
  }

  // Cart persistence methods
  static Future<Set<String>> getCartItems() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final cartItemsList = prefs.getStringList(_cartItemsKey);
      if (cartItemsList != null) {
        print('DEBUG: StorageService - Using SharedPreferences, cartItems: $cartItemsList');
        return Set<String>.from(cartItemsList);
      }
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed: $e');
    }
    
    // Fallback to file storage
    try {
      final cartItemsList = await _readFromFile(_cartItemsKey);
      if (cartItemsList is List) {
        print('DEBUG: StorageService - Using file storage, cartItems: $cartItemsList');
        return Set<String>.from(cartItemsList.cast<String>());
      }
    } catch (e) {
      print('DEBUG: StorageService - File storage failed: $e');
    }
    
    return <String>{}; // Return empty set if no data found
  }

  static Future<void> saveCartItems(Set<String> cartItems) async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_cartItemsKey, cartItems.toList());
      print('DEBUG: StorageService - Saved cartItems in SharedPreferences: $cartItems');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
      // Fallback to file storage
      try {
        await _writeToFile(_cartItemsKey, cartItems.toList());
        print('DEBUG: StorageService - Saved cartItems in file storage: $cartItems');
      } catch (e) {
        print('DEBUG: StorageService - File storage also failed: $e');
      }
    }
  }

  static Future<void> clearCart() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartItemsKey);
      print('DEBUG: StorageService - Cleared cart in SharedPreferences');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
    }
    
    // Also clear in file storage
    try {
      await _writeToFile(_cartItemsKey, <String>[]);
      print('DEBUG: StorageService - Cleared cart in file storage');
    } catch (e) {
      print('DEBUG: StorageService - File storage clear failed: $e');
    }
  }

  // Location storage methods
  static Future<Map<String, dynamic>?> getUserLocation() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final locationString = prefs.getString(_userLocationKey);
      if (locationString != null) {
        final locationData = json.decode(locationString) as Map<String, dynamic>;
        print('DEBUG: StorageService - Using SharedPreferences, userLocation: $locationData');
        return locationData;
      }
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed: $e');
    }
    
    // Fallback to file storage
    try {
      final locationData = await _readFromFile(_userLocationKey);
      if (locationData is Map<String, dynamic>) {
        print('DEBUG: StorageService - Using file storage, userLocation: $locationData');
        return locationData;
      }
    } catch (e) {
      print('DEBUG: StorageService - File storage failed: $e');
    }
    
    return null; // Return null if no location data found
  }

  static Future<void> saveUserLocation(Map<String, dynamic> locationData) async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userLocationKey, json.encode(locationData));
      print('DEBUG: StorageService - Saved userLocation in SharedPreferences: $locationData');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
      // Fallback to file storage
      try {
        await _writeToFile(_userLocationKey, locationData);
        print('DEBUG: StorageService - Saved userLocation in file storage: $locationData');
      } catch (e) {
        print('DEBUG: StorageService - File storage also failed: $e');
      }
    }
  }

  static Future<void> clearUserLocation() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userLocationKey);
      print('DEBUG: StorageService - Cleared userLocation in SharedPreferences');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
    }
    
    // Also clear in file storage
    try {
      await _writeToFile(_userLocationKey, null);
      print('DEBUG: StorageService - Cleared userLocation in file storage');
    } catch (e) {
      print('DEBUG: StorageService - File storage clear failed: $e');
    }
  }

  // Profile storage methods
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString(_userProfileKey);
      if (profileString != null) {
        final profileData = json.decode(profileString) as Map<String, dynamic>;
        print('DEBUG: StorageService - Using SharedPreferences, userProfile: $profileData');
        return profileData;
      }
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed: $e');
    }
    
    // Fallback to file storage
    try {
      final profileData = await _readFromFile(_userProfileKey);
      if (profileData is Map<String, dynamic>) {
        print('DEBUG: StorageService - Using file storage, userProfile: $profileData');
        return profileData;
      }
    } catch (e) {
      print('DEBUG: StorageService - File storage failed: $e');
    }
    
    return null; // Return null if no profile data found
  }

  static Future<void> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileKey, json.encode(profileData));
      print('DEBUG: StorageService - Saved userProfile in SharedPreferences: $profileData');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
      // Fallback to file storage
      try {
        await _writeToFile(_userProfileKey, profileData);
        print('DEBUG: StorageService - Saved userProfile in file storage: $profileData');
      } catch (e) {
        print('DEBUG: StorageService - File storage also failed: $e');
      }
    }
  }

  static Future<void> clearUserProfile() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      print('DEBUG: StorageService - Cleared userProfile in SharedPreferences');
    } catch (e) {
      print('DEBUG: StorageService - SharedPreferences failed, trying file storage: $e');
    }
    
    // Also clear in file storage
    try {
      await _writeToFile(_userProfileKey, null);
      print('DEBUG: StorageService - Cleared userProfile in file storage');
    } catch (e) {
      print('DEBUG: StorageService - File storage clear failed: $e');
    }
  }
  
  // File storage methods
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  
  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_storageFileName');
  }
  
  static Future<dynamic> _readFromFile(String key) async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = json.decode(contents) as Map<String, dynamic>;
        return data[key];
      }
      return null;
    } catch (e) {
      print('DEBUG: StorageService - Error reading from file: $e');
      return null;
    }
  }
  
  static Future<void> _writeToFile(String key, dynamic value) async {
    try {
      final file = await _localFile;
      Map<String, dynamic> data = {};
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        data = json.decode(contents) as Map<String, dynamic>;
      }
      
      data[key] = value;
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print('DEBUG: StorageService - Error writing to file: $e');
    }
  }
} 