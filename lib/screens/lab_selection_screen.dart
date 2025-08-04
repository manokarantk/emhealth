import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class LabSelectionScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final Map<String, dynamic> cartData;

  const LabSelectionScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.cartData,
  });

  @override
  State<LabSelectionScreen> createState() => _LabSelectionScreenState();
}

class _LabSelectionScreenState extends State<LabSelectionScreen> {
  String? selectedLab;
  bool isLoading = true;
  List<Map<String, dynamic>> labs = [];
  
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
      
      // Extract test IDs and package IDs from cart data
      final List<String> testIds = [];
      final List<String> packageIds = [];
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        print('Cart summary items: $items');
        
        for (final item in items) {
          print('Processing cart item: $item');
          
          // Extract test ID from cart summary
          String? testId = item['lab_test_id']?.toString();
          
          // Extract package ID from cart summary
          String? packageId = item['lab_package_id']?.toString();
          
          // Also check for test name for debugging
          String? testName = item['test_name']?.toString();
          
          print('Extracted - Test ID: $testId, Package ID: $packageId, Test Name: $testName');
          
          if (testId != null && testId.isNotEmpty) {
            testIds.add(testId);
            print('✅ Added test ID: $testId for test: $testName');
          } else {
            print('❌ No valid test ID found for item: $item');
          }
          
          if (packageId != null && packageId.isNotEmpty) {
            packageIds.add(packageId);
            print('✅ Added package ID: $packageId');
          }
        }
      } else {
        print('❌ No cart data or items found');
        print('Cart data keys: ${widget.cartData.keys}');
      }
      
      print('📊 SUMMARY:');
      print('Final test IDs to send to API: $testIds');
      print('Final package IDs to send to API: $packageIds');
      print('Total items in cart: ${widget.cartItems.length}');
      print('Total test IDs extracted: ${testIds.length}');
      print('Total package IDs extracted: ${packageIds.length}');
      print('Cart item names: ${widget.cartItems.toList()}');
      
      // Verify that we have test IDs for all cart items
      if (testIds.isEmpty && widget.cartItems.isNotEmpty) {
        print('⚠️ WARNING: No test IDs extracted but cart has items!');
        print('This might indicate a mismatch between cart data structure and expected format.');
      }
      
      // If no test IDs found from cart items, try to get them from test names
      if (testIds.isEmpty && widget.cartItems.isNotEmpty) {
        print('No test IDs found in cart items, using test names: ${widget.cartItems}');
        // TODO: Implement proper mapping from test names to test IDs
        // For now, we'll skip the API call if no valid test IDs are found
        print('No valid test IDs found, skipping lab providers API call');
        setState(() {
          isLoading = false;
          labs = [];
        });
        return;
      }
      
      // Check if we have fallback test IDs (which won't work with real API)
      final hasFallbackIds = testIds.any((id) => id.startsWith('fallback_'));
      if (hasFallbackIds) {
        print('⚠️ WARNING: Found fallback test IDs, these won\'t work with real API');
        print('Fallback test IDs: $testIds');
        print('This usually means the cart API failed and we\'re using local storage');
        print('Skipping lab providers API call for fallback IDs');
        setState(() {
          isLoading = false;
          labs = [];
        });
        return;
      }
      
      final apiService = ApiService();
      final result = await apiService.getOrganizationsProviders(
        testIds: testIds,
        packageIds: packageIds,
      );
      print(result);
      if (result['success'] == true && mounted) {
        setState(() {
          try {
            labs = List<Map<String, dynamic>>.from(result['data']['organizations'] ?? []);
          } catch (e) {
            labs = [];
            print(e);
          }
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          // Load fallback data if API fails
         // _loadFallbackLabs();
        }
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Labs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Filter options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Filter
                    const Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('4.0'),
                              Text('5.0'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primaryBlue,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: AppColors.primaryBlue,
                              overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: 4.5,
                              min: 4.0,
                              max: 5.0,
                              divisions: 10,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text(
                            'Selected: 4.5★',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Distance Filter
                    const Text(
                      'Maximum Distance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0 km'),
                              Text('10 km'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primaryBlue,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: AppColors.primaryBlue,
                              overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: 5.0,
                              min: 0,
                              max: 10,
                              divisions: 20,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text(
                            'Selected: 0 - 5 km',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Delivery Time Filter
                    const Text(
                      'Delivery Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildDeliveryTimeOption('Same Day', 'same_day'),
                          const SizedBox(height: 12),
                          _buildDeliveryTimeOption('Next Day', 'next_day'),
                          const SizedBox(height: 12),
                          _buildDeliveryTimeOption('Both', 'both'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeOption(String title, String value) {
    return InkWell(
      onTap: () {
        // TODO: Implement delivery time selection
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.radio_button_unchecked,
              color: Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Lab',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: AppColors.primaryBlue),
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
          final isSelected = selectedLab == lab['name'];
          
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
            
            if (discountValue != '0' && discountValue.isNotEmpty) {
              discountText = '$discountValue% OFF';
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
                  selectedLab = lab['name'];
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
                                    'Nearby',
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
                    final selectedLabData = labs.firstWhere((lab) => lab['name'] == selectedLab);
                    print('🔄 Selected Lab Data: $selectedLabData');
                    print('🔄 Lab ID field: ${selectedLabData['id']}');
                    print('🔄 Lab ID type: ${selectedLabData['id'].runtimeType}');
                    
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
                    
                    print('🔄 Updating lab for cart items...');
                    print('Lab test IDs: $labTestIds');
                    print('Selected lab: $selectedLab');
                    print('Lab ID: ${selectedLabData['id']}');
                    
                    // Call API to update lab for cart items
                    final apiService = ApiService();
                    final result = await apiService.updateCartLab(
                      labTestIds: labTestIds,
                      labId: selectedLabData['id']?.toString() ?? '',
                      labName: selectedLab!,
                    );
                    
                    if (result['success']) {
                      print('✅ Lab updated successfully');
                      
                      // Calculate total price and discount for selected lab
                      final services = List<Map<String, dynamic>>.from(selectedLabData['services'] ?? []);
                      double totalOriginalPrice = 0.0;
                      double totalDiscountedPrice = 0.0;
                      String discountText = '';
                      
                      for (final service in services) {
                        final basePrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
                        final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
                        final discountValue = service['discountvalue']?.toString() ?? '0';
                        
                        totalOriginalPrice += basePrice;
                        totalDiscountedPrice += discountedPrice;
                        
                        if (discountValue != '0' && discountValue.isNotEmpty) {
                          discountText = '$discountValue% OFF';
                        }
                      }
                      
                      // Navigate to checkout screen
                      if (mounted) {
                        print('🔄 Navigating to CheckoutScreen');
                        print('🔄 Selected Lab: $selectedLab');
                        print('🔄 Lab Data: $selectedLabData');
                        print('🔄 Organization ID: ${selectedLabData['id']?.toString() ?? ''}');
                        
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              cartItems: widget.cartItems,
                              testPrices: widget.testPrices,
                              testDiscounts: widget.testDiscounts,
                              selectedLab: selectedLab!,
                              labOriginalPrice: totalOriginalPrice,
                              labDiscountedPrice: totalDiscountedPrice,
                              labDiscount: discountText,
                              organizationId: selectedLabData['id']?.toString() ?? '',
                              cartData: widget.cartData,
                            ),
                          ),
                        );
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
                    print('❌ Error updating lab: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating lab: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    // Clear loading state
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
} 