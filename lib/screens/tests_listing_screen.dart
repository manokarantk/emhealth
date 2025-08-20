import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'dart:async';

class TestsListingScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Function(String) onAddToCart;
  final Function(String) onRemoveFromCart;

  const TestsListingScreen({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
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
                const IconButton(
                  icon: Icon(Icons.shopping_cart_outlined, color: AppColors.primaryBlue),
                  onPressed: null,
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
      body: Column(
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
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
} 