import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/add_family_member_bottom_sheet.dart';
import '../widgets/address_selection_widget.dart';

class MultiLabCheckoutScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final Map<String, dynamic> cartData;
  final Map<String, dynamic> multiLabData;
  final VoidCallback? onCartCleared; // Callback for when entire cart is cleared

  const MultiLabCheckoutScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.cartData,
    required this.multiLabData,
    this.onCartCleared, // Optional callback for cart clearing
  });

  @override
  State<MultiLabCheckoutScreen> createState() => _MultiLabCheckoutScreenState();
}

class _MultiLabCheckoutScreenState extends State<MultiLabCheckoutScreen> {
  final ApiService _apiService = ApiService();
  
  // Payment and booking related variables
  String selectedPaymentMethod = 'Online Payment';
  String selectedPatient = 'Myself';
  String? selectedPatientId; // To store the selected patient's ID
  String? selectedAddress;
  bool useWalletBalance = false;
  double walletBalance = 0.0; // Will be loaded from API
  String? appliedCoupon;
  String? couponCode;
  double couponDiscount = 0.0;
  String? couponError;
  bool isApplyingCoupon = false;
  
  // Dependents related variables
  List<Map<String, dynamic>> _familyMembers = [];
  bool isLoadingDependents = false;
  String? dependentsError;
  
  // Wallet related variables
  bool isLoadingWallet = true; // Start loading immediately
  String? walletError;
  
  // Booking related variables
  bool isBooking = false;
  String? bookingError;

  @override
  void initState() {
    super.initState();
    
    print('🔄 MultiLabCheckoutScreen initState');
    print('🔄 Multi-lab data: ${widget.multiLabData.keys}');
    print('💰 Initial wallet state: balance=$walletBalance, loading=$isLoadingWallet');
    
    // Load dependents and wallet balance
    _loadDependents();
    _loadWalletBalance();
  }

