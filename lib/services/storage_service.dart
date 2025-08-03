import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _introSeenKey = 'intro_seen';
  static const String _cartItemsKey = 'cart_items';
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