# Location Storage System Implementation

## Overview

This implementation provides an efficient approach to handle user location in the EmHealth Flutter app by storing location data locally and retrieving it when needed for API calls, instead of fetching location on every API request.

## Key Features

### 🎯 **Efficient Location Management**
- **One-time location fetch**: Location is retrieved once when the app starts
- **Local storage**: Location data is stored locally using SharedPreferences and file storage
- **Automatic updates**: Location is updated when user changes their location
- **Fallback support**: Works even if location services are disabled

### 📍 **Location Storage Flow**

1. **App Startup** (`SplashScreen`):
   - Checks for stored location
   - If no stored location, attempts to get current GPS location
   - Stores location data locally

2. **Location Selection** (`LocationSelectionScreen`):
   - User selects a city from Tamil Nadu
   - Coordinates are mapped to the selected city
   - New location is stored locally

3. **API Calls** (`ApiService`):
   - Automatically uses stored location coordinates
   - No need to pass location parameters manually
   - Falls back gracefully if no location is available

## Implementation Details

### Enhanced Services

#### 1. **StorageService** (`lib/services/storage_service.dart`)
```dart
// New location storage methods
static Future<Map<String, dynamic>?> getUserLocation()
static Future<void> saveUserLocation(Map<String, dynamic> locationData)
static Future<void> clearUserLocation()
```

#### 2. **LocationService** (`lib/services/location_service.dart`)
```dart
// New methods for stored location management
Future<Map<String, dynamic>?> getStoredLocation()
Future<void> storeLocation(Map<String, dynamic> locationData)
Future<Map<String, dynamic>> getAndStoreLocation(BuildContext context)
Future<Map<String, dynamic>> updateStoredLocation(BuildContext context)
Future<Map<String, double>?> getStoredCoordinates()
Future<void> clearStoredLocation()
```

#### 3. **ApiService** (`lib/services/api_service.dart`)
```dart
// Enhanced API method that automatically uses stored location
Future<Map<String, dynamic>> getOrganizationsProvidersWithStoredLocation({
  required List<String> testIds,
  required List<String> packageIds,
})
```

### Location Data Structure

```dart
{
  'latitude': 13.0827,
  'longitude': 80.2707,
  'city': 'Chennai',
  'timestamp': '2024-01-15T10:30:00.000Z',
  'accuracy': 10.0,
  'altitude': 0.0,
  'speed': 0.0,
  'heading': 0.0,
}
```

### Tamil Nadu City Coordinates

The system includes coordinates for all major Tamil Nadu cities:
- Chennai, Coimbatore, Madurai, Salem, Tiruchirappalli
- Vellore, Erode, Tiruppur, Thoothukkudi, Dindigul
- Thanjavur, Villupuram, Cuddalore, Kanchipuram
- And many more...

## Usage Examples

### 1. **Getting Stored Location**
```dart
final locationService = LocationService();
final storedLocation = await locationService.getStoredLocation();

if (storedLocation != null) {
  print('Stored location: ${storedLocation['city']}');
  print('Coordinates: ${storedLocation['latitude']}, ${storedLocation['longitude']}');
}
```

### 2. **Updating Location When User Changes City**
```dart
// This is automatically handled in LandingPage when user selects a new city
onLocationSelected: (String city) async {
  final cityCoordinates = _getCityCoordinates(city);
  if (cityCoordinates != null) {
    final locationData = {
      'latitude': cityCoordinates['latitude'],
      'longitude': cityCoordinates['longitude'],
      'city': city,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await locationService.storeLocation(locationData);
  }
}
```

### 3. **Using Stored Location in API Calls**
```dart
// Old way (requires manual location parameters)
final result = await apiService.getOrganizationsProviders(
  testIds: ['test1', 'test2'],
  packageIds: ['package1'],
  latitude: 13.0827,
  longitude: 80.2707,
);

// New way (automatically uses stored location)
final result = await apiService.getOrganizationsProvidersWithStoredLocation(
  testIds: ['test1', 'test2'],
  packageIds: ['package1'],
);
```

## Benefits

### ✅ **Performance Improvements**
- **Reduced API calls**: No need to fetch location on every request
- **Faster response times**: Stored location is instantly available
- **Reduced battery usage**: Fewer GPS requests

### ✅ **Better User Experience**
- **Seamless operation**: App works even without GPS
- **Consistent location**: Same location used across all features
- **Offline support**: Location data persists between app sessions

### ✅ **Developer Experience**
- **Simplified API calls**: No need to manage location parameters
- **Automatic fallbacks**: Graceful handling of missing location
- **Centralized management**: All location logic in one place

## Error Handling

The system includes comprehensive error handling:

1. **Location Services Disabled**: App continues with stored location
2. **Permission Denied**: User can still select cities manually
3. **Network Issues**: Stored location is used as fallback
4. **Storage Failures**: Multiple storage mechanisms (SharedPreferences + File)

## Migration Guide

### For Existing Code

1. **Replace manual location fetching**:
   ```dart
   // Old
   final location = await LocationService().getCurrentLocation(context);
   
   // New
   final storedLocation = await LocationService().getStoredLocation();
   ```

2. **Update API calls**:
   ```dart
   // Old
   final result = await apiService.getOrganizationsProviders(
     testIds: testIds,
     packageIds: packageIds,
     latitude: latitude,
     longitude: longitude,
   );
   
   // New
   final result = await apiService.getOrganizationsProvidersWithStoredLocation(
     testIds: testIds,
     packageIds: packageIds,
   );
   ```

3. **Location updates**: Use the new storage methods when location changes

## Testing

The implementation includes extensive logging for debugging:
- Location storage/retrieval operations
- API calls with stored location
- Error scenarios and fallbacks

Check the console logs for detailed information about location operations.

## Future Enhancements

1. **Location caching with expiration**
2. **Background location updates**
3. **Location accuracy improvements**
4. **Geofencing support**
5. **Location analytics**

---

This implementation provides a robust, efficient, and user-friendly approach to location management in the EmHealth app.