  // Load family members/dependents
  Future<void> _loadDependents() async {
    setState(() {
      isLoadingDependents = true;
      dependentsError = null;
    });

    try {
      final result = await _apiService.getDependents(context);
      
      print('🔍 Dependents API Response: $result');
      
      if (result['success'] == true && mounted) {
        final familyData = List<Map<String, dynamic>>.from(result['data'] ?? []);
        setState(() {
          _familyMembers = familyData;
          isLoadingDependents = false;
        });
        print('✅ Loaded ${_familyMembers.length} family members');
        for (int i = 0; i < _familyMembers.length; i++) {
          final member = _familyMembers[i];
          final id = member['id']?.toString() ?? member['user_id']?.toString() ?? 'NO_ID';
          final name = member['name']?.toString() ?? member['first_name']?.toString() ?? 'NO_NAME';
          print('👨‍👩‍👧‍👦 Family Member $i: ID=$id, Name=$name');
          print('📋 Full data: $member');
        }
      } else {
        setState(() {
          dependentsError = result['message'] ?? 'Failed to load family members';
          isLoadingDependents = false;
        });
        print('❌ Failed to load dependents: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        dependentsError = 'Error loading family members: $e';
        isLoadingDependents = false;
      });
      print('❌ Exception loading dependents: $e');
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

  // Calculate totals from multi-lab data
  double get totalOriginalPrice {
    double total = 0.0;
    final labs = List<Map<String, dynamic>>.from(widget.multiLabData['labs'] ?? []);
    
    for (final lab in labs) {
      final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
      for (final service in services) {
        final price = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
        total += price;
      }
    }
    return total;
  }

  double get totalDiscountedPrice {
    double total = 0.0;
    final labs = List<Map<String, dynamic>>.from(widget.multiLabData['labs'] ?? []);
    
    for (final lab in labs) {
      final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
      for (final service in services) {
        final price = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
        total += price;
      }
    }
    return total;
  }

  double get totalSavings => totalOriginalPrice - totalDiscountedPrice;

  // New getters for conditional pricing based on payment method
  bool get shouldApplyDiscount {
    return selectedPaymentMethod == 'Online Payment' || selectedPaymentMethod == 'Wallet';
  }

  double get conditionalTotalPrice {
    return shouldApplyDiscount ? totalDiscountedPrice : totalOriginalPrice;
  }

  double get conditionalTotalSavings {
    return shouldApplyDiscount ? totalSavings : 0.0;
  }

  // Check if at least one lab has home collection selected
  bool get hasAnyHomeCollection {
    final labHomeCollection = Map<String, bool>.from(widget.multiLabData['labHomeCollection'] ?? <String, bool>{});
    return labHomeCollection.values.any((isHomeCollection) => isHomeCollection == true);
  }

  // Helper method to get relationship name from dynamic data
  String _getRelationshipName(dynamic relationshipData) {
    print('🔍 Relationship data type: ${relationshipData.runtimeType}');
    print('🔍 Relationship data value: $relationshipData');

    if (relationshipData == null) return 'Family member';

    // If it's already a string, return it
    if (relationshipData is String) {
      print('✅ Returning string: $relationshipData');
      return relationshipData;
    }

    // If it's a Map/JSON object, try different possible field names
    if (relationshipData is Map) {
      // Try common field names for relationship
      String? name = relationshipData['name']?.toString() ??
                    relationshipData['title']?.toString() ??
                    relationshipData['label']?.toString() ??
                    relationshipData['value']?.toString() ??
                    relationshipData['relation_name']?.toString() ??
                    relationshipData['relationship_name']?.toString();

      if (name != null && name.isNotEmpty) {
        print('✅ Extracted name from Map: $name');
        return name;
      }
    }

    // If it's any other type or name not found, convert to string
    final result = relationshipData.toString();
    print('⚠️ Converting to string: $result');
    return result;
  }

  // Helper method to calculate age from date of birth
  String _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty || dobString == 'N/A') {
      return 'N/A';
    }

    DateTime? dob;
    final now = DateTime.now();

    try {
      // Try different date formats
      final formats = [
        'yyyy-MM-dd', // ISO format
        'dd-MM-yyyy', // European format
        'MM-dd-yyyy', // US format
        'dd/MM/yyyy', // European with slashes
        'MM/dd/yyyy', // US with slashes
        'yyyy/MM/dd', // ISO with slashes
      ];

      for (final format in formats) {
        try {
          if (format.contains('-')) {
            if (format == 'yyyy-MM-dd') {
              dob = DateTime.parse(dobString);
            } else if (format == 'dd-MM-yyyy') {
              List<String> parts = dobString.split('-');
              dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            } else if (format == 'MM-dd-yyyy') {
              List<String> parts = dobString.split('-');
              dob = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
            }
          } else if (format.contains('/')) {
            if (format == 'dd/MM/yyyy') {
              List<String> parts = dobString.split('/');
              dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            } else if (format == 'MM/dd/yyyy') {
              List<String> parts = dobString.split('/');
              dob = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
            } else if (format == 'yyyy/MM/dd') {
              List<String> parts = dobString.split('/');
              dob = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          }
          if (dob != null) break;
        } catch (e) {
          continue;
        }
      }

      if (dob == null) {
        print('⚠️ Could not parse DOB: $dobString');
        return 'N/A';
      }

      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      return age.toString();
    } catch (e) {
      print('❌ Error calculating age from DOB: $dobString, Error: $e');
      return 'N/A';
    }
  }

  double get finalAmount {
    double amount = conditionalTotalPrice - couponDiscount;
    if (useWalletBalance) {
      amount = (amount - walletBalance).clamp(0.0, double.infinity);
    }
    return amount;
  }

  // Check if wallet balance covers the full amount after coupon discount
  bool get walletCoversFullAmount {
    final finalAmountBeforeWallet = conditionalTotalPrice - couponDiscount;
    return walletBalance >= finalAmountBeforeWallet;
  }

  // Check if payment methods should be disabled (when wallet covers full amount)
  bool get shouldDisablePaymentMethods {
    return walletCoversFullAmount && useWalletBalance;
  }

  // Apply coupon
  Future<void> _applyCoupon() async {
    if (couponCode == null || couponCode!.isEmpty) return;

    setState(() {
      isApplyingCoupon = true;
      couponError = null;
    });

    try {
      // Extract test and package IDs from cart data
      List<String> testIds = [];
      List<String> packageIds = [];
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        for (final item in items) {
          if (item['lab_test_id']?.toString().isNotEmpty == true) {
            testIds.add(item['lab_test_id'].toString());
          }
          if (item['lab_package_id']?.toString().isNotEmpty == true) {
            packageIds.add(item['lab_package_id'].toString());
          }
        }
      }
      
      final result = await _apiService.applyPromoCode(
        promoCode: couponCode!,
        totalAmount: totalDiscountedPrice,
        testIds: testIds,
        packageIds: packageIds,
        labId: '', // Multi-lab, no single lab ID
        cartId: widget.cartData['id']?.toString() ?? '',
        paymentMethod: selectedPaymentMethod,
        context: context,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          appliedCoupon = couponCode;
          couponDiscount = double.tryParse(result['data']['discount']?.toString() ?? '0') ?? 0.0;
          isApplyingCoupon = false;
          couponCode = null;
        });
      } else {
        setState(() {
          couponError = result['message'] ?? 'Invalid coupon code';
          isApplyingCoupon = false;
        });
      }
    } catch (e) {
      setState(() {
        couponError = 'Error applying coupon: $e';
        isApplyingCoupon = false;
      });
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

  // Book multi-lab appointment
  Future<void> _bookMultiLabAppointment() async {
    print('🎯 _bookMultiLabAppointment called');
    print('🎯 selectedAddress: ${selectedAddress ?? "NULL"}');
    print('🎯 selectedPatient: ${selectedPatient ?? "NULL"}');
    print('🎯 selectedPatientId: ${selectedPatientId ?? "NULL"}');
    print('🎯 selectedPaymentMethod: ${selectedPaymentMethod ?? "NULL"}');
    print('🎯 widget.multiLabData keys: ${widget.multiLabData?.keys?.toList() ?? "NULL"}');
    
    // Enhanced validation with detailed logging
    // Only require address if at least one lab has home collection
    if (hasAnyHomeCollection && (selectedAddress?.isEmpty ?? true)) {
      print('❌ Validation failed: No address selected for home collection');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address for home collection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPatient == null || selectedPatient!.isEmpty) {
      print('❌ Validation failed: No patient selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For family members, patient ID is required, but for "Myself" it's optional
    if (selectedPatient != 'Myself' && (selectedPatientId == null || selectedPatientId!.isEmpty)) {
      print('❌ Validation failed: No patient ID for family member');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid family member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == null || selectedPaymentMethod.isEmpty) {
      print('❌ Validation failed: No payment method selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ All validations passed, proceeding with booking');

    setState(() {
      isBooking = true;
      bookingError = null;
    });

    try {
      // Extract lab schedules from multiLabData with comprehensive null safety
      final List<Map<String, dynamic>> labSchedules = [];
      
      // Safely extract data from multiLabData
      final multiLabData = widget.multiLabData ?? <String, dynamic>{};
      final labs = List<Map<String, dynamic>>.from(multiLabData['labs'] ?? <Map<String, dynamic>>[]);
      final labSelectedDates = Map<String, dynamic>.from(multiLabData['labSelectedDates'] ?? <String, dynamic>{});
      final labSelectedTimes = Map<String, dynamic>.from(multiLabData['labSelectedTimes'] ?? <String, dynamic>{});
      final labHomeCollection = Map<String, bool>.from(multiLabData['labHomeCollection'] ?? <String, bool>{});
      
      print('🔍 Extracted data - Labs: ${labs.length}, Dates: ${labSelectedDates.length}, Times: ${labSelectedTimes.length}');
      
      for (final lab in labs) {
        final labId = lab['id']?.toString() ?? '';
        
        // Safely extract and convert dates/times to strings
        final rawDate = labSelectedDates[labId];
        final rawTime = labSelectedTimes[labId];
        
        print('🔍 Raw data for lab $labId: Date type=${rawDate.runtimeType}, Time type=${rawTime.runtimeType}');
        print('🔍 Raw date value: $rawDate');
        print('🔍 Raw time value: $rawTime');
        
        String selectedDate = '';
        String selectedTime = '';
        
        // Handle date conversion
        if (rawDate != null) {
          try {
            if (rawDate is DateTime) {
              // Convert DateTime to YYYY-MM-DD format
              selectedDate = '${rawDate.year.toString().padLeft(4, '0')}-${rawDate.month.toString().padLeft(2, '0')}-${rawDate.day.toString().padLeft(2, '0')}';
              print('📅 Converted DateTime to date string: $selectedDate');
            } else if (rawDate is String) {
              // If it's already a string, check if it needs formatting
              selectedDate = rawDate;
              print('📅 Used string date: $selectedDate');
            } else {
              // Try to convert whatever it is to a string
              selectedDate = rawDate.toString();
              print('📅 Converted unknown type to string: $selectedDate');
            }
          } catch (e) {
            print('❌ Error converting date: $e');
            selectedDate = '';
          }
        }
        
        // Handle time conversion  
        if (rawTime != null) {
          try {
            if (rawTime is DateTime) {
              // Convert DateTime to HH:MM format
              selectedTime = '${rawTime.hour.toString().padLeft(2, '0')}:${rawTime.minute.toString().padLeft(2, '0')}';
              print('⏰ Converted DateTime to time string: $selectedTime');
            } else if (rawTime is String) {
              // If it's already a string, use it directly
              selectedTime = rawTime;
              print('⏰ Used string time: $selectedTime');
            } else {
              // Try to convert whatever it is to a string
              selectedTime = rawTime.toString();
              print('⏰ Converted unknown type to string: $selectedTime');
            }
          } catch (e) {
            print('❌ Error converting time: $e');
            selectedTime = '';
          }
        }
        
        final isHomeCollection = labHomeCollection[labId] ?? true;
        
        if (labId.isNotEmpty && selectedDate.isNotEmpty && selectedTime.isNotEmpty) {
          final schedule = <String, dynamic>{
            'lab_id': labId,
            'appointment_date': selectedDate,
            'appointment_time': selectedTime,
            'is_home_collection': isHomeCollection,
          };
          
          // Add address only if home collection is enabled and address is valid
          if (isHomeCollection && selectedAddress?.isNotEmpty == true) {
            schedule['address'] = selectedAddress!;
          }
          
          print('📅 Lab schedule created: $schedule');
          labSchedules.add(schedule);
        } else {
          print('⚠️ Skipping lab due to missing data - ID: $labId, Date: $selectedDate, Time: $selectedTime');
        }
      }
      
      // Convert payment method to API expected format
      final apiPaymentMode = _getApiPaymentMode(selectedPaymentMethod);
      
      // Prepare booking data according to API specification with null safety
      final cartData = widget.cartData ?? <String, dynamic>{};
      final String cartId = cartData['id']?.toString() ?? 
                           cartData['cart_id']?.toString() ?? 
                           cartData['cartId']?.toString() ?? '';
      
      print('🔍 Cart ID extracted: $cartId');
      
      final String patientValue = selectedPatientId?.toString() ?? 
                                 selectedPatient?.toString() ?? 
                                 'Myself';
      
      final bookingData = {
        'cart_id': cartId,
        'patient': patientValue,
        'lab_schedules': labSchedules,
        'is_use_wallet': useWalletBalance,
        'payment_mode': apiPaymentMode, // Use converted API payment mode
        'amountPayable': finalAmount, // Use the final amount after coupon and wallet deduction
      };
      
      print('💳 Payment method conversion: "$selectedPaymentMethod" → "$apiPaymentMode"');
      
      // Add coupon code if available with null safety
      final String? couponValue = appliedCoupon?.toString().trim();
      if (couponValue != null && couponValue.isNotEmpty) {
        bookingData['coupon_code'] = couponValue;
      }
      
      // Validate lab schedules
      if (labSchedules.isEmpty) {
        print('❌ Validation failed: No lab schedules found');
        setState(() {
          bookingError = 'No lab schedules found. Please ensure dates and times are selected for all labs.';
          isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No lab schedules found. Please ensure dates and times are selected for all labs.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('📋 Lab schedules prepared: ${labSchedules.length} schedules');
      print('📋 Booking data prepared: $bookingData');
      print('📋 Multi-lab data structure: ${widget.multiLabData}');
      print('📋 Cart data structure: ${widget.cartData}');

      print('🔄 Booking multi-lab appointment with data: $bookingData');

      print('🌐 Making API call to book multi-lab appointment...');
      final result = await _apiService.bookMultiLabAppointment(bookingData);
      print('🌐 API call completed with result: $result');

      if (result['success'] == true && mounted) {
        print('✅ Multi-lab booking created successfully');
        
        // Clear the cart after successful booking
        await _clearCart();
        
        // Notify parent that cart has been cleared
        if (widget.onCartCleared != null) {
          print('🔄 Notifying parent that cart has been cleared');
          widget.onCartCleared!();
        }
        
        // Show success popup and navigate back to landing page (same as single lab booking)
        _showSuccessPopup();
      } else {
        print('❌ Booking failed with result: $result');
        setState(() {
          bookingError = result['message'] ?? 'Failed to book appointment';
          isBooking = false;
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingError!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Exception during booking: $e');
      setState(() {
        bookingError = 'Error booking appointment: $e';
        isBooking = false;
      });
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clear cart after successful booking
  Future<bool> _clearCart() async {
    print('🛒 Clearing cart from database and local storage after multi-lab booking...');
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

  DateTime _combineDateAndTime(DateTime date, String timeString) {
    try {
      // Parse time string (assuming format like "09:00" or "14:30")
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      print('❌ Error combining date and time: $e');
    }
    // Fallback: return original date if time parsing fails
    return date;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF64748B), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Multi-lab summary
                  _buildMultiLabSummary(),
                  const SizedBox(height: 20),
                  
                  // Patient selection
                  _buildPatientSelection(),
                  const SizedBox(height: 20),
                  
                  // Address selection - only show if at least one lab has home collection
                  if (hasAnyHomeCollection) ...[
                    _buildAddressSelection(),
                    const SizedBox(height: 20),
                  ],
                  
                  // Coupon section
                  _buildCouponSection(),
                  const SizedBox(height: 20),
                  
                  // Payment method
                  _buildPaymentMethod(),
                  const SizedBox(height: 20),
                  
                  // Price breakdown
                  _buildPriceBreakdown(),
                  
                  if (bookingError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bookingError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom booking button with enhanced design
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      Text(
                        '₹${finalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Book button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isBooking 
                          ? [const Color(0xFF94A3B8), const Color(0xFF94A3B8)]
                          : [AppColors.primaryBlue, const Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isBooking 
                            ? Colors.transparent 
                            : AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isBooking ? null : () {
                      print('🎯 Button pressed - calling _bookMultiLabAppointment');
                      _bookMultiLabAppointment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isBooking
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Booking Your Appointment...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Book Appointment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLabSummary() {
    final labs = List<Map<String, dynamic>>.from(widget.multiLabData['labs'] ?? []);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (int i = 0; i < labs.length; i++) ...[
              _buildLabSummaryItem(labs[i], i + 1),
              if (i < labs.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabSummaryItem(Map<String, dynamic> lab, int index) {
    final labName = lab['name']?.toString() ?? 'Unknown Lab';
    final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
    final labHomeCollection = widget.multiLabData['labHomeCollection']?[lab['id']?.toString()] ?? false;
    final labSelectedDate = widget.multiLabData['labSelectedDates']?[lab['id']?.toString()];
    final labSelectedTime = widget.multiLabData['labSelectedTimes']?[lab['id']?.toString()];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: labHomeCollection 
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          labHomeCollection ? Icons.home : Icons.location_on,
                          size: 12,
                          color: labHomeCollection 
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          labHomeCollection ? 'Home Collection' : 'Visit Lab',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: labHomeCollection 
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${services.length} items',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Individual service items with conditional pricing
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items:',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                ...services.map((service) => _buildServiceItem(service)).toList(),
              ],
            ),
          ),
          
          if (labSelectedDate != null && labSelectedTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(_combineDateAndTime(labSelectedDate, labSelectedTime)),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final serviceName = service['testname']?.toString() ?? service['name']?.toString() ?? 'Unknown Service';
    final originalPrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
    final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
    
    // Use conditional pricing based on payment method
    final displayPrice = shouldApplyDiscount ? discountedPrice : originalPrice;
    final showDiscount = shouldApplyDiscount && discountedPrice < originalPrice;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              serviceName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          if (showDiscount) ...[
            Text(
              '₹${originalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '₹${displayPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: showDiscount ? const Color(0xFF059669) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8B5CF6).withOpacity(0.1), const Color(0xFF8B5CF6).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Patient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Myself option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPatient = 'Myself';
                      selectedPatientId = null; // Reset ID for 'Myself'
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedPatient == 'Myself' 
                          ? AppColors.primaryBlue.withOpacity(0.1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedPatient == 'Myself' 
                            ? AppColors.primaryBlue 
                            : const Color(0xFFE2E8F0),
                        width: selectedPatient == 'Myself' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selectedPatient == 'Myself' 
                                ? AppColors.primaryBlue 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedPatient == 'Myself' 
                                  ? AppColors.primaryBlue 
                                  : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: selectedPatient == 'Myself' 
                              ? const Icon(Icons.check, color: Colors.white, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Myself',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Family members section
                if (isLoadingDependents)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text(
                            'Loading family members...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (dependentsError != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dependentsError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_familyMembers.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No family members added yet. Add a family member to book for them.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < _familyMembers.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < _familyMembers.length - 1 ? 12 : 0,
                          ),
                          child: _buildFamilyMemberCard(_familyMembers[i]),
                        ),
                    ],
                  ),
                
                // Add family member button
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AddFamilyMemberBottomSheet.show(
                        context: context,
                        onMemberAdded: _loadDependents,
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Family Member'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard(Map<String, dynamic> member) {
    final memberId = member['id']?.toString() ?? member['user_id']?.toString() ?? '';
    // Try different possible name fields from API
    String memberName = 'Unknown Member';
    if (member['name']?.toString().isNotEmpty == true) {
      memberName = member['name'].toString();
    } else if (member['first_name']?.toString().isNotEmpty == true) {
      final firstName = member['first_name'].toString();
      final lastName = member['last_name']?.toString() ?? '';
      memberName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
    } else if (member['full_name']?.toString().isNotEmpty == true) {
      memberName = member['full_name'].toString();
    }
    // Get relationship name from multiple possible sources
    final relationshipData = member['relation'] ?? member['relationship'];
    final memberRelation = _getRelationshipName(relationshipData);
    // Get age from multiple possible sources
    String memberAge = '';
    if (member['age']?.toString().isNotEmpty == true) {
      memberAge = member['age'].toString();
    } else {
      // Try to calculate age from date of birth
      final dobValue = member['date_of_birth'] ?? member['dob'] ?? member['dateOfBirth'] ?? member['birth_date'] ?? member['birthDate'];
      if (dobValue != null && dobValue.toString().isNotEmpty) {
        memberAge = _calculateAge(dobValue.toString());
      }
    }
    final isSelected = selectedPatientId == memberId && memberId.isNotEmpty;
    
    print('🎯 Building family member card: ID=$memberId, Name=$memberName, Selected=$isSelected');
    print('🔍 Full member data: $member');
    print('📋 Current selectedPatientId: $selectedPatientId');
    print('🔗 Member relation field: ${member['relation']}');
    print('🔗 Member relationship field: ${member['relationship']}');
    print('👥 Final relationship name: $memberRelation');
    print('📅 Member age field: ${member['age']}');
    print('📅 Member date_of_birth field: ${member['date_of_birth']}');
    print('📅 Member dob field: ${member['dob']}');
    print('📅 Member dateOfBirth field: ${member['dateOfBirth']}');
    print('📅 Member birth_date field: ${member['birth_date']}');
    print('📅 Member birthDate field: ${member['birthDate']}');
    print('🎂 Final calculated age: $memberAge');
    
    return GestureDetector(
      onTap: () {
        if (memberId.isNotEmpty) {
          print('👆 Tapped on family member: ID=$memberId, Name=$memberName');
          setState(() {
            selectedPatient = memberName;
            selectedPatientId = memberId;
          });
          print('✅ Selected patient updated - Name: $selectedPatient, ID: $selectedPatientId');
        } else {
          print('❌ Cannot select member without valid ID');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryBlue.withOpacity(0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryBlue 
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryBlue 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryBlue 
                      : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isSelected 
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Family member icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.people_outline,
                color: Color(0xFF8B5CF6),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            
            // Member details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? AppColors.primaryBlue 
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (memberRelation.isNotEmpty || memberAge.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${memberRelation.isNotEmpty ? memberRelation : 'Family member'} ${memberAge.isNotEmpty ? '• $memberAge years' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Selected indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

    Widget _buildAddressSelection() {
    return AddressSelectionWidget(
      selectedAddressId: selectedAddress,
      onAddressSelected: (addressId) {
        setState(() {
          selectedAddress = addressId;
        });
      },
      showTitle: true,
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply Coupon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          if (appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon "$appliedCoupon" applied! You saved ₹${couponDiscount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        appliedCoupon = null;
                        couponDiscount = 0.0;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.green),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      couponCode = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: isApplyingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
            
            if (couponError != null) ...[
              const SizedBox(height: 8),
              Text(
                couponError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF3B82F6).withOpacity(0.1), const Color(0xFF3B82F6).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment_outlined,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Online Payment option
                GestureDetector(
                  onTap: shouldDisablePaymentMethods ? null : () {
                    setState(() {
                      selectedPaymentMethod = 'Online Payment';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: shouldDisablePaymentMethods 
                          ? Colors.grey[200]
                          : selectedPaymentMethod == 'Online Payment' 
                              ? const Color(0xFF3B82F6).withOpacity(0.1)
                              : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: shouldDisablePaymentMethods 
                            ? Colors.grey[400]!
                            : selectedPaymentMethod == 'Online Payment' 
                                ? const Color(0xFF3B82F6) 
                                : const Color(0xFFE2E8F0),
                        width: shouldDisablePaymentMethods 
                            ? 1
                            : selectedPaymentMethod == 'Online Payment' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: shouldDisablePaymentMethods 
                                ? Colors.grey[400]
                                : selectedPaymentMethod == 'Online Payment' 
                                    ? const Color(0xFF3B82F6) 
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: shouldDisablePaymentMethods 
                                  ? Colors.grey[400]!
                                  : selectedPaymentMethod == 'Online Payment' 
                                      ? const Color(0xFF3B82F6) 
                                      : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: shouldDisablePaymentMethods 
                              ? const Icon(Icons.block, color: Colors.white, size: 12)
                              : selectedPaymentMethod == 'Online Payment' 
                                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                                  : null,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF059669), const Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Online Payment',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: shouldDisablePaymentMethods 
                                      ? Colors.grey[500]
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  if (shouldDisablePaymentMethods)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PAID VIA WALLET',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'SECURE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Card • UPI • Wallet',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: shouldDisablePaymentMethods 
                                            ? Colors.grey[500]
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (selectedPaymentMethod == 'Online Payment')
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Cash on Collection option
                GestureDetector(
                  onTap: shouldDisablePaymentMethods ? null : () {
                    setState(() {
                      selectedPaymentMethod = 'Cash on Collection';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: shouldDisablePaymentMethods 
                          ? Colors.grey[200]
                          : selectedPaymentMethod == 'Cash on Collection' 
                              ? const Color(0xFFF59E0B).withOpacity(0.1)
                              : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: shouldDisablePaymentMethods 
                            ? Colors.grey[400]!
                            : selectedPaymentMethod == 'Cash on Collection' 
                                ? const Color(0xFFF59E0B) 
                                : const Color(0xFFE2E8F0),
                        width: shouldDisablePaymentMethods 
                            ? 1
                            : selectedPaymentMethod == 'Cash on Collection' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: shouldDisablePaymentMethods 
                                ? Colors.grey[400]
                                : selectedPaymentMethod == 'Cash on Collection' 
                                    ? const Color(0xFFF59E0B) 
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: shouldDisablePaymentMethods 
                                  ? Colors.grey[400]!
                                  : selectedPaymentMethod == 'Cash on Collection' 
                                      ? const Color(0xFFF59E0B) 
                                      : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: shouldDisablePaymentMethods 
                              ? const Icon(Icons.block, color: Colors.white, size: 12)
                              : selectedPaymentMethod == 'Cash on Collection' 
                                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                                  : null,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cash on Collection',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: shouldDisablePaymentMethods 
                                      ? Colors.grey[500]
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  if (shouldDisablePaymentMethods)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'PAID VIA WALLET',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'CONVENIENT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                  if (!shouldDisablePaymentMethods)
                                    Text(
                                      'Pay during collection',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: shouldDisablePaymentMethods 
                                            ? Colors.grey[500]
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (selectedPaymentMethod == 'Cash on Collection')
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Wallet balance option (always show)
                ...[
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFE2E8F0),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  GestureDetector(
                    onTap: (walletBalance > 0 && !isLoadingWallet) ? () {
                      setState(() {
                        useWalletBalance = !useWalletBalance;
                      });
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (walletBalance <= 0 && !isLoadingWallet)
                            ? const Color(0xFFF1F5F9)
                            : useWalletBalance 
                                ? const Color(0xFF8B5CF6).withOpacity(0.1)
                                : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (walletBalance <= 0 && !isLoadingWallet)
                              ? const Color(0xFFCBD5E1)
                              : useWalletBalance 
                                  ? const Color(0xFF8B5CF6) 
                                  : const Color(0xFFE2E8F0),
                          width: useWalletBalance ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: useWalletBalance 
                                  ? const Color(0xFF8B5CF6) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: useWalletBalance 
                                    ? const Color(0xFF8B5CF6) 
                                    : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: useWalletBalance 
                                ? const Icon(Icons.check, color: Colors.white, size: 12)
                                : null,
                          ),
                                                  const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Use Wallet Balance',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        size: 10,
                                        color: Color(0xFF059669),
                                      ),
                                      Flexible(
                                        child: isLoadingWallet
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                                                ),
                                              )
                                            : Text(
                                                walletBalance > 0 
                                                    ? '${walletBalance.toStringAsFixed(0)} available'
                                                    : 'No balance available',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: walletBalance > 0 
                                                      ? const Color(0xFF059669)
                                                      : const Color(0xFF94A3B8),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (useWalletBalance)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF059669).withOpacity(0.1), const Color(0xFF059669).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Price Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Show original price with strikethrough if discount is applied
                if (shouldApplyDiscount && totalSavings > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Original Price',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '₹${totalOriginalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                _buildPriceRow('Subtotal', '₹${conditionalTotalPrice.toStringAsFixed(0)}'),
                if (conditionalTotalSavings > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Discount', '-₹${conditionalTotalSavings.toStringAsFixed(0)}', 
                      color: const Color(0xFF059669), icon: Icons.local_offer),
                ],
                if (couponDiscount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Coupon Discount', '-₹${couponDiscount.toStringAsFixed(0)}', 
                      color: const Color(0xFF8B5CF6), icon: Icons.confirmation_number),
                ],
                if (useWalletBalance && walletBalance > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Wallet Used', '-₹${walletBalance.toStringAsFixed(0)}', 
                      color: const Color(0xFF3B82F6), icon: Icons.account_balance_wallet),
                ],
                
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFE2E8F0),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Final amount with special styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF059669).withOpacity(0.1), const Color(0xFF059669).withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Final Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${finalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {Color? color, bool isTotal = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color != null ? color.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: color ?? const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 15,
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? const Color(0xFF475569),
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.primaryBlue : const Color(0xFF1E293B)),
            ),
          ),
        ],
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