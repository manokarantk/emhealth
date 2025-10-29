import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'checkout_screen.dart';
import 'lab_wise_summary_screen.dart';

class LabSelectionScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final Map<String, dynamic> cartData;
  final VoidCallback? onCartChanged; // Callback to notify parent of cart changes

  const LabSelectionScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.cartData,
    this.onCartChanged, // Optional callback
  });

  @override
  State<LabSelectionScreen> createState() => _LabSelectionScreenState();
}

class _LabSelectionScreenState extends State<LabSelectionScreen> {
  String? selectedLab;
  bool isLoading = true;
  List<Map<String, dynamic>> labs = [];
  
  // Filter variables
  List<String> selectedCertificationFilters = [];
  String? selectedParkingFilter;
  String? selectedLiftFilter;
  String? selectedXRayLocationFilter;
  String? selectedDistanceFilter;
  String? selectedCollectionFilter;
  
  // Sort variable
  String currentSortOption = 'distance_near_to_far'; // Default sort by distance
  
  // Original labs list for filtering
  List<Map<String, dynamic>> originalLabs = [];
  
  // Helper method to format discount value (remove decimal points)
  String _formatDiscount(dynamic discountValue) {
    if (discountValue == null) return '0';
    String formatted = discountValue.toString();
    if (formatted.contains('.')) {
      // Remove all decimal points and trailing zeros
      double? number = double.tryParse(formatted);
      if (number != null) {
        formatted = number.toInt().toString();
      }
    }
    return formatted;
  }

  // Helper method to check if discount should be shown
  bool _shouldShowDiscount(dynamic discountValue) {
    if (discountValue == null || discountValue.toString().isEmpty) return false;
    double? number = double.tryParse(discountValue.toString());
    return number != null && number > 0;
  }

  // Helper method to safely get distance from lab data
  dynamic _getSafeDistance(Map<String, dynamic> lab) {
    try {
      if (lab.containsKey('distance')) {
        return lab['distance'];
      }
      return null;
    } catch (e) {
      print('🔍 Error accessing distance field: $e');
      return null;
    }
  }

  // Helper method to format distance value (converts meters to km)
  String _formatDistance(dynamic distance) {
    try {
      print('🔍 Formatting distance: $distance (type: ${distance.runtimeType})');
      
      // Handle null or undefined values
      if (distance == null) {
        print('🔍 Distance is null, returning "Nearby"');
        return 'Nearby';
      }
      
      double distanceInMeters;
      
      // Handle different data types with explicit type checking
      if (distance is double) {
        distanceInMeters = distance;
        print('🔍 Distance is double: $distanceInMeters');
      } else if (distance is int) {
        distanceInMeters = distance.toDouble();
        print('🔍 Distance is int, converted to double: $distanceInMeters');
      } else if (distance is String) {
        final parsed = double.tryParse(distance);
        if (parsed == null) {
          print('🔍 Could not parse string distance value: "$distance", returning "Nearby"');
          return 'Nearby';
        }
        distanceInMeters = parsed;
        print('🔍 Distance is string, parsed to double: $distanceInMeters');
      } else {
        // For any other type, try to convert safely
        try {
          final distanceString = distance.toString();
          final parsed = double.tryParse(distanceString);
          if (parsed == null) {
            print('🔍 Could not parse distance value: "$distanceString", returning "Nearby"');
            return 'Nearby';
          }
          distanceInMeters = parsed;
          print('🔍 Distance converted from ${distance.runtimeType} to double: $distanceInMeters');
        } catch (conversionError) {
          print('🔍 Error converting distance to string: $conversionError, returning "Nearby"');
          return 'Nearby';
        }
      }
      
      // Validate the distance value
      if (distanceInMeters.isNaN || distanceInMeters.isInfinite || distanceInMeters < 0) {
        print('🔍 Invalid distance value: $distanceInMeters, returning "Nearby"');
        return 'Nearby';
      }
      
      // Convert meters to kilometers
      final distanceInKm = distanceInMeters / 1000;
      print('🔍 Distance in meters: $distanceInMeters, converted to km: $distanceInKm');
      
      String formattedDistance;
      if (distanceInKm < 1) {
        // Less than 1 km, show in meters
        final meters = distanceInMeters.round();
        formattedDistance = '${meters} m away';
      } else if (distanceInKm < 10) {
        // Less than 10 km, show with 1 decimal place
        formattedDistance = '${distanceInKm.toStringAsFixed(1)} km away';
      } else {
        // 10 km or more, show as whole number
        formattedDistance = '${distanceInKm.round()} km away';
      }
      
      print('🔍 Formatted distance: $formattedDistance');
      return formattedDistance;
    } catch (e) {
      print('❌ Unexpected error formatting distance: $e');
      return 'Nearby';
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Force refresh cart data and load labs
    _refreshAndLoadLabs();
  }
  
  Future<void> _refreshAndLoadLabs() async {
    // Clear any cached data and reload
    setState(() {
      labs = [];
      selectedLab = null;
      isLoading = true;
    });
    
    // Clear any stored test IDs from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_test_ids');
      print('Cleared cached test IDs from SharedPreferences');
    } catch (e) {
      print('Error clearing cached test IDs: $e');
    }
    
    // Force a small delay to ensure fresh data
    await Future.delayed(const Duration(milliseconds: 100));
    
    await _loadLabs();
  }

