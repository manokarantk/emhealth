import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Get the current location of the user
  Future<Map<String, dynamic>> getCurrentLocation(BuildContext context) async {
    try {
      print('📍 LocationService: Starting location request...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 LocationService: Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ LocationService: Location services are disabled');
        return {
          'success': false,
          'message': 'Location services are disabled. Please enable location services in your device settings.',
          'error': 'LOCATION_SERVICES_DISABLED',
        };
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 LocationService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 LocationService: Permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        print('📍 LocationService: Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ LocationService: Permission still denied after request');
          return {
            'success': false,
            'message': 'Location permissions are denied. Please grant location permissions to use this feature.',
            'error': 'LOCATION_PERMISSION_DENIED',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ LocationService: Permission denied forever');
        return {
          'success': false,
          'message': 'Location permissions are permanently denied. Please enable location permissions in your device settings.',
          'error': 'LOCATION_PERMISSION_DENIED_FOREVER',
        };
      }

      print('📍 LocationService: Permission granted, getting current position...');
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('📍 LocationService: Position obtained - Lat: ${position.latitude}, Long: ${position.longitude}');

      return {
        'success': true,
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': position.timestamp?.toIso8601String(),
        },
        'message': 'Location retrieved successfully',
      };
    } catch (e) {
      print('❌ LocationService: Exception occurred: $e');
      return {
        'success': false,
        'message': 'Failed to get current location: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Get stored user location from local storage
  Future<Map<String, dynamic>?> getStoredLocation() async {
    try {
      final locationData = await StorageService.getUserLocation();
      if (locationData != null) {
        print('📍 LocationService: Retrieved stored location: $locationData');
        return locationData;
      }
      print('📍 LocationService: No stored location found');
      return null;
    } catch (e) {
      print('❌ LocationService: Error getting stored location: $e');
      return null;
    }
  }

  /// Store user location in local storage
  Future<void> storeLocation(Map<String, dynamic> locationData) async {
    try {
      await StorageService.saveUserLocation(locationData);
      print('📍 LocationService: Location stored successfully: $locationData');
    } catch (e) {
      print('❌ LocationService: Error storing location: $e');
    }
  }

  /// Get current location and store it locally
  Future<Map<String, dynamic>> getAndStoreLocation(BuildContext context) async {
    try {
      print('📍 LocationService: Getting and storing current location...');
      
      final locationResult = await getCurrentLocation(context);
      
      if (locationResult['success'] == true) {
        // Store the location data
        await storeLocation(locationResult['data']);
        print('📍 LocationService: Location retrieved and stored successfully');
      } else {
        print('❌ LocationService: Failed to get location: ${locationResult['message']}');
      }
      
      return locationResult;
    } catch (e) {
      print('❌ LocationService: Error in getAndStoreLocation: $e');
      return {
        'success': false,
        'message': 'Failed to get and store location: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Update stored location (called when user changes location)
  Future<Map<String, dynamic>> updateStoredLocation(BuildContext context) async {
    try {
      print('📍 LocationService: Updating stored location...');
      
      final locationResult = await getCurrentLocation(context);
      
      if (locationResult['success'] == true) {
        // Store the new location data
        await storeLocation(locationResult['data']);
        print('📍 LocationService: Location updated and stored successfully');
      } else {
        print('❌ LocationService: Failed to update location: ${locationResult['message']}');
      }
      
      return locationResult;
    } catch (e) {
      print('❌ LocationService: Error in updateStoredLocation: $e');
      return {
        'success': false,
        'message': 'Failed to update stored location: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Get stored location coordinates for API calls
  Future<Map<String, double>?> getStoredCoordinates() async {
    try {
      final locationData = await getStoredLocation();
      if (locationData != null && 
          locationData['latitude'] != null && 
          locationData['longitude'] != null) {
        return {
          'latitude': locationData['latitude'].toDouble(),
          'longitude': locationData['longitude'].toDouble(),
        };
      }
      return null;
    } catch (e) {
      print('❌ LocationService: Error getting stored coordinates: $e');
      return null;
    }
  }

  /// Clear stored location
  Future<void> clearStoredLocation() async {
    try {
      await StorageService.clearUserLocation();
      print('📍 LocationService: Stored location cleared successfully');
    } catch (e) {
      print('❌ LocationService: Error clearing stored location: $e');
    }
  }
} 