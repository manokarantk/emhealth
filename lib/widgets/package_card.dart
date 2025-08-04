import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PackageCard extends StatelessWidget {
  final String title;
  final String discount;
  final String price;
  final int parameters;
  final int tests;
  final String reportTime;
  final VoidCallback onAdd;
  final double? width;
  final List<String> testNames;

  const PackageCard({
    super.key,
    required this.title,
    required this.discount,
    required this.price,
    required this.parameters,
    required this.tests,
    required this.reportTime,
    required this.onAdd,
    required this.testNames,
    this.width,
  });

  void _showTestNamesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Package info at the top
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C32),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            '$discount Off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$parameters parameters',
                          style: const TextStyle(
                            color: Color(0xFF2ECC71),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.science, color: Color(0xFF6C7A89), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '$tests tests',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.receipt_long, color: Color(0xFF6C7A89), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          reportTime,
                          style: const TextStyle(
                            color: Color(0xFFFF8C32),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Test Names',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      controller: scrollController,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: testNames.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      itemBuilder: (context, idx) => ListTile(
                        leading: const Icon(Icons.check, color: Color(0xFF2ECC71), size: 20),
                        title: Text(
                          testNames[idx],
                          style: const TextStyle(fontSize: 16),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      child: Container(
        width: width ?? 340,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Add button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: onAdd,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2ECC71)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF2ECC71),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Discount and Price on the same line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C32),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '$discount Off',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, thickness: 1.1, color: Color(0xFFE0E0E0)),
            // Parameters included (now above the columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 15),
                const SizedBox(width: 4),
                Text(
                  '$parameters parameters included',
                  style: const TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tests included and Report time as two columns, each with two lines
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.science, color: Color(0xFF6C7A89), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            'Tests Included',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$tests',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showTestNamesSheet(context),
                            child: const Icon(Icons.info_outline, color: Color(0xFF6C7A89), size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.2,
                  height: 28,
                  color: const Color(0xFFE0E0E0),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, color: Color(0xFF6C7A89), size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Reports Within',
                            style: TextStyle(
                              color: Color(0xFF6C7A89),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        reportTime,
                        style: const TextStyle(
                          color: Color(0xFFFF8C32),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
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

// New PackageTestCard for tests tab with price and discount display
class PackageTestCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final bool isInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final Function(String packageName, String packageId, double price, {String? organizationId, String? organizationName})? onAddToCartApi;
  final Function(String itemId)? onRemoveFromCartApi;
  final bool isLoading;

  const PackageTestCard({
    super.key,
    required this.package,
    required this.isInCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.onAddToCartApi,
    this.onRemoveFromCartApi,
    this.isLoading = false,
  });

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    String priceStr = price.toString();
    if (priceStr.contains('.')) {
      // Remove .00 if it's exactly .00
      if (priceStr.endsWith('.00')) {
        priceStr = priceStr.substring(0, priceStr.length - 3);
      }
    }
    return priceStr;
  }

  bool _shouldShowStrikeThrough() {
    // Check if discount exists and is not zero
    if (package['discountvalue'] == null || package['discountvalue'] == '0.00') {
      return false;
    }
    
    // Get base and discounted prices
    final basePrice = package['baseprice']?.toString() ?? '0';
    final discountedPrice = package['discountedprice']?.toString() ?? basePrice;
    
    // Compare prices (remove .00 for comparison)
    final formattedBasePrice = _formatPrice(basePrice);
    final formattedDiscountedPrice = _formatPrice(discountedPrice);
    
    // Only show strike-through if prices are different
    return formattedBasePrice != formattedDiscountedPrice;
  }

  void _showLabSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _OrganizationSelectionSheet(
          package: package,
          onAddToCart: onAddToCart,
          onAddToCartApi: onAddToCartApi,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        package['packagename'] ?? package['name'] ?? 'Package',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (package['organization'] != null && package['organization']['name'].toString().isNotEmpty)
                        Text(
                          package['organization']['name'].toString(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const Text(
                          'EmHealth',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  (package['rating'] ?? package['organization']?['rating'] ?? '0').toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600], size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '${package['distance'] ?? package['organization']?['distance'] ?? '0'} km',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_shouldShowStrikeThrough())
                                    Text(
                                      '₹${_formatPrice(package['baseprice'] ?? '0')}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  if (_shouldShowStrikeThrough())
                                    const SizedBox(width: 6),
                                  Text(
                                    '₹${_formatPrice(package['discountedprice'] ?? package['baseprice'] ?? '0')}',
                                    style: const TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Tags row
            if (package['tests'] != null && (package['tests'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(
                        '${package['tests']?.length ?? 0} Tests',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Text(
                        'Package',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (package['discountvalue'] != null && package['discountvalue'] != '0.00')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          '${package['discountvalue']}% OFF',
                          style: const TextStyle(
                            color: Color(0xFFFF8C32),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            
            // Info row: Tests count, Reports time, and Action button
            Row(
              children: [
                // Tests count
                Row(
                  children: [
                    Icon(Icons.science, color: Colors.grey[600], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${package['tests']?.length ?? 0} Tests',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Reports time
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.grey[600], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Reports in 24 Hrs',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Action button
                isInCart
                    ? ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (onRemoveFromCartApi != null) {
                            final itemId = package['id'] ?? '';
                            await onRemoveFromCartApi!(itemId);
                          }
                          onRemoveFromCart();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 28),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Added',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                    : OutlinedButton(
                        onPressed: isLoading ? null : () async {
                          // Check if organization is null
                          if (package['organization'] == null) {
                            _showLabSelectionBottomSheet(context);
                            return;
                          }
                          
                          if (onAddToCartApi != null) {
                            final packageName = package['packagename'] ?? package['name'] ?? 'Package';
                            final packageId = package['id'] ?? '';
                            final price = double.tryParse(package['baseprice']?.toString() ?? '0') ?? 0.0;
                            
                            await onAddToCartApi!(packageName, packageId, price);
                          }
                          onAddToCart();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2ECC71)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 28),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
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
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 12,
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
  }
}

class _OrganizationSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> package;
  final VoidCallback onAddToCart;
  final Function(String packageName, String packageId, double price, {String? organizationId, String? organizationName})? onAddToCartApi;

  const _OrganizationSelectionSheet({
    required this.package,
    required this.onAddToCart,
    this.onAddToCartApi,
  });

  @override
  State<_OrganizationSelectionSheet> createState() => _OrganizationSelectionSheetState();
}

class _OrganizationSelectionSheetState extends State<_OrganizationSelectionSheet> {
  List<Map<String, dynamic>> organizations = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, bool> loadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final packageId = widget.package['id'] ?? '';
      final apiService = ApiService();
      final result = await apiService.getPackageOrganizations(
        packageId: packageId,
        packageIds: [packageId],
        testIds: [],
      );

      if (result['success'] == true) {
        final data = result['data'];
        final orgsList = data['organizations'] as List<dynamic>;
        
        setState(() {
          organizations = orgsList.map((org) => org as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load organizations';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error occurred';
        isLoading = false;
      });
    }
  }

  Future<void> _addToCartWithOrganization(Map<String, dynamic> organization) async {
    final orgId = organization['id'] ?? '';
    
    setState(() {
      loadingStates[orgId] = true;
    });

    try {
      if (widget.onAddToCartApi != null) {
        final packageName = widget.package['packagename'] ?? widget.package['name'] ?? 'Package';
        final packageId = widget.package['id'] ?? '';
        final organizationId = organization['id'] ?? '';
        final organizationName = organization['name'] ?? '';
        final price = double.tryParse(organization['pricing']?['final_price']?.toString() ?? '0') ?? 0.0;
        
        // Call API with package ID, organization ID, and organization name
        await widget.onAddToCartApi!(packageName, packageId, price, organizationId: organizationId, organizationName: organizationName);
      }
      widget.onAddToCart();
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        loadingStates[orgId] = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    String priceStr = price.toString();
    if (priceStr.contains('.')) {
      if (priceStr.endsWith('.00')) {
        priceStr = priceStr.substring(0, priceStr.length - 3);
      }
    }
    return priceStr;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Lab for ${widget.package['packagename'] ?? widget.package['name'] ?? 'Package'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            

            
            // Content
            Expanded(
              child: isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading organizations...'),
                        ],
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadOrganizations,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : organizations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'No organizations found for this package',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              itemCount: organizations.length,
                              itemBuilder: (context, index) {
                                final organization = organizations[index];
                                final orgId = organization['id'] ?? '';
                                final isAdding = loadingStates[orgId] ?? false;
                                
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
                                        // Organization name and price
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                organization['name'] ?? 'Unknown Lab',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '₹${_formatPrice(organization['pricing']?['final_price'] ?? '0')}',
                                              style: const TextStyle(
                                                color: Color(0xFF2ECC71),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 8),
                                        
                                        // Address and distance
                                        if (organization['addressline1'] != null)
                                          Row(
                                            children: [
                                              Icon(Icons.location_on, color: Colors.grey[600], size: 14),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  organization['addressline1'],
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        
                                        if (organization['distance'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(Icons.directions_walk, color: Colors.grey[600], size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  organization['distance'],
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Add button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: isAdding ? null : () => _addToCartWithOrganization(organization),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2ECC71),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: isAdding
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Text('Add to Cart'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }
}