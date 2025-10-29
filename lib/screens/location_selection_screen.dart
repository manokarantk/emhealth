import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

/// LocationSelectionScreen
/// 
/// A comprehensive location selection screen with primary color theme.
/// Features:
/// - Primary color theme with search functionality
/// - Current location detection using GPS
/// - Dynamic area list fetched from API (/areas/search endpoint)
/// - Real-time search with API integration
/// - Permission handling for location services
/// - Loading states and error handling
/// 
/// Usage:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => LocationSelectionScreen(
///       currentLocation: 'Chennai',
///       onLocationSelected: (String area) {
///         // Handle the selected area
///         print('Selected area: $area');
///       },
///     ),
///   ),
/// );
/// ```
/// 
/// Parameters:
/// - currentLocation: The currently selected location (optional)
/// - onLocationSelected: Callback function that receives the selected area name
/// 
/// The screen automatically handles:
/// - Location permissions
/// - GPS service availability
/// - API-based area search
/// - Loading states and error handling
/// - Network connectivity issues
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
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _filteredAreas = [];
  bool _isSearching = false;
  bool _isLoadingAreas = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialAreas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isEmpty) {
      _filteredAreas = List.from(_areas);
    } else {
      _searchAreas(query);
    }
  }

  Future<void> _loadInitialAreas() async {
    setState(() {
      _isLoadingAreas = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getAreasSearch(context: context);
      
      if (result['success'] == true && result['data'] != null) {
        final areasData = result['data'];
        List<Map<String, dynamic>> areas = [];
        
        if (areasData is List) {
          areas = areasData.cast<Map<String, dynamic>>();
        } else if (areasData is Map && areasData['areas'] != null) {
          areas = (areasData['areas'] as List).cast<Map<String, dynamic>>();
        }
        
        setState(() {
          _areas = areas;
          _filteredAreas = List.from(_areas);
          _isLoadingAreas = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load areas';
          _isLoadingAreas = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error occurred';
        _isLoadingAreas = false;
      });
    }
  }

  Future<void> _searchAreas(String query) async {
    setState(() {
      _isLoadingAreas = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getAreasSearch(
        search: query,
        context: context,
      );
      
      if (result['success'] == true && result['data'] != null) {
        final areasData = result['data'];
        List<Map<String, dynamic>> areas = [];
        
        if (areasData is List) {
          areas = areasData.cast<Map<String, dynamic>>();
        } else if (areasData is Map && areasData['areas'] != null) {
          areas = (areasData['areas'] as List).cast<Map<String, dynamic>>();
        }
        
        setState(() {
          _filteredAreas = areas;
          _isLoadingAreas = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to search areas';
          _isLoadingAreas = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error occurred';
        _isLoadingAreas = false;
      });
    }
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
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set to: $selectedCity'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your current location. Please select manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
    // Find the closest match from our areas list
    for (Map<String, dynamic> area in _areas) {
      final areaName = area['name']?.toString() ?? area['area_name']?.toString() ?? '';
      if (areaName.toLowerCase().contains(detectedCity.toLowerCase()) ||
          detectedCity.toLowerCase().contains(areaName.toLowerCase())) {
        return areaName;
      }
    }
    return 'Chennai'; // Default fallback for Tamil Nadu
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
              child: const Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
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
              child: const Text('OK', style: TextStyle(color: AppColors.primaryBlue)),
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
          // Search Bar with Current Location Icon
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Box
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Search areas',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Current Location Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingLocation
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(
                            Icons.my_location,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          tooltip: 'Use current location',
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

                     // All Cities - Only show when searching
           if (_isSearching) ...[
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
                         'Available Areas',
                         style: TextStyle(
                           color: Colors.black87,
                           fontSize: 18,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                     Expanded(
                       child: _buildAreasList(),
                     ),
                   ],
                 ),
               ),
             ),
           ] else ...[
             // Empty space when not searching
             Expanded(
               child: Container(
                 decoration: const BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.only(
                     topLeft: Radius.circular(20),
                     topRight: Radius.circular(20),
                   ),
                 ),
                 child: const Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         Icons.search,
                         size: 64,
                         color: Colors.grey,
                       ),
                       SizedBox(height: 16),
                       Text(
                         'Search for areas',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.w500,
                           color: Colors.grey,
                         ),
                       ),
                       SizedBox(height: 8),
                       Text(
                         'Type in the search bar above to find areas',
                         style: TextStyle(
                           fontSize: 14,
                           color: Colors.grey,
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           ],
        ],
      ),
    );
  }

  Widget _buildAreasList() {
    if (_isLoadingAreas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            SizedBox(height: 16),
            Text(
              'Loading areas...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_searchController.text.isEmpty) {
                  _loadInitialAreas();
                } else {
                  _searchAreas(_searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredAreas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No areas found',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAreas.length,
      itemBuilder: (context, index) {
        final area = _filteredAreas[index];
        final areaName = area['name']?.toString() ?? 
                        'Unknown Area';
        final areaState = area['city']['name']?.toString() ?? 
                         '';
        final displayText = areaName.isNotEmpty ? '$areaName, $areaState' : areaState
        ;
        
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.location_on,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            title: Text(
              displayText,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            onTap: () {
              widget.onLocationSelected(areaName);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
