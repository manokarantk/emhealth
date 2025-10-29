import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'dart:async';

class TestsListingScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, dynamic> cartData;
  final Function(String) onAddToCart;
  final Function(String) onRemoveFromCart;
  final VoidCallback onCartChanged;

  const TestsListingScreen({
    super.key,
    required this.cartItems,
    required this.cartData,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onCartChanged,
  });

  @override
  State<TestsListingScreen> createState() => _TestsListingScreenState();
}

class _TestsListingScreenState extends State<TestsListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();
    
    // Set a new timer for debouncing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _loadTests();
    });
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
      _isSearching = _searchQuery.isNotEmpty;
    });

    try {
      final result = await _apiService.getDiagnosisTests(

        page: 1,
        limit: 50,
        search: "251"
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearching = false;
          
          if (result['success']) {
            _tests = List<Map<String, dynamic>>.from(result['data'] ?? []);
          } else {
            _tests = [];
            // Show error message if needed
            if (result['message'] != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearching = false;
          _tests = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Add More Tests',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryBlue),
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
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside input fields
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
                _loadTests(); // Trigger API call with search query
              },
              decoration: InputDecoration(
                hintText: 'Search for tests...',
                prefixIcon: _isSearching 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadTests(); // Reload all tests when cleared
                        },
                      )
                    : null,
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
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Tests List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _tests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.medical_services_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? 'No tests found' : 'No tests available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'Try adjusting your search terms'
                                  : 'Please try again later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _tests.length,
                        itemBuilder: (context, index) {
                          final test = _tests[index];
                          final testName = test['testname'] ?? test['name'] ?? 'Test';
                          final isInCart = widget.cartItems.contains(testName);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Test Name and Description
                                  Text(
                                    testName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Also known as: ${test['shortname'] ?? test['description'] ?? 'Test description'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Tags
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _buildTag('Home Collection'),
                                      _buildTag('Same Day Report'),
                                      if (test['collectioninstruction'] != null && 
                                          test['collectioninstruction'].toString().toLowerCase().contains('fasting')) 
                                        _buildTag('Fasting Required'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Report Time and Add Button Row
                                  Row(
                                    children: [
                                      // Report Time
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Reports within',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Padding(
                                              padding: EdgeInsets.only(left: 20),
                                              child: Text(
                                                '6 Hrs',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Add/Remove Button
                                      SizedBox(
                                        height: 40,
                                        child: isInCart
                                            ? ElevatedButton.icon(
                                                onPressed: () {
                                                  widget.onRemoveFromCart(testName);
                                                },
                                                icon: const Icon(Icons.remove, size: 18),
                                                label: const Text('Remove'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: () {
                                                  widget.onAddToCart(testName);
                                                },
                                                icon: const Icon(Icons.add, size: 18),
                                                label: const Text('Add'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primaryBlue,
                                                  side: const BorderSide(color: AppColors.primaryBlue),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
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

  /// Show cart summary bottom sheet
  void _showCartSummaryBottomSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TestsListingCartSummaryBottomSheet(
        cartItems: widget.cartItems,
        cartData: widget.cartData,
        onCartChanged: widget.onCartChanged,
      ),
    );
  }
}

// Tests Listing Cart Summary Bottom Sheet Widget
class _TestsListingCartSummaryBottomSheet extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, dynamic> cartData;
  final VoidCallback onCartChanged;

  const _TestsListingCartSummaryBottomSheet({
    required this.cartItems,
    required this.cartData,
    required this.onCartChanged,
  });

  @override
  State<_TestsListingCartSummaryBottomSheet> createState() => _TestsListingCartSummaryBottomSheetState();
}

class _TestsListingCartSummaryBottomSheetState extends State<_TestsListingCartSummaryBottomSheet> {
  late Set<String> _cartItems;
  late Map<String, dynamic> _cartData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cartItems = Set<String>.from(widget.cartItems);
    _cartData = Map<String, dynamic>.from(widget.cartData);
    // Refresh cart data when bottom sheet opens to ensure latest data
    _refreshCartData();
  }

  Future<void> _refreshCartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.getCart();
      
      if (result['success'] && mounted) {
        final cartData = result['data'];
        final items = List<Map<String, dynamic>>.from(cartData['items'] ?? []);
        
        // Extract package/test names from cart items to sync local state
        final Set<String> serverCartItems = items.map((item) {
          final testName = item['test_name']?.toString();
          final packageName = item['package_name']?.toString();
          
          return testName?.isNotEmpty == true ? testName! :
                 packageName?.isNotEmpty == true ? packageName! :
                 item['id']?.toString() ?? '';
        }).where((name) => name.isNotEmpty).toSet();
        
        setState(() {
          _cartData = cartData;
          _cartItems = serverCartItems;
        });
      }
    } catch (e) {
      print('❌ CART REFRESH ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cartItems.isEmpty
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
                              'Add some tests to get started',
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
                        itemCount: _cartData['items']?.length ?? 0,
                        itemBuilder: (context, index) {
                          final cartItem = _cartData['items'][index];
                          final itemName = cartItem['test_name'] ?? cartItem['package_name'] ?? 'Item';
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
                                  if (cartItem['price'] != null && itemType == 'Package')
                                    Text(
                                      '₹${cartItem['discounted_amount'] ?? cartItem['price']}',
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
                                      // Close loading dialog
                                      Navigator.pop(context);
                                      
                                      // Refresh cart data
                                      await _refreshCartData();
                                      
                                      // Notify parent widget to refresh cart data
                                      widget.onCartChanged();
                                      
                                      // Item removed from cart - no toast message needed
                                    } else {
                                      // Close loading dialog
                                      Navigator.pop(context);
                                      
                                      // Error removing item - no toast message needed
                                    }
                                  } catch (e) {
                                    // Close loading dialog
                                    Navigator.pop(context);
                                    
                                    // Error removing item - no toast message needed
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Checkout button
          if (_cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to checkout or show checkout options - no toast message needed
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
    );
  }
} 