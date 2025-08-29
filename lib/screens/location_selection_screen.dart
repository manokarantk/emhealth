import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';

/// LocationSelectionScreen
/// 
/// A comprehensive location selection screen for Tamil Nadu with primary color theme.
/// Features:
/// - Primary color theme with search functionality
/// - Current location detection using GPS (Tamil Nadu focused)
/// - Popular Tamil Nadu cities grid with custom icons
/// - Complete list of all Tamil Nadu cities with search filtering
/// - Permission handling for location services
/// 
/// Usage:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => LocationSelectionScreen(
///       currentLocation: 'Delhi',
///       onLocationSelected: (String city) {
///         // Handle the selected city
///         print('Selected city: $city');
///       },
///     ),
///   ),
/// );
/// ```
/// 
/// Parameters:
/// - currentLocation: The currently selected location (optional)
/// - onLocationSelected: Callback function that receives the selected city name
/// 
/// The screen automatically handles:
/// - Location permissions
/// - GPS service availability
/// - Search functionality
/// - Error states and user feedback
class LocationSelectionScreen extends StatefulWidget {
  final String? currentLocation;
  final Function(String) onLocationSelected;

  const LocationSelectionScreen({
    super.key,
    this.currentLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingLocation = false;
  List<String> _filteredCities = [];
  bool _isSearching = false;

  // Popular cities with their icons
  final List<Map<String, dynamic>> _popularCities = [
    {
      'name': 'Chennai',
      'icon': Icons.location_city,
      'iconColor': Colors.orange,
    },
    {
      'name': 'Coimbatore',
      'icon': Icons.location_city,
      'iconColor': Colors.blue,
    },
    {
      'name': 'Madurai',
      'icon': Icons.location_city,
      'iconColor': Colors.purple,
    },
    {
      'name': 'Salem',
      'icon': Icons.location_city,
      'iconColor': Colors.green,
    },
    {
      'name': 'Tiruchirappalli',
      'icon': Icons.location_city,
      'iconColor': Colors.red,
    },
    {
      'name': 'Vellore',
      'icon': Icons.location_city,
      'iconColor': Colors.teal,
    },
  ];

  // All cities list - Tamil Nadu only
  final List<String> _allCities = [
    'Ariyalur',
    'Chennai',
    'Coimbatore',
    'Cuddalore',
    'Dharmapuri',
    'Dindigul',
    'Erode',
    'Kanchipuram',
    'Kanyakumari',
    'Karur',
    'Krishnagiri',
    'Madurai',
    'Nagapattinam',
    'Namakkal',
    'Nilgiris',
    'Perambalur',
    'Pudukkottai',
    'Ramanathapuram',
    'Salem',
    'Sivaganga',
    'Thanjavur',
    'Theni',
    'Thoothukkudi',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tiruppur',
    'Tiruvallur',
    'Tiruvannamalai',
    'Tiruvarur',
    'Vellore',
    'Villupuram',
    'Virudhunagar',
  ];

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_allCities);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredCities = List.from(_allCities);
      } else {
        _filteredCities = _allCities
            .where((city) => city.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Extract city from coordinates (simplified)
      String cityFromCoordinates = _extractCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Find the closest city from our list
      String selectedCity = _findClosestCity(cityFromCoordinates);
      
      widget.onLocationSelected(selectedCity);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location set to: $selectedCity'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your current location. Please select manually.'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  String _extractCityFromCoordinates(double latitude, double longitude) {
    // This is a simplified implementation for Tamil Nadu coordinates
    // In a real app, you would use reverse geocoding API
    if (latitude >= 13.0 && latitude <= 13.2 && longitude >= 80.2 && longitude <= 80.3) {
      return 'Chennai';
    } else if (latitude >= 11.0 && latitude <= 11.1 && longitude >= 76.9 && longitude <= 77.0) {
      return 'Coimbatore';
    } else if (latitude >= 9.9 && latitude <= 10.0 && longitude >= 78.1 && longitude <= 78.2) {
      return 'Madurai';
    } else if (latitude >= 11.6 && latitude <= 11.7 && longitude >= 78.1 && longitude <= 78.2) {
      return 'Salem';
    } else if (latitude >= 10.8 && latitude <= 10.9 && longitude >= 78.6 && longitude <= 78.7) {
      return 'Tiruchirappalli';
    } else if (latitude >= 12.9 && latitude <= 13.0 && longitude >= 79.1 && longitude <= 79.2) {
      return 'Vellore';
    } else if (latitude >= 8.0 && latitude <= 13.5 && longitude >= 76.0 && longitude <= 80.5) {
      // General Tamil Nadu area - return Chennai as default
      return 'Chennai';
    } else {
      return 'Chennai'; // Default for Tamil Nadu
    }
  }

  String _findClosestCity(String detectedCity) {
    // Find the closest match from our city list
    for (String city in _allCities) {
      if (city.toLowerCase().contains(detectedCity.toLowerCase()) ||
          detectedCity.toLowerCase().contains(city.toLowerCase())) {
        return city;
      }
    }
    return 'Delhi'; // Default fallback
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Location Services Disabled',
            style: TextStyle(color: Colors.black87),
          ),
          content: const Text(
            'Please enable location services to automatically detect your city.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Location Permission Required',
            style: TextStyle(color: Colors.black87),
          ),
          content: const Text(
            'Please grant location permission to automatically detect your city.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black87),
                                  decoration: const InputDecoration(
                    hintText: 'Search cities in Tamil Nadu',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
              ),
            ),
          ),

          // Use Current Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: _isLoadingLocation
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                title: Text(
                  _isLoadingLocation ? 'Getting location...' : 'Use current location',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
                onTap: _isLoadingLocation ? null : _getCurrentLocation,
              ),
            ),
          ),

          const SizedBox(height: 24),

                     // Popular Cities
           if (!_isSearching) ...[
             const Padding(
               padding: EdgeInsets.symmetric(horizontal: 16.0),
               child: Align(
                 alignment: Alignment.centerLeft,
                 child: Text(
                   'Popular cities in Tamil Nadu',
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 18,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _popularCities.length,
                itemBuilder: (context, index) {
                  final city = _popularCities[index];
                  return GestureDetector(
                    onTap: () {
                      widget.onLocationSelected(city['name']);
                      Navigator.of(context).pop();
                    },
                                         child: Container(
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(
                           color: AppColors.primaryBlue.withOpacity(0.2),
                           width: 1,
                         ),
                       ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: city['iconColor'].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              city['icon'],
                              color: city['iconColor'],
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                                                     Text(
                             city['name'],
                             style: const TextStyle(
                               color: Colors.black87,
                               fontSize: 14,
                               fontWeight: FontWeight.w500,
                             ),
                             textAlign: TextAlign.center,
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

                     // All Cities
           Expanded(
             child: Container(
               decoration: const BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.only(
                   topLeft: Radius.circular(20),
                   topRight: Radius.circular(20),
                 ),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                     child: Text(
                       'All cities in Tamil Nadu',
                       style: TextStyle(
                         color: Colors.black87,
                         fontSize: 18,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                   Expanded(
                     child: ListView.builder(
                       itemCount: _filteredCities.length,
                       itemBuilder: (context, index) {
                         final city = _filteredCities[index];
                         return Container(
                           decoration: BoxDecoration(
                             border: Border(
                               bottom: BorderSide(
                                 color: Colors.grey.withOpacity(0.3),
                                 width: 0.5,
                               ),
                             ),
                           ),
                           child: ListTile(
                             title: Text(
                               city,
                               style: const TextStyle(
                                 color: Colors.black87,
                                 fontSize: 16,
                               ),
                             ),
                             onTap: () {
                               widget.onLocationSelected(city);
                               Navigator.of(context).pop();
                             },
                           ),
                         );
                       },
                     ),
                   ),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }
}
