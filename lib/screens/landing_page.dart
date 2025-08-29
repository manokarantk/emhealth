import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import '../constants/colors.dart';
import '../widgets/package_card.dart';
import '../widgets/tests_list_tab.dart';
import '../widgets/packages_list_tab.dart';
import 'medical_history_screen.dart';
import 'wallet_history_screen.dart';
import 'family_members_screen.dart';
import 'addresses_screen.dart';
import 'lab_selection_screen.dart';
import 'order_detail_screen.dart';
import 'location_selection_screen.dart';
import '../services/intro_service.dart';
import '../services/token_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../utils/auth_utils.dart';
import '../utils/snackbar_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/add_money_bottom_sheet.dart';
import '../widgets/profile_image_picker.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Set<String> cartItems = {}; // Track cart items by test name
  bool _isLoadingCart = true;
  Map<String, dynamic> cartData = {};
  
  // Sample test data with prices for cart calculation
  final Map<String, double> testPrices = {
    'Complete Blood Count (CBC)': 599.0,
    'Diabetes Screening': 299.0,
    'Liver Function Test (LFT)': 799.0,
    'Kidney Function Test (KFT)': 699.0,
    'Thyroid Profile (T3, T4, TSH)': 899.0,
    'Lipid Profile': 499.0,
    'Vitamin D Test': 399.0,
    'HbA1c Test': 349.0,
  };
  
  // Sample test data with discounts
  final Map<String, String> testDiscounts = {
    'Complete Blood Count (CBC)': '40% OFF',
    'Diabetes Screening': '50% OFF',
    'Liver Function Test (LFT)': '38% OFF',
    'Kidney Function Test (KFT)': '42% OFF',
    'Thyroid Profile (T3, T4, TSH)': '40% OFF',
    'Lipid Profile': '44% OFF',
    'Vitamin D Test': '43% OFF',
    'HbA1c Test': '46% OFF',
  };
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Handle route arguments for tab navigation
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      final tabIndex = arguments['tabIndex'] as int?;
      if (tabIndex != null && tabIndex >= 0 && tabIndex < _pages.length) {
        // Use post frame callback to ensure the tab is built first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentIndex = tabIndex;
            });
          }
        });
      }
    }
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get help with your health tests and packages',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Call option
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await _makePhoneCall('+91-1800-123-4567');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5BFE),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B5BFE).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Call Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Speak with our health experts',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // WhatsApp option
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await _openWhatsApp();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WhatsApp Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Chat with us on WhatsApp',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    const String phoneNumber = '+91-1800-123-4567';
    const String message = 'Hello! I need help with my health tests and packages.';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
    );
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCartItems() async {
    try {
      // Load cart from API
      final apiService = ApiService();
      final result = await apiService.getCart();
      
      if (result['success'] && mounted) {
        final cartData = result['data'];
        final items = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        
        print('🛒 CART API SUCCESS:');
        print('Cart data from API: $cartData');
        print('Cart items from API: $items');
        
        // Extract test names from cart items
        final Set<String> serverCartItems = items.map((item) => item['test_name'] as String).toSet();
        
        print('Extracted test names: $serverCartItems');
        
        setState(() {
          this.cartData = cartData;
          cartItems = serverCartItems;
          _isLoadingCart = false;
        });
        
        print('✅ Cart data set successfully');
        print('Final cartData: ${this.cartData}');
        print('Final cartItems: $cartItems');
      } else {
        // Fallback to local storage if API fails
        print('❌ CART API FAILED:');
        print('API result: $result');
        final savedCartItems = await StorageService.getCartItems();
        print('Fallback to local storage: $savedCartItems');
        
        // Create a fallback cart data structure
        final fallbackCartData = {
          'cart_id': 'fallback_cart',
          'total_price': '0.00',
          'discount_value': '0.00',
          'discounted_amount': '0.00',
          'items': savedCartItems.map((testName) => {
            'id': 'fallback_${testName.hashCode}',
            'lab_test_id': 'fallback_test_id_${testName.hashCode}',
            'lab_package_id': null,
            'test_name': testName,
            'price': '0.00',
            'discount_type': null,
            'discount_value': '0.00',
            'discounted_amount': '0.00',
          }).toList(),
          'item_count': savedCartItems.length,
        };
        
        setState(() {
          cartData = fallbackCartData;
          cartItems = savedCartItems;
          _isLoadingCart = false;
        });
        print('✅ Fallback cart data created: $fallbackCartData');
      }
    } catch (e) {
      print('❌ CART LOADING ERROR: $e');
      // Fallback to local storage on error
      try {
        final savedCartItems = await StorageService.getCartItems();
        print('Fallback to local storage on error: $savedCartItems');
        
        // Create a fallback cart data structure
        final fallbackCartData = {
          'cart_id': 'fallback_cart_error',
          'total_price': '0.00',
          'discount_value': '0.00',
          'discounted_amount': '0.00',
          'items': savedCartItems.map((testName) => {
            'id': 'fallback_${testName.hashCode}',
            'lab_test_id': 'fallback_test_id_${testName.hashCode}',
            'lab_package_id': null,
            'test_name': testName,
            'price': '0.00',
            'discount_type': null,
            'discount_value': '0.00',
            'discounted_amount': '0.00',
          }).toList(),
          'item_count': savedCartItems.length,
        };
        
        setState(() {
          cartData = fallbackCartData;
          cartItems = savedCartItems;
          _isLoadingCart = false;
        });
        print('✅ Fallback cart data created on error: $fallbackCartData');
      } catch (e) {
        print('❌ Even local storage failed: $e');
        setState(() {
          cartData = {
            'cart_id': 'empty_cart',
            'total_price': '0.00',
            'discount_value': '0.00',
            'discounted_amount': '0.00',
            'items': [],
            'item_count': 0,
          };
          cartItems = {};
          _isLoadingCart = false;
        });
        print('✅ Empty cart data created');
      }
    }
  }

  Future<void> _saveCartItems() async {
    try {
      await StorageService.saveCartItems(cartItems);
    } catch (e) {
      print('DEBUG: Error saving cart items: $e');
    }
  }

  Future<void> _refreshCartData() async {
    try {
      print('🔄 Refreshing cart data from API...');
      final apiService = ApiService();
      final result = await apiService.getCart();
      
      if (result['success'] && mounted) {
        final cartData = result['data'];
        final items = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        
        print('🛒 CART REFRESH SUCCESS:');
        print('Updated cart data: $cartData');
        print('Updated cart items: $items');
        
        // Extract package/test IDs from cart items to sync local state
        final Set<String> serverCartItems = items.map((item) {
          // Use lab_package_id for packages, lab_test_id for tests, or fallback to item id
          final packageId = item['lab_package_id']?.toString();
          final testId = item['lab_test_id']?.toString();
          final itemId = item['id']?.toString();
          
          return packageId?.isNotEmpty == true ? packageId! :
                 testId?.isNotEmpty == true ? testId! :
                 itemId ?? item['test_name'] as String;
        }).toSet();
        
        setState(() {
          this.cartData = cartData;
          cartItems = serverCartItems;
        });
        
        print('✅ Cart data refreshed successfully');
      } else {
        print('❌ CART REFRESH FAILED:');
        print('API result: $result');
      }
    } catch (e) {
      print('❌ CART REFRESH ERROR: $e');
    }
  }

  List<Widget> get _pages => [
    HomeTab(
      cartItems: cartItems,
      cartData: cartData,
      onAddToCart: (itemId) async {
        setState(() {
          cartItems.add(itemId);
        });
        await _saveCartItems();
        // Refresh cart data from API after adding item
        await _refreshCartData();
      },
      onRemoveFromCart: (itemId) async {
        setState(() {
          cartItems.remove(itemId);
        });
        await _saveCartItems();
        // Refresh cart data from API after removing item
        await _refreshCartData();
      },
      testPrices: testPrices,
      testDiscounts: testDiscounts,
      onCartChanged: _refreshCartData, // Pass cart refresh callback
    ),
    TestsTab(
      key: _testsTabKey,
      cartItems: cartItems,
      cartData: cartData,
      onAddToCart: (itemId) async {
        setState(() {
          cartItems.add(itemId);
        });
        await _saveCartItems();
        // Refresh cart data from API after adding item
        await _refreshCartData();
      },
      onRemoveFromCart: (itemId) async {
        setState(() {
          cartItems.remove(itemId);
        });
        await _saveCartItems();
        // Refresh cart data from API after removing item
        await _refreshCartData();
      },
      testPrices: testPrices,
      testDiscounts: testDiscounts,
      onCartChanged: _refreshCartData, // Pass cart refresh callback
    ),
    const MyOrdersTab(),
    const ProfileTab(),
  ];

  // Global key for TestsTab to access its state
  final GlobalKey<_TestsTabState> _testsTabKey = GlobalKey<_TestsTabState>();
  
  // Method to navigate to Tests tab with category and optional tab index
  void _navigateToTestsTab(String category, {int? tabIndex}) {
    setState(() {
      _currentIndex = 1; // Navigate to Tests tab
    });
    
    // Use post frame callback to set category and tab index after tab is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testsTabKey.currentState?._setCategory(category, tabIndex: tabIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCart) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      resizeToAvoidBottomInset: false,
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCallOptions(context);
        },
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        child: const Icon(
          Icons.headset,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.grey,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, dynamic> cartData;
  final Future<void> Function(String) onAddToCart;
  final Future<void> Function(String) onRemoveFromCart;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final VoidCallback onCartChanged; // Callback for cart refresh

  const HomeTab({
    super.key,
    required this.cartItems,
    required this.cartData,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.testPrices,
    required this.testDiscounts,
    required this.onCartChanged, // Required callback
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? userProfile;
  bool isLoadingProfile = true;
  final LocationService _locationService = LocationService();
  String selectedCity = 'Chennai'; // Default selected city
  Set<String> cartItems = {}; // Track cart items by test name
  bool _isLoadingCart = true;
  Map<String, dynamic> cartData = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCartItems();
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    try {
      final apiService = ApiService();
      final result = await apiService.updateProfileImage(
        imageUrl: imageUrl,
        context: context,
      );

      if (result['success'] && mounted) {
        // Update the profile data with the new image URL from the response
        if (result['data'] != null && result['data']['profile'] != null) {
          setState(() {
            // Update the profile image URL in the user profile data
            if (userProfile != null) {
              userProfile!['profileimage'] = result['data']['profile']['profileimage'];
              if (userProfile!['profile'] != null) {
                userProfile!['profile']['profileimage'] = result['data']['profile']['profileimage'];
              }
            }
          });
        }
        
        // Also refresh the full profile data to ensure everything is up to date
        await _loadUserProfile();
        SnackBarHelper.showSuccess(context, 'Profile image updated successfully!');
      } else {
        SnackBarHelper.showError(context, result['message'] ?? 'Failed to update profile image');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error updating profile image: ${e.toString()}');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getMobileProfile(context);
      
      if (result['success'] && mounted) {
        setState(() {
          userProfile = result['data'];
          isLoadingProfile = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoadingProfile = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to load profile'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadCartItems() async {
    try {
      // Load cart from API
      final apiService = ApiService();
      final result = await apiService.getCart();
      
      if (result['success'] && mounted) {
        final cartData = result['data'];
        final items = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        
        // Extract test names and package names from cart items
        final Set<String> serverCartItems = items.map((item) {
          return (item['test_name'] ?? item['package_name'] ?? 'Unknown Item') as String;
        }).toSet();
        
        setState(() {
          this.cartData = cartData;
          cartItems = serverCartItems;
          _isLoadingCart = false;
        });
      } else {
        // Fallback to local storage if API fails
        final savedCartItems = await StorageService.getCartItems();
        
        // Create a fallback cart data structure
        final fallbackCartData = {
          'cart_id': 'fallback_cart',
          'total_price': '0.00',
          'discount_value': '0.00',
          'discounted_amount': '0.00',
          'items': savedCartItems.map((testName) => {
            'id': 'fallback_${testName.hashCode}',
            'lab_test_id': 'fallback_test_id_${testName.hashCode}',
            'lab_package_id': null,
            'test_name': testName,
            'price': '0.00',
            'discount_type': null,
            'discount_value': '0.00',
            'discounted_amount': '0.00',
          }).toList(),
          'item_count': savedCartItems.length,
        };
        
        setState(() {
          cartData = fallbackCartData;
          cartItems = savedCartItems;
          _isLoadingCart = false;
        });
      }
    } catch (e) {
      // Fallback to local storage on error
      try {
        final savedCartItems = await StorageService.getCartItems();
        
        // Create a fallback cart data structure
        final fallbackCartData = {
          'cart_id': 'fallback_cart_error',
          'total_price': '0.00',
          'discount_value': '0.00',
          'discounted_amount': '0.00',
          'items': savedCartItems.map((testName) => {
            'id': 'fallback_${testName.hashCode}',
            'lab_test_id': 'fallback_test_id_${testName.hashCode}',
            'lab_package_id': null,
            'test_name': testName,
            'price': '0.00',
            'discount_type': null,
            'discount_value': '0.00',
            'discounted_amount': '0.00',
          }).toList(),
          'item_count': savedCartItems.length,
        };
        
        setState(() {
          cartData = fallbackCartData;
          cartItems = savedCartItems;
          _isLoadingCart = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingCart = false;
        });
      }
    }
  }

  Future<void> _refreshCartData() async {
    try {
      // Load cart from API
      final apiService = ApiService();
      final result = await apiService.getCart();
      
      if (result['success'] && mounted) {
        final cartData = result['data'];
        final items = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        
        print('🛒 CART REFRESH SUCCESS:');
        print('Updated cart data from API: $cartData');
        print('Updated cart items from API: $items');
        
        // Extract test names and package names from cart items
        final Set<String> serverCartItems = items.map((item) {
          return (item['test_name'] ?? item['package_name'] ?? 'Unknown Item') as String;
        }).toSet();
        
        setState(() {
          this.cartData = cartData;
          cartItems = serverCartItems;
        });
        
        print('✅ Cart data refreshed successfully');
        print('Updated cartData: ${this.cartData}');
        print('Updated cartItems: $cartItems');
      }
    } catch (e) {
      print('❌ CART REFRESH ERROR: $e');
    }
  }

  /// Show cart summary bottom sheet
  void _showCartSummaryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              margin: const EdgeInsets.only(top: 8),
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
                  const Icon(
                    Icons.shopping_cart,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cart Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Cart items list
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add some tests or packages to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cartData['items']?.length ?? 0,
                      itemBuilder: (context, index) {
                        final cartItem = cartData['items'][index];
                        final itemName = cartItem['test_name'] ?? cartItem['package_name'] ?? 'Unknown Item';
                        final itemType = cartItem['lab_test_id'] != null ? 'Test' : 'Package';
                        final itemId = cartItem['id'] ?? cartItem['lab_test_id'] ?? cartItem['lab_package_id'] ?? '';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              itemType == 'Test' ? Icons.science : Icons.inventory,
                              color: AppColors.primaryBlue,
                            ),
                            title: Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemType,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (cartItem['price'] != null)
                                  Text(
                                    '₹${cartItem['price']}',
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );
                                
                                try {
                                  // Remove from database via API
                                  final apiService = ApiService();
                                  final result = await apiService.removeFromCart(itemId);
                                  
                                  if (result['success']) {
                                    // Refresh cart data from API first
                                    await _refreshCartData();
                                    
                                    // Close loading dialog
                                    Navigator.pop(context);
                                    
                                    // Close bottom sheet
                                    Navigator.pop(context);
                                    
                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Item removed from cart successfully'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    
                                    // Force rebuild of the entire widget tree
                                    if (mounted) {
                                      setState(() {});
                                    }
                                    
                                    // Notify parent widget to refresh cart data
                                    widget.onCartChanged();
                                    
                                    // Force parent widget to rebuild
                                    if (mounted) {
                                      // Trigger a rebuild of the parent widget
                                      final parentState = context.findAncestorStateOfType<_LandingPageState>();
                                      if (parentState != null && parentState.mounted) {
                                        parentState.setState(() {});
                                      }
                                    }
                                  } else {
                                    // Close loading dialog
                                    Navigator.pop(context);
                                    
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ?? 'Failed to remove item from cart'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Close loading dialog
                                  Navigator.pop(context);
                                  
                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error removing item: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Proceed button
            Container(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: cartItems.isEmpty ? null : () {
                  Navigator.pop(context);
                  _proceedToCheckout(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cartItems.isEmpty ? Colors.grey : AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  cartItems.isEmpty ? 'Cart is Empty' : 'Proceed to Checkout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Proceed to checkout (similar to bottom cart proceed button)
  void _proceedToCheckout(BuildContext context) {
    // Navigate to lab selection screen for checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabSelectionScreen(
          cartItems: cartItems,
          testPrices: const {}, // Will be loaded in lab selection screen
          testDiscounts: const {}, // Will be loaded in lab selection screen
          cartData: cartData,
          onCartChanged: () {
            // Refresh cart when returning
            _loadCartItems();
          },
        ),
      ),
    );
  }

  /// Extract city name from coordinates (simplified)
  String _extractCityFromCoordinates(double latitude, double longitude) {
    // For now, return a default city based on coordinates
    // In a real app, you would use reverse geocoding API
    if (latitude >= 12.9716 && latitude <= 13.0827 && 
        longitude >= 80.2707 && longitude <= 80.2707) {
      return 'Chennai';
    } else if (latitude >= 11.0168 && latitude <= 11.0168 && 
               longitude >= 76.9558 && longitude <= 76.9558) {
      return 'Coimbatore';
    } else if (latitude >= 9.9252 && latitude <= 9.9252 && 
               longitude >= 78.1198 && longitude <= 78.1198) {
      return 'Madurai';
    } else {
      return 'Chennai'; // Default fallback
    }
  }

  /// Test location functionality directly
  Future<void> _testLocationDirectly(BuildContext context) async {
    try {
      print('🧪 Testing location directly...');
      
      // Simple test to check if geolocator is working
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Testing geolocator plugin...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Try to get the last known position first (this might work without permissions)
      try {
        Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          print('🧪 Last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Last known: ${lastKnownPosition.latitude.toStringAsFixed(6)}, ${lastKnownPosition.longitude.toStringAsFixed(6)}'),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }
      } catch (e) {
        print('🧪 Last known position error: $e');
      }
      
      // If no last known position, try to get current position
      print('🧪 Trying to get current position...');
      Position position = await Geolocator.getCurrentPosition();
      print('🧪 Position obtained: ${position.latitude}, ${position.longitude}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Current: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('❌ Location test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Location error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get current location and show it in a toast
  Future<void> _getCurrentLocationAndShowToast(BuildContext context) async {
    try {
      // Show loading
      print('📍 Starting location request...');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Getting your current location...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      print('📍 Testing location directly...');
      
      // Try to get the last known position first (this might work without permissions)
      Position? lastKnownPosition;
      try {
        lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          print('📍 Last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
          
          // Dismiss loading toast
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Update selected city based on coordinates
          String cityFromCoordinates = _extractCityFromCoordinates(
            lastKnownPosition.latitude,
            lastKnownPosition.longitude,
          );
          setState(() {
            selectedCity = cityFromCoordinates;
          });
          
          // Location detected successfully (no toast needed)
          print('📍 Current location detected: $cityFromCoordinates');
          
          // Dismiss the bottom sheet
          Navigator.of(context).pop();
          return;
        }
      } catch (e) {
        print('📍 Last known position error: $e');
      }
      
      // If no last known position, try to get current position
      print('📍 Trying to get current position...');
      Position position = await Geolocator.getCurrentPosition();
      print('📍 Position obtained: ${position.latitude}, ${position.longitude}');
      
      // Update selected city based on coordinates
      String cityFromCoordinates = _extractCityFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        selectedCity = cityFromCoordinates;
      });
      
      // Dismiss loading toast
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Location detected successfully (no toast needed)
      print('📍 Current location detected: $cityFromCoordinates');
      
      // Dismiss the bottom sheet
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ Location exception: $e');
      // Dismiss loading toast and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error getting location: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showLocationPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationSelectionScreen(
          currentLocation: selectedCity,
          onLocationSelected: (String city) {
            setState(() {
              selectedCity = city;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location changed to $city'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // User Profile Section
                  GestureDetector(
                    onTap: () {
                      _showLocationPicker(context);
                    },
                    child: Row(
                      children: [
                        isLoadingProfile
                            ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                    ),
                                  ),
                                ),
                              )
                            : ProfileImagePicker(
                                currentImageUrl: userProfile?['profileimage'],
                                userId: userProfile?['user']?['id']?.toString() ?? 'unknown',
                                size: 40,
                                onImageUploaded: _updateProfileImage,
                                showEditIcon: false, // Don't show edit icon in header
                              ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLoadingProfile)
                              Container(
                                width: 100,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            else
                            Text(
                                userProfile?['profile']?['full_name'] ?? 'Customer',
                                style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (isLoadingProfile)
                                  Container(
                                    width: 80,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  )
                                else
                                Text(
                                    selectedCity,
                                    style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                  Icons.edit_location,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Cart Icon with Item Count
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        onPressed: () {
                          // Show cart summary bottom sheet
                          _showCartSummaryBottomSheet(context);
                        },
                      ),
                      if (cartItems.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartItems.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Notification Icon
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: Column(
                children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          // Service Grid Section
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ServiceGridSection(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                    // OfferBannerCarousel outside the horizontal padding
                    const OfferBannerCarousel(),
                    const SizedBox(height: 24),
                          // Stats Section
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: StatsInfoSection(),
                          ),
                          const SizedBox(height: 24),
                          // Top Diagnostics Tests Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                                  'Top Diagnostics Tests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                                    color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                                  child: const Text('View All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                          const SizedBox(height: 12),
                          _TopDiagnosticsCarousel(
                            cartItems: widget.cartItems,
                            onAddToCart: widget.onAddToCart,
                          ),
                    const SizedBox(height: 24),
                          // Popular Health Packages Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                                  'Popular Health Packages',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                                    color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                                  child: const Text('View all', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                          _TestPackagesCarousel(
                            cartItems: widget.cartItems,
                            onAddToCart: widget.onAddToCart,
                          ),
                    const SizedBox(height: 24),
                    // For Women Care Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'For Women Care',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _WomenCareGrid(),
                    const SizedBox(height: 24),
                    // const _HelpBookingCard(),
                    // const SizedBox(height: 24),
                  ],
                ),
                    ),
                  ),
                  _buildCartSummary(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0, left: 2.0),
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, color: AppColors.primaryBlue, size: 28)),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildLabCard(String name, String asset, double rating) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0, left: 2.0),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lab image or icon
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(16),
                  image: asset.startsWith('assets/')
                      ? DecorationImage(
                          image: AssetImage(asset),
                          fit: BoxFit.cover,
                          onError: (e, s) {},
                        )
                      : null,
                ),
                child: asset.startsWith('assets/')
                    ? null
                    : const Icon(Icons.local_hospital, size: 28, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 10),
              // Lab name
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Location (mock)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 13, color: AppColors.grey),
                  SizedBox(width: 2),
                  Text(
                    'Pune',
                    style: TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rating chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.green, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
  }

  Widget _buildRoutineTestCard(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0, left: 2.0),
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, color: AppColors.primaryBlue, size: 30)),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(String name, String price, String desc, {String? oldPrice}) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0, left: 2.0),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryBlue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Subtitle
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Price row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (oldPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          oldPrice,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB2EBF2),
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      child: const Text('Add'),
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

  Widget _buildCartSummary() {
    if (widget.cartItems.isEmpty) return const SizedBox.shrink();
    
    // Count tests and packages from cart data
    int testCount = 0;
    int packageCount = 0;
    
    if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (var item in items) {
        if (item['lab_test_id'] != null && item['lab_test_id'].toString().isNotEmpty) {
          testCount++;
        }
        if (item['lab_package_id'] != null && item['lab_package_id'].toString().isNotEmpty) {
          packageCount++;
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'Item' : 'Items'} in Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (testCount > 0)
                      Text(
                        '$testCount ${testCount == 1 ? 'Test' : 'Tests'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    if (testCount > 0 && packageCount > 0)
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    if (packageCount > 0)
                      Text(
                        '$packageCount ${packageCount == 1 ? 'Package' : 'Packages'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LabSelectionScreen(
                    cartItems: widget.cartItems,
                    testPrices: widget.testPrices,
                    testDiscounts: widget.testDiscounts,
                    cartData: widget.cartData,
                    onCartChanged: widget.onCartChanged, // Pass cart refresh callback
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tests Tab
class TestsTab extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, dynamic> cartData;
  final Future<void> Function(String) onAddToCart;
  final Future<void> Function(String) onRemoveFromCart;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final VoidCallback onCartChanged; // Callback for cart refresh
  final String? initialCategory; // Category filter to apply initially

  const TestsTab({
    super.key,
    required this.cartItems,
    required this.cartData,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.testPrices,
    required this.testDiscounts,
    required this.onCartChanged, // Required callback
    this.initialCategory, // Optional initial category
  });

  @override
  State<TestsTab> createState() => _TestsTabState();
}

class _TestsTabState extends State<TestsTab> with SingleTickerProviderStateMixin {
  List<String> selectedCategories = ['Blood Tests & Consultations'];
  String selectedCollectionType = 'both';
  late TabController _tabController;
  String _searchPlaceholder = 'Search tests & consultations';
  int _lastTabIndex = 0;
  
  // Search functionality
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Category filtering
  String? _selectedCategory;
  
  // Public method to set category from outside
  void _setCategory(String category, {int? tabIndex}) {
    if (mounted) {
      _searchController.clear(); // Clear search text field
      setState(() {
        _selectedCategory = category;
        _searchQuery = ''; // Clear search when setting category
        _searchResults = [];
        _isSearching = false;
      });
      
      // Switch to specific tab if tabIndex is provided
      if (tabIndex != null && tabIndex >= 0 && tabIndex < 2) {
        _tabController.animateTo(tabIndex);
      }
      
      _performCategorySearch();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {
        _searchPlaceholder = _tabController.index == 0 
            ? 'Search tests & consultations' 
            : 'Search packages';
      });
      
      // Reset pagination when switching tabs
      if (_tabController.index != _lastTabIndex) {
        print('🔄 Tab changed from $_lastTabIndex to ${_tabController.index}');
        _lastTabIndex = _tabController.index;
        
        // Force rebuild of the tab content to reset pagination
        setState(() {});
      }
    });
    
    // Set initial category if provided
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performCategorySearch();
        }
      });
    }
    
    // Ensure first tab is loaded immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _tabController.animateTo(0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Search functionality with debouncing
  void _performSearch(String query) {
    print('🔍 _performSearch called with query: "$query"');
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _isSearching = true;
      });

      try {
        print('🔍 Performing search for: "$query"');
        print('🔍 Query trimmed: "${query.trim()}"');
        print('🔍 Query length: ${query.trim().length}');
        
        // Only proceed if query is not empty
        if (query.trim().isEmpty) {
          print('🔍 Query is empty, skipping API call');
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
          return;
        }
        
        // Call API based on current tab
        if (_tabController.index == 0) {
          // Search for tests
          print('🔍 Calling API with search parameter...');
          print('🔍 Search query being passed: "${query.trim()}"');
          final result = await _apiService.getDiagnosisTests(
            search: query.trim(),
            latitude: 12.95154427492096,
            longitude: 80.25149535327924,
          );
          
          if (result['success'] && mounted) {
            final tests = List<Map<String, dynamic>>.from(result['data']['tests'] ?? []);
            setState(() {
              _searchResults = tests;
              _isSearching = false;
            });
            print('✅ Search results: ${tests.length} tests found');
            print('✅ API Response: $result');
          } else {
            print('❌ Search failed: ${result['message']}');
            print('❌ API Response: $result');
            setState(() {
              _searchResults = [];
              _isSearching = false;
            });
          }
        } else {
          // Search for packages
          print('📦 Calling packages API with search parameter...');
          print('📦 Search query being passed: "${query.trim()}"');
          final result = await _apiService.getPackages(
            search: query.trim(),
            page: 1,
            limit: 50,
            sortBy: 'baseprice',
            sortOrder: 'desc',
          );
          
          if (result['success'] && mounted) {
            final packages = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
            setState(() {
              _searchResults = packages;
              _isSearching = false;
            });
            print('✅ Package search results: ${packages.length} packages found');
            print('✅ Package API Response: $result');
          } else {
            print('❌ Package search failed: ${result['message']}');
            print('❌ Package API Response: $result');
            setState(() {
              _searchResults = [];
              _isSearching = false;
            });
          }
        }
      } catch (e) {
        print('❌ Search error: $e');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  /// Category search functionality
  void _performCategorySearch() async {
    if (_selectedCategory == null) return;
    
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      print('🏷️ Performing category search for: "$_selectedCategory"');
      
      // Call API based on current tab with category filter
      if (_tabController.index == 0) {
        // Search for tests with category
        final result = await _apiService.getDiagnosisTests(
          search: '', // Empty search to get all results
          latitude: 12.95154427492096,
          longitude: 80.25149535327924,
          category: _selectedCategory, // Pass category to API
        );
        
        if (result['success'] && mounted) {
          final tests = List<Map<String, dynamic>>.from(result['data']['tests'] ?? []);
          setState(() {
            _searchResults = tests;
            _isSearching = false;
          });
          print('✅ Category search results: ${tests.length} tests found for $_selectedCategory');
        } else {
          print('❌ Category search failed: ${result['message']}');
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } else {
        // Search for packages with category
        final result = await _apiService.getPackages(
          search: '', // Empty search to get all results
          page: 1,
          limit: 50,
          sortBy: 'baseprice',
          sortOrder: 'desc',
          category: _selectedCategory, // Pass category to API
        );
        
        if (result['success'] && mounted) {
          final packages = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
          setState(() {
            _searchResults = packages;
            _isSearching = false;
          });
          print('✅ Category package search results: ${packages.length} packages found for $_selectedCategory');
        } else {
          print('❌ Category package search failed: ${result['message']}');
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      print('❌ Category search error: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
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
                    'Filter',
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
                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: ValueKey(selectedCategories.length),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: InkWell(
                        onTap: () => _showCategorySearchDialog(context),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: selectedCategories.isEmpty
                                  ? Text(
                                      'Select Categories',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[500],
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${selectedCategories.length} selected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          children: selectedCategories.take(2).map((category) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.primaryBlue.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                        if (selectedCategories.length > 2)
                                          Text(
                                            '+${selectedCategories.length - 2} more',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Collection Type
                    const Text(
                      'Collection Type',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCollectionTypeOption('Home Collection', 'home_collection'),
                          const SizedBox(height: 12),
                          _buildCollectionTypeOption('Lab', 'lab'),
                          const SizedBox(height: 12),
                          _buildCollectionTypeOption('Both', 'both'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Price Range
                    const Text(
                      'Price Range',
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
                              Text('₹0'),
                              Text('₹5000'),
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
                              value: 2500,
                              min: 0,
                              max: 5000,
                              divisions: 50,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text(
                            'Selected: ₹0 - ₹2500',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Distance Range
                    const Text(
                      'Distance Range',
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
                              Text('50 km'),
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
                              value: 25,
                              min: 0,
                              max: 50,
                              divisions: 50,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text(
                            'Selected: 0 - 25 km',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
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

  void _showCategorySearchDialog(BuildContext context) {
    final List<String> categories = [
      'Blood Tests & Consultations',
      'Diabetes Tests',
      'Liver Function Tests',
      'Kidney Function Tests',
      'Thyroid Tests',
      'Lipid Profile Tests',
      'Vitamin Tests',
      'Hormone Tests',
      'Cardiac Tests',
      'Cancer Screening',
      'STD Tests',
      'Allergy Tests',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            List<String> tempSelectedCategories = List.from(selectedCategories);
            String searchQuery = '';
            List<String> filteredCategories = categories;
            
            return AlertDialog(
              title: const Text(
                'Select Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search TextField
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        dialogSetState(() {
                          searchQuery = value;
                          filteredCategories = categories
                              .where((category) => category.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Selected Categories Chips
                    if (tempSelectedCategories.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: tempSelectedCategories.map((category) => Chip(
                          label: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: AppColors.primaryBlue,
                          deleteIcon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          onDeleted: () {
                            dialogSetState(() {
                              tempSelectedCategories.remove(category);
                            });
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Categories List
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final isSelected = tempSelectedCategories.contains(category);
                          
                          return ListTile(
                            title: Text(
                              category,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? AppColors.primaryBlue : Colors.black87,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primaryBlue : Colors.grey,
                              size: 20,
                            ),
                            onTap: () {
                              dialogSetState(() {
                                if (isSelected) {
                                  tempSelectedCategories.remove(category);
                                } else {
                                  tempSelectedCategories.add(category);
                                }
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCategories = List.from(tempSelectedCategories);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(180),
          child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Health Tests & Packages',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Cart Icon with Item Count
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                              onPressed: () {
                                // Show cart summary bottom sheet
                                _showCartSummaryBottomSheet(context);
                              },
                            ),
                            if (widget.cartItems.isNotEmpty)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${widget.cartItems.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Container(
                        height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primaryBlue, width: 1),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.search, color: Colors.grey, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    print('🔍 TextField onChanged called with value: "$value"');
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                    _performSearch(value);
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: _searchPlaceholder,
                                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                                    suffixIcon: _isSearching 
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          )
                                        : _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 20),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchQuery = '';
                                                    _searchResults = [];
                                                  });
                                                  // Trigger search to reload all tests
                                                  _performSearch('');
                                                },
                                              )
                                            : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              // IconButton(
                              //   icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFF3B5BFE)),
                              // onPressed: () {
                              //   _showFilterBottomSheet(context);
                              // },
                              // ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primaryBlue,
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.primaryBlue,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.science, size: 18),
                                  SizedBox(width: 6),
                                  Text('Tests & Scans'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2, size: 18),
                                  SizedBox(width: 6),
                                  Text('Packages'),
                                ],
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
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping
                children: [
                    TestsListTab(
                      cartItems: widget.cartItems,
                      onAddToCart: (testName) async => await widget.onAddToCart(testName),
                      onRemoveFromCart: (testName) async => await widget.onRemoveFromCart(testName),
                      onTabActivated: () {
                        print('🔄 Tests tab activated - resetting pagination');
                        // Reset pagination when tests tab is activated
                      },
                      searchResults: _searchResults.isNotEmpty ? _searchResults : null,
                      isSearching: _isSearching,
                      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                      category: _selectedCategory, // Pass category filter
                    ),
                    PackagesListTab(
                      cartItems: widget.cartItems,
                      onAddToCart: (testName) async => await widget.onAddToCart(testName),
                      onRemoveFromCart: (testName) async => await widget.onRemoveFromCart(testName),
                      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                      isSearching: _isSearching,
                      searchResults: _searchResults.isNotEmpty ? _searchResults : null,
                      category: _selectedCategory, // Pass category filter
                    ),
                ],
              ),
            ),
            _buildCartSummary(),
          ],
        ),

      ),
    );
  }

  Widget _buildCollectionTypeOption(String title, String value) {
    final isSelected = selectedCollectionType == value;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCollectionType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? AppColors.primaryBlue : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get help with your health tests and packages',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Call option
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await _makePhoneCall('+91-1800-123-4567');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5BFE),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B5BFE).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Call Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Speak with our health experts',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // WhatsApp option
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await _openWhatsApp();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WhatsApp Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Chat with us on WhatsApp',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    const String phoneNumber = '+91-1800-123-4567';
    const String message = 'Hello! I need help with my health tests and packages.';
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
    );
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCartSummary() {
    if (widget.cartItems.isEmpty) return const SizedBox.shrink();
    
    // Count tests and packages from cart data
    int testCount = 0;
    int packageCount = 0;
    
    if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (var item in items) {
        if (item['lab_test_id'] != null && item['lab_test_id'].toString().isNotEmpty) {
          testCount++;
        }
        if (item['lab_package_id'] != null && item['lab_package_id'].toString().isNotEmpty) {
          packageCount++;
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
      color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
          children: [
                Text(
                  '${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'Item' : 'Items'} in Cart',
                    style: const TextStyle(
                      fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 4),
            Row(
              children: [
                    if (testCount > 0)
                      Text(
                        '$testCount ${testCount == 1 ? 'Test' : 'Tests'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    if (testCount > 0 && packageCount > 0)
                const Text(
                        ' • ',
                  style: TextStyle(
                          fontSize: 14,
                    fontWeight: FontWeight.w500,
                          color: Colors.grey,
                  ),
                ),
                    if (packageCount > 0)
                Text(
                        '$packageCount ${packageCount == 1 ? 'Package' : 'Packages'}',
                  style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LabSelectionScreen(
                    cartItems: widget.cartItems,
                    testPrices: widget.testPrices,
                    testDiscounts: widget.testDiscounts,
                    cartData: widget.cartData,
                    onCartChanged: widget.onCartChanged, // Pass cart refresh callback
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Proceed',
                  style: TextStyle(
                    fontSize: 16,
                fontWeight: FontWeight.w600,
                  ),
                ),
            ),
          ],
      ),
    );
  }

  /// Show cart summary bottom sheet
  void _showCartSummaryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              margin: const EdgeInsets.only(top: 8),
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
                  const Icon(
                    Icons.shopping_cart,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cart Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Cart items list
            Expanded(
              child: widget.cartItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add some tests or packages to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final itemName = widget.cartItems.elementAt(index);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text('Test/Package'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () {
                                widget.onRemoveFromCart(itemName);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Checkout button
            if (widget.cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to checkout or show checkout options
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Proceed to checkout'),
                          backgroundColor: AppColors.primaryBlue,
                        ),
                      );
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
                      'Proceed to Checkout',
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
  }
}







// My Orders Tab
class MyOrdersTab extends StatefulWidget {
  const MyOrdersTab({super.key});

  @override
  State<MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<MyOrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> upcomingOrders = [];
  List<Map<String, dynamic>> pastOrders = [];
  bool isLoadingUpcoming = true;
  bool isLoadingPast = true;
  String? errorMessageUpcoming;
  String? errorMessagePast;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointmentHistory();
  }

  Future<void> _loadAppointmentHistory() async {
    await Future.wait([
      _loadUpcomingOrders(),
      _loadPastOrders(),
    ]);
  }

  Future<void> _loadUpcomingOrders() async {
    try {
      setState(() {
        isLoadingUpcoming = true;
        errorMessageUpcoming = null;
      });

      final apiService = ApiService();
      final result = await apiService.getAppointmentHistory(
        bookingType: 'future',
        page: 1,
        limit: 10,
        statusId: 1,
        paymentStatus: 1,
      );

      if (result['success'] && mounted) {
        final data = result['data'];
        final appointments = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        // Debug: Print the first appointment to see the data structure
        if (appointments.isNotEmpty) {
          print('🔄 Debug: First upcoming appointment data structure:');
          print('🔄 Debug: ${appointments.first}');
        }
        
        setState(() {
          upcomingOrders = appointments;
          isLoadingUpcoming = false;
        });
      } else {
        setState(() {
          errorMessageUpcoming = result['message'] ?? 'Failed to load upcoming orders';
          isLoadingUpcoming = false;
        });
      }
    } catch (e) {
      setState(() {
        print('🔄 API Service: Error in appointment history API: $e');
        errorMessageUpcoming = 'Network error occurred12';
        isLoadingUpcoming = false;
      });
    }
  }

  Future<void> _loadPastOrders() async {
    try {
      setState(() {
        isLoadingPast = true;
        errorMessagePast = null;
      });

      final apiService = ApiService();
      final result = await apiService.getAppointmentHistory(
        bookingType: 'past',
        page: 1,
        limit: 10,
        statusId: 1,
        paymentStatus: 1,
      );

      if (result['success'] && mounted) {
        final data = result['data'];
        final appointments = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        // Debug: Print the first appointment to see the data structure
        if (appointments.isNotEmpty) {
          print('🔄 Debug: First past appointment data structure:');
          print('🔄 Debug: ${appointments.first}');
        }
        
        setState(() {
          pastOrders = appointments;
          isLoadingPast = false;
        });
      } else {
        setState(() {
          errorMessagePast = result['message'] ?? 'Failed to load past orders';
          isLoadingPast = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessagePast = 'Network error occurred12';
        isLoadingPast = false;
      });
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

  String _formatTimeOnly(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    // Convert to 12-hour format
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatAppointmentDate(Map<String, dynamic> order) {
    // Try different possible date fields
    final dateString = order['appointment_date']?.toString() ?? 
                      order['date']?.toString() ?? 
                      order['scheduled_date']?.toString() ?? 
                      order['created_at']?.toString() ?? 
                      'N/A';
    
    if (dateString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatAppointmentTime(Map<String, dynamic> order) {
    // Try different possible time fields
    final timeString = order['appointment_time']?.toString() ?? 
                      order['time']?.toString() ?? 
                      order['scheduled_time']?.toString() ?? 
                      'N/A';
    
    if (timeString == 'N/A') return 'N/A';
    
    try {
      // If it's a full datetime string, extract time
      if (timeString.contains('T') || timeString.contains(' ')) {
        final dateTime = DateTime.parse(timeString);
        return _formatTimeOnly(dateTime);
      }
      
      // If it's just a time string, try to parse it
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
        }
      }
      
      return timeString;
    } catch (e) {
      return timeString;
        }
  }

  String _getTestPackageNames(Map<String, dynamic> order) {
    final lineItems = order['lineItems'] as List<dynamic>? ?? [];
    if (lineItems.isEmpty) {
      return 'No tests/packages';
    }
    
    final names = <String>[];
    for (final item in lineItems) {
      if (item['test'] != null) {
        names.add(item['test']['testname'] ?? 'Unknown Test');
      } else if (item['package'] != null) {
        names.add(item['package']['packagename'] ?? 'Unknown Package');
      }
    }
    
    if (names.isEmpty) {
      return 'No tests/packages';
    } else if (names.length == 1) {
      return names.first;
    } else {
      return '${names.first} +${names.length - 1} more';
    }
  }

  String _formatPastDate(Map<String, dynamic> order) {
    final dateString = order['appointment_datetime']?.toString() ?? 
                      order['appointment_date']?.toString() ?? 
                      order['date']?.toString() ?? 
                      'N/A';
    
    if (dateString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPastTime(Map<String, dynamic> order) {
    final dateString = order['appointment_datetime']?.toString() ?? 
                      order['appointment_time']?.toString() ?? 
                      order['time']?.toString() ?? 
                      'N/A';
    
    if (dateString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateString);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      
      // Convert to 12-hour format
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPastCollectionType(Map<String, dynamic> order) {
    final isHomeCollection = order['is_home_collection'] ?? false;
    return isHomeCollection ? 'Home Collection' : 'Lab Collection';
  }

  String _formatPastAmount(Map<String, dynamic> order) {
    final amountRaw = order['final_amount'] ?? 
                     order['total_amount'] ?? 
                     order['amount'] ?? 
                     0.0;
    
    if (amountRaw == 0.0) return 'N/A';
    
    try {
      final amount = amountRaw is String 
          ? double.tryParse(amountRaw) ?? 0.0 
          : (amountRaw is num ? amountRaw.toDouble() : 0.0);
      
      if (amount == 0.0) return 'N/A';
      
      return '₹${amount.toStringAsFixed(2)}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatCollectionType(Map<String, dynamic> order) {
    // Try different possible collection type fields
    final isHomeCollection = order['is_home_collection'] ?? 
                           order['home_collection'] ?? 
                           order['collection_type'] == 'home' ?? 
                           false;
    
    return isHomeCollection ? 'Home Collection' : 'Lab Collection';
  }

  String _formatUpcomingAmount(Map<String, dynamic> order) {
    // Try different possible amount fields for upcoming appointments
    final amountRaw = order['final_amount'] ?? 
                     order['amount'] ?? 
                     order['total_amount'] ?? 
                     order['paid_amount'] ?? 
                     0.0;
    
    if (amountRaw == 0.0) return 'N/A';
    
    try {
      final amount = amountRaw is String 
          ? double.tryParse(amountRaw) ?? 0.0 
          : (amountRaw is num ? amountRaw.toDouble() : 0.0);
      
      if (amount == 0.0) return 'N/A';
      
      return '₹${amount.toStringAsFixed(2)}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAmount(Map<String, dynamic> order) {
    // Try different possible amount fields
    final amountRaw = order['amount'] ?? 
                     order['total_amount'] ?? 
                     order['final_amount'] ?? 
                     order['paid_amount'] ?? 
                     0.0;
    
    if (amountRaw == 0.0) return 'N/A';
    
    try {
      final amount = amountRaw is String 
          ? double.tryParse(amountRaw) ?? 0.0 
          : (amountRaw is num ? amountRaw.toDouble() : 0.0);
      
      if (amount == 0.0) return 'N/A';
      
      return '₹${amount.toStringAsFixed(2)}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatUpcomingDate(Map<String, dynamic> order) {
    // Try different possible date fields for upcoming appointments
    final dateString = order['appointment_datetime']?.toString() ?? 
                      order['appointment_date']?.toString() ?? 
                      order['scheduled_datetime']?.toString() ?? 
                      order['scheduled_date']?.toString() ?? 
                      order['date']?.toString() ?? 
                      'N/A';
    
    if (dateString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateString);
      return _formatDateTime(dateTime.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  String _formatUpcomingTime(Map<String, dynamic> order) {
    // Try different possible time fields for upcoming appointments
    final timeString = order['appointment_datetime']?.toString() ?? 
                      order['appointment_time']?.toString() ?? 
                      order['scheduled_datetime']?.toString() ?? 
                      order['scheduled_time']?.toString() ?? 
                      order['time']?.toString() ?? 
                      'N/A';
    
    if (timeString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(timeString);
      return _formatTimeOnly(dateTime.toLocal());
    } catch (e) {
      return timeString;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cancel appointment method
  Future<void> _cancelAppointment(Map<String, dynamic> order) async {
    // Show cancellation dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CancelAppointmentDialog(),
    );
    
    if (result != null && result['confirmed'] == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.primaryBlue,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cancelling appointment...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        
        final apiService = ApiService();
        final appointmentId = order['appointment_id']?.toString() ?? order['id']?.toString() ?? '';
        
        final cancelResult = await apiService.cancelAppointment(
          appointmentId: appointmentId,
          cancellationReason: result['reason'] ?? 'User requested cancellation',
          refundToWallet: result['refundToWallet'] ?? true,
          context: context,
        );
        
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
        
        if (cancelResult['success'] == true) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appointment cancelled successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Refresh the orders list
          _loadAppointmentHistory();
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(cancelResult['message'] ?? 'Failed to cancel appointment'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog if still open
        if (mounted) Navigator.of(context).pop();
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Tab Bar
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      labelColor: AppColors.primaryBlue,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar View
              Expanded(
              child: TabBarView(
                controller: _tabController,
                  children: [
                  // Upcoming Orders Tab
                  _buildUpcomingOrdersTab(),
                  
                  // Past Orders Tab
                  _buildPastOrdersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildUpcomingOrdersTab() {
    if (isLoadingUpcoming) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading upcoming orders...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
      ),
    );
  }

    if (errorMessageUpcoming != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessageUpcoming!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUpcomingOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (upcomingOrders.isEmpty) {
      return _buildEmptyState('No upcoming orders', 'You don\'t have any scheduled tests', isUpcoming: true);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUpcomingOrders();
      },
      color: Colors.white,
      backgroundColor: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: upcomingOrders.length,
        itemBuilder: (context, index) {
          final order = upcomingOrders[index];
          return _buildUpcomingOrderCard(context, order);
        },
      ),
    );
  }

  Widget _buildPastOrdersTab() {
    if (isLoadingPast) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading past orders...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (errorMessagePast != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessagePast!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPastOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (pastOrders.isEmpty) {
      return _buildEmptyState('No past orders', 'You haven\'t completed any tests yet', isUpcoming: false);
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPastOrders();
      },
      color: Colors.white,
      backgroundColor: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pastOrders.length,
        itemBuilder: (context, index) {
          final order = pastOrders[index];
          return _buildPastOrderCard(context, order);
        },
      ),
    );
  }

  Widget _buildUpcomingOrderCard(BuildContext context, Map<String, dynamic> order) {
    return InkWell(
      onTap: () {
                 final appointmentId = order['appointment_id']?.toString() ?? order['id']?.toString() ?? '';
         if (appointmentId.isNotEmpty) {
           Navigator.of(context).push(
             MaterialPageRoute(
               builder: (context) => OrderDetailScreen.withAppointmentId(
                 appointmentId: appointmentId,
               ),
             ),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Unable to load appointment details'),
               backgroundColor: Colors.red,
             ),
           );
         }
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
                child: const Icon(
                  Icons.schedule,
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
                      order['organization']?['name']?.toString() ?? 
                      order['lab_name']?.toString() ?? 
                      order['lab']?.toString() ?? 
                      order['organization_name']?.toString() ?? 
                      'Lab Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                      order['organization']?['branchname']?.toString() ?? 
                      
                      'Branch Name',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
          ),
        ],
      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                  order['status_text']?.toString() ?? 'Pending',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.calendar_today,
                  'Date',
                  _formatUpcomingDate(order),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(Icons.location_on, 'Collection', _formatCollectionType(order)),
              ),
              Expanded(
                child: _buildDetailItem(Icons.payment, 'Amount', _formatUpcomingAmount(order)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Reschedule functionality
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _cancelAppointment(order);
                  },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ) );
  }
  }

  Widget _buildPastOrderCard(BuildContext context, Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () {
                 final appointmentId = order['appointment_id']?.toString() ?? order['id']?.toString() ?? '';
         if (appointmentId.isNotEmpty) {
           Navigator.of(context).push(
             MaterialPageRoute(
               builder: (context) => OrderDetailScreen.withAppointmentId(
                 appointmentId: appointmentId,
               ),
             ),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Unable to load appointment details'),
               backgroundColor: Colors.red,
             ),
           );
         }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      order['organization']?['name']?.toString() ?? 
                      order['lab_name']?.toString() ?? 
                      order['lab']?.toString() ?? 
                      order['organization_name']?.toString() ?? 
                      'Lab Name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                      order['organization']?['branch_name']?.toString() ?? 
                      order['organization']?['name']?.toString() ?? 
                      order['branch_name']?.toString() ?? 
                      'Branch Name',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(Icons.calendar_today, 'Date', _formatPastDate(order)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(Icons.location_on, 'Collection', _formatPastCollectionType(order)),
              ),
              Expanded(
                child: _buildDetailItem(Icons.payment, 'Amount', _formatPastAmount(order)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Download report functionality
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Share report functionality
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )  );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
              style: TextStyle(
                fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                fontWeight: FontWeight.w600,
                  color: Colors.black87,
              ),
              ),
            ],
            ),
          ),
        ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, {bool isUpcoming = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpcoming ? Icons.schedule : Icons.history,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isUpcoming)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Book your first test to see it here',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getDetailedOrderData(Map<String, dynamic> order) {
    return {
      'orderId': 'ORD123456',
      'orderDate': '2024-01-15',
      'scheduledDate': order['date']?.toString() ?? 'N/A',
      'scheduledTime': order['time']?.toString() ?? 'N/A',
      'status': order['status']?.toString() ?? 'Pending',
      'collectionType': order['collectionType']?.toString() ?? 'N/A',
      'tests': [
        {
          'name': order['name']?.toString() ?? 'Test Name',
          'description': 'Blood test',
          'price': order['amount']?.toString() ?? 'N/A',
          'originalPrice': '₹999',
        },
      ],
      'lab': {
        'name': order['lab']?.toString() ?? 'Lab Name',
        'address': '123 Street, City',
        'phone': '+91 98765 43210',
        'email': 'info@lab.com',
        'rating': 4.5,
        'reviews': 1250,
        'workingHours': '8:00 AM - 8:00 PM',
      },
      'payment': {
        'method': 'Online Payment',
        'transactionId': 'TXN123456',
        'subtotal': '₹999',
        'discount': '₹200',
        'couponDiscount': '₹100',
        'walletUsed': '₹50',
        'total': order['amount']?.toString() ?? 'N/A',
      },
      'collection': {
        'address': 'Home Address',
        'contactPerson': 'John Doe',
        'contactPhone': '+91 98765 43210',
        'instructions': 'Fasting required',
      },
    };
  }

  String _getTestPackageNames(Map<String, dynamic> order) {
    final lineItems = order['lineItems'] as List<dynamic>? ?? [];
    if (lineItems.isEmpty) {
      return 'No tests/packages';
    }
    
    final names = <String>[];
    for (final item in lineItems) {
      if (item['test'] != null) {
        names.add(item['test']['testname'] ?? 'Unknown Test');
      } else if (item['package'] != null) {
        names.add(item['package']['packagename'] ?? 'Unknown Package');
      }
    }
    
    if (names.isEmpty) {
      return 'No tests/packages';
    } else if (names.length == 1) {
      return names.first;
    } else {
      return '${names.first} +${names.length - 1} more';
    }
  }

  String _formatPastDate(Map<String, dynamic> order) {
    final dateString = order['appointment_datetime']?.toString() ?? 
                      order['appointment_date']?.toString() ?? 
                      order['date']?.toString() ?? 
                      'N/A';
    
    if (dateString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPastTime(Map<String, dynamic> order) {
    final dateString = order['appointment_datetime']?.toString() ?? 
                      order['appointment_time']?.toString() ?? 
                      order['time']?.toString() ?? 
                      'N/A';
    
    if (dateString == 'N/A') return 'N/A';
    
    try {
      final dateTime = DateTime.parse(dateString);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      
      // Convert to 12-hour format
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPastCollectionType(Map<String, dynamic> order) {
    final isHomeCollection = order['is_home_collection'] ?? false;
    return isHomeCollection ? 'Home Collection' : 'Lab Collection';
  }

  String _formatPastAmount(Map<String, dynamic> order) {
    final amountRaw = order['final_amount'] ?? 
                     order['total_amount'] ?? 
                     order['amount'] ?? 
                     0.0;
    
    if (amountRaw == 0.0) return 'N/A';
    
    try {
      final amount = amountRaw is String 
          ? double.tryParse(amountRaw) ?? 0.0 
          : (amountRaw is num ? amountRaw.toDouble() : 0.0);
      
      if (amount == 0.0) return 'N/A';
      
      return '₹${amount.toStringAsFixed(2)}';
    } catch (e) {
      return 'N/A';
    }
  }
  



// Call Tab
class CallTab extends StatefulWidget {
  const CallTab({super.key});

  @override
  State<CallTab> createState() => _CallTabState();
}

class _CallTabState extends State<CallTab> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger dialer when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _makeCall();
    });
  }

  Future<void> _makeCall() async {
    try {
      // Use url_launcher to open dialer
      final Uri phoneUri = Uri(scheme: 'tel', path: '+91 98765 43210');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
        ),
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _showWalletHistory = false;
  Map<String, dynamic>? userProfile;
  bool isLoadingProfile = true;
  String? errorMessage;
  
  // Wallet state
  Map<String, dynamic>? walletData;
  bool isLoadingWallet = true;
  String? walletErrorMessage;
  
  // Referral stats state
  Map<String, dynamic>? referralStats;
  bool isLoadingReferralStats = true;
  String? referralStatsErrorMessage;

  final List<Map<String, dynamic>> walletTransactions = [
    {
      'type': 'Credit',
      'amount': 1000.0,
      'description': 'Added money to wallet',
      'date': '2024-01-15',
      'time': '14:30',
      'method': 'UPI',
    },
    {
      'type': 'Debit',
      'amount': 450.0,
      'description': 'Blood test payment',
      'date': '2024-01-14',
      'time': '10:15',
      'method': 'Wallet',
    },
    {
      'type': 'Credit',
      'amount': 500.0,
      'description': 'Referral bonus',
      'date': '2024-01-12',
      'time': '16:45',
      'method': 'Bonus',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadWalletData();
    _loadReferralStats();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoadingProfile = true;
        errorMessage = null;
      });

      final apiService = ApiService();
      final result = await apiService.getMobileProfile(context);

      if (result['success'] && mounted) {
        setState(() {
          userProfile = result['data'];
          isLoadingProfile = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load profile';
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error occurred';
        isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadWalletData() async {
    try {
      setState(() {
        isLoadingWallet = true;
        walletErrorMessage = null;
      });

      final apiService = ApiService();
      final result = await apiService.getMobileWallet();

      if (result['success'] && mounted) {
        setState(() {
          walletData = result['data'];
          isLoadingWallet = false;
        });
      } else {
        setState(() {
          walletErrorMessage = result['message'] ?? 'Failed to load wallet';
          isLoadingWallet = false;
        });
      }
    } catch (e) {
      setState(() {
        walletErrorMessage = 'Network error occurred';
        isLoadingWallet = false;
      });
    }
  }

  Future<void> _loadReferralStats() async {
    try {
      setState(() {
        isLoadingReferralStats = true;
        referralStatsErrorMessage = null;
      });

      final apiService = ApiService();
      final result = await apiService.getReferralStats(context);

      if (result['success'] && mounted) {
        setState(() {
          referralStats = result['data'];
          isLoadingReferralStats = false;
        });
      } else {
        setState(() {
          referralStatsErrorMessage = result['message'] ?? 'Failed to load referral stats';
          isLoadingReferralStats = false;
        });
      }
    } catch (e) {
      setState(() {
        referralStatsErrorMessage = 'Network error occurred';
        isLoadingReferralStats = false;
      });
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    try {
      final apiService = ApiService();
      final result = await apiService.updateProfileImage(
        imageUrl: imageUrl,
        context: context,
      );

      if (result['success'] && mounted) {
        // Update the profile data with the new image URL from the response
        if (result['data'] != null && result['data']['profile'] != null) {
          setState(() {
            // Update the profile image URL in the user profile data
            if (userProfile != null) {
              userProfile!['profileimage'] = result['data']['profile']['profileimage'];
              if (userProfile!['profile'] != null) {
                userProfile!['profile']['profileimage'] = result['data']['profile']['profileimage'];
              }
            }
          });
        }
        
        // Also refresh the full profile data to ensure everything is up to date
        await _loadUserProfile();
        SnackBarHelper.showSuccess(context, 'Profile image updated successfully!');
      } else {
        SnackBarHelper.showError(context, result['message'] ?? 'Failed to update profile image');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Error updating profile image: ${e.toString()}');
    }
  }

  void _shareReferralLink() {
    final referralLink = referralStats?['referral_link'] ?? 'https://yourapp.com/referral';
    final referralCode = referralStats?['user_info']?['referral_code'] ?? '';
    
    // Show a dialog with the referral information
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.share, color: Color(0xFFE74C3C)),
              SizedBox(width: 8),
              Text('Share Referral Link'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share your referral link with friends and earn rewards!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Referral Code:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      referralCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE74C3C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Referral Link:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      referralLink,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Earn ₹${referralStats?['bonus_info']?['referral_bonus'] ?? '25'} for each successful referral!',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you can implement actual sharing functionality
                // For now, just close the dialog
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing functionality will be implemented'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMoneyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMoneyBottomSheet(
        onMoneyAdded: () {
          // Refresh wallet data after adding money
          _loadWalletData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Profile Header - No Card View
              Row(
                children: [
                  // Profile picture
                  isLoadingProfile
                      ? Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primaryBlue, AppColors.primaryBlue],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B5BFE).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : ProfileImagePicker(
                          currentImageUrl: userProfile?['profile']?['profileimage'],
                          userId: userProfile?['user']?['id']?.toString() ?? 'unknown',
                          size: 80,
                          onImageUploaded: _updateProfileImage,
                          showEditIcon: true,
                        ),
                  const SizedBox(width: 16),
                  // User info
                  Expanded(
                child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        if (isLoadingProfile)
                          const SizedBox(
                            height: 24,
                            child: LinearProgressIndicator(),
                          )
                        else
                          Text(
                            userProfile?['profile']?['full_name'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (!isLoadingProfile)
                          Text(
                            userProfile?['profile']?['email'] ?? 'No email provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (!isLoadingProfile)
                          Text(
                            userProfile?['user']?['phone'] ?? 'No phone provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () {},
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Error message for profile loading
              if (errorMessage != null)
                    Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadUserProfile,
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Wallet error message
              if (walletErrorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          walletErrorMessage!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadWalletData,
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Referral stats error message
              if (referralStatsErrorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          referralStatsErrorMessage!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadReferralStats,
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Wallet Section
                    Container(
                padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00), // Solid Amber
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'My Wallet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (walletData?['transactions']?['data'] != null && 
                            (walletData!['transactions']['data'] as List).isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showWalletHistory = !_showWalletHistory;
                              });
                            },
                      child: Icon(
                              _showWalletHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
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
                    const Text(
                              'Available Balance',
                      style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isLoadingWallet)
                              const SizedBox(
                                width: 80,
                                height: 28,
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.white30,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              Text(
                                '₹${walletData?['wallet']?['balance'] ?? '0.00'}',
                                style: const TextStyle(
                                  fontSize: 28,
                        fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => _showAddMoneyBottomSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF8F00),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Money',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showWalletHistory && walletData?['transactions']?['data'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const WalletHistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                    ),
                    const SizedBox(height: 8),
                            if ((walletData!['transactions']['data'] as List).isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ...(walletData!['transactions']['data'] as List)
                                  .take(2)
                                  .map((transaction) => _buildWalletTransactionItem(transaction)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Referral Program Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Refer & Earn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Invite friends and earn ₹${referralStats?['bonus_info']?['referral_bonus'] ?? '25'} for each successful referral',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Referrals',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isLoadingReferralStats)
                                const SizedBox(
                                  width: 40,
                                  height: 20,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.white30,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                Text(
                                  '${referralStats?['referral_stats']?['total_referrals'] ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Earned Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isLoadingReferralStats)
                                const SizedBox(
                                  width: 40,
                                  height: 20,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.white30,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                Text(
                                  '₹${referralStats?['referral_stats']?['total_earnings'] ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _shareReferralLink(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE74C3C),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Menu Items with enhanced design
              Container(
      decoration: BoxDecoration(
        color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
          ),
        ],
      ),
                child: Column(
                  children: [
                    _buildMenuItem(context, Icons.medical_services, 'Medical History', 'View your medical records'),
                    _buildDivider(),
                    _buildMenuItem(context, Icons.family_restroom, 'Family Members', 'Manage family accounts'),
                    _buildDivider(),
                    _buildMenuItem(context, Icons.account_balance_wallet, 'Wallet History', 'View transaction history'),
                    _buildDivider(),
                    _buildMenuItem(context, Icons.location_on, 'Addresses', 'Manage delivery addresses'),
                    _buildDivider(),
                    _buildMenuItem(context, Icons.settings, 'Settings', 'App preferences & notifications'),
                    _buildDivider(),
                    _buildMenuItem(context, Icons.help, 'Help & Support', 'Get help and contact support'),
                    _buildDivider(),
                    _buildMenuItem(context, Icons.logout, 'Logout', 'Sign out of your account', isLogout: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // App Version Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF7F8C8D),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'App Version 1.0.0',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
  }





  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, {bool isLogout = false, bool isDebug = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
        width: 48,
        height: 48,
          decoration: BoxDecoration(
            color: isLogout 
                ? Colors.red.withOpacity(0.1)
                : isDebug
                    ? Colors.orange.withOpacity(0.1)
                    : const Color(0xFF3B5BFE).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
                              color: isLogout ? Colors.red : isDebug ? Colors.orange : AppColors.primaryBlue,
          size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          color: isLogout ? Colors.red : isDebug ? Colors.orange : const Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: isLogout ? Colors.red.withOpacity(0.7) : isDebug ? Colors.orange.withOpacity(0.7) : const Color(0xFF7F8C8D),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
        color: isLogout ? Colors.red : isDebug ? Colors.orange : const Color(0xFF7F8C8D),
      ),
      onTap: () async {
        if (title == 'Medical History') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MedicalHistoryScreen(),
            ),
          );
        } else if (title == 'Wallet History') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WalletHistoryScreen(),
            ),
          );
        } else if (title == 'Family Members') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FamilyMembersScreen(),
            ),
          );
        } else if (title == 'Addresses') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddressesScreen(),
            ),
          );
        } else if (title == 'Logout') {
          // Use AuthUtils for proper logout
          await AuthUtils.logout(context);
        }
        // TODO: Add navigation for other menu items
      },
    );
  }

  Widget _buildWalletTransactionItem(Map<String, dynamic> transaction) {
    // Map API transaction data to UI fields
    final transactionType = transaction['transaction_type'] ?? transaction['type'] ?? 'debit';
    final isCredit = transactionType.toLowerCase() == 'credit' || transactionType.toLowerCase() == 'credit';
    
    // Handle amount as either string or number
    final amountRaw = transaction['amount'] ?? transaction['transaction_amount'] ?? 0.0;
    final amount = amountRaw is String ? double.tryParse(amountRaw) ?? 0.0 : (amountRaw is num ? amountRaw.toDouble() : 0.0);
    final amountText = isCredit ? '+₹${amount.toStringAsFixed(2)}' : '-₹${amount.toStringAsFixed(2)}';
    
    // Format date and time
    final createdAt = transaction['created_at'] ?? transaction['date'];
    String dateTimeText = '';
    if (createdAt != null) {
      try {
        final dateTime = DateTime.parse(createdAt);
        dateTimeText = '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        dateTimeText = '${transaction['date'] ?? ''} at ${transaction['time'] ?? ''}';
      }
    } else {
      dateTimeText = '${transaction['date'] ?? ''} at ${transaction['time'] ?? ''}';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['description'] ?? transaction['transaction_description'] ?? 'Transaction',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateTimeText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green[300] : Colors.red[300],
                ),
              ),
              Text(
                transaction['method'] ?? transaction['payment_method'] ?? 'Wallet',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: const Color(0xFFE0E0E0).withOpacity(0.5),
      ),
    );
  }
} 

class ServiceGridSection extends StatelessWidget {
  const ServiceGridSection({super.key});

  void _navigateToTestsWithCategory(BuildContext context, String category, {int? tabIndex}) {
    // Find the LandingPageState to access the tab controller
    final landingPageState = context.findAncestorStateOfType<_LandingPageState>();
    if (landingPageState != null) {
      // Navigate to Tests tab (index 1) and pass the category and tab index
      landingPageState._navigateToTestsTab(category, tabIndex: tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'icon': Icons.bloodtype,
        'color': const Color(0xFFE74C3C),
        'label': 'Blood Tests & Consultations',
        'category': 'blood_tests',
      },
      {
        'icon': Icons.scanner,
        'color': const Color(0xFF9B59B6),
        'label': 'Doctor / Dietitian / Physio Consultation',
        'category': 'scans',
      },
      {
        'icon': Icons.medical_services,
        'color': const Color(0xFF2980F2),
        'label': 'Master Health Checkup @ Home',
        'category': 'health_checkup',
        'tabIndex': 1, // Navigate to Packages tab
      },
      {
        'icon': Icons.description,
        'color': const Color(0xFFF2994A),
        'label': 'View Reports',
        'category': null,
      },
    ];

    return Column(
      children: [
        // Service Grid (2x2)
        GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return GestureDetector(
          onTap: service['category'] != null 
              ? () => _navigateToTestsWithCategory(
                  context, 
                  service['category'] as String,
                  tabIndex: service['tabIndex'] as int?,
                )
              : () {
                  // Handle other service taps (View Reports)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${service['label']} coming soon!'),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                  );
                },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (service['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(service['icon'] as IconData, color: service['color'] as Color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    service['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        );
      },
        ),
        const SizedBox(height: 12),
        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.6), width: 1.5),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Book via WhatsApp',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.6), width: 1.5),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: AppColors.primaryBlue, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Book with Dr prescription',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WhatsAppBanner extends StatelessWidget {
  const WhatsAppBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WhatsApp icon
          Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Appointment via WhatsApp',
                  style: TextStyle(
                    color: Color(0xFF43B02A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chat with us. Book your appointment in 2 min.',
                  style: TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 

class StatsInfoSection extends StatelessWidget {
  const StatsInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'value': '60\nMins',
        'title': 'Home',
        'subtitle': 'Collection',
        'icon': null,
      },
      {
        'value': '1M',
        'title': 'Happy',
        'subtitle': 'Customers',
        'icon': null,
      },
      {
        'value': '4.9',
        'title': 'Google',
        'subtitle': 'Rating',
        'icon': null,
      },
      {
        'value': null,
        'title': 'NABL Certified',
        'subtitle': 'Labs',
        'icon': Icons.verified_user,
      },

      {
        'value': '100+',
        'title': 'Diagnostic / Scan',
        'subtitle': 'Centers',
        'icon': null,
      },
    ];
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF176B5A),
                    shape: BoxShape.circle,
                  ),
                  child: stat['icon'] == null
                      ? Center(
                          child: Text(
                            (stat['value'] ?? '') as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                                fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            stat['icon'] as IconData,
                            color: Colors.white,
                              size: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (stat['title'] ?? '') as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                            fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        (stat['subtitle'] ?? '') as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                            fontSize: 12,
                          color: Color(0xFF6B7280),
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
    );
  }
} 

class OfferBannerCarousel extends StatefulWidget {
  const OfferBannerCarousel({super.key});

  @override
  State<OfferBannerCarousel> createState() => _OfferBannerCarouselState();
}

class _OfferBannerCarouselState extends State<OfferBannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  List<Map<String, dynamic>> banners = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getBanners();
      
      if (result['success'] && mounted) {
        setState(() {
          banners = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          // Load fallback banners if API fails
          _loadFallbackBanners();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Load fallback banners on error
        _loadFallbackBanners();
      }
    }
  }

  void _loadFallbackBanners() {
    setState(() {
      banners = [
        {
          'image_url': 'https://via.placeholder.com/400x120.png?text=Offer+1',
      'title': 'Get 20% OFF on your first test!',
          'description': 'Use code FIRST20 at checkout.',
    },
    {
          'image_url': 'https://via.placeholder.com/400x120.png?text=Offer+2',
      'title': 'Free Home Collection',
          'description': 'On all health checkups above ₹999.',
    },
    {
          'image_url': 'https://via.placeholder.com/400x120.png?text=Offer+3',
      'title': 'Refer & Earn',
          'description': 'Invite friends and earn rewards.',
    },
  ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                )
              : banners.isEmpty
                  ? const Center(
                      child: Text(
                        'No banners available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : PageView.builder(
            controller: _controller,
                      itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
                        final banner = banners[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: index == banners.length - 1 ? 0 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                                  banner['image_url']?.toString() ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                        ),
                      ),
                                // Text overlay removed - only image is shown
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (!isLoading && banners.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
            final bool isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
} 

class _TestPackagesCarousel extends StatefulWidget {
  final Set<String> cartItems;
  final Future<void> Function(String) onAddToCart;

  const _TestPackagesCarousel({
    required this.cartItems,
    required this.onAddToCart,
  });

  @override
  State<_TestPackagesCarousel> createState() => _TestPackagesCarouselState();
}

class _TestPackagesCarouselState extends State<_TestPackagesCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  List<Map<String, dynamic>> packages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopPackages();
  }

  Future<void> _loadTopPackages() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getTopPackages();
      
      if (result['success'] && mounted) {
        setState(() {
          packages = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          // Load fallback data if API fails
          _loadFallbackPackages();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Load fallback data on error
        _loadFallbackPackages();
      }
    }
  }

  void _loadFallbackPackages() {
    setState(() {
      packages = [
        {
          'packagename': 'Fever Profile - I',
          'discountvalue': '19',
          'baseprice': '1110.00',
          'tests': [
            {'test': {'testname': 'CBC'}},
            {'test': {'testname': 'ESR'}},
            {'test': {'testname': 'Malaria'}},
            {'test': {'testname': 'Dengue'}},
            {'test': {'testname': 'Typhoid'}},
      ],
    },
    {
          'packagename': 'Diabetes Check',
          'discountvalue': '15',
          'baseprice': '900.00',
          'tests': [
            {'test': {'testname': 'Fasting Glucose'}},
            {'test': {'testname': 'PP Glucose'}},
            {'test': {'testname': 'HbA1c'}},
            {'test': {'testname': 'Urine Sugar'}},
            {'test': {'testname': 'Cholesterol'}},
            {'test': {'testname': 'Triglycerides'}},
            {'test': {'testname': 'Creatinine'}},
      ],
    },
    {
          'packagename': 'Full Body Checkup',
          'discountvalue': '25',
          'baseprice': '2500.00',
          'tests': [
            {'test': {'testname': 'CBC'}},
            {'test': {'testname': 'LFT'}},
            {'test': {'testname': 'KFT'}},
            {'test': {'testname': 'Lipid Profile'}},
            {'test': {'testname': 'Thyroid'}},
            {'test': {'testname': 'Blood Sugar'}},
            {'test': {'testname': 'Urine Routine'}},
            {'test': {'testname': 'Calcium'}},
            {'test': {'testname': 'Vitamin D'}},
            {'test': {'testname': 'Vitamin B12'}},
            {'test': {'testname': 'Iron'}},
            {'test': {'testname': 'Electrolytes'}},
            {'test': {'testname': 'ESR'}},
            {'test': {'testname': 'CRP'}},
            {'test': {'testname': 'Uric Acid'}},
            {'test': {'testname': 'PSA'}},
            {'test': {'testname': 'HIV'}},
            {'test': {'testname': 'Hepatitis B'}},
            {'test': {'testname': 'Hepatitis C'}},
            {'test': {'testname': 'Blood Group'}},
      ],
    },
  ];
    });
  }

  // Helper method to extract test names from package data
  List<String> _extractTestNames(Map<String, dynamic> package) {
    final tests = package['tests'] as List<dynamic>? ?? [];
    return tests.map((test) {
      final testData = test['test'] as Map<String, dynamic>? ?? {};
      return testData['testname']?.toString() ?? 'Test';
    }).toList();
  }

  // Helper method to calculate discounted price
  String _calculateDiscountedPrice(String basePrice, String discountValue) {
    try {
      final base = double.parse(basePrice);
      final discount = double.parse(discountValue);
      final discounted = base - (base * discount / 100);
      return '₹${discounted.toStringAsFixed(0)}';
    } catch (e) {
      return '₹$basePrice';
    }
  }

  // Helper method to format discount value (remove floating points)
  String _formatDiscount(String discountValue) {
    if (discountValue == null || discountValue.isEmpty) return '0';
    String formatted = discountValue;
    if (formatted.contains('.')) {
      // Remove .00, .0, or any decimal part if it's a whole number
      double? number = double.tryParse(formatted);
      if (number != null && number == number.toInt()) {
        formatted = number.toInt().toString();
      }
    }
    return formatted;
  }

  // Helper method to format price value (remove floating points)
  String _formatPrice(String priceValue) {
    if (priceValue == null || priceValue.isEmpty) return '0';
    String formatted = priceValue;
    if (formatted.contains('.')) {
      // Remove .00, .0, or any decimal part if it's a whole number
      double? number = double.tryParse(formatted);
      if (number != null && number == number.toInt()) {
        formatted = number.toInt().toString();
      }
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : packages.isEmpty
                  ? const Center(
                      child: Text(
                        'No packages available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : PageView.builder(
            controller: _controller,
            itemCount: packages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final pkg = packages[index];
                        final testNames = _extractTestNames(pkg);
                        final discountedPrice = _calculateDiscountedPrice(
                          pkg['baseprice']?.toString() ?? '0',
                          pkg['discountvalue']?.toString() ?? pkg['discount_value']?.toString() ?? '0',
                        );
                        
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: index == packages.length - 1 ? 0 : 4),
                child: PackageCard(
                            title: pkg['packagename'] ?? 'Package',
                            discount: _formatDiscount(pkg['discountvalue']?.toString() ?? pkg['discount_value']?.toString() ?? '0'),
                            price: discountedPrice,
                            originalPrice: '₹${_formatPrice(pkg['baseprice']?.toString() ?? '0')}',
                            parameters: testNames.length,
                            tests: testNames.length,
                            reportTime: '24 hours', // Default value
                  isInCart: widget.cartItems.contains(pkg['packagename'] ?? 'Package'),
                  onAdd: () async {
                    final packageName = pkg['packagename'] ?? 'Package';
                    
                    try {
                      // Calculate discounted price
                      final basePrice = double.tryParse(pkg['baseprice']?.toString() ?? '0') ?? 0.0;
                      final discountValue = double.tryParse(pkg['discountvalue']?.toString() ?? '0') ?? 0.0;
                      final discountedPrice = basePrice - (basePrice * discountValue / 100);
                      final discountType = pkg['discounttype']?.toString() ?? pkg['discount_type']?.toString() ?? 'percentage';
                      
                      print('🛒 Adding package to cart with original price: $basePrice, discounted price: $discountedPrice');
                      print('🛒 Discount value: $discountValue, discount type: $discountType');
                      
                      // Call the actual API to add to cart
                      final apiService = ApiService();
                      final result = await apiService.addToCart(
                        price: basePrice,
                        testName: packageName,
                        labTestId: 'dummy_test_id', // Required but not used when packageId is provided
                        packageId: pkg['id']?.toString() ?? 'default_package_id',
                        preferredDate: null,
                        preferredTime: null,
                        discountedPrice: discountedPrice,
                        discountedValue: discountValue,
                        discountType: discountType,
                      );
                      
                      if (result['success']) {
                        // Call parent's onAddToCart to update UI
                        await widget.onAddToCart(packageName);
                        
                        if (mounted) {
                          SnackBarHelper.showSuccess(
                            context,
                            '$packageName added to cart!',
                            duration: const Duration(seconds: 2),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Failed to add to cart'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding to cart: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  width: MediaQuery.of(context).size.width * 0.8,
                            testNames: testNames,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (!isLoading && packages.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(packages.length, (index) {
            final bool isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
} 

class _TopDiagnosticsCarousel extends StatefulWidget {
  final Set<String> cartItems;
  final Future<void> Function(String) onAddToCart;

  const _TopDiagnosticsCarousel({
    required this.cartItems,
    required this.onAddToCart,
  });

  @override
  State<_TopDiagnosticsCarousel> createState() => _TopDiagnosticsCarouselState();
}

class _TopDiagnosticsCarouselState extends State<_TopDiagnosticsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  List<Map<String, dynamic>> diagnostics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopTests();
  }

  Future<void> _loadTopTests() async {
    try {
      final apiService = ApiService();
      final result = await apiService.getTopTests();
      
      if (result['success'] && mounted) {
        setState(() {
          diagnostics = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
          isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          // Load fallback data if API fails
          _loadFallbackTests();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Load fallback data on error
        _loadFallbackTests();
      }
    }
  }

  void _loadFallbackTests() {
    setState(() {
      diagnostics = [
        {
          'testname': 'Leptospirosis - IgG',
          'shortname': 'Leptospirosis - IgG',
          'collectioninstruction': '6 hours',
        },
        {
          'testname': 'Dengue NS1 Antigen',
          'shortname': 'Dengue Antigen',
          'collectioninstruction': '8 hours',
        },
        {
          'testname': 'Malaria Antigen',
          'shortname': 'Malaria Rapid Test',
          'collectioninstruction': '5 hours',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : diagnostics.isEmpty
                  ? const Center(
                      child: Text(
                        'No tests available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : PageView.builder(
            controller: _controller,
            itemCount: diagnostics.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final diag = diagnostics[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: index == diagnostics.length - 1 ? 0 : 8),
                child: _DiagnosticsTestCard(
                            title: diag['testname'] ?? diag['shortname'] ?? 'Test',
                            reportTime: diag['collectioninstruction'] ?? '6 hours',
                            alsoKnownAs: diag['shortname'] ?? diag['testname'] ?? 'Test',
                            isInCart: widget.cartItems.contains(diag['testname'] ?? diag['shortname'] ?? 'Test'),
                  onAdd: () async {
                    final testName = diag['testname'] ?? diag['shortname'] ?? 'Test';
                    
                    try {
                      // Call the actual API to add to cart
                      final apiService = ApiService();
                      final result = await apiService.addToCart(
                        price: 0.0, // Default price, will be updated by server
                        testName: testName,
                        labTestId: diag['id']?.toString() ?? 'default_test_id',
                        preferredDate: null,
                        preferredTime: null,
                      );
                      
                      if (result['success']) {
                        // Call parent's onAddToCart to update UI
                        await widget.onAddToCart(testName);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$testName added to cart!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Failed to add to cart'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding to cart: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  onViewDetails: () {},
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (!isLoading && diagnostics.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(diagnostics.length, (index) {
            final bool isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DiagnosticsTestCard extends StatefulWidget {
  final String title;
  final String reportTime;
  final String alsoKnownAs;
  final Future<void> Function() onAdd;
  final VoidCallback onViewDetails;
  final bool isInCart;

  const _DiagnosticsTestCard({
    required this.title,
    required this.reportTime,
    required this.alsoKnownAs,
    required this.onAdd,
    required this.onViewDetails,
    required this.isInCart,
  });

  @override
  State<_DiagnosticsTestCard> createState() => _DiagnosticsTestCardState();
}

class _DiagnosticsTestCardState extends State<_DiagnosticsTestCard> {
  bool _isLoading = false;
  bool _isAdded = false;

  @override
  void initState() {
    super.initState();
    _isAdded = widget.isInCart;
  }

  @override
  void didUpdateWidget(_DiagnosticsTestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isInCart != widget.isInCart) {
      setState(() {
        _isAdded = widget.isInCart;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the added state whenever dependencies change (like cart updates)
    if (_isAdded != widget.isInCart) {
      setState(() {
        _isAdded = widget.isInCart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      await widget.onAdd();
                      // Don't set _isAdded here as it will be updated by didUpdateWidget
                      setState(() {
                        _isLoading = false;
                      });
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFF2ECC71),
                    ),
                    backgroundColor: _isAdded ? const Color(0xFF2ECC71) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    minimumSize: const Size(0, 36),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                          ),
                        )
                      : Text(
                          _isAdded ? 'Added' : '+ Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _isAdded ? Colors.white : const Color(0xFF2ECC71),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF6C7A89), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Reports Within',
                  style: TextStyle(
                    color: Color(0xFF6C7A89),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.reportTime,
                  style: const TextStyle(
                    color: Color(0xFFFF8C32),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 18, thickness: 1.1, color: Color(0xFFE0E0E0)),
            Row(
              children: [
                const Text(
                  'Also Known as',
                  style: TextStyle(
                    color: Color(0xFFFF8C32),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.alsoKnownAs,
                  style: const TextStyle(
                    color: Color(0xFF6C7A89),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
} 

class _WomenCareGrid extends StatelessWidget {
  const _WomenCareGrid({super.key});

  void _navigateToTestsWithCategory(BuildContext context, String category, {int? tabIndex}) {
    // Find the LandingPageState to access the tab controller
    final landingPageState = context.findAncestorStateOfType<_LandingPageState>();
    if (landingPageState != null) {
      // Navigate to Tests tab (index 1) and pass the category and tab index
      landingPageState._navigateToTestsTab(category, tabIndex: tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.female,
        'label': 'PCOD Screening',
        'category': 'pcod_screening',
      },
      {
        'icon': Icons.bloodtype,
        'label': 'Blood Studies',
        'category': 'blood_studies',
      },
      {
        'icon': Icons.pregnant_woman,
        'label': 'Pregnancy',
        'category': 'pregnancy_tests',
      },
      {
        'icon': Icons.medication_outlined,
        'label': 'Iron Studies',
        'category': 'iron_studies',
      },
      {
        'icon': Icons.abc,
        'label': 'Vitamin',
        'category': 'vitamin_tests',
      },
      {
        'icon': Icons.bug_report,
        'label': 'Viral organs / Diseases',
        'category': 'viral_organs_diseases',
      },
    ];
    // Use outlined icons and left-align content
    final outlinedIcons = [
      Icons.female_outlined,
      Icons.bloodtype_outlined,
      Icons.pregnant_woman_outlined,
      Icons.medication_outlined,
      Icons.abc_outlined,
      Icons.bug_report_outlined,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.7,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => _navigateToTestsWithCategory(
              context, 
              item['category'] as String,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(outlinedIcons[index], color: Colors.black, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 

class _HelpBookingCard extends StatelessWidget {
  const _HelpBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Need help with booking your test?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Our experts are here to help you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call, color: Color(0xFF1976D2), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Call Now',
                    style: TextStyle(
                      color: Color(0xFF222B45),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cancel Appointment Dialog
class _CancelAppointmentDialog extends StatefulWidget {
  @override
  _CancelAppointmentDialogState createState() => _CancelAppointmentDialogState();
}

class _CancelAppointmentDialogState extends State<_CancelAppointmentDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _refundToWallet = true;
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Cancel Appointment',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please provide a reason for cancellation:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., Emergency came up, need to reschedule',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _refundToWallet,
                onChanged: (value) {
                  setState(() {
                    _refundToWallet = value ?? true;
                  });
                },
                activeColor: AppColors.primaryBlue,
              ),
              const Expanded(
                child: Text(
                  'Refund amount to wallet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a cancellation reason'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            Navigator.of(context).pop({
              'confirmed': true,
              'reason': reason,
              'refundToWallet': _refundToWallet,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Cancel'),
        ),
      ],
    );
  }
} 