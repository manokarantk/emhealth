import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package_card.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

class PackagesListTab extends StatefulWidget {
  final Set<String> cartItems;
  final Future<void> Function(String) onAddToCart;
  final Future<void> Function(String) onRemoveFromCart;

  const PackagesListTab({
    super.key,
    required this.cartItems,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<PackagesListTab> createState() => _PackagesListTabState();
}

class _PackagesListTabState extends State<PackagesListTab> {
  List<Map<String, dynamic>> packages = [];
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
    print('🔄 Packages scroll controller initialized and listener added');
    
    // Don't load packages immediately - wait for tab activation
    print('🔄 PackagesListTab initialized - waiting for tab activation');
  }



  void _loadPackagesIfNeeded() {
    if (packages.isEmpty && !isLoading) {
      print('🔄 Packages: Loading packages for first time');
      _loadTopPackages(isRefresh: true);
    }
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
        print('🔄 Packages scroll controller has no clients');
        return;
      }
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      const delta = 50.0;
      
      // Log every scroll event for debugging
      print('🔄 Packages Scroll Event:');
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
        print('🔄 Near bottom, checking if should load more packages...');
        
        // Additional check: ensure we're not already loading and have more data
        if (hasMoreData && !isLoadingMore && !isLoading && currentPage > 0) {
          print('🔄 Loading more packages for page: $currentPage');
          _loadTopPackages(isRefresh: false);
        } else {
          print('🔄 Not loading more packages:');
          print('🔄 - hasMoreData: $hasMoreData');
          print('🔄 - isLoadingMore: $isLoadingMore');
          print('🔄 - isLoading: $isLoading');
          print('🔄 - currentPage: $currentPage');
        }
      }
    } catch (e) {
      print('❌ Error in packages scroll listener: $e');
    }
  }

  Future<bool> _testNetworkConnection() async {
    try {
      print('🔄 Packages: Testing network connection...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      
      print('🔄 Packages: Network test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🔄 Packages: Network test failed: $e');
      return false;
    }
  }

  Future<void> _loadTopPackages({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMoreData = true;
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    try {
      print('🔄 Packages: Making API call with page: $currentPage, limit: $limit');
      final apiService = ApiService();
      final result = await apiService.getPackages(
        page: currentPage,
        limit: limit,
        sortBy: 'baseprice',
        sortOrder: 'desc',
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('🔄 Packages: API call timeout');
          return {
            'success': false,
            'message': 'Request timeout',
            'error': 'TIMEOUT',
          };
        },
      );
      print('🔄 Packages: API call completed, result success: ${result['success']}');
      print('🔄 Packages: API response: $result');
      
      if (result['success'] && mounted) {
        final newPackages = List<Map<String, dynamic>>.from(result['data']['data'] ?? []);
        final pagination = result['data']['pagination'] ?? {};
        final totalPages = pagination['total_pages'] ?? 1;
        final currentPageFromApi = pagination['current_page'] ?? currentPage;
        final totalItems = pagination['total'] ?? newPackages.length;
        final perPage = pagination['per_page'] ?? limit;
        
        print('🔄 Packages API Response Debug:');
        print('🔄 New packages count: ${newPackages.length}');
        print('🔄 Pagination data: $pagination');
        print('🔄 Total pages: $totalPages');
        print('🔄 Current page from API: $currentPageFromApi');
        print('🔄 Total items: $totalItems');
        print('🔄 Per page: $perPage');
        print('🔄 Current page before increment: $currentPage');
        print('🔄 Is refresh: $isRefresh');
        
        setState(() {
          if (isRefresh) {
            packages = newPackages;
            currentPage = 1;
            print('🔄 Refreshed packages list, new count: ${packages.length}');
          } else {
            packages.addAll(newPackages);
            print('🔄 Added more packages, total count: ${packages.length}');
          }
          
          // Update current page based on API response
          currentPage = currentPageFromApi + 1;
          
          // Calculate if there's more data
          final hasMorePages = currentPage <= totalPages;
          final hasMoreItems = packages.length < totalItems;
          
          // Additional check: if we got new data, assume there might be more
          final gotNewData = newPackages.isNotEmpty;
          
          hasMoreData = hasMorePages || hasMoreItems || (gotNewData && newPackages.length >= limit);
          
          print('🔄 Packages pagination calculation:');
          print('🔄 Has more pages: $hasMorePages');
          print('🔄 Has more items: $hasMoreItems');
          print('🔄 Got new data: $gotNewData');
          print('🔄 New data length: ${newPackages.length}');
          print('🔄 Limit: $limit');
          
          isLoading = false;
          isLoadingMore = false;
          
          print('🔄 Updated packages state:');
          print('🔄 Current page after increment: $currentPage');
          print('🔄 Has more pages: $hasMorePages');
          print('🔄 Has more items: $hasMoreItems');
          print('🔄 Has more data: $hasMoreData');
          print('🔄 Total packages: ${packages.length}');
          print('🔄 Total items from API: $totalItems');
        });
      } else {
        print('🔄 Packages: API call failed - ${result['message']}');
        if (mounted) {
          setState(() {
            isLoading = false;
            isLoadingMore = false;
          });
          // Load fallback data if API fails
          if (isRefresh) {
            _loadFallbackPackages();
          }
        }
      }
    } catch (e) {
      print('🔄 Packages: Exception occurred - $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
        // Load fallback data on error
        if (isRefresh) {
          _loadFallbackPackages();
        }
      }
    }
  }

  Future<void> _addToCartApi(String packageName, String packageId, double price, {String? organizationId, String? organizationName}) async {
    // Set loading state for this specific package
    setState(() {
      loadingStates[packageName] = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.addToCart(
        price: price,
        testName: packageName,
        labTestId: packageId,
        packageId: packageId,
        organizationId: organizationId,
        organizationName: organizationName,
      );
      
      if (result['success']) {
        // Success - no toast needed
      } else {
        // Show error message only
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
      // Clear loading state
      if (mounted) {
        setState(() {
          loadingStates[packageName] = false;
        });
      }
    }
  }

  Future<void> _removeFromCartApi(String itemId) async {
    // Find the package name for this item ID to set loading state
    String? packageName;
    for (final package in packages) {
      if (package['id'] == itemId) {
        packageName = package['packagename'] ?? package['name'];
        break;
      }
    }
    
    // Set loading state for this specific package
    if (packageName != null) {
      setState(() {
        loadingStates[packageName!] = true;
      });
    }
    
    try {
      final apiService = ApiService();
      final result = await apiService.removeFromCart(itemId);
      
      if (result['success']) {
        // Success - no toast needed
      } else {
        // Show error message only
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
      // Clear loading state
      if (mounted && packageName != null) {
        setState(() {
          loadingStates[packageName!] = false;
        });
      }
    }
  }

  void _loadFallbackPackages() {
    print('🔄 Loading fallback packages data');
    setState(() {
      packages = [
        {
          'packagename': 'Fever Profile - I',
          'description': 'Complete fever diagnosis package',
          'baseprice': '1110.00',
          'discountvalue': '19.01',
          'discountedprice': '899.00',
          'tests': [
            {'test': {'testname': 'Widal'}},
            {'test': {'testname': 'Urine Routine Analysis'}},
          ],
        },
        {
          'packagename': 'Diabetes Check',
          'description': 'Comprehensive diabetes screening',
          'baseprice': '900.00',
          'discountvalue': '15.00',
          'discountedprice': '765.00',
          'tests': [
            {'test': {'testname': 'Blood Sugar Fasting'}},
            {'test': {'testname': 'HbA1c'}},
          ],
        },
        {
          'packagename': 'Full Body Checkup',
          'description': 'Complete health assessment',
          'baseprice': '2500.00',
          'discountvalue': '25.00',
          'discountedprice': '1875.00',
          'tests': [
            {'test': {'testname': 'Complete Blood Count'}},
            {'test': {'testname': 'Liver Function Test'}},
            {'test': {'testname': 'Kidney Function Test'}},
          ],
        },
      ];
      // Set hasMoreData to false for fallback data since it's static
      hasMoreData = false;
      currentPage = 1;
    });
    print('🔄 Fallback packages loaded, hasMoreData set to false');
  }

  Future<void> _resetPagination() async {
    print('🔄 Resetting pagination for packages tab');
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      isLoading = false;
      isLoadingMore = false;
      packages.clear();
    });
    // Reload data from the beginning
    await _loadTopPackages(isRefresh: true);
  }

  @override
  void didUpdateWidget(PackagesListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Load packages when this tab becomes active and reset pagination
    print('🔄 PackagesListTab widget updated - loading packages and resetting pagination');
    _loadPackagesIfNeeded();
    _resetPagination(); // Fire and forget for tab switches
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading packages...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (packages.isEmpty) {
      return const Center(
        child: Text(
          'No packages available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _resetPagination(),
      color: const Color(0xFF2ECC71),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: packages.length + (hasMoreData ? 1 : 0),
        // Add physics to ensure scrolling works
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom when loading more
          if (index == packages.length && hasMoreData) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                ),
              ),
            );
          }
          
          final package = packages[index];
          final packageName = package['packagename'] ?? package['name'] ?? 'Package';
          final isInCart = widget.cartItems.contains(packageName);
          
          return PackageTestCard(
            package: package,
            isInCart: isInCart,
            onAddToCart: () async => await widget.onAddToCart(packageName),
            onRemoveFromCart: () async => await widget.onRemoveFromCart(packageName),
            onAddToCartApi: _addToCartApi,
            onRemoveFromCartApi: _removeFromCartApi,
            isLoading: loadingStates[packageName] ?? false,
          );
        },
      ),
    );
  }
} 