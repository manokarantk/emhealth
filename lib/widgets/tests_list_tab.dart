import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'test_card.dart';

class TestsListTab extends StatefulWidget {
  final Set<String> cartItems;
  final Future<void> Function(String) onAddToCart;
  final Future<void> Function(String) onRemoveFromCart;
  final VoidCallback? onTabActivated;
  final List<Map<String, dynamic>>? searchResults;
  final bool isSearching;
  final String? searchQuery;
  final String? category;

  const TestsListTab({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.onTabActivated,
    this.searchResults,
    this.isSearching = false,
    this.searchQuery,
    this.category,
  });

  @override
  State<TestsListTab> createState() => _TestsListTabState();
}

class _TestsListTabState extends State<TestsListTab> {
  List<Map<String, dynamic>> tests = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  int limit = 10;
  Map<String, bool> loadingStates = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    print('🔄 Scroll controller initialized and listener added');
    _loadDiagnosisTests(isRefresh: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure scroll controller is properly attached after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        print('🔄 Scroll controller has clients after build');
        print('🔄 Max scroll extent: ${_scrollController.position.maxScrollExtent}');
        print('🔄 Tests count: ${tests.length}');
      }
    });
  }

  @override
  void didUpdateWidget(TestsListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when widget is updated (tab switch)
    print('🔄 TestsListTab widget updated - resetting pagination');
    _resetPagination(); // Fire and forget for tab switches
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    try {
      // Check if scroll controller is attached
      if (!_scrollController.hasClients) {
        print('🔄 Scroll controller has no clients');
        return;
      }
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      const delta = 50.0; // Even smaller threshold
      
      // Log every scroll event for debugging
      print('🔄 Scroll Event:');
      print('🔄 Current scroll: $currentScroll');
      print('🔄 Max scroll: $maxScroll');
      print('🔄 Has more data: $hasMoreData');
      print('🔄 Is loading more: $isLoadingMore');
      print('🔄 Is loading: $isLoading');
      print('🔄 Current page: $currentPage');
      print('🔄 Threshold check: ${currentScroll >= maxScroll - delta}');
      print('🔄 Scroll percentage: ${maxScroll > 0 ? (currentScroll / maxScroll * 100).toStringAsFixed(1) : '0'}%');
      print('🔄 Is scrollable: ${maxScroll > 0}');
      
      // Check if we're near the bottom (within 50 pixels or at 95% of scroll)
      if (maxScroll > 0 && (currentScroll >= maxScroll - delta || currentScroll / maxScroll >= 0.95)) {
        print('🔄 Near bottom, checking if should load more...');
        
        // Additional check: ensure we're not already loading and have more data
        if (hasMoreData && !isLoadingMore && !isLoading && currentPage > 0) {
          print('🔄 Loading more data for page: $currentPage');
          _loadDiagnosisTests(isRefresh: false);
        } else {
          print('🔄 Not loading more:');
          print('🔄 - hasMoreData: $hasMoreData');
          print('🔄 - isLoadingMore: $isLoadingMore');
          print('🔄 - isLoading: $isLoading');
          print('🔄 - currentPage: $currentPage');
        }
      }
    } catch (e) {
      print('❌ Error in scroll listener: $e');
    }
  }

  Future<void> _loadDiagnosisTests({bool isRefresh = false}) async {
    print('🔄 _loadDiagnosisTests called with isRefresh: $isRefresh');
    print('🔄 Current page: $currentPage');
    print('🔄 Has more data: $hasMoreData');
    
    if (isRefresh) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMoreData = true;
      });
      print('🔄 Refreshing - reset page to 1');
    } else {
      setState(() {
        isLoadingMore = true;
      });
      print('🔄 Loading more - setting isLoadingMore to true');
    }

    try {
      print('🔄 Making API call with page: $currentPage, limit: $limit');
      print('🔄 Search query from widget: "${widget.searchQuery}"');
      final apiService = ApiService();
      final result = await apiService.getDiagnosisTests(
        search: widget.searchQuery,
        page: currentPage,
        limit: limit,
        category: widget.category, // Pass category filter
      );
      print('🔄 API call completed, result success: ${result['success']}');
      
      if (result['success'] && mounted) {
        final newTests = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
        final pagination = result['data']['pagination'] ?? {};
        final totalPages = pagination['total_pages'] ?? 1;
        final currentPageFromApi = pagination['current_page'] ?? currentPage;
        final totalItems = pagination['total'] ?? newTests.length;
        final perPage = pagination['per_page'] ?? limit;
        
        print('🔄 API Response Debug:');
        print('🔄 New tests count: ${newTests.length}');
        print('🔄 Pagination data: $pagination');
        print('🔄 Total pages: $totalPages');
        print('🔄 Current page from API: $currentPageFromApi');
        print('🔄 Total items: $totalItems');
        print('🔄 Per page: $perPage');
        print('🔄 Current page before increment: $currentPage');
        print('🔄 Is refresh: $isRefresh');
        
        setState(() {
          if (isRefresh) {
            tests = newTests;
            currentPage = 1;
            print('🔄 Refreshed tests list, new count: ${tests.length}');
          } else {
            tests.addAll(newTests);
            print('🔄 Added more tests, total count: ${tests.length}');
          }
          
          // Update current page based on API response
          currentPage = currentPageFromApi + 1;
          
          // Calculate if there's more data
          final hasMorePages = currentPage <= totalPages;
          final hasMoreItems = tests.length < totalItems;
          
          // Additional check: if we got new data, assume there might be more
          final gotNewData = newTests.isNotEmpty;
          
          hasMoreData = hasMorePages || hasMoreItems || (gotNewData && newTests.length >= limit);
          
          print('🔄 Pagination calculation:');
          print('🔄 Has more pages: $hasMorePages');
          print('🔄 Has more items: $hasMoreItems');
          print('🔄 Got new data: $gotNewData');
          print('🔄 New data length: ${newTests.length}');
          print('🔄 Limit: $limit');
          
          isLoading = false;
          isLoadingMore = false;
          
          print('🔄 Updated state:');
          print('🔄 Current page after increment: $currentPage');
          print('🔄 Has more pages: $hasMorePages');
          print('🔄 Has more items: $hasMoreItems');
          print('🔄 Has more data: $hasMoreData');
          print('🔄 Total tests: ${tests.length}');
          print('🔄 Total items from API: $totalItems');
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            isLoadingMore = false;
          });
          // Load fallback data if API fails
          if (isRefresh) {
            _loadFallbackTests();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        // Load fallback data on error
        if (isRefresh) {
          _loadFallbackTests();
        }
      }
    }
  }

  Future<void> _addToCartApi(String testName, String labTestId, double originalPrice, {double? discountedPrice, double? discountedValue, String? discountType}) async {
    // Set loading state for this specific test using test ID
    setState(() {
      loadingStates[labTestId] = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.addToCart(
        price: originalPrice,
        testName: testName,
        labTestId: labTestId,
        discountedPrice: discountedPrice,
        discountedValue: discountedValue,
        discountType: discountType,
      );
      
      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Item added to cart successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add item to cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Clear loading state using test ID
      if (mounted) {
        setState(() {
          loadingStates[labTestId] = false;
        });
      }
    }
  }

  Future<void> _removeFromCartApi(String itemId) async {
    // Use itemId directly for loading state since it's the test ID
    setState(() {
      loadingStates[itemId] = true;
    });
    
    try {
      final apiService = ApiService();
      final result = await apiService.removeFromCart(itemId);
      
      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Item removed from cart successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to remove item from cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Clear loading state using itemId (test ID)
      if (mounted) {
        setState(() {
          loadingStates[itemId] = false;
        });
      }
    }
  }

  void _loadFallbackTests() {
    print('🔄 Loading fallback tests data');
    setState(() {
      tests = [
        {
          'testname': 'Complete Blood Count (CBC)',
          'shortname': 'CBC',
          'baseprice': '599.00',
          'discountvalue': '40.00',
          'ishomecollection': true,
          'collectioninstruction': 'Random',
        },
        {
          'testname': 'Diabetes Screening',
          'shortname': 'Blood Sugar Test',
          'baseprice': '299.00',
          'discountvalue': '50.00',
          'ishomecollection': true,
          'collectioninstruction': 'Fasting Required',
        },
        {
          'testname': 'Liver Function Test (LFT)',
          'shortname': 'LFT',
          'baseprice': '799.00',
          'discountvalue': '38.00',
          'ishomecollection': true,
          'collectioninstruction': 'Fasting Required',
        },
        {
          'testname': 'Kidney Function Test (KFT)',
          'shortname': 'KFT',
          'baseprice': '699.00',
          'discountvalue': '42.00',
          'ishomecollection': true,
          'collectioninstruction': 'Fasting Required',
        },
        {
          'testname': 'Thyroid Profile (T3, T4, TSH)',
          'shortname': 'Thyroid Test',
          'baseprice': '899.00',
          'discountvalue': '40.00',
          'ishomecollection': true,
          'collectioninstruction': 'Random',
        },
        {
          'testname': 'Lipid Profile',
          'shortname': 'Cholesterol Test',
          'baseprice': '499.00',
          'discountvalue': '44.00',
          'ishomecollection': true,
          'collectioninstruction': 'Fasting Required',
        },
        {
          'testname': 'Vitamin D Test',
          'shortname': 'Vitamin D',
          'baseprice': '399.00',
          'discountvalue': '43.00',
          'ishomecollection': true,
          'collectioninstruction': 'Random',
        },
        {
          'testname': 'HbA1c Test',
          'shortname': 'HbA1c',
          'baseprice': '349.00',
          'discountvalue': '46.00',
          'ishomecollection': true,
          'collectioninstruction': 'Random',
        },
      ];
      // Set hasMoreData to false for fallback data since it's static
      hasMoreData = false;
      currentPage = 1;
    });
    print('🔄 Fallback tests loaded, hasMoreData set to false');
  }

  Future<void> _resetPagination() async {
    print('🔄 Resetting pagination for tests tab');
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      isLoading = false;
      isLoadingMore = false;
      tests.clear();
    });
    // Reload data from the beginning
    await _loadDiagnosisTests(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // Handle search results
    if (widget.searchResults != null) {
      if (widget.isSearching) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Searching...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }

      if (widget.searchResults!.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No tests found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }

      // Display search results
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.searchResults!.length,
        itemBuilder: (context, index) {
          final test = widget.searchResults![index];
          final testId = test['id']?.toString() ?? '';
          final testName = test['testname'] ?? test['name'] ?? 'Test';
          final isInCart = widget.cartItems.contains(testName);
          
          return TestCard(
            test: test,
            isInCart: isInCart,
            onAddToCart: () async => await widget.onAddToCart(testName),
            onRemoveFromCart: () async => await widget.onRemoveFromCart(testName),
            onAddToCartApi: _addToCartApi,
            onRemoveFromCartApi: _removeFromCartApi,
            isLoading: loadingStates[testId] ?? false,
          );
        },
      );
    }

    // Handle normal loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (tests.isEmpty) {
      return const Center(
        child: Text(
          'No tests available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _resetPagination(),
          color: AppColors.primaryBlue,
          backgroundColor: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: tests.length + (hasMoreData ? 1 : 0),
            // Add physics to ensure scrolling works
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              // Show loading indicator at the bottom when loading more
              if (index == tests.length && hasMoreData) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              }
              
              final test = tests[index];
              final testId = test['id']?.toString() ?? '';
              final testName = test['testname'] ?? test['name'] ?? 'Test';
              final isInCart = widget.cartItems.contains(testName);
              
              return TestCard(
                test: test,
                isInCart: isInCart,
                onAddToCart: () async => await widget.onAddToCart(testName),
                onRemoveFromCart: () async => await widget.onRemoveFromCart(testName),
                onAddToCartApi: _addToCartApi,
                onRemoveFromCartApi: _removeFromCartApi,
                isLoading: loadingStates[testId] ?? false,
              );
            },
          ),
        ),

      ],
    );
  }
} 