  Future<void> _loadLabs() async {
    try {
      // Clear any previous data and start fresh
      print('🔍 DEBUGGING CART DATA:');
      print('Cart data type: ${widget.cartData.runtimeType}');
      print('Cart data keys: ${widget.cartData.keys}');
      print('Cart data: ${widget.cartData}');
      print('Cart items type: ${widget.cartItems.runtimeType}');
      print('Cart items: ${widget.cartItems}');
      print('Cart items length: ${widget.cartItems.length}');
      
      // Extract SELECTED labs from cart data instead of getting all available labs
      final Map<String, Map<String, dynamic>> selectedLabs = {};
      final List<Map<String, dynamic>> cartServices = [];
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        print('Cart summary items: $items');
        
        for (final item in items) {
          print('Processing cart item: $item');
          
          // Extract SELECTED lab information
          String? labId = item['lab_id']?.toString();
          String? labName = item['lab_name']?.toString();
          String? testName = item['test_name']?.toString();
          String? price = item['price']?.toString();
          String? discountedAmount = item['discounted_amount']?.toString();
          String? discountValue = item['discount_value']?.toString();
          
          print('Extracted - Lab ID: $labId, Lab Name: $labName, Test: $testName');
          
          if (labId != null && labId.isNotEmpty && labName != null && labName.isNotEmpty) {
            // Initialize lab if not already added
            if (!selectedLabs.containsKey(labId)) {
              selectedLabs[labId] = {
                'id': labId,
                'name': labName,
                'services': <Map<String, dynamic>>[],
              };
              print('✅ Added selected lab: $labName (ID: $labId)');
            }
            
            // Add service/test to this lab
            final service = {
              'id': item['id']?.toString() ?? '',
              'testname': testName ?? '',
              'name': testName ?? '',
              'baseprice': price ?? '0',
              'discountedprice': discountedAmount ?? price ?? '0',
              'discountvalue': discountValue ?? '0',
              'lab_test_id': item['lab_test_id']?.toString() ?? '',
              'lab_package_id': item['lab_package_id']?.toString() ?? '',
            };
            
            selectedLabs[labId]!['services'].add(service);
            cartServices.add(service);
            print('✅ Added service to lab $labName: $testName');
          } else {
            print('❌ No lab information found for item: $testName');
            print('This item may not have been assigned a lab yet');
          }
        }
      } else {
        print('❌ No cart data or items found');
        print('Cart data keys: ${widget.cartData.keys}');
      }
      
      print('📊 SUMMARY:');
      print('Selected labs from cart: ${selectedLabs.keys.length}');
      print('Total cart services: ${cartServices.length}');
      print('Total items in cart: ${widget.cartItems.length}');
      print('Selected labs: ${selectedLabs.keys.map((id) => selectedLabs[id]!['name']).toList()}');
      
      // Check if there are any individual tests in cart
      bool hasIndividualTests = false;
      int testCount = 0;
      int packageCount = 0;
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        for (var item in items) {
          if (item['lab_test_id'] != null && item['lab_test_id'].toString().isNotEmpty) {
            testCount++;
            hasIndividualTests = true;
          }
          if (item['lab_package_id'] != null && item['lab_package_id'].toString().isNotEmpty) {
            packageCount++;
          }
        }
      }
      
      print('🔍 Cart analysis: $testCount tests, $packageCount packages');
      print('🔍 Has individual tests: $hasIndividualTests');
      
      // RULE: If there are any individual tests, always show lab selection screen
      if (hasIndividualTests) {
        print('✅ Individual tests detected - must show lab selection screen');
        if (selectedLabs.isEmpty) {
          print('⚠️ Tests have no labs assigned - loading available labs');
          await _loadAvailableLabsForSelection();
        } else {
          print('✅ Tests have some labs assigned - showing all labs for review/assignment');
          final allLabsForSelection = await _getAvailableLabsForSelection();
          setState(() {
            labs = allLabsForSelection;
            isLoading = false;
          });
        }
        return;
      }
      
      // If NO individual tests, proceed with package-only logic
      print('🔍 No individual tests - proceeding with package-only navigation logic');
      
