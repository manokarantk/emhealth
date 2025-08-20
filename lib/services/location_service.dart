import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

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
} 