import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'tests_listing_screen.dart';
import 'family_members_screen.dart';
import 'addresses_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final String selectedLab;
  final double labOriginalPrice;
  final double labDiscountedPrice;
  final String labDiscount;
  final String organizationId;
  final Map<String, dynamic> cartData;
  final Function(String)? onRemoveFromCart; // Callback for removing items from cart

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.selectedLab,
    required this.labOriginalPrice,
    required this.labDiscountedPrice,
    required this.labDiscount,
    required this.organizationId,
    required this.cartData,
    this.onRemoveFromCart, // Optional callback
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  Set<String> selectedTests = {};
  String selectedPaymentMethod = 'Online Payment';
  bool isHomeCollection = true;
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:00 AM - 12:00 PM';
  String selectedPatient = 'Myself';
  String? selectedAddress;
  bool useWalletBalance = false;
  double walletBalance = 1250.0; // Sample wallet balance
  String? appliedCoupon;
  String? couponCode;
  double couponDiscount = 0.0;
  String? couponError;
  bool isApplyingCoupon = false;
  
  // Timeslot related variables
  Map<String, dynamic>? timeslotData;
  bool isLoadingTimeslots = false;
  String? selectedSession;
  String? selectedSlot;
  String? selectedDoctor;
  
  // Dependents related variables
  List<Map<String, dynamic>> _familyMembers = [];
  bool isLoadingDependents = false;
  String? dependentsError;
  
  // Addresses related variables
  List<Map<String, dynamic>> _addresses = [];
  bool isLoadingAddresses = false;
  String? addressesError;
  
  // Booking related variables
  bool isBooking = false;
  String? bookingError;

  @override
  void initState() {
    super.initState();
    selectedTests = Set.from(widget.cartItems);
    
    print('🔄 CheckoutScreen initState');
    print('🔄 Organization ID: ${widget.organizationId}');
    print('🔄 Selected Lab: ${widget.selectedLab}');
    
    // Load timeslots for today's date if organization ID is available
    if (widget.organizationId.isNotEmpty) {
      print('🔄 Loading timeslots for initial date: $selectedDate');
      print('🔄 Organization ID length: ${widget.organizationId.length}');
      _loadTimeslots(selectedDate);
    } else {
      print('❌ Organization ID is empty, not loading timeslots');
      print('❌ Organization ID value: "${widget.organizationId}"');
    }
    
    // Load dependents
    _loadDependents();
    
    // Load addresses
    _loadAddresses();
  }

  Future<void> _loadDependents() async {
    print('🔄 Loading dependents...');
    setState(() {
      isLoadingDependents = true;
      dependentsError = null;
    });

    try {
      final result = await _apiService.getDependents(context);
      print('🔄 API Result: $result');
      
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        print('🔄 Dependents data: $data');
        
        // Convert API data to the format expected by the UI
        final List<Map<String, dynamic>> convertedDependents = [];
        
        // Add "Myself" as the first option
        convertedDependents.add({
          'name': 'Myself',
          'relation': 'Account Holder',
          'age': 28, // You might want to get this from user profile
          'gender': 'Male', // You might want to get this from user profile
          'isPrimary': true,
        });
        
        // Convert API dependents to UI format
        for (final dependent in data) {
          final age = _calculateAge(dependent['date_of_birth'] ?? '');
          final convertedDependent = {
            'name': '${dependent['first_name'] ?? ''} ${dependent['last_name'] ?? ''}'.trim(),
            'relation': dependent['relationship']?['name'] ?? 'Other',
            'age': age,
            'gender': dependent['gender'] ?? 'Other',
            'isPrimary': false,
            'id': dependent['id'],
            'contact_number': dependent['contact_number'],
            'email': dependent['email'],
          };
          convertedDependents.add(convertedDependent);
          print('🔄 Converted dependent: $convertedDependent');
        }
        
        print('🔄 Final converted dependents: $convertedDependents');
        setState(() {
          _familyMembers = convertedDependents;
          isLoadingDependents = false;
        });
        print('🔄 Dependents loaded successfully. Count: ${_familyMembers.length}');
      } else {
        print('❌ Failed to load dependents: ${result['message']}');
        setState(() {
          dependentsError = result['message'] ?? 'Failed to load dependents';
          isLoadingDependents = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dependents: $e');
      setState(() {
        dependentsError = 'Network error occurred';
        isLoadingDependents = false;
      });
    }
  }

  int _calculateAge(String dateOfBirth) {
    if (dateOfBirth.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadAddresses() async {
    print('🔄 Loading addresses...');
    setState(() {
      isLoadingAddresses = true;
      addressesError = null;
    });

    try {
      final result = await _apiService.getUserAddresses(context);
      print('🔄 Addresses API Result: $result');
      
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        print('🔄 Addresses data: $data');
        
        // Convert API data to the format expected by the UI
        final List<Map<String, dynamic>> convertedAddresses = [];
        
        for (final address in data) {
          final convertedAddress = {
            'id': address['id'],
            'type': 'Home', // You might want to add type field to your API
            'address': '${address['address_line1'] ?? ''}${address['address_line2'] != null && address['address_line2'].isNotEmpty ? ', ${address['address_line2']}' : ''}',
            'city': address['city'] ?? '',
            'state': address['state'] ?? '',
            'pincode': address['postal_code'] ?? '',
            'isDefault': address['is_primary'] == true,
            'contact_number': address['contact_number'],
            'country': address['country'],
          };
          convertedAddresses.add(convertedAddress);
          print('🔄 Converted address: $convertedAddress');
        }
        
        print('🔄 Final converted addresses: $convertedAddresses');
        setState(() {
          _addresses = convertedAddresses;
          isLoadingAddresses = false;
        });
        print('🔄 Addresses loaded successfully. Count: ${_addresses.length}');
      } else {
        print('❌ Failed to load addresses: ${result['message']}');
        setState(() {
          addressesError = result['message'] ?? 'Failed to load addresses';
          isLoadingAddresses = false;
        });
      }
    } catch (e) {
      print('❌ Error loading addresses: $e');
      setState(() {
        addressesError = 'Network error occurred';
        isLoadingAddresses = false;
      });
    }
  }

  Future<bool> _clearCart() async {
    print('🛒 Clearing cart...');
    try {
      final result = await _apiService.clearCart(context);
      if (result['success']) {
        print('✅ Cart cleared successfully');
        return true;
      } else {
        print('❌ Failed to clear cart: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      return false;
    }
  }

  Future<void> _removeFromCart(String testName) async {
    print('🛒 Removing test: $testName from cart...');
    try {
      // Find the cart item ID for this test
      String? cartItemId;
      
      // Check in cart data for the item
      // Check in tests array
      if (widget.cartData!['tests'] != null) {
        for (final test in widget.cartData!['tests']) {
          if (test['name'] == testName) {
            cartItemId = test['lab_test_id']?.toString() ?? test['id']?.toString();
            break;
          }
        }
      }
      
      // Check in packages array
      if (cartItemId == null && widget.cartData!['packages'] != null) {
        for (final package in widget.cartData!['packages']) {
          if (package['name'] == testName) {
            cartItemId = package['cart_item_id']?.toString() ?? package['id']?.toString();
            break;
          }
        }
      }
      
      // Check in items array
      if (cartItemId == null && widget.cartData!['items'] != null) {
        for (final item in widget.cartData!['items']) {
          if (item['name'] == testName) {
            cartItemId = item['cart_item_id']?.toString() ?? item['id']?.toString();
            break;
          }
        }
      }
          
      if (cartItemId != null && cartItemId.isNotEmpty) {
        print('🛒 Found cart item ID: $cartItemId for test: $testName');
        final result = await _apiService.removeFromCart(cartItemId);
        if (result['success']) {
          print('✅ Item removed from cart successfully');
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$testName removed from cart'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('❌ Failed to remove item from cart: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove $testName from cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ Could not find cart item ID for test: $testName');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove $testName from cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing $testName from cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createBooking() async {
    print('📋 Creating booking...');
    setState(() {
      isBooking = true;
      bookingError = null;
    });

    try {
      // Validate required fields
      if (isHomeCollection && selectedAddress == null) {
        throw Exception('Please select a delivery address for home collection');
      }

      // Prepare booking data
      final dynamic labIdValue = widget.organizationId;
      final String labId = labIdValue ?? '550e8400-e29b-41d4-a716-446655440001';
      
      // Get cart ID - try multiple possible locations
      String cartId = '';
      cartId = widget.cartData!['id']?.toString() ?? 
               widget.cartData!['cart_id']?.toString() ?? 
               widget.cartData!['cartId']?.toString() ?? '';
          
      // If cart ID is still empty, use a placeholder
      if (cartId.isEmpty) {
        cartId = '550e8400-e29b-41d4-a716-446655440002';
      }
      
      print('📋 Cart Data: ${widget.cartData}');
      print('📋 Selected Tests: $selectedTests');
      
      // Extract test IDs from selected tests
      final List<String> labTests = [];
      final List<String> packages = [];
      
      // Since selectedTests contains test names, we need to find the corresponding test objects
      for (final testName in selectedTests) {
        print('📋 Processing test: $testName');
        
        // First try to find in cart data
        bool foundInCart = false;
        
        // Check packages in cart data
        if (widget.cartData['packages'] != null) {
          for (final package in widget.cartData['packages']) {
            print('📋 Checking package: ${package['name']} vs $testName');
            if (package['name'] == testName || package['title'] == testName) {
              final packageId = package['id']?.toString();
              if (packageId != null && packageId.isNotEmpty) {
                packages.add(packageId);
                print('📋 Found package: $testName with ID: $packageId');
                foundInCart = true;
                break;
              }
            }
          }
        }
        
        // Check tests in cart data
        if (!foundInCart && widget.cartData['items'] != null) {
          for (final test in widget.cartData['items']) {
            print('📋 Checking test: ${test['name']} vs $testName');
           // if (test['name'] == testName || test['title'] == testName) {
              final testId = test['lab_test_id']?.toString();
              if (testId != null && testId.isNotEmpty) {
                labTests.add(testId);
                print('📋 Found test: $testName with ID: $testId');
                foundInCart = true;
                break;
              }
           // }
          }
        }
        
        // Check if cart data has items array (alternative structure)
        if (!foundInCart && widget.cartData['items'] != null) {
          for (final item in widget.cartData['items']) {
            print('📋 Checking item: ${item['name']} vs $testName');
            if (item['name'] == testName || item['title'] == testName) {
              final itemId = item['id']?.toString();
              if (itemId != null && itemId.isNotEmpty) {
                if (item['type'] == 'package') {
                  packages.add(itemId);
                  print('📋 Found package item: $testName with ID: $itemId');
                } else {
                  labTests.add(itemId);
                  print('📋 Found test item: $testName with ID: $itemId');
                }
                foundInCart = true;
                break;
              }
            }
          }
        }
        
        // If not found in cart data, use placeholder IDs
        if (!foundInCart) {
          // Determine if it's a package or test based on available tests
          final test = _availableTests.firstWhere(
            (test) => test['name'] == testName,
            orElse: () => {'id': '', 'type': 'test'},
          );
          
          if (test['type'] == 'package') {
            packages.add('550e8400-e29b-41d4-a716-446655440005'); // Placeholder package ID
            print('📋 Using placeholder package ID for: $testName');
          } else {
          //  labTests.add('550e8400-e29b-41d4-a716-446655440003'); // Placeholder test ID
            print('📋 Using placeholder test ID for: $testName');
          }
        }
      }
      
      // Get patient ID (if it's not "Myself", use the dependent ID)
      String patientId = '550e8400-e29b-41d4-a716-446655440006'; // Default to "Myself"
      if (selectedPatient != 'Myself') {
        final selectedDependent = _familyMembers.firstWhere(
          (member) => member['name'] == selectedPatient,
          orElse: () => {'id': '550e8400-e29b-41d4-a716-446655440006'},
        );
        patientId = selectedDependent['id']?.toString() ?? '550e8400-e29b-41d4-a716-446655440006';
      }
      
      // Get address ID
      String addressId = '550e8400-e29b-41d4-a716-446655440007'; // Default address
      if (selectedAddress != null) {
        addressId = selectedAddress!.toString();
      }
      
      // Format date and time
      final appointmentDate = selectedDate.toIso8601String().split('T')[0];
      final appointmentTime = selectedTime;
      
      // Determine payment mode
      String paymentMode = 'card';
      if (useWalletBalance && amountAfterWallet <= 0) {
        paymentMode = 'wallet';
      }
      
      print('📋 Booking Data:');
      print('📋 Lab ID: $labId');
      print('📋 Cart ID: $cartId');
      print('📋 Lab Tests: $labTests');
      print('📋 Packages: $packages');
      print('📋 Cart Data Keys: ${widget.cartData.keys.toList()}');
      if (widget.cartData['packages'] != null) {
        print('📋 Cart Packages: ${widget.cartData['packages']}');
      }
      if (widget.cartData['tests'] != null) {
        print('📋 Cart Tests: ${widget.cartData['tests']}');
      }
      if (widget.cartData['items'] != null) {
        print('📋 Cart Items: ${widget.cartData['items']}');
      }
      print('📋 Final Lab Tests Count: ${labTests.length}');
      print('📋 Final Packages Count: ${packages.length}');
      print('📋 Patient: $patientId');
      print('📋 Is Home Collection: $isHomeCollection');
      print('📋 Address: $addressId');
      print('📋 Date: $appointmentDate');
      print('📋 Time: $appointmentTime');
      print('📋 Use Wallet: $useWalletBalance');
      print('📋 Payment Mode: $paymentMode');
      print('📋 Coupon Code: $couponCode');
      print('📋 Amount Payable: $amountAfterWallet');

      final result = await _apiService.createAppointment(
        labId: labId,
        cartId: cartId,
        labTests: labTests,
        packages: packages,
        patient: patientId,
        isHomeCollection: isHomeCollection,
        address: addressId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        isUseWallet: useWalletBalance,
        paymentMode: paymentMode,
        couponCode: couponCode,
        amountPayable: amountAfterWallet,
        context: context,
      );

      print('📋 Booking API Result: $result');

      if (result['status'] == 'success') {
        print('✅ Booking created successfully');
        setState(() {
          isBooking = false;
        });
        
        // Clear the cart after successful booking
        await _clearCart();
        
        _showSuccessPopup();
      } else {
        print('❌ Failed to create booking: ${result['message']}');
        setState(() {
          bookingError = result['message'] ?? 'Failed to create booking';
          isBooking = false;
        });
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Failed'),
            content: Text(bookingError!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating booking: $e');
      setState(() {
        bookingError = e.toString();
        isBooking = false;
      });
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking Failed'),
          content: Text(bookingError!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadTimeslots(DateTime date) async {
    print('🔄 _loadTimeslots called with date: $date');
    print('🔄 Organization ID: ${widget.organizationId}');
    
    if (widget.organizationId.isEmpty) {
      print('❌ Organization ID is empty, skipping timeslot load');
      return;
    }
    
    setState(() {
      isLoadingTimeslots = true;
    });
    
    try {
      final apiService = ApiService();
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      print('🔄 Calling API with orgId: ${widget.organizationId}, date: $dateString');
      
      final result = await apiService.getOrganizationTimeslots(
        orgId: widget.organizationId,
        date: dateString,
      );
      
      print('🔄 API result: $result');
      
      if (result['success'] && mounted) {
        setState(() {
          timeslotData = result['data'];
          isLoadingTimeslots = false;
        });
        print('✅ Timeslots loaded successfully');
        print('✅ Timeslot data: $timeslotData');
      } else {
        if (mounted) {
          setState(() {
            isLoadingTimeslots = false;
          });
          print('❌ API call failed: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to load timeslots'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _loadTimeslots: $e');
      if (mounted) {
        setState(() {
          isLoadingTimeslots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading timeslots: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTimeslotSelectionBottomSheet() {
    if (timeslotData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                    'Select Time Slot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
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
            // Timeslots list
            Expanded(
              child: isLoadingTimeslots
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: (timeslotData?['timeslots'] as List<dynamic>?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final session = (timeslotData?['timeslots'] as List<dynamic>)[index];
                        final sessionName = session['session_name'] ?? '';
                        final slots = List<Map<String, dynamic>>.from(session['slots'] ?? []);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Session header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      sessionName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${session['session_start']} - ${session['session_end']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Slots grid
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: List.generate(
                                    (slots.length / 3).ceil(),
                                    (rowIndex) {
                                      final startIndex = rowIndex * 3;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: List.generate(
                                            (startIndex + 3 <= slots.length) ? 3 : slots.length - startIndex,
                                            (colIndex) {
                                              final slotIndex = startIndex + colIndex;
                                              return Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.only(right: colIndex < 2 ? 8 : 0),
                                                  child: _buildSlotItem(
                                                    slots[slotIndex],
                                                    sessionName,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double get totalOriginalPrice {
    // Use lab prices instead of local test prices
    return widget.labOriginalPrice;
  }

  double get totalDiscountedPrice {
    // Use lab discounted price instead of local test prices
    return widget.labDiscountedPrice;
  }

  // Get the actual payable amount based on payment method
  double get actualPayableAmount {
    // If user is paying online or using full wallet balance, apply discounts
    if (selectedPaymentMethod == 'Online Payment' || 
        (useWalletBalance && walletBalance >= totalDiscountedPrice)) {
      return totalDiscountedPrice - couponDiscount;
    } else {
      // If partial wallet payment or other methods, charge original price
      return totalOriginalPrice - couponDiscount;
    }
  }

  // Get the amount to pay after wallet deduction
  double get amountAfterWallet {
    if (!useWalletBalance) {
      return actualPayableAmount;
    }
    
    final amountToPay = actualPayableAmount - walletBalance;
    return amountToPay.clamp(0, actualPayableAmount);
  }

  // Check if discount should be applied
  bool get shouldApplyDiscount {
    return selectedPaymentMethod == 'Online Payment' || 
           (useWalletBalance && walletBalance >= totalDiscountedPrice);
  }

  void _showAddMoreTestsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                    'Add More Tests',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for tests...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            // Tests list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _availableTests.length,
                itemBuilder: (context, index) {
                  final test = _availableTests[index];
                  final isSelected = selectedTests.contains(test['name']);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        test['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Also known as: ${test['description']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildTag('Home Collection'),
                              _buildTag('Same Day Report'),
                              if (test['requiresFasting'] == true) _buildTag('Fasting Required'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${test['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  test['discount'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedTests.remove(test['name']);
                                } else {
                                  selectedTests.add(test['name']);
                                }
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryBlue : Colors.grey[400]!,
                                ),
                              ),
                              child: Icon(
                                isSelected ? Icons.check : Icons.add,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Done button
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
                    'Done',
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

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  void _showDatePicker() async {
    print('🔄 _showDatePicker called');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      print('🔄 Date selected: $picked');
      print('🔄 Previous date: $selectedDate');
      
      setState(() {
        selectedDate = picked;
        selectedTime = '10:00 AM - 12:00 PM'; // Reset time when date changes
        // Clear previous timeslot selections
        selectedSession = null;
        selectedSlot = null;
        selectedDoctor = null;
        timeslotData = null;
      });
      
      print('🔄 About to call _loadTimeslots with date: $picked');
      // Load timeslots for the selected date
      await _loadTimeslots(picked);
      print('🔄 _loadTimeslots completed');
    }
  }

  void _showPatientSelectionBottomSheet() {
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
                    'Select Patient',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadDependents,
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh',
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FamilyMembersScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Family members list
            Expanded(
              child: isLoadingDependents
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : dependentsError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                dependentsError!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadDependents,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _familyMembers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.family_restroom,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Family Members',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add family members to select them',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _familyMembers.length,
                              itemBuilder: (context, index) {
                                final member = _familyMembers[index];
                                final isSelected = selectedPatient == member['name'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          member['gender'] == 'Male' ? Icons.male : Icons.female,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            member['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (member['isPrimary']) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${member['relation']} • ${member['age']} years • ${member['gender']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Container(
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
                      onTap: () {
                        setState(() {
                          selectedPatient = member['name'];
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                    'Select Address',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadAddresses,
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh',
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddressesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Addresses list
            Expanded(
              child: isLoadingAddresses
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : addressesError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                addressesError!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAddresses,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _addresses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Addresses Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your delivery addresses to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _addresses.length,
                              itemBuilder: (context, index) {
                                final address = _addresses[index];
                                final isSelected = selectedAddress == address['id']?.toString();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          address['type'] == 'Home' ? Icons.home : Icons.business,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            address['type'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (address['isDefault']) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            address['address'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${address['city']}, ${address['state']} - ${address['pincode']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
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
                      onTap: () {
                        setState(() {
                          selectedAddress = address['id'];
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() {
    // Use the new timeslot selection bottom sheet
    _showTimeslotSelectionBottomSheet();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else if (selectedDay == dayAfterTomorrow) {
      return 'Day After Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _applyCoupon() async {
    if (couponCode == null || couponCode!.isEmpty) return;

    setState(() {
      isApplyingCoupon = true;
      couponError = null; // Clear previous errors
    });

    try {
      // Extract test and package IDs from cart data
      List<String> testIds = [];
      List<String> packageIds = [];
      String cartId = '';
      
      print('🔄 Cart data structure: ${widget.cartData}');
      print('🔄 Cart data keys: ${widget.cartData.keys}');
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        
        for (var item in items) {
          if (item['lab_test_id'] != null) {
            testIds.add(item['lab_test_id'].toString());
          }
          if (item['lab_package_id'] != null) {
            packageIds.add(item['lab_package_id'].toString());
          }
        }
        
        // Try different possible cart ID field names
        cartId = widget.cartData['id']?.toString() ?? 
                 widget.cartData['cart_id']?.toString() ?? 
                 widget.cartData['cartId']?.toString() ?? 
                 widget.cartData['cartId']?.toString() ?? '';
        
        print('🔄 Cart ID from id: ${widget.cartData['id']}');
        print('🔄 Cart ID from cart_id: ${widget.cartData['cart_id']}');
        print('🔄 Cart ID from cartId: ${widget.cartData['cartId']}');
        
        print('🔄 Extracted cart ID: $cartId');
      }

      print('🔄 Applying coupon: $couponCode');
      print('🔄 Test IDs: $testIds');
      print('🔄 Package IDs: $packageIds');
      print('🔄 Cart ID: $cartId');
      print('🔄 Lab ID: ${widget.organizationId}');
      print('🔄 Total amount: $actualPayableAmount');

      final apiService = ApiService();
      final result = await apiService.applyPromoCode(
        promoCode: couponCode!,
        totalAmount: actualPayableAmount,
        testIds: testIds,
        packageIds: packageIds,
        labId: widget.organizationId,
        cartId: cartId,
        paymentMethod: selectedPaymentMethod,
        context: context,
      );

      print('🔄 Coupon API result: $result');

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          appliedCoupon = data['promo_code'];
          couponDiscount = (data['discount_amount'] ?? 0.0).toDouble();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon applied successfully! ${data['discount_type'] == 'percentage' ? '${data['discount_value']}% OFF' : '₹${data['discount_value']} OFF'}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          couponError = result['message'] ?? 'Invalid coupon code';
        });
      }
    } catch (e) {
      print('❌ Error applying coupon: $e');
      setState(() {
        couponError = 'Error applying coupon. Please try again.';
      });
    } finally {
      setState(() {
        isApplyingCoupon = false;
      });
    }
  }

  void _updateCouponForPaymentMethod() async {
    // Only update if a coupon is already applied
    if (appliedCoupon == null || appliedCoupon!.isEmpty) {
      return;
    }

    print('🔄 Updating coupon for payment method: $selectedPaymentMethod');

    setState(() {
      isApplyingCoupon = true;
      couponError = null;
    });

    try {
      // Extract test and package IDs from cart data
      List<String> testIds = [];
      List<String> packageIds = [];
      String cartId = '';
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        
        for (var item in items) {
          if (item['lab_test_id'] != null) {
            testIds.add(item['lab_test_id'].toString());
          }
          if (item['lab_package_id'] != null) {
            packageIds.add(item['lab_package_id'].toString());
          }
        }
        
        cartId = widget.cartData['id']?.toString() ?? 
                 widget.cartData['cart_id']?.toString() ?? 
                 widget.cartData['cartId']?.toString() ?? '';
      }

      print('🔄 Re-applying coupon: $appliedCoupon');
      print('🔄 New payment method: $selectedPaymentMethod');
      print('🔄 Total amount: $actualPayableAmount');

      final apiService = ApiService();
      final result = await apiService.applyPromoCode(
        promoCode: appliedCoupon!,
        totalAmount: actualPayableAmount,
        testIds: testIds,
        packageIds: packageIds,
        labId: widget.organizationId,
        cartId: cartId,
        paymentMethod: selectedPaymentMethod,
        context: context,
      );

      print('🔄 Coupon update result: $result');

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          couponDiscount = (data['discount_amount'] ?? 0.0).toDouble();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon updated for $selectedPaymentMethod! ${data['discount_type'] == 'percentage' ? '${data['discount_value']}% OFF' : '₹${data['discount_value']} OFF'}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          couponError = result['message'] ?? 'Coupon not valid for this payment method';
          // Clear the applied coupon if it's not valid for the new payment method
          appliedCoupon = null;
          couponDiscount = 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon not valid for $selectedPaymentMethod. Please try a different coupon.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating coupon: $e');
      setState(() {
        couponError = 'Error updating coupon. Please try again.';
      });
    } finally {
      setState(() {
        isApplyingCoupon = false;
      });
    }
  }

  void _changeLab() async {
    print('🔄 Change lab button pressed');
    
    // Show confirmation dialog
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Lab'),
          content: const Text('Are you sure you want to change the lab? This will clear your current selection and take you back to lab selection.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Lab'),
            ),
          ],
        );
      },
    );

    if (shouldChange == true) {
      print('🔄 User confirmed lab change');
      
      // Clear any applied coupon since lab is changing
      if (appliedCoupon != null) {
        setState(() {
          appliedCoupon = null;
          couponDiscount = 0.0;
          couponError = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon cleared due to lab change'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      // Navigate back to lab selection screen
      Navigator.of(context).pop(); // Close checkout screen
      // The lab selection screen should still be in the navigation stack
      // so we don't need to pop again
    }
  }

  void _addMoreTests() {
    print('🔄 Add more tests button pressed');
    
    // Navigate back to tests tab
    // First pop to go back to lab selection screen
    Navigator.of(context).pop(); // Close checkout screen
    // Then pop again to go back to tests tab
    Navigator.of(context).pop(); // Close lab selection screen to go back to tests tab
    
    // Show a helpful message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can now add more tests to your cart'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AnimatedSuccessDialog(
          onAnimationComplete: () {
            print('🔄 Animation complete, navigating to order detail');
            try {
              Navigator.of(context).pop();
              // Navigate to order detail page with sample order data
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(
                                      order: {
                    'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
                    'orderDate': _formatDateTime(DateTime.now()),
                    'status': 'confirmed',
                    'scheduledDate': _formatDateTime(selectedDate),
                    'scheduledTime': selectedTime,
                    'collectionType': isHomeCollection ? 'Home Collection' : 'Lab Visit',
                    'tests': widget.cartItems.map((testName) => {
                      'name': testName,
                      'description': 'Test description',
                      'price': (widget.testPrices[testName] ?? 0.0).toString(),
                    }).toList(),
                    'lab': {
                      'name': widget.selectedLab,
                      'address': 'Lab Address',
                      'rating': '4.5',
                      'reviews': '120',
                      'phone': '+91 98765 43210',
                      'email': 'info@lab.com',
                      'workingHours': '8:00 AM - 8:00 PM',
                    },
                    'payment': {
                      'method': 'Online Payment',
                      'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
                      'subtotal': widget.labOriginalPrice.toString(),
                      'discount': widget.labDiscount,
                      'total': widget.labDiscountedPrice.toString(),
                    },
                    'collection': {
                      'address': selectedAddress ?? 'Not specified',
                      'contactPerson': selectedPatient,
                      'contactPhone': '+91 98765 43210',
                      'instructions': 'Please keep the sample ready for collection',
                    },
                  },
                  ),
                ),
              );
              print('✅ Navigation to OrderDetailScreen successful');
            } catch (e) {
              print('❌ Navigation error: $e');
              // Fallback: navigate to home
              Navigator.of(context).pushReplacementNamed('/landing');
            }
          },
        );
      },
    );
  }



  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    // Convert to 12-hour format
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$day $month $year ${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatTimeTo12Hour(String time24) {
    if (time24.isEmpty) return '';
    
    try {
      // Parse 24-hour format (e.g., "09:00", "14:30")
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) hour -= 12;
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24; // Return original if parsing fails
    }
  }

  Widget _buildSlotItem(Map<String, dynamic> slot, String sessionName) {
    final isAvailable = slot['status'] == 'available';
    final isSelected = selectedSession == sessionName && 
                     selectedSlot == '${slot['start_time']} - ${slot['end_time']}';
    final doctor = slot['doctor'] as Map<String, dynamic>?;
    
    return InkWell(
      onTap: isAvailable ? () {
        setState(() {
          selectedSession = sessionName;
          selectedSlot = '${slot['start_time']} - ${slot['end_time']}';
          selectedDoctor = doctor?['name'] ?? '';
          selectedTime = '${slot['start_time']} - ${slot['end_time']}';
        });
        Navigator.pop(context);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryBlue 
              : isAvailable 
                  ? Colors.grey[100] 
                  : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryBlue 
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Text(
              _formatTimeTo12Hour(slot['start_time'] ?? ''),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : isAvailable 
                        ? Colors.black87 
                        : Colors.grey,
              ),
            ),
            if (doctor != null) ...[
              const SizedBox(height: 4),
              Text(
                doctor['name'] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected 
                      ? Colors.white.withOpacity(0.8) 
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCoupon(String code, String description, String discount) {
    return InkWell(
      onTap: () async {
        setState(() {
          couponCode = code;
        });
        await _applyCoupon();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_offer,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                discount,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }







  final List<Map<String, dynamic>> _availableTests = [
    {
      'name': 'Complete Blood Count (CBC)',
      'description': 'Blood cell count analysis',
      'price': 599.0,
      'discount': '40% OFF',
      'requiresFasting': false,
    },
    {
      'name': 'Diabetes Screening',
      'description': 'Blood glucose level test',
      'price': 299.0,
      'discount': '50% OFF',
      'requiresFasting': true,
    },
    {
      'name': 'Liver Function Test (LFT)',
      'description': 'Liver enzyme analysis',
      'price': 799.0,
      'discount': '38% OFF',
      'requiresFasting': true,
    },
    {
      'name': 'Kidney Function Test (KFT)',
      'description': 'Kidney function analysis',
      'price': 699.0,
      'discount': '42% OFF',
      'requiresFasting': true,
    },
    {
      'name': 'Thyroid Profile (T3, T4, TSH)',
      'description': 'Thyroid hormone levels',
      'price': 899.0,
      'discount': '40% OFF',
      'requiresFasting': false,
    },
    {
      'name': 'Lipid Profile',
      'description': 'Cholesterol and triglyceride levels',
      'price': 499.0,
      'discount': '44% OFF',
      'requiresFasting': true,
    },
    {
      'name': 'Vitamin D Test',
      'description': 'Vitamin D level analysis',
      'price': 399.0,
      'discount': '43% OFF',
      'requiresFasting': false,
    },
    {
      'name': 'HbA1c Test',
      'description': 'Average blood sugar levels',
      'price': 349.0,
      'discount': '46% OFF',
      'requiresFasting': false,
    },
  ];

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
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: AppColors.primaryBlue,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.selectedLab,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _changeLab(),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Change'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
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
                                  '4.8',
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
                                  '2.5 km away',
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tests Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Tests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addMoreTests(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add More'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tests List
            ...selectedTests.map((testName) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (widget.labOriginalPrice > widget.labDiscountedPrice)
                                Text(
                                  '₹${widget.labOriginalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (widget.labOriginalPrice > widget.labDiscountedPrice)
                                const SizedBox(width: 8),
                              Text(
                                '₹${widget.labDiscountedPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              if (widget.labDiscount.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  widget.labDiscount,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        setState(() {
                          selectedTests.remove(testName);
                        });
                        
                        // Remove from cart
                        await _removeFromCart(testName);
                        
                        // Call the callback function if provided
                        if (widget.onRemoveFromCart != null) {
                          widget.onRemoveFromCart!(testName);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Clear Cart Button
            if (selectedTests.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Store the items before clearing
                    final itemsToRemove = selectedTests.toList();
                    
                    setState(() {
                      selectedTests.clear();
                    });
                    
                    final result = await _clearCart();
                    if (result) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cart cleared successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Call the callback function for each removed item
                      if (widget.onRemoveFromCart != null) {
                        for (final testName in itemsToRemove) {
                          widget.onRemoveFromCart!(testName);
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to clear cart'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All Items'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Patient Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _showPatientSelectionBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patient',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  selectedPatient,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Collection Type
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Home Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Switch(
                        value: isHomeCollection,
                        onChanged: (value) {
                          setState(() {
                            isHomeCollection = value;
                            if (!value) {
                              selectedAddress = null;
                            }
                          });
                        },
                        activeColor: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                  if (isHomeCollection) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _showAddressSelectionBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primaryBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Collection Address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    selectedAddress != null
                                        ? _addresses.firstWhere((addr) => addr['id'] == selectedAddress)['address']
                                        : 'Select address',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: selectedAddress != null ? Colors.black87 : Colors.grey,
                                    ),
                                  ),
                                  if (selectedAddress != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_addresses.firstWhere((addr) => addr['id'] == selectedAddress)['city']}, ${_addresses.firstWhere((addr) => addr['id'] == selectedAddress)['state']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date and Time Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _showDatePicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _formatDate(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _showTimePicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  selectedTime,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Wallet Balance Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Wallet Balance',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${walletBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: useWalletBalance,
                          onChanged: (value) {
                            setState(() {
                              useWalletBalance = value;
                              if (value) {
                                selectedPaymentMethod = 'Wallet';
                              } else {
                                selectedPaymentMethod = 'Online Payment';
                              }
                            });
                            // Update coupon discount for new payment method
                            _updateCouponForPaymentMethod();
                          },
                          activeColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Options
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedPaymentMethod = 'Online Payment';
                        useWalletBalance = false;
                      });
                      // Update coupon discount for new payment method
                      _updateCouponForPaymentMethod();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Online Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue : Colors.black87,
                              ),
                            ),
                          ),
                          if (selectedPaymentMethod == 'Online Payment')
                            const Icon(Icons.check_circle, color: AppColors.primaryBlue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedPaymentMethod = 'Pay at Collection';
                        useWalletBalance = false;
                      });
                      // Update coupon discount for new payment method
                      _updateCouponForPaymentMethod();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money,
                            color: selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pay at Collection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue : Colors.black87,
                              ),
                            ),
                          ),
                          if (selectedPaymentMethod == 'Pay at Collection')
                            const Icon(Icons.check_circle, color: AppColors.primaryBlue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Coupon Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apply Coupon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (appliedCoupon == null) ...[
                    // Coupon Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            onChanged: (value) {
                              setState(() {
                                couponCode = value;
                                couponError = null; // Clear error when user types
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryBlue),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.local_offer, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (couponCode != null && couponCode!.isNotEmpty && !isApplyingCoupon) ? () async {
                            await _applyCoupon();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isApplyingCoupon
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    // Error display
                    if (couponError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                couponError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ] else ...[
                    // Applied Coupon Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coupon Applied: $appliedCoupon',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Discount: ₹${couponDiscount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                appliedCoupon = null;
                                couponCode = null;
                                couponDiscount = 0.0;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price Summary
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (shouldApplyDiscount && totalOriginalPrice > totalDiscountedPrice)
                            Text(
                              '₹${totalOriginalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '₹${actualPayableAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (shouldApplyDiscount && totalOriginalPrice > totalDiscountedPrice) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Discount applied (${selectedPaymentMethod == 'Online Payment' ? 'Online Payment' : 'Full Wallet Payment'})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!shouldApplyDiscount && totalOriginalPrice > totalDiscountedPrice) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pay online or use full wallet balance to get discount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (appliedCoupon != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Coupon Discount:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          '-₹${couponDiscount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'After Coupon:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '₹${actualPayableAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (useWalletBalance) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Wallet Balance:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          '₹${walletBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Amount to Pay:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '₹${amountAfterWallet.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Book Button
              ElevatedButton(
                onPressed: selectedTests.isNotEmpty && 
                         (!isHomeCollection || (isHomeCollection && selectedAddress != null)) &&
                         (useWalletBalance ? amountAfterWallet <= 0 : true) && !isBooking ? () {
                  print('🔄 Book Now button pressed');
                  _createBooking();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isBooking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Booking...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSuccessDialog extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const _AnimatedSuccessDialog({required this.onAnimationComplete});

  @override
  State<_AnimatedSuccessDialog> createState() => _AnimatedSuccessDialogState();
}

class _AnimatedSuccessDialogState extends State<_AnimatedSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _scaleController.forward();
    
    // Delay check animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkController.forward();
      }
    });
    
    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Success Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _checkAnimation.value,
                          child: const Icon(
                            Icons.check_circle,
                            size: 50,
                            color: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Success Title
                  const Text(
                    'Booking Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Success Message
                  const Text(
                    'Your appointment has been confirmed. You will receive a confirmation email shortly.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Loading indicator
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Redirecting to order details...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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
}