      // Check if all packages belong to a single lab - if so, go directly to checkout
      if (selectedLabs.length == 1) {
        print('✅ All packages belong to single lab - navigating directly to checkout');
        
        final singleLab = selectedLabs.values.first;
        final labId = singleLab['id']?.toString() ?? '';
        final labName = singleLab['name']?.toString() ?? 'Unknown Lab';
        final services = List<Map<String, dynamic>>.from(singleLab['services'] ?? []);
        
        // Calculate total price and discount for the single lab
        double totalOriginalPrice = 0.0;
        double totalDiscountedPrice = 0.0;
        String discountText = '';
        
        for (final service in services) {
          final basePrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
          final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
          final discountValue = service['discountvalue']?.toString() ?? '0';
          
          totalOriginalPrice += basePrice;
          totalDiscountedPrice += discountedPrice;
          
          if (_shouldShowDiscount(discountValue) && discountText.isEmpty) {
            discountText = '${_formatDiscount(discountValue)}% OFF';
          }
        }
        
        // Navigate directly to checkout
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutScreen(
                cartItems: widget.cartItems,
                testPrices: widget.testPrices,
                testDiscounts: widget.testDiscounts,
                selectedLab: labName,
                labOriginalPrice: totalOriginalPrice,
                labDiscountedPrice: totalDiscountedPrice,
                labDiscount: discountText,
                organizationId: labId,
                cartData: widget.cartData,
                onRemoveFromCart: (testName) {
                  // Notify parent that cart has changed
                  if (widget.onCartChanged != null) {
                    print('🔄 Checkout removed $testName - triggering parent cart refresh');
                    widget.onCartChanged!();
                  }
                },
                onCartCleared: () {
                  // Notify parent that entire cart has been cleared
                  if (widget.onCartChanged != null) {
                    print('🔄 Cart cleared - triggering parent cart refresh');
                    widget.onCartChanged!();
                  }
                },
                onCartChanged: () {
                  // Notify parent that cart has been modified
                  if (widget.onCartChanged != null) {
                    print('🔄 Cart changed from checkout - triggering parent cart refresh');
                    widget.onCartChanged!();
                  }
                },
              ),
            ),
          );
        }
        return;
      }
      
      // Check if multiple labs are already assigned - if so, go directly to lab-wise summary
      if (selectedLabs.length > 1) {
        print('✅ Multiple labs already assigned - navigating directly to lab-wise summary');
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LabWiseSummaryScreen(
                cartItems: widget.cartItems,
                testPrices: widget.testPrices,
                testDiscounts: widget.testDiscounts,
                cartData: widget.cartData,
                labsData: selectedLabs.values.toList(),
                onCartChanged: widget.onCartChanged, // Pass callback
              ),
            ),
          );
        }
        return;
      }
      
      // For no labs assigned, show lab selection screen
      if (selectedLabs.isEmpty) {
        print('⚠️ No selected labs found - need to get available labs for selection');
        // Load available labs for selection
        await _loadAvailableLabsForSelection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Load fallback data on error
     //   _loadFallbackLabs();
      }
    }
  }

  Future<void> _loadAvailableLabsForSelection() async {
    try {
      final allLabs = await _getAvailableLabsForSelection();
      if (mounted) {
        setState(() {
          labs = allLabs;
          originalLabs = List.from(allLabs); // Store original list for filtering
          isLoading = false;
        });
        
        // Apply default sorting by distance
        _sortLabs(currentSortOption);
      }
    } catch (e) {
      print('❌ Error loading available labs: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableLabsForSelection() async {
    try {
      // Extract test IDs and package IDs from cart data for API call
      final List<String> testIds = [];
      final List<String> packageIds = [];
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        
        for (final item in items) {
          String? testId = item['lab_test_id']?.toString();
          String? packageId = item['lab_package_id']?.toString();
          
          if (testId != null && testId.isNotEmpty) {
            testIds.add(testId);
          }
          if (packageId != null && packageId.isNotEmpty) {
            packageIds.add(packageId);
          }
        }
      }
      
      // Get user's stored location from local storage
      double? latitude;
      double? longitude;
      
      try {
        print('📍 Getting stored location for lab selection...');
        final locationService = LocationService();
        final storedCoordinates = await locationService.getStoredCoordinates();
        
        if (storedCoordinates != null) {
          latitude = storedCoordinates['latitude'];
          longitude = storedCoordinates['longitude'];
          print('📍 Stored location obtained - Lat: $latitude, Long: $longitude');
        } else {
          print('⚠️ No stored location found, attempting to get current location...');
          // Fallback to current location if no stored location
          final locationResult = await locationService.getCurrentLocation(context);
          
          if (locationResult['success'] == true) {
            final locationData = locationResult['data'];
            latitude = locationData['latitude'];
            longitude = locationData['longitude'];
            print('📍 Current location obtained - Lat: $latitude, Long: $longitude');
            
            // Store the location for future use
            await locationService.storeLocation(locationData);
            print('📍 Location stored for future use');
          } else {
            print('⚠️ Could not get user location: ${locationResult['message']}');
            print('📍 Proceeding without location data');
          }
        }
      } catch (e) {
        print('❌ Error getting location: $e');
        print('📍 Proceeding without location data');
      }
      
      // Call API to get available labs using stored location
      final apiService = ApiService();
      final result = await apiService.getOrganizationsProvidersWithStoredLocation(
        testIds: testIds,
        packageIds: packageIds,
      );
      
      if (result['success'] == true) {
        final labsData = List<Map<String, dynamic>>.from(result['data']['organizations'] ?? []);
        print('✅ Loaded ${labsData.length} available labs for selection');
        
        // Debug: Print lab data structure to see available fields including distance
        if (labsData.isNotEmpty) {
          print('🔍 First lab data structure: ${labsData.first}');
          print('🔍 Available fields in lab data: ${labsData.first.keys}');
          if (labsData.first.containsKey('distance')) {
            final distanceValue = labsData.first['distance'];
            print('🔍 Distance field found: $distanceValue (type: ${distanceValue.runtimeType})');
          }
        }
        
        return labsData;
      } else {
        print('❌ Failed to load available labs: ${result['message']}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting available labs: $e');
      return [];
    }
  }

  double get totalOriginalPrice {
    return widget.cartItems.fold<double>(
      0.0,
      (sum, testName) => sum + (widget.testPrices[testName] ?? 0.0),
    );
  }

  double get totalDiscountedPrice {
    return widget.cartItems.fold<double>(
      0.0,
      (sum, testName) {
        final originalPrice = widget.testPrices[testName] ?? 0.0;
        final discount = widget.testDiscounts[testName] ?? '0%';
        final discountPercent = int.tryParse(discount.replaceAll('% OFF', '')) ?? 0;
        return sum + (originalPrice * (100 - discountPercent) / 100);
      },
    );
  }

  Widget _buildViewFacilitiesButton(Map<String, dynamic> lab) {
    return GestureDetector(
      onTap: () => _showFacilitiesBottomSheet(context, lab),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 16,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'View Available Facilities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  void _showFacilitiesBottomSheet(BuildContext context, Map<String, dynamic> lab) {
    // Define facility definitions based on the provided format
    final facilityDefs = <Map<String, dynamic>>[
      { 
        'name': 'Certification', 
        'input': 'MULTI_DROPDOWN', 
        'options': ['NABL', 'NABH', 'ISO'],
        'icon': Icons.verified,
      },
      { 
        'name': 'MRI Field Strength', 
        'input': 'DROPDOWN', 
        'options': ['0.5 Tesla', '1 Tesla', '1.5 Tesla', '3 Tesla'],
        'icon': Icons.memory,
      },
      { 
        'name': 'CT Slice', 
        'input': 'TEXT',
        'icon': Icons.scanner,
        'description': 'CT scan slice specifications'
      },
      { 
        'name': 'Car Parking Facility', 
        'input': 'BOOLEAN',
        'icon': Icons.local_parking,
        'description': 'Parking space available for patients'
      },
      { 
        'name': 'Lift Facility', 
        'input': 'BOOLEAN',
        'icon': Icons.elevator,
        'description': 'Elevator access available'
      },
      { 
        'name': 'XRay Machine Location', 
        'input': 'DROPDOWN', 
        'options': ['Ground Floor', 'First Floor', 'Second Floor', 'Third Floor'],
        'icon': Icons.medical_services,
      },
    ];

    // Additional common facilities
    final additionalFacilities = <Map<String, dynamic>>[
      {
        'name': 'Home Collection',
        'icon': Icons.home,
        'description': 'Lab technician will visit your home for sample collection',
        'available': lab['home_collection'] == true || lab['home_collection'] == 'true' || lab['home_collection'] == 1,
      },
      {
        'name': 'Lab Visit',
        'icon': Icons.directions_walk,
        'description': 'Visit our lab directly for sample collection',
        'available': lab['walk_in'] == true || lab['walk_in'] == 'true' || lab['walk_in'] == 1,
      },
      {
        'name': 'Online Report Facility',
        'icon': Icons.cloud_download,
        'description': 'Digital reports delivered via email/app',
        'available': lab['online_reports'] == true || lab['online_reports'] == 'true' || lab['online_reports'] == 1,
      },
    ];

    // Filter only available additional facilities
    final availableAdditionalFacilities = additionalFacilities.where((facility) => facility['available'] == true).toList();
    
    // If no additional facilities are explicitly marked, show default ones
    if (availableAdditionalFacilities.isEmpty) {
      availableAdditionalFacilities.addAll([
        {
          'name': 'Home Collection',
          'icon': Icons.home,
          'description': 'Lab technician will visit your home for sample collection',
          'available': true
        },
        {
          'name': 'Lab Visit',
          'icon': Icons.directions_walk,
          'description': 'Visit our lab directly for sample collection',
          'available': true
        },
        {
          'name': 'Online Report Facility',
          'icon': Icons.cloud_download,
          'description': 'Digital reports delivered via email/app',
          'available': true
        },
      ]);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lab['name'] ?? 'Lab',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Available Facilities & Services',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Facilities list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: facilityDefs.length + availableAdditionalFacilities.length,
                itemBuilder: (context, index) {
                  // Show facility definitions first, then additional facilities
                  final facility = index < facilityDefs.length 
                      ? facilityDefs[index]
                      : availableAdditionalFacilities[index - facilityDefs.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            facility['icon'] as IconData,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                facility['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (facility['description'] != null)
                                Text(
                                  facility['description'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                                ),
                              // Show options for dropdown/multi-dropdown facilities
                              if (facility['options'] != null) ...[
                                const SizedBox(height: 8),
                                // Special handling for XRay Machine Location
                                if (facility['name'] == 'XRay Machine Location') ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.green[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Available in Ground Floor',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Regular options display for other facilities
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: (facility['options'] as List<String>).map((option) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primaryBlue.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 24,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom padding for safe area
            const SizedBox(height: 40),
          ],
        ),
        ),
      ),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Lab for Test/Scans',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {
              _showSortBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.primaryBlue,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading Labs...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we fetch available labs',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : labs.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: labs.length,
                itemBuilder: (context, index) {
                final lab = labs[index];
                final isSelected = selectedLab == lab['id']?.toString();
                
                // Extract service data for pricing
                final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
                
                // Calculate total price and discount
                double totalOriginalPrice = 0.0;
                double totalDiscountedPrice = 0.0;
                String discountText = '';
                
                for (final service in services) {
                  final basePrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
                  final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
                  final discountValue = service['discountvalue']?.toString() ?? '0';
                  
                  totalOriginalPrice += basePrice;
                  totalDiscountedPrice += discountedPrice;
                  
                  if (_shouldShowDiscount(discountValue)) {
                    discountText = '${_formatDiscount(discountValue)}% OFF';
                  }
                }
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryBlue : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedLab = lab['id']?.toString();
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(
                            children: [
                              // Lab Image/Icon
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_hospital,
                                  color: AppColors.primaryBlue,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lab['name'] ?? 'Lab',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left side: Rating and Distance
                                        Row(
                                          children: [
                                            // Show rating only if it exists
                                            if (lab['rating'] != null && lab['rating'].toString().isNotEmpty) ...[
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.orange[400],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                lab['rating'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDistance(_getSafeDistance(lab)),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Right side: Offer tag
                                        if (discountText.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              discountText,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Radio Button
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryBlue : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Delivery Time
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  lab['addresses'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Price Section with Facilities Button
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Facilities button on the left
                                GestureDetector(
                                  onTap: () => _showFacilitiesBottomSheet(context, lab),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.primaryBlue.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'View Facilities',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                // Price on the right
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        if (totalOriginalPrice > totalDiscountedPrice)
                                          Text(
                                            '₹${totalOriginalPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        if (totalOriginalPrice > totalDiscountedPrice)
                                          const SizedBox(width: 8),
                                        Text(
                                          '₹${totalDiscountedPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
        child: ElevatedButton(
          
          onPressed: selectedLab != null && isLoading == false
              ? () async {
                  // Show loading state
                  setState(() {
                    isLoading = true;
                  });
                  
                  try {
                    final selectedLabData = labs.firstWhere((lab) => lab['id']?.toString() == selectedLab);
                    print('🔄 Selected Lab Data: $selectedLabData');
                    
                    // Extract lab_test_ids from cart data
                    final List<String> labTestIds = [];
                    if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
                      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
                      for (final item in items) {
                        final labTestId = item['lab_test_id']?.toString();
                        if (labTestId != null && labTestId.isNotEmpty) {
                          labTestIds.add(labTestId);
                        }
                      }
                    }
                    
                    // Call API to update lab for cart items
                    final apiService = ApiService();
                    final result = await apiService.updateCartLab(
                      labTestIds: labTestIds,
                      labId: selectedLabData['id']?.toString() ?? '',
                      labName: selectedLabData['name']?.toString() ?? '',
                    );
                    
                    if (result['success']) {
                      print('✅ Lab updated successfully');
                      
                      // These totals will be calculated from the updated cart data after lab assignment
                      
                      // Navigate based on updated cart state
                      if (mounted) {
                        print('✅ Lab updated successfully - determining next screen');
                        
                        // Refresh cart data to get updated lab assignments
                        final apiService = ApiService();
                        final cartResult = await apiService.getCart();
                        
                        if (cartResult['success']) {
                          final updatedCartData = cartResult['data'];
                          final items = List<Map<String, dynamic>>.from(updatedCartData['items'] ?? []);
                          
                          // Count unique labs in updated cart
                          final Set<String> uniqueLabIds = {};
                          final Map<String, Map<String, dynamic>> labsInCart = {};
                          
                          for (final item in items) {
                            String? labId = item['lab_id']?.toString();
                            String? labName = item['lab_name']?.toString();
                            
                            if (labId != null && labId.isNotEmpty) {
                              uniqueLabIds.add(labId);
                              if (!labsInCart.containsKey(labId)) {
                                labsInCart[labId] = {
                                  'id': labId,
                                  'name': labName ?? 'Unknown Lab',
                                  'services': <Map<String, dynamic>>[],
                                };
                              }
                              
                              // Add service to lab
                              labsInCart[labId]!['services'].add({
                                'id': item['id']?.toString() ?? '',
                                'testname': item['test_name'] ?? '',
                                'name': item['test_name'] ?? '',
                                'baseprice': item['price']?.toString() ?? '0',
                                'discountedprice': item['discounted_amount']?.toString() ?? item['price']?.toString() ?? '0',
                                'discountvalue': item['discount_value']?.toString() ?? '0',
                              });
                            }
                          }
                          
                          print('🔍 Unique labs in updated cart: ${uniqueLabIds.length}');
                          print('🔍 Lab names: ${labsInCart.values.map((lab) => lab['name']).toList()}');
                          
                          // Navigate based on number of labs
                          if (uniqueLabIds.length == 1) {
                            // Single lab - go to checkout
                            print('✅ Single lab in cart - navigating to checkout');
                            
                            final singleLab = labsInCart.values.first;
                            final services = List<Map<String, dynamic>>.from(singleLab['services']);
                            
                            // Calculate totals
                            double totalOriginalPrice = 0.0;
                            double totalDiscountedPrice = 0.0;
                            String discountText = '';
                            
                            for (final service in services) {
                              totalOriginalPrice += double.tryParse(service['baseprice'] ?? '0') ?? 0.0;
                              totalDiscountedPrice += double.tryParse(service['discountedprice'] ?? '0') ?? 0.0;
                              
                              final discountValue = service['discountvalue']?.toString() ?? '0';
                              if (_shouldShowDiscount(discountValue) && discountText.isEmpty) {
                                discountText = '${_formatDiscount(discountValue)}% OFF';
                              }
                            }
                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  cartItems: widget.cartItems,
                                  testPrices: widget.testPrices,
                                  testDiscounts: widget.testDiscounts,
                                  selectedLab: singleLab['name'],
                                  labOriginalPrice: totalOriginalPrice,
                                  labDiscountedPrice: totalDiscountedPrice,
                                  labDiscount: discountText,
                                  organizationId: singleLab['id'],
                                  cartData: updatedCartData,
                                  onRemoveFromCart: (testName) {
                                    // Notify parent that cart has changed
                                    if (widget.onCartChanged != null) {
                                      print('🔄 Checkout removed $testName - triggering parent cart refresh');
                                      widget.onCartChanged!();
                                    }
                                  },
                                  onCartCleared: () {
                                    // Notify parent that entire cart has been cleared
                                    if (widget.onCartChanged != null) {
                                      print('🔄 Cart cleared - triggering parent cart refresh');
                                      widget.onCartChanged!();
                                    }
                                  },
                                  onCartChanged: () {
                                    // Notify parent that cart has been modified
                                    if (widget.onCartChanged != null) {
                                      print('🔄 Cart changed from checkout - triggering parent cart refresh');
                                      widget.onCartChanged!();
                                    }
                                  },
                                ),
                              ),
                            );
                          } else {
                            // Multiple labs - go to lab-wise summary
                            print('✅ Multiple labs in cart - navigating to lab-wise summary');
                            
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => LabWiseSummaryScreen(
                                  cartItems: widget.cartItems,
                                  testPrices: widget.testPrices,
                                  testDiscounts: widget.testDiscounts,
                                  cartData: updatedCartData,
                                  labsData: labsInCart.values.toList(),
                                  onCartChanged: widget.onCartChanged, // Pass callback
                                ),
                              ),
                            );
                          }
                        }
                      }
                    } else {
                      print('❌ Failed to update lab: ${result['message']}');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Failed to update lab'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('❌ Error during lab selection: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error selecting lab: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                )
              : Text(
                  selectedLab != null ? 'Confirm Booking' : 'Select a Lab',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Filter Labs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Active Filters Indicator
                if (_hasActiveFilters())
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Filters:',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _buildActiveFilterTags(),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Certification Filter
                      _buildFilterSection(
                        'Certification',
                        Icons.verified,
                        [
                          _buildMultiSelectFilterChip('NABL Certified', 'nabl_certified', selectedCertificationFilters, (value) {
                            setModalState(() {
                              if (selectedCertificationFilters.contains(value)) {
                                selectedCertificationFilters.remove(value);
                              } else {
                                selectedCertificationFilters.add(value);
                              }
                            });
                          }),
                          _buildMultiSelectFilterChip('NABH Certified', 'nabh_certified', selectedCertificationFilters, (value) {
                            setModalState(() {
                              if (selectedCertificationFilters.contains(value)) {
                                selectedCertificationFilters.remove(value);
                              } else {
                                selectedCertificationFilters.add(value);
                              }
                            });
                          }),
                          _buildMultiSelectFilterChip('ISO Certified', 'iso_certified', selectedCertificationFilters, (value) {
                            setModalState(() {
                              if (selectedCertificationFilters.contains(value)) {
                                selectedCertificationFilters.remove(value);
                              } else {
                                selectedCertificationFilters.add(value);
                              }
                            });
                          }),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Parking Available Filter
                      _buildFilterSection(
                        'Parking Facility',
                        Icons.local_parking,
                        [
                          _buildFilterChip('Parking Available', 'parking_available', selectedParkingFilter, (value) {
                            setModalState(() {
                              selectedParkingFilter = value;
                            });
                          }),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Lift Facility Filter
                      _buildFilterSection(
                        'Lift Facility',
                        Icons.elevator,
                        [
                          _buildFilterChip('Lift Available', 'lift_available', selectedLiftFilter, (value) {
                            setModalState(() {
                              selectedLiftFilter = value;
                            });
                          }),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // XRay Machine Location Filter
                      _buildFilterSection(
                        'XRay Machine Location',
                        Icons.medical_services,
                        [
                          _buildFilterChip('Ground Floor', 'xray_ground_floor', selectedXRayLocationFilter, (value) {
                            setModalState(() {
                              selectedXRayLocationFilter = value;
                            });
                          }),
                          _buildFilterChip('First Floor', 'xray_first_floor', selectedXRayLocationFilter, (value) {
                            setModalState(() {
                              selectedXRayLocationFilter = value;
                            });
                          }),
                          _buildFilterChip('Second Floor', 'xray_second_floor', selectedXRayLocationFilter, (value) {
                            setModalState(() {
                              selectedXRayLocationFilter = value;
                            });
                          }),
                          _buildFilterChip('Third Floor', 'xray_third_floor', selectedXRayLocationFilter, (value) {
                            setModalState(() {
                              selectedXRayLocationFilter = value;
                            });
                          }),
                        ],
                      ),
                  
                  const SizedBox(height: 24),
                  
                  // Distance Filter
                  _buildFilterSection(
                    'Distance',
                    Icons.location_on,
                    [
                      _buildFilterChip('Under 2 km', 'distance_under_2km', selectedDistanceFilter, (value) {
                        setModalState(() {
                          selectedDistanceFilter = value;
                        });
                      }),
                      _buildFilterChip('2-5 km', 'distance_2_5km', selectedDistanceFilter, (value) {
                        setModalState(() {
                          selectedDistanceFilter = value;
                        });
                      }),
                      _buildFilterChip('5-10 km', 'distance_5_10km', selectedDistanceFilter, (value) {
                        setModalState(() {
                          selectedDistanceFilter = value;
                        });
                      }),
                      _buildFilterChip('Above 10 km', 'distance_above_10km', selectedDistanceFilter, (value) {
                        setModalState(() {
                          selectedDistanceFilter = value;
                        });
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Collection Type Filter
                  _buildFilterSection(
                    'Collection Type',
                    Icons.home,
                    [
                      _buildFilterChip('Home Collection', 'home_collection', selectedCollectionFilter, (value) {
                        setModalState(() {
                          selectedCollectionFilter = value;
                        });
                      }),
                      _buildFilterChip('Lab Visit', 'lab_visit', selectedCollectionFilter, (value) {
                        setModalState(() {
                          selectedCollectionFilter = value;
                        });
                      }),
                      _buildFilterChip('Both', 'both', selectedCollectionFilter, (value) {
                        setModalState(() {
                          selectedCollectionFilter = value;
                        });
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  

                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            // Apply Filters Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      );
        },
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sort Labs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSortOption(
                    context,
                    'Price: Low to High',
                    Icons.trending_up,
                    'price_low_to_high',
                    () => _sortLabs('price_low_to_high'),
                  ),
                  _buildSortOption(
                    context,
                    'Price: High to Low',
                    Icons.trending_down,
                    'price_high_to_low',
                    () => _sortLabs('price_high_to_low'),
                  ),
                  _buildSortOption(
                    context,
                    'Distance: Near to Far',
                    Icons.location_on,
                    'distance_near_to_far',
                    () => _sortLabs('distance_near_to_far'),
                  ),
                  _buildSortOption(
                    context,
                    'Name: A to Z',
                    Icons.sort_by_alpha,
                    'name_a_to_z',
                    () => _sortLabs('name_a_to_z'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String title, IconData icon, String sortType, VoidCallback onTap) {
    final isSelected = currentSortOption == sortType;
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.primaryBlue : Colors.black87,
        ),
      ),
      trailing: isSelected 
        ? Icon(
            Icons.check_circle,
            color: AppColors.primaryBlue,
            size: 24,
          )
        : null,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _sortLabs(String sortType) {
    setState(() {
      currentSortOption = sortType; // Track current sort option
      switch (sortType) {
        case 'price_low_to_high':
          labs.sort((a, b) {
            final aPrice = _getLabTotalPrice(a);
            final bPrice = _getLabTotalPrice(b);
            return aPrice.compareTo(bPrice);
          });
          break;
        case 'price_high_to_low':
          labs.sort((a, b) {
            final aPrice = _getLabTotalPrice(a);
            final bPrice = _getLabTotalPrice(b);
            return bPrice.compareTo(aPrice);
          });
          break;
        case 'distance_near_to_far':
          labs.sort((a, b) {
            final aDistance = double.tryParse(a['distance']?.toString() ?? '0') ?? 0.0;
            final bDistance = double.tryParse(b['distance']?.toString() ?? '0') ?? 0.0;
            return aDistance.compareTo(bDistance);
          });
          break;
        case 'name_a_to_z':
          labs.sort((a, b) {
            final aName = a['name']?.toString() ?? '';
            final bName = b['name']?.toString() ?? '';
            return aName.compareTo(bName);
          });
          break;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Labs sorted by ${_getSortTypeDisplayName(sortType)}'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _getLabTotalPrice(Map<String, dynamic> lab) {
    final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
    double totalPrice = 0.0;
    
    for (final service in services) {
      final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
      totalPrice += discountedPrice;
    }
    
    return totalPrice;
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primaryBlue,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                              Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.local_hospital_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'No Labs Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t find any labs in your area for the selected tests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or check back later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _refreshAndLoadLabs();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortTypeDisplayName(String sortType) {
    switch (sortType) {
      case 'price_low_to_high':
        return 'Price (Low to High)';
      case 'price_high_to_low':
        return 'Price (High to Low)';
      case 'rating_high_to_low':
        return 'Rating (High to Low)';
      case 'distance_near_to_far':
        return 'Distance (Near to Far)';
      case 'name_a_to_z':
        return 'Name (A to Z)';
      default:
        return 'Default';
    }
  }

  // Filter helper methods
  Widget _buildFilterSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String? selectedValue, Function(String?) onFilterChanged) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(value);
        } else {
          // Deselect
          onFilterChanged(null);
        }
      },
      backgroundColor: isSelected ? AppColors.primaryBlue : Colors.grey[100],
      selectedColor: AppColors.primaryBlue,
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 1,
      pressElevation: 8,
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildMultiSelectFilterChip(String label, String value, List<String> selectedValues, Function(String) onFilterChanged) {
    final isSelected = selectedValues.contains(value);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        onFilterChanged(value);
      },
      backgroundColor: isSelected ? AppColors.primaryBlue : Colors.grey[100],
      selectedColor: AppColors.primaryBlue,
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 1,
      pressElevation: 8,
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      selectedCertificationFilters.clear();
      selectedParkingFilter = null;
      selectedLiftFilter = null;
      selectedXRayLocationFilter = null;
      selectedDistanceFilter = null;
      selectedCollectionFilter = null;
      labs = List.from(originalLabs);
    });
  }

  bool _hasActiveFilters() {
    return selectedCertificationFilters.isNotEmpty ||
           selectedParkingFilter != null ||
           selectedLiftFilter != null ||
           selectedXRayLocationFilter != null ||
           selectedDistanceFilter != null ||
           selectedCollectionFilter != null;
  }

  List<Widget> _buildActiveFilterTags() {
    final List<Widget> tags = [];
    
    // Add certification tags
    for (String certification in selectedCertificationFilters) {
      tags.add(_buildActiveFilterTag(_getFilterDisplayName(certification)));
    }
    
    if (selectedParkingFilter != null) {
      tags.add(_buildActiveFilterTag(_getFilterDisplayName(selectedParkingFilter!)));
    }
    if (selectedLiftFilter != null) {
      tags.add(_buildActiveFilterTag(_getFilterDisplayName(selectedLiftFilter!)));
    }
    if (selectedXRayLocationFilter != null) {
      tags.add(_buildActiveFilterTag(_getFilterDisplayName(selectedXRayLocationFilter!)));
    }
    if (selectedDistanceFilter != null) {
      tags.add(_buildActiveFilterTag(_getFilterDisplayName(selectedDistanceFilter!)));
    }
    if (selectedCollectionFilter != null) {
      tags.add(_buildActiveFilterTag(_getFilterDisplayName(selectedCollectionFilter!)));
    }
    
    return tags;
  }

  Widget _buildActiveFilterTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getFilterDisplayName(String filterValue) {
    switch (filterValue) {
      case 'nabl_certified':
        return 'NABL Certified';
      case 'nabh_certified':
        return 'NABH Certified';
      case 'iso_certified':
        return 'ISO Certified';
      case 'parking_available':
        return 'Parking Available';
      case 'lift_available':
        return 'Lift Available';
      case 'xray_ground_floor':
        return 'Ground Floor';
      case 'xray_first_floor':
        return 'First Floor';
      case 'xray_second_floor':
        return 'Second Floor';
      case 'xray_third_floor':
        return 'Third Floor';
      case 'distance_under_2km':
        return 'Under 2 km';
      case 'distance_2_5km':
        return '2-5 km';
      case 'distance_5_10km':
        return '5-10 km';
      case 'distance_above_10km':
        return 'Above 10 km';
      case 'home_collection':
        return 'Home Collection';
      case 'lab_visit':
        return 'Lab Visit';
      case 'both':
        return 'Both';
      default:
        return filterValue;
    }
  }

  void _applyFilters() {
    setState(() {
      labs = List.from(originalLabs);
      
      // Apply certification filter
      if (selectedCertificationFilters.isNotEmpty) {
        labs = labs.where((lab) {
          // This would need to be implemented based on actual lab data structure
          // For now, we'll assume all labs have certifications
          return true;
        }).toList();
      }
      
      // Apply parking filter
      if (selectedParkingFilter != null) {
        labs = labs.where((lab) {
          return lab['parking'] == true || lab['parking'] == 'true' || lab['parking'] == 1;
        }).toList();
      }
      
      // Apply lift filter
      if (selectedLiftFilter != null) {
        labs = labs.where((lab) {
          return lab['lift_facility'] == true || lab['lift_facility'] == 'true' || lab['lift_facility'] == 1;
        }).toList();
      }
      
      // Apply XRay location filter
      if (selectedXRayLocationFilter != null) {
        labs = labs.where((lab) {
          // This would need to be implemented based on actual lab data structure
          // For now, we'll assume all labs have XRay machines
          return true;
        }).toList();
      }
      
      // Apply distance filter
      if (selectedDistanceFilter != null) {
        labs = labs.where((lab) {
          final distance = double.tryParse(lab['distance']?.toString() ?? '0') ?? 0.0;
          switch (selectedDistanceFilter) {
            case 'distance_under_2km':
              return distance < 2;
            case 'distance_2_5km':
              return distance >= 2 && distance < 5;
            case 'distance_5_10km':
              return distance >= 5 && distance < 10;
            case 'distance_above_10km':
              return distance >= 10;
            default:
              return true;
          }
        }).toList();
      }
      
      // Apply collection type filter
      if (selectedCollectionFilter != null) {
        labs = labs.where((lab) {
          final hasHomeCollection = lab['home_collection'] == true;
          final hasLabVisit = lab['lab_visit'] == true;
          
          switch (selectedCollectionFilter) {
            case 'home_collection':
              return hasHomeCollection;
            case 'lab_visit':
              return hasLabVisit;
            case 'both':
              return hasHomeCollection && hasLabVisit;
            default:
              return true;
          }
        }).toList();
      }
      

    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${labs.length} labs found with applied filters'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 