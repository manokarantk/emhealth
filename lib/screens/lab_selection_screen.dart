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
        formattedDistance = '${meters}m away';
      } else if (distanceInKm < 10) {
        // Less than 10 km, show with 1 decimal place
        formattedDistance = '${distanceInKm.toStringAsFixed(1)}km away';
      } else {
        // 10 km or more, show as whole number
        formattedDistance = '${distanceInKm.round()}km away';
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
          isLoading = false;
        });
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
      
      // Get user's current location
      double? latitude;
      double? longitude;
      
      try {
        print('📍 Getting user location for lab selection...');
        final locationService = LocationService();
        final locationResult = await locationService.getCurrentLocation(context);
        
        if (locationResult['success'] == true) {
          final locationData = locationResult['data'];
          latitude = locationData['latitude'];
          longitude = locationData['longitude'];
          print('📍 User location obtained - Lat: $latitude, Long: $longitude');
        } else {
          print('⚠️ Could not get user location: ${locationResult['message']}');
          print('📍 Proceeding without location data');
        }
      } catch (e) {
        print('❌ Error getting user location: $e');
        print('📍 Proceeding without location data');
      }
      
      // Call API to get available labs
      final apiService = ApiService();
      final result = await apiService.getOrganizationsProviders(
        testIds: testIds,
        packageIds: packageIds,
        latitude: latitude,
        longitude: longitude,
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
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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
                    child: Padding(
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
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.orange[400],
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '4.5',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
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
                          const SizedBox(height: 12),
                          // Delivery Time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reports: Same Day',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Price Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (totalOriginalPrice > totalDiscountedPrice)
                                          Text(
                                            '₹${totalOriginalPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        if (totalOriginalPrice > totalDiscountedPrice)
                                          const SizedBox(width: 8),
                                        Text(
                                          '₹${totalDiscountedPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (discountText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      discountText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          onPressed: selectedLab != null
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
                            
                            Navigator.of(context).pushReplacement(
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
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryBlue,
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
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
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
                'Filter Labs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Add filter options here
            const Expanded(
              child: Center(
                child: Text(
                  'Filter options coming soon...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 