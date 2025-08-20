import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'tests_listing_screen.dart';
import 'family_members_screen.dart';
import 'addresses_screen.dart';


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
  final VoidCallback? onCartCleared; // Callback for when entire cart is cleared
  final Map<String, dynamic>? multiLabData; // For multi-lab bookings
  final Map<String, dynamic>? schedulingData; // For single lab scheduling

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
    this.onCartCleared, // Optional callback for cart clearing
    this.multiLabData, // Optional multi-lab data
    this.schedulingData, // Optional scheduling data
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  Set<String> selectedTests = {};
  Set<String> selectedPackages = {};
  Map<String, String> testIdToName = {}; // Map test IDs to test names
  Map<String, String> packageIdToName = {}; // Map package IDs to package names
  String selectedPaymentMethod = 'Online Payment';
  bool isHomeCollection = true;
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:00 AM - 12:00 PM';
  String selectedPatient = 'Myself';
  String? selectedAddress;
  bool useWalletBalance = false;
  double walletBalance = 0.0; // Will be loaded from API
  bool isLoadingWallet = true; // Start loading immediately
  String? walletError;
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
    
    // Initialize cart items from the initial cart data
    _updateCartFromFreshData(widget.cartData);
    
    print('🔄 CheckoutScreen initState');
    print('🔄 Organization ID: ${widget.organizationId}');
    print('🔄 Selected Lab: ${widget.selectedLab}');
    
    // Debug test and package prices
    print('🔍 DEBUGGING TEST AND PACKAGE PRICES:');
    print('🔍 Selected Tests: $selectedTests');
    print('🔍 Selected Packages: $selectedPackages');
    print('🔍 Test prices map: ${widget.testPrices}');
    print('🔍 Cart data: ${widget.cartData}');
    for (final testId in selectedTests) {
      final testName = testIdToName[testId] ?? testId;
      final price = widget.testPrices[testName];
      print('🔍 Test "$testName" (ID: $testId) -> Price: ₹$price');
    }
    for (final packageId in selectedPackages) {
      final packageName = packageIdToName[packageId] ?? packageId;
      final price = _getPackagePrice(packageName);
      print('🔍 Package "$packageName" (ID: $packageId) -> Price: ₹$price');
    }
    
    // Check if cart data has price information
    if (widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      print('🔍 Cart data items with prices:');
      for (final item in items) {
        print('🔍 Item: ${item['test_name']} -> Price: ${item['price']} (Type: ${item.runtimeType})');
      }
    }
    
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
    
    // Load wallet balance
    _loadWalletBalance();
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

  // Load wallet balance
  Future<void> _loadWalletBalance() async {
    setState(() {
      isLoadingWallet = true;
      walletError = null;
    });

    try {
      final result = await _apiService.getMobileWallet();
      
      print('💰 Wallet API Response: $result');
      print('💰 Response type: ${result.runtimeType}');
      print('💰 Success field: ${result['success']}');
      print('💰 Data field: ${result['data']}');
      print('💰 Data type: ${result['data']?.runtimeType}');
      
      if (result['success'] == true && mounted) {
        final walletData = result['data'];
        print('💰 Wallet data: $walletData');
        print('💰 Wallet data type: ${walletData.runtimeType}');
        print('💰 Wallet field: ${walletData?['wallet']}');
        print('💰 Balance field: ${walletData?['wallet']?['balance']}');
        print('💰 Balance field type: ${walletData?['wallet']?['balance']?.runtimeType}');
        
        if (walletData != null && walletData['wallet'] != null && walletData['wallet']['balance'] != null) {
          final balanceString = walletData['wallet']['balance'].toString();
          print('💰 Balance string: "$balanceString"');
          final balance = double.tryParse(balanceString) ?? 0.0;
          print('💰 Parsed balance: $balance');
          
          setState(() {
            walletBalance = balance;
            isLoadingWallet = false;
          });
          print('✅ Loaded wallet balance: ₹${walletBalance.toStringAsFixed(0)}');
        } else {
          setState(() {
            walletBalance = 0.0;
            isLoadingWallet = false;
          });
          print('⚠️ No wallet balance found, setting to 0');
          print('⚠️ walletData is null: ${walletData == null}');
          print('⚠️ wallet field is null: ${walletData?['wallet'] == null}');
          print('⚠️ balance is null: ${walletData?['wallet']?['balance'] == null}');
        }
      } else {
        setState(() {
          walletError = result['message'] ?? 'Failed to load wallet balance';
          isLoadingWallet = false;
        });
        print('❌ Failed to load wallet balance: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        walletError = 'Error loading wallet balance: $e';
        isLoadingWallet = false;
      });
      print('❌ Error loading wallet balance: $e');
    }
  }

  // Helper method to get discounted test price (always shows discounted price by default)
  double _getTestDiscountedPrice(String testName) {
    if (widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (final item in items) {
        final itemName = item['test_name']?.toString() ?? '';
        if (itemName == testName || itemName.toLowerCase() == testName.toLowerCase()) {
          print('🔍 Found matching item for discount calculation: $item');
          
          // Always try to get discounted price first (by default)
          // Try to get discounted price from different possible fields
          if (item['discounted_amount'] != null) {
            print('🔍 Using discounted_price field: ${item['discounted_price']}');
            if (item['discounted_amount'] is String) {
              return double.tryParse(item['discounted_amount']) ?? _getTestPrice(testName);
            } else if (item['discounted_amount'] is num) {
              return item['discounted_amount'].toDouble();
            }
          }
          if (item['final_price'] != null) {
            print('🔍 Using final_price field: ${item['final_price']}');
            if (item['final_price'] is String) {
              return double.tryParse(item['final_price']) ?? _getTestPrice(testName);
            } else if (item['final_price'] is num) {
              return item['final_price'].toDouble();
            }
          }
          
          // Always calculate discounted price from original price and discount percentage
          final originalPrice = _getTestPrice(testName);
          if (originalPrice > 0) {
            final discountText = widget.testDiscounts[testName] ?? '';
            if (discountText.isNotEmpty && discountText.contains('%')) {
              // Extract discount percentage
              final percentMatch = RegExp(r'(\d+)%').firstMatch(discountText);
              if (percentMatch != null) {
                final discountPercent = int.tryParse(percentMatch.group(1) ?? '0') ?? 0;
                final discountAmount = (originalPrice * discountPercent) / 100;
                final discountedPrice = originalPrice - discountAmount;
                print('🔍 Calculated discounted price: $originalPrice - $discountAmount = $discountedPrice');
                return discountedPrice;
              }
            }
          }
          break;
        }
      }
    }
    
    // If couldn't find discounted price, return original price
    return _getTestPrice(testName);
  }

  // Helper method to get test price from cart data
  double _getTestPrice(String testName) {
    print('🔍 _getTestPrice called for: "$testName"');
    
    if (widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (final item in items) {
        final itemName = item['test_name']?.toString() ?? '';
        if (itemName == testName || itemName.toLowerCase() == testName.toLowerCase()) {
          print('🔍 Found matching item in cart data: $item');
          
          // Try to get price from different possible fields
          if (item['price'] != null) {
            print('🔍 Found price field: ${item['price']} (type: ${item['price'].runtimeType})');
            if (item['price'] is String) {
              final price = double.tryParse(item['price']) ?? 0.0;
              print('🔍 Parsed string price: $price');
              return price;
            } else if (item['price'] is num) {
              final price = item['price'].toDouble();
              print('🔍 Converted num price: $price');
              return price;
            }
          }
          if (item['test_price'] != null) {
            print('🔍 Found test_price field: ${item['test_price']} (type: ${item['test_price'].runtimeType})');
            if (item['test_price'] is String) {
              final price = double.tryParse(item['test_price']) ?? 0.0;
              print('🔍 Parsed string test_price: $price');
              return price;
            } else if (item['test_price'] is num) {
              final price = item['test_price'].toDouble();
              print('🔍 Converted num test_price: $price');
              return price;
            }
          }
          break;
        }
      }
    }
    
    // Fallback to widget.testPrices if cart data doesn't have price
    final fallbackPrice = widget.testPrices[testName] ?? 0.0;
    print('🔍 Using fallback price for "$testName": $fallbackPrice');
    return fallbackPrice;
  }

  // Helper method to get package price from cart data
  double _getPackagePrice(String packageName) {
    print('🔍 _getPackagePrice called for: "$packageName"');
    
    if (widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (final item in items) {
        final itemName = item['test_name']?.toString() ?? '';
        if (itemName == packageName || itemName.toLowerCase() == packageName.toLowerCase()) {
          print('🔍 Found matching package item in cart data: $item');
          
          // Try to get price from different possible fields for packages
          if (item['price'] != null) {
            print('🔍 Found price field: ${item['price']} (type: ${item['price'].runtimeType})');
            if (item['price'] is String) {
              final price = double.tryParse(item['price']) ?? 0.0;
              print('🔍 Parsed string price: $price');
              return price;
            } else if (item['price'] is num) {
              final price = item['price'].toDouble();
              print('🔍 Converted num price: $price');
              return price;
            }
          }
          if (item['baseprice'] != null) {
            print('🔍 Found baseprice field: ${item['baseprice']} (type: ${item['baseprice'].runtimeType})');
            if (item['baseprice'] is String) {
              final price = double.tryParse(item['baseprice']) ?? 0.0;
              print('🔍 Parsed string baseprice: $price');
              return price;
            } else if (item['baseprice'] is num) {
              final price = item['baseprice'].toDouble();
              print('🔍 Converted num baseprice: $price');
              return price;
            }
          }
          break;
        }
      }
    }
    
    // Fallback to widget.testPrices if cart data doesn't have price
    final fallbackPrice = widget.testPrices[packageName] ?? 0.0;
    print('🔍 Using fallback price for package "$packageName": $fallbackPrice');
    return fallbackPrice;
  }

  // Helper method to get package discounted price from cart data
  double _getPackageDiscountedPrice(String packageName) {
    print('🔍 _getPackageDiscountedPrice called for: "$packageName"');
    
    if (widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (final item in items) {
        final itemName = item['test_name']?.toString() ?? '';
        if (itemName == packageName || itemName.toLowerCase() == packageName.toLowerCase()) {
          print('🔍 Found matching package item in cart data: $item');
          
          // Try to get discounted price from different possible fields for packages
          if (item['discounted_amount'] != null) {
            print('🔍 Found discounted_amount field: ${item['discounted_amount']} (type: ${item['discounted_amount'].runtimeType})');
            if (item['discounted_amount'] is String) {
              final price = double.tryParse(item['discounted_amount']) ?? _getPackagePrice(packageName);
              print('🔍 Parsed string discounted_amount: $price');
              return price;
            } else if (item['discounted_amount'] is num) {
              final price = item['discounted_amount'].toDouble();
              print('🔍 Converted num discounted_amount: $price');
              return price;
            }
          }
          if (item['final_price'] != null) {
            print('🔍 Found final_price field: ${item['final_price']} (type: ${item['final_price'].runtimeType})');
            if (item['final_price'] is String) {
              final price = double.tryParse(item['final_price']) ?? _getPackagePrice(packageName);
              print('🔍 Parsed string final_price: $price');
              return price;
            } else if (item['final_price'] is num) {
              final price = item['final_price'].toDouble();
              print('🔍 Converted num final_price: $price');
              return price;
            }
          }
          if (item['discountedprice'] != null) {
            print('🔍 Found discountedprice field: ${item['discountedprice']} (type: ${item['discountedprice'].runtimeType})');
            if (item['discountedprice'] is String) {
              final price = double.tryParse(item['discountedprice']) ?? _getPackagePrice(packageName);
              print('🔍 Parsed string discountedprice: $price');
              return price;
            } else if (item['discountedprice'] is num) {
              final price = item['discountedprice'].toDouble();
              print('🔍 Converted num discountedprice: $price');
              return price;
            }
          }
          break;
        }
      }
    }
    
    // If no discounted price found, return the original price
    return _getPackagePrice(packageName);
  }

  Future<bool> _clearCart() async {
    print('🛒 Clearing cart from database and local storage...');
    try {
      // Clear cart from database
      final result = await _apiService.clearCart(context);
      if (result['success']) {
        // Clear cart from local storage
        await StorageService.clearCart();
        print('✅ Cart cleared successfully from both database and local storage');
        return true;
      } else {
        print('❌ Failed to clear cart from database: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      return false;
    }
  }

  Future<void> _removeFromCart(String testId) async {
    print('🛒 Removing test ID: $testId from cart...');
    print('🛒 Current selectedTests: $selectedTests');
    print('🛒 Cart data available: ${widget.cartData != null}');
    try {
      // Find the cart item ID for this test ID
      String? cartItemId;
      
      print('🔍 Looking for cart item with test ID: $testId');
      print('🔍 Available cart data keys: ${widget.cartData?.keys}');
      
      // The main items array should contain all cart items with proper structure
      if (widget.cartData != null && widget.cartData!['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData!['items']);
        print('🔍 Found ${items.length} items in cart data');
        
        for (final item in items) {
          final itemTestId = item['lab_test_id']?.toString() ?? item['lab_package_id']?.toString() ?? item['id']?.toString();
          print('🔍 Checking item test ID: $itemTestId against target: $testId');
          
          if (itemTestId == testId) {
            cartItemId = item['id']?.toString() ?? item['cart_id']?.toString();
            print('✅ Found matching item with test ID: $itemTestId and cart ID: $cartItemId');
            break;
          }
        }
      } else {
        print('❌ No items array found in cart data');
        print('❌ Cart data structure: ${widget.cartData}');
      }
          
      if (cartItemId != null && cartItemId.isNotEmpty) {
        print('🛒 Found cart item ID: $cartItemId for test ID: $testId');
        final result = await _apiService.removeFromCart(cartItemId);
        if (result['success']) {
          print('✅ Item removed from cart successfully');
          
          // Update local state to remove the test
          setState(() {
            selectedTests.remove(testId);
          });
          
          // Call parent callback if available
          if (widget.onRemoveFromCart != null) {
            print('📞 Calling parent callback for removed test ID: $testId');
            widget.onRemoveFromCart!(testId);
          }
          
          // Show success message
          final testName = testIdToName[testId] ?? testId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$testName removed from cart'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('❌ Failed to remove item from cart: ${result['message']}');
          final testName = testIdToName[testId] ?? testId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove $testName from cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ Could not find cart item ID for test ID: $testId');
        final testName = testIdToName[testId] ?? testId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not remove $testName from cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error removing item from cart: $e');
      final testName = testIdToName[testId] ?? testId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing $testName from cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Convert display payment method to API expected value
  String _getApiPaymentMode(String displayPaymentMethod) {
    switch (displayPaymentMethod) {
      case 'Pay at Collection':
      case 'Cash on Collection':
        return 'CASH';
      case 'Online Payment':
      case 'Card Payment':
      case 'Debit/Credit Card':
        return 'CARD';
      case 'Wallet':
        return 'WALLET';
      default:
        print('⚠️ Unknown payment method: $displayPaymentMethod, defaulting to CARD');
        return 'CARD';
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
      print('📋 Test ID to Name Mapping: $testIdToName');
      
      // Debug cart items structure
      if (widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        print('📋 Cart Items Structure:');
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          print('📋 Item $i:');
          print('📋   test_name: ${item['test_name']}');
          print('📋   lab_test_id: ${item['lab_test_id']}');
          print('📋   lab_package_id: ${item['lab_package_id']}');
          print('📋   id: ${item['id']}');
          print('📋   type: ${item['type']}');
        }
      }
      
      // Extract test IDs from selected tests (now contains IDs directly)
      final List<String> labTests = [];
      final List<String> packages = [];
      
      // Since selectedTests now contains IDs, we need to categorize them as tests or packages
      for (final testId in selectedTests) {
        print('📋 Processing test ID: $testId');
        
        // Find the corresponding item in cart data to determine if it's a test or package
        bool foundInCart = false;
        
        if (widget.cartData['items'] != null) {
          for (final item in widget.cartData['items']) {
            final itemTestId = item['lab_test_id']?.toString();
            final itemPackageId = item['lab_package_id']?.toString();
            final itemId = item['id']?.toString();
            
            // Check if this item matches our test ID
            if (itemTestId == testId || itemPackageId == testId || itemId == testId) {
              print('📋 Found matching item in cart: ${item['test_name']}');
              print('📋 Item details - lab_test_id: $itemTestId, lab_package_id: $itemPackageId, id: $itemId');
              
              // Determine if it's a package or test based on which ID field is present
              if (itemPackageId != null && itemPackageId.isNotEmpty) {
                packages.add(itemPackageId);
                print('📋 Found package with ID: $itemPackageId');
              } else if (itemTestId != null && itemTestId.isNotEmpty) {
                labTests.add(itemTestId);
                print('📋 Found test with ID: $itemTestId');
              } else {
                // Fallback: use the item ID and determine type from item structure
                final testName = item['test_name']?.toString().toLowerCase() ?? '';
                final itemType = item['type']?.toString().toLowerCase() ?? '';
                
                bool isPackage = itemType == 'package' || 
                                testName.contains('package') || 
                                testName.contains('combo') || 
                                testName.contains('bundle') ||
                                testName.contains('profile');
                
                if (isPackage) {
                  packages.add(itemId!);
                  print('📋 Found package item with ID: $itemId (name: ${item['test_name']})');
                } else {
                  labTests.add(itemId!);
                  print('📋 Found test item with ID: $itemId (name: ${item['test_name']})');
                }
              }
              foundInCart = true;
              break;
            }
          }
        }
        
        // If not found in cart data, try to determine type from testIdToName mapping
        if (!foundInCart) {
          final testName = testIdToName[testId];
          print('📋 Not found in cart data, checking testIdToName for: $testId -> $testName');
          
          // More robust package detection
          bool isPackage = false;
          if (testName != null) {
            final lowerName = testName.toLowerCase();
            isPackage = lowerName.contains('package') || 
                       lowerName.contains('combo') || 
                       lowerName.contains('bundle') ||
                       lowerName.contains('profile');
          }
          
          if (isPackage) {
            packages.add(testId);
            print('📋 Added as package based on name: $testName');
          } else {
            labTests.add(testId);
            print('📋 Added as test based on name: $testName');
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
      
      // Determine payment mode using helper function
      String paymentMode = _getApiPaymentMode(selectedPaymentMethod);
      
      // Override with wallet if wallet covers full amount
      if (useWalletBalance && amountAfterWallet <= 0) {
        paymentMode = 'WALLET';
      }
      
      print('💳 Payment method conversion: "$selectedPaymentMethod" → "$paymentMode"');
      
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

      if (result['success'] == true) {
        print('✅ Booking created successfully');
        setState(() {
          isBooking = false;
        });
        
        // Clear the cart after successful booking
        await _clearCart();
        
        // Notify parent that cart has been cleared
        if (widget.onCartCleared != null) {
          print('🔄 Notifying parent that cart has been cleared');
          widget.onCartCleared!();
        }
        
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
      // Try to load from API first to get session parameters
      final apiService = ApiService();
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      print('🔄 Calling API with orgId: ${widget.organizationId}, date: $dateString');
      
      final result = await apiService.getOrganizationTimeslots(
        orgId: widget.organizationId,
        date: dateString,
      );
      
      print('🔄 API result: $result');
      
      // Extract session parameters from API response or use defaults
      String sessionStart = '09:00:00';
      String sessionEnd = '19:00:00';
      int slotDurationMin = 30;
      String sessionName = 'Working Hours';
      
      if (result['success'] && result['data'] != null && result['data']['timeslots'] != null) {
        final timeslots = List<Map<String, dynamic>>.from(result['data']['timeslots']);
        if (timeslots.isNotEmpty) {
          final firstSession = timeslots[0];
          sessionStart = firstSession['session_start'] ?? '09:00:00';
          sessionEnd = firstSession['session_end'] ?? '19:00:00';
          slotDurationMin = firstSession['slot_duration_min'] ?? 30;
          sessionName = firstSession['session_name'] ?? 'Working Hours';
          
          // Ensure session times have seconds if missing
          if (!sessionStart.contains(':') || sessionStart.split(':').length < 3) {
            sessionStart = sessionStart.contains(':') ? '$sessionStart:00' : '09:00:00';
          }
          if (!sessionEnd.contains(':') || sessionEnd.split(':').length < 3) {
            sessionEnd = sessionEnd.contains(':') ? '$sessionEnd:00' : '19:00:00';
          }
          
          print('🔄 Extracted session parameters from API:');
          print('🔄 Session Start: $sessionStart');
          print('🔄 Session End: $sessionEnd');
          print('🔄 Slot Duration: ${slotDurationMin}min');
        }
      }
      
      // Generate time slots based on dynamic session parameters
      final generatedSlots = _generateTimeSlots(
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
        slotDurationMin: slotDurationMin,
      );
      
      // Create timeslot data structure with generated slots
      final generatedTimeslotData = {
        'timeslots': [
          {
            'session_name': sessionName,
            'session_start': sessionStart.substring(0, 5), // Remove seconds for display
            'session_end': sessionEnd.substring(0, 5),     // Remove seconds for display
            'slot_duration_min': slotDurationMin,
            'slots': generatedSlots,
          }
        ]
      };
      
      print('🔄 Generated timeslot data: $generatedTimeslotData');
      
      if (result['success'] && mounted) {
        // If API returns data, merge it with generated slots
        final apiData = result['data'];
        final mergedData = _mergeTimeslotData(generatedTimeslotData, apiData);
        
        setState(() {
          timeslotData = mergedData;
          isLoadingTimeslots = false;
        });
        print('✅ Timeslots loaded and merged successfully');
        print('✅ Final timeslot data: $timeslotData');
      } else {
        // If API fails, use generated slots as fallback
        if (mounted) {
          setState(() {
            timeslotData = generatedTimeslotData;
            isLoadingTimeslots = false;
          });
          print('⚠️ API call failed, using generated slots: ${result['message']}');
        }
      }
    } catch (e) {
      print('❌ Error in _loadTimeslots: $e');
      if (mounted) {
        // Even if there's an error, show generated slots
        final fallbackSlots = _generateTimeSlots(
          sessionStart: '09:00:00',
          sessionEnd: '19:00:00',
          slotDurationMin: 30,
        );
        
        setState(() {
          timeslotData = {
            'timeslots': [
              {
                'session_name': 'Working Hours',
                'session_start': '09:00',
                'session_end': '19:00',
                'slot_duration_min': 30,
                'slots': fallbackSlots,
              }
            ]
          };
          isLoadingTimeslots = false;
        });
        print('⚠️ Error occurred, using fallback generated slots');
      }
    }
  }

  // Merge generated timeslot data with API response to preserve availability information
  Map<String, dynamic> _mergeTimeslotData(Map<String, dynamic> generatedData, Map<String, dynamic> apiData) {
    print('🔄 Merging generated slots with API data');
    
    try {
      // Start with generated data as base
      final mergedData = Map<String, dynamic>.from(generatedData);
      
      // If API data has timeslots, use it to update availability
      if (apiData['timeslots'] != null) {
        final apiTimeslots = List<Map<String, dynamic>>.from(apiData['timeslots']);
        final generatedTimeslots = List<Map<String, dynamic>>.from(mergedData['timeslots']);
        
        // For each generated session, check if API has corresponding data
        for (int i = 0; i < generatedTimeslots.length; i++) {
          final generatedSession = generatedTimeslots[i];
          final generatedSlots = List<Map<String, dynamic>>.from(generatedSession['slots']);
          
          // Find matching session in API data (if any)
          final matchingApiSession = apiTimeslots.firstWhere(
            (session) => session['session_name'] == generatedSession['session_name'],
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingApiSession.isNotEmpty && matchingApiSession['slots'] != null) {
            final apiSlots = List<Map<String, dynamic>>.from(matchingApiSession['slots']);
            
            // Update generated slots with API availability data
            for (int j = 0; j < generatedSlots.length; j++) {
              final generatedSlot = generatedSlots[j];
              
              // Find matching slot in API data
              final matchingApiSlot = apiSlots.firstWhere(
                (apiSlot) => apiSlot['start_time'] == generatedSlot['start_time'] && 
                            apiSlot['end_time'] == generatedSlot['end_time'],
                orElse: () => <String, dynamic>{},
              );
              
              if (matchingApiSlot.isNotEmpty) {
                // Update with API data (status, doctor, etc.)
                generatedSlots[j] = {
                  ...generatedSlot,
                  'status': matchingApiSlot['status'] ?? 'available',
                  'doctor': matchingApiSlot['doctor'] ?? generatedSlot['doctor'],
                };
              }
            }
            
            // Update the session with merged slots
            generatedTimeslots[i] = {
              ...generatedSession,
              'slots': generatedSlots,
            };
          }
        }
        
        mergedData['timeslots'] = generatedTimeslots;
      }
      
      print('✅ Successfully merged timeslot data');
      return mergedData;
      
    } catch (e) {
      print('❌ Error merging timeslot data: $e');
      // Return generated data as fallback
      return generatedData;
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
                              // Slots grid (3 per row, future slots only)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: () {
                                  // Filter future slots
                                  final futureSlots = _filterFutureSlots(slots, selectedDate);
                                  
                                  if (futureSlots.isEmpty) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          'No available time slots for this date',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return Column(
                                    children: List.generate(
                                      (futureSlots.length / 3).ceil(),
                                      (rowIndex) {
                                        final startIndex = rowIndex * 3;
                                        final endIndex = (startIndex + 3 <= futureSlots.length) ? startIndex + 3 : futureSlots.length;
                                        final rowSlots = futureSlots.sublist(startIndex, endIndex);
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              ...rowSlots.asMap().entries.map((entry) {
                                                final index = entry.key;
                                                final slot = entry.value;
                                                return [
                                                  _buildSlotItem(slot, sessionName),
                                                  if (index < rowSlots.length - 1) const SizedBox(width: 8),
                                                ];
                                              }).expand((element) => element),
                                              // Fill remaining space if less than 3 slots in this row
                                              ...List.generate(
                                                3 - rowSlots.length,
                                                (index) => const Expanded(child: SizedBox()),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }(),
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
    print('🔍 actualPayableAmount calculation:');
    print('🔍   selectedPaymentMethod: $selectedPaymentMethod');
    print('🔍   useWalletBalance: $useWalletBalance');
    print('🔍   walletCoversFullAmount: $walletCoversFullAmount');
    print('🔍   shouldApplyDiscount: $shouldApplyDiscount');
    
    // Use centralized discount logic
    if (shouldApplyDiscount) {
      final discountedAmount = totalDiscountedPrice - couponDiscount;
      print('🔍   Using discounted price: $totalDiscountedPrice - $couponDiscount = $discountedAmount');
      return discountedAmount;
    } else {
      final originalAmount = totalOriginalPrice - couponDiscount;
      print('🔍   Using original price: $totalOriginalPrice - $couponDiscount = $originalAmount');
      return originalAmount;
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
    // Check if user is paying full amount via online payment or wallet
    bool isFullPaymentOnline = selectedPaymentMethod == 'Online Payment';
    bool isFullPaymentWallet = useWalletBalance && walletCoversFullAmount;
    
    final shouldApply = (isFullPaymentOnline || isFullPaymentWallet) &&
                        selectedPaymentMethod != 'Pay at Collection';
    
    print('🔍 shouldApplyDiscount: $shouldApply (payment: $selectedPaymentMethod, wallet: $useWalletBalance, walletCoversFullAmount: $walletCoversFullAmount)');
    return shouldApply;
  }

  // Check if wallet balance covers the full amount after coupon discount
  bool get walletCoversFullAmount {
    // Check if wallet covers the discounted amount (which is what we want to check for full wallet payment)
    final finalAmount = totalDiscountedPrice - couponDiscount;
    return walletBalance >= finalAmount;
  }

  // Check if payment methods should be disabled (when wallet covers full amount)
  bool get shouldDisablePaymentMethods {
    return walletCoversFullAmount && useWalletBalance;
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
    _showAddMoreItemsBottomSheet();
  }

  void _addMorePackages() {
    print('🔄 Add more packages button pressed');
    _showAddMoreItemsBottomSheet();
  }

  // Show add more items bottom sheet
  void _showAddMoreItemsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AddMoreItemsBottomSheet(
          labId: widget.organizationId,
          labName: widget.selectedLab,
          cartItems: selectedTests.union(selectedPackages),
          onItemAdded: _onItemAddedToCart,
        );
      },
    );
  }

  // Wrapper method for when items are added to cart
  Future<void> _onItemAddedToCart() async {
    await _refreshCartData();
    setState(() {}); // Refresh the UI
  }

  // Refresh cart data after changes
  Future<void> _refreshCartData() async {
    print('🔄 Refreshing cart data...');
    
    try {
      // Fetch fresh cart data from API
      final cartResult = await _apiService.getCart();
      
      if (cartResult['success']) {
        final freshCartData = cartResult['data'];
        print('✅ Fresh cart data received: $freshCartData');
        
        // Update cart data - we need to handle this differently since cartData is final
        // We'll update the local state instead
        setState(() {
          // Update the cart items based on fresh data
          _updateCartFromFreshData(freshCartData);
        });
      }
    } catch (e) {
      print('❌ Error refreshing cart data: $e');
    }
  }

  // Update cart from fresh data
  void _updateCartFromFreshData(Map<String, dynamic> freshCartData) {
    // Clear existing items
    selectedTests.clear();
    selectedPackages.clear();
    testIdToName.clear();
    packageIdToName.clear();
    
    // Create mapping from test IDs and package IDs to names using fresh cart data
    if (freshCartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(freshCartData['items']);
      for (final item in items) {
        final testId = item['lab_test_id']?.toString();
        final packageId = item['lab_package_id']?.toString();
        final itemName = item['test_name']?.toString() ?? '';
        
        if (testId != null && testId.isNotEmpty && itemName.isNotEmpty) {
          testIdToName[testId] = itemName;
        }
        if (packageId != null && packageId.isNotEmpty && itemName.isNotEmpty) {
          packageIdToName[packageId] = itemName;
        }
      }
    }
    
    // Separate tests and packages from fresh cart items
    if (freshCartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(freshCartData['items']);
      for (final item in items) {
        final testId = item['lab_test_id']?.toString();
        final packageId = item['lab_package_id']?.toString();
        
        if (testId != null && testId.isNotEmpty) {
          selectedTests.add(testId);
        }
        if (packageId != null && packageId.isNotEmpty) {
          selectedPackages.add(packageId);
        }
      }
    }
    
    print('🔄 Updated local state - Tests: $selectedTests, Packages: $selectedPackages');
    print('🔄 Test ID to Name mapping: $testIdToName');
    print('🔄 Package ID to Name mapping: $packageIdToName');
  }



  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AnimatedSuccessDialog(
          onAnimationComplete: () {
            print('🔄 Animation complete, navigating back to home');
            try {
              Navigator.of(context).pop();
              // Navigate back to landing page after successful booking
              Navigator.of(context).pushReplacementNamed('/landing');
              print('✅ Navigation to landing page successful');
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

  // Generate time slots based on session parameters
  List<Map<String, dynamic>> _generateTimeSlots({
    required String sessionStart, // '09:00:00'
    required String sessionEnd,   // '19:00:00'
    required int slotDurationMin, // 30
  }) {
    print('🔄 Generating time slots from $sessionStart to $sessionEnd with ${slotDurationMin}min intervals');
    
    List<Map<String, dynamic>> slots = [];
    
    try {
      // Parse start and end times
      final startParts = sessionStart.split(':');
      final endParts = sessionEnd.split(':');
      
      if (startParts.length < 2 || endParts.length < 2) {
        print('❌ Invalid time format');
        return slots;
      }
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      // Create DateTime objects for easier calculation
      final today = DateTime.now();
      var currentSlotStart = DateTime(today.year, today.month, today.day, startHour, startMinute);
      final sessionEndTime = DateTime(today.year, today.month, today.day, endHour, endMinute);
      
      print('🔄 Session start: $currentSlotStart');
      print('🔄 Session end: $sessionEndTime');
      
      int slotIndex = 1;
      
      // Generate slots until we reach the session end time
      while (currentSlotStart.add(Duration(minutes: slotDurationMin)).isBefore(sessionEndTime) || 
             currentSlotStart.add(Duration(minutes: slotDurationMin)).isAtSameMomentAs(sessionEndTime)) {
        
        final slotEnd = currentSlotStart.add(Duration(minutes: slotDurationMin));
        
        // Format times as HH:mm for consistency with API
        final startTimeStr = '${currentSlotStart.hour.toString().padLeft(2, '0')}:${currentSlotStart.minute.toString().padLeft(2, '0')}';
        final endTimeStr = '${slotEnd.hour.toString().padLeft(2, '0')}:${slotEnd.minute.toString().padLeft(2, '0')}';
        
        slots.add({
          'id': slotIndex,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'status': 'available', // Default to available
          'doctor': {
            'name': 'Available', // Default doctor name
            'id': 'default',
          },
        });
        
        print('🔄 Generated slot ${slotIndex}: $startTimeStr - $endTimeStr');
        
        // Move to next slot
        currentSlotStart = slotEnd;
        slotIndex++;
      }
      
      print('✅ Generated ${slots.length} time slots');
      return slots;
      
    } catch (e) {
      print('❌ Error generating time slots: $e');
      return slots;
    }
  }

  // Filter timeslots to show only future times
  List<Map<String, dynamic>> _filterFutureSlots(List<Map<String, dynamic>> slots, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slotDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // If selected date is not today, return all slots
    if (!slotDate.isAtSameMomentAs(today)) {
      return slots;
    }
    
    // If it's today, filter out past slots
    return slots.where((slot) {
      try {
        final startTime = slot['start_time']?.toString() ?? '';
        if (startTime.isEmpty) return false;
        
        final timeParts = startTime.split(':');
        if (timeParts.length < 2) return false;
        
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        
        final slotDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
        
        // Show slots that are at least 30 minutes in the future
        return slotDateTime.isAfter(now.add(const Duration(minutes: 30)));
      } catch (e) {
        print('❌ Error filtering slot: $e');
        return true; // Keep slot if there's an error
      }
    }).toList();
  }

  Widget _buildSlotItem(Map<String, dynamic> slot, String sessionName) {
    final isAvailable = slot['status'] == 'available';
    final isSelected = selectedSession == sessionName && 
                     selectedSlot == '${slot['start_time']} - ${slot['end_time']}';
    
    return Expanded(
      child: InkWell(
        onTap: isAvailable ? () {
          setState(() {
            selectedSession = sessionName;
            selectedSlot = '${slot['start_time']} - ${slot['end_time']}';
            selectedDoctor = slot['doctor']?['name'] ?? '';
            selectedTime = _formatTimeTo12Hour(slot['start_time'] ?? '');
          });
          Navigator.pop(context);
        } : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryBlue 
                : isAvailable 
                    ? Colors.white
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primaryBlue 
                  : isAvailable
                      ? AppColors.primaryBlue.withOpacity(0.3)
                      : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              _formatTimeTo12Hour(slot['start_time'] ?? ''),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : isAvailable 
                        ? AppColors.primaryBlue 
                        : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
            // Tests Section (only show if there are tests)
            if (selectedTests.isNotEmpty) ...[
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
                  GestureDetector(
                    onTap: () => _addMoreTests(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Add More Tests',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tests List
              ...selectedTests.map((testId) {
              final testName = testIdToName[testId] ?? testId; // Use mapped name or fallback to ID
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
                              // Show strikethrough original price only when discount should be applied and discount is available
                              if (shouldApplyDiscount && _getTestDiscountedPrice(testName) < _getTestPrice(testName)) ...[
                                Text(
                                  '₹${_getTestPrice(testName).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Show appropriate price based on whether discount should be applied
                              Text(
                                shouldApplyDiscount 
                                  ? '₹${_getTestDiscountedPrice(testName).toStringAsFixed(0)}'
                                  : '₹${_getTestPrice(testName).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              // Show discount badge only when discount should be applied
                              if (shouldApplyDiscount && widget.testDiscounts[testName]?.isNotEmpty == true) ...[
                                const SizedBox(width: 8),
                                Text(
                                  widget.testDiscounts[testName]!,
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
                        // Remove from cart (this handles state update and callback internally)
                        await _removeFromCart(testId);
                      },
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),
            ],

            // Packages Section (only show if there are packages)
            if (selectedPackages.isNotEmpty) ...[
              const SizedBox(height: 20),
              
              // Packages Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selected Packages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _addMorePackages(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Add More Packages',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Packages List
              ...selectedPackages.map((packageId) {
                final packageName = packageIdToName[packageId] ?? packageId; // Use mapped name or fallback to ID
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
                              packageName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Show strikethrough original price only when discount should be applied and discount is available
                                if (shouldApplyDiscount && _getPackageDiscountedPrice(packageName) < _getPackagePrice(packageName)) ...[
                                  Text(
                                    '₹${_getPackagePrice(packageName).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // Show appropriate price based on whether discount should be applied
                                Text(
                                  shouldApplyDiscount 
                                    ? '₹${_getPackageDiscountedPrice(packageName).toStringAsFixed(0)}'
                                    : '₹${_getPackagePrice(packageName).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                // Show discount badge only when discount should be applied
                                if (shouldApplyDiscount && widget.testDiscounts[packageName]?.isNotEmpty == true) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.testDiscounts[packageName]!,
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
                          // Remove from cart (this handles state update and callback internally)
                          await _removeFromCart(packageId);
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }),
            ],

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
                              isLoadingWallet
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                      ),
                                    )
                                  : Text(
                                      walletBalance > 0 
                                          ? '₹${walletBalance.toStringAsFixed(0)}'
                                          : 'No balance',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: walletBalance > 0 
                                            ? AppColors.primaryBlue
                                            : Colors.grey[600],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        Switch(
                          value: useWalletBalance,
                          onChanged: (walletBalance > 0 && !isLoadingWallet) ? (value) {
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
                          } : null,
                          activeColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Options
                  InkWell(
                    onTap: shouldDisablePaymentMethods ? null : () {
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
                        color: shouldDisablePaymentMethods 
                            ? Colors.grey[200]
                            : selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: shouldDisablePaymentMethods 
                              ? Colors.grey[400]!
                              : selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payment,
                            color: shouldDisablePaymentMethods 
                                ? Colors.grey[500]
                                : selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Online Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: shouldDisablePaymentMethods 
                                    ? Colors.grey[500]
                                    : selectedPaymentMethod == 'Online Payment' ? AppColors.primaryBlue : Colors.black87,
                              ),
                            ),
                          ),
                          if (shouldDisablePaymentMethods)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Paid via Wallet',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
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
                    onTap: shouldDisablePaymentMethods ? null : () {
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
                        color: shouldDisablePaymentMethods 
                            ? Colors.grey[200]
                            : selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: shouldDisablePaymentMethods 
                              ? Colors.grey[400]!
                              : selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money,
                            color: shouldDisablePaymentMethods 
                                ? Colors.grey[500]
                                : selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pay at Collection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: shouldDisablePaymentMethods 
                                    ? Colors.grey[500]
                                    : selectedPaymentMethod == 'Pay at Collection' ? AppColors.primaryBlue : Colors.black87,
                              ),
                            ),
                          ),
                          if (shouldDisablePaymentMethods)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Paid via Wallet',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          if (selectedPaymentMethod == 'Pay at Collection' && !shouldDisablePaymentMethods)
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
                          // Show strikethrough original price only when discount should be applied and discount is available
                          if (shouldApplyDiscount && totalOriginalPrice > totalDiscountedPrice)
                            Text(
                              '₹${totalOriginalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          // Show actual payable amount (which already considers shouldApplyDiscount)
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
                  // Show discount message only when discount should be applied and discount is available
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
                              'Discount applied - Best prices guaranteed!',
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
                        isLoadingWallet
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                ),
                              )
                            : Text(
                                walletBalance > 0 
                                    ? '₹${walletBalance.toStringAsFixed(0)}'
                                    : 'No balance',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: walletBalance > 0 
                                      ? AppColors.primaryBlue
                                      : Colors.grey[600],
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

// Add More Items Bottom Sheet Widget
class _AddMoreItemsBottomSheet extends StatefulWidget {
  final String labId;
  final String labName;
  final Set<String> cartItems;
  final VoidCallback onItemAdded;

  const _AddMoreItemsBottomSheet({
    required this.labId,
    required this.labName,
    required this.cartItems,
    required this.onItemAdded,
  });

  @override
  State<_AddMoreItemsBottomSheet> createState() => _AddMoreItemsBottomSheetState();
}

class _AddMoreItemsBottomSheetState extends State<_AddMoreItemsBottomSheet> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _packages = [];
  bool _isLoadingTests = false;
  bool _isLoadingPackages = false;
  bool _showTests = true; // true for tests, false for packages
  Set<String> _loadingItems = {};

  @override
  void initState() {
    super.initState();
    _loadTests();
    _loadPackages();
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoadingTests = true;
    });

    try {
      // Get organization-specific tests using the API endpoint
      final result = await _apiService.getOrganizationTests(
        organizationId: widget.labId,
        search: '',
        sortBy: 'testname',
        sortOrder: 'asc',
      );

      if (result['success'] && mounted) {
        final responseData = result['data'];
        final organizationTests = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        
        // Transform the organization-specific test data to match the expected format
        final transformedTests = organizationTests.map((orgTest) {
          final test = orgTest['test'] as Map<String, dynamic>? ?? {};
          return {
            'id': test['id'] ?? orgTest['test_id'],
            'testname': test['name'] ?? '',
            'shortname': test['short_name'] ?? '',
            'name': test['name'] ?? '',
            'description': test['description'] ?? '',
            'baseprice': orgTest['baseprice'] ?? '0',
            'discountedprice': orgTest['discountedprice'] ?? orgTest['baseprice'] ?? '0',
            'discountvalue': orgTest['discountvalue'] ?? '0',
            'discounttype': orgTest['discounttype'] ?? 'percentage',
            'category': test['category']?['name'] ?? '',
            'is_home_collection': test['is_home_collection'] ?? false,
            'service_id': orgTest['service_id'],
            'test_id': orgTest['test_id'],
          };
        }).toList();
        
        setState(() {
          _tests = transformedTests;
          _isLoadingTests = false;
        });
        
        print('✅ Loaded ${transformedTests.length} organization-specific tests for ${widget.labName}');
      } else {
        setState(() {
          _isLoadingTests = false;
        });
        print('❌ Failed to load organization tests: ${result['message']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTests = false;
        });
      }
      print('❌ Error loading organization tests: $e');
    }
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoadingPackages = true;
    });

    try {
      // Get organization-specific packages using the API endpoint
      final result = await _apiService.getOrganizationPackages(
        organizationId: widget.labId,
      );

      if (result['success'] && mounted) {
        final organizationPackages = List<Map<String, dynamic>>.from(result['data'] ?? []);
        
        // Transform the organization-specific package data to match the expected format
        final transformedPackages = organizationPackages.map((orgPackage) {
          final package = orgPackage['package'] as Map<String, dynamic>? ?? {};
          return {
            'id': orgPackage['id'],
            'packagename': package['packagename'] ?? '',
            'name': package['packagename'] ?? '',
            'description': package['description'] ?? '',
            'baseprice': orgPackage['baseprice'] ?? '0',
            'discountvalue': orgPackage['discountvalue'] ?? '0',
            'discounttype': orgPackage['discounttype'] ?? 'percentage',
            'discountedprice': orgPackage['discountedprice'] ?? orgPackage['baseprice'] ?? '0',
            'package_id': orgPackage['package_id'],
            'org_id': orgPackage['org_id'],
            'status': orgPackage['status'],
            'tests': [], // Empty tests array for now, can be populated if needed
          };
        }).toList();
        
        setState(() {
          _packages = transformedPackages;
          _isLoadingPackages = false;
        });
        
        print('✅ Loaded ${transformedPackages.length} organization-specific packages for ${widget.labName}');
      } else {
        setState(() {
          _isLoadingPackages = false;
        });
        print('❌ Failed to load organization packages: ${result['message']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPackages = false;
        });
      }
      print('❌ Error loading organization packages: $e');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item, bool isPackage) async {
    final itemName = isPackage 
        ? (item['packagename'] ?? item['name'] ?? 'Package')
        : (item['testname'] ?? item['shortname'] ?? item['name'] ?? 'Test');
    
    if (widget.cartItems.contains(itemName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName is already in cart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _loadingItems.add(itemName);
    });

    try {
      final price = double.tryParse(item['baseprice']?.toString() ?? '0') ?? 0.0;
      
      // For organization-specific tests, use test_id for lab_test_id key
      final labTestId = isPackage ? '' : (item['test_id']?.toString() ?? item['id']?.toString() ?? '');
      final packageId = isPackage ? (item['package_id']?.toString() ?? '') : null;

      final result = await _apiService.addToCart(
        price: price,
        testName: itemName,
        labTestId: labTestId,
        packageId: packageId,
        organizationId: widget.labId,
        organizationName: widget.labName,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Update local state to add the item to cart
        final itemId = isPackage 
            ? (item['package_id']?.toString() ?? item['id']?.toString() ?? '')
            : (item['test_id']?.toString() ?? item['id']?.toString() ?? '');
        setState(() {
          widget.cartItems.add(itemId);
        });
        
        widget.onItemAdded();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _loadingItems.remove(itemName);
    });
  }

  Future<void> _removeFromCart(Map<String, dynamic> item, bool isPackage) async {
    final itemName = isPackage 
        ? (item['packagename'] ?? item['name'] ?? 'Package')
        : (item['testname'] ?? item['shortname'] ?? item['name'] ?? 'Test');
    
    setState(() {
      _loadingItems.add(itemName);
    });

    try {
      // Get the item ID (test_id or package_id)
      final itemId = isPackage 
          ? (item['package_id']?.toString() ?? item['id']?.toString() ?? '')
          : (item['test_id']?.toString() ?? item['id']?.toString() ?? '');
      
      // Find the cart item ID from the cart data
      String? cartItemId;
      
      if (widget.cartItems.isNotEmpty) {
        // We need to access the cart data from the parent widget
        // For now, we'll use the item ID directly and let the API handle it
        // This is a simplified approach - in a real scenario, we'd need to pass cart data
        cartItemId = itemId;
      }

      final result = await _apiService.removeFromCart(cartItemId ?? itemId);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName removed from cart'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Update local state to remove the item from cart
        setState(() {
          widget.cartItems.remove(itemId);
        });
        
        widget.onItemAdded(); // This will refresh the cart data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to remove item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _loadingItems.remove(itemName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add More Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'to ${widget.labName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          
          // Tab switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showTests = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showTests ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tests',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _showTests ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showTests = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showTests ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Packages',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_showTests ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _showTests ? _buildTestsList() : _buildPackagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList() {
    if (_isLoadingTests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tests.isEmpty) {
      return const Center(
        child: Text(
          'No tests available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _tests.length,
      itemBuilder: (context, index) {
        final test = _tests[index];
        final testName = test['testname'] ?? test['shortname'] ?? test['name'] ?? 'Test';
        final testId = test['test_id']?.toString() ?? test['id']?.toString() ?? '';
        final basePrice = double.tryParse(test['baseprice']?.toString() ?? '0') ?? 0.0;
        final discountedPrice = double.tryParse(test['discountedprice']?.toString() ?? '0') ?? 0.0;
        final isInCart = widget.cartItems.contains(testId);
        final isLoading = _loadingItems.contains(testName);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  testName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Also known as:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  test['shortname'] ?? test['description'] ?? 'Test',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (test['is_home_collection'] == true || test['ishomecollection'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Home Collection',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discountedPrice < basePrice) ...[
                          Text(
                            '₹${basePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        Text(
                          '₹${discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    isInCart
                        ? ElevatedButton(
                            onPressed: isLoading ? null : () => _removeFromCart(test, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE74C3C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Remove',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          )
                        : OutlinedButton(
                            onPressed: isLoading ? null : () => _addToCart(test, false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2ECC71)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Color(0xFF2ECC71),
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2ECC71),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPackagesList() {
    if (_isLoadingPackages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_packages.isEmpty) {
      return const Center(
        child: Text(
          'No packages available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final package = _packages[index];
        final packageName = package['packagename'] ?? package['name'] ?? 'Package';
        final packageId = package['package_id']?.toString() ?? package['id']?.toString() ?? '';
        final price = double.tryParse(package['baseprice']?.toString() ?? '0') ?? 0.0;
        final discountedPrice = double.tryParse(package['discountedprice']?.toString() ?? '0') ?? 0.0;
        final isInCart = widget.cartItems.contains(packageId);
        final isLoading = _loadingItems.contains(packageName);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Package name and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            packageName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            package['description'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (discountedPrice < price) ...[
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        Text(
                          '₹${discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    isInCart
                        ? ElevatedButton(
                            onPressed: isLoading ? null : () => _removeFromCart(package, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE74C3C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Remove',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          )
                        : OutlinedButton(
                            onPressed: isLoading ? null : () => _addToCart(package, true),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2ECC71)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: Color(0xFF2ECC71),
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2ECC71),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}