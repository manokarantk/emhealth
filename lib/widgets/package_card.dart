import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../constants/colors.dart';

class PackageCard extends StatefulWidget {
  final String title;
  final String discount;
  final String price;
  final String? originalPrice; // Add original price parameter
  final int parameters;
  final int tests;
  final String reportTime;
  final Future<void> Function() onAdd;
  final double? width;
  final List<String> testNames;
  final bool isInCart;



  const PackageCard({
    super.key,
    required this.title,
    required this.discount,
    required this.price,
    this.originalPrice,
    required this.parameters,
    required this.tests,
    required this.reportTime,
    required this.onAdd,
    required this.testNames,
    this.width,
    required this.isInCart,
  });

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  bool _isLoading = false;
  bool _isAdded = false;

  @override
  void initState() {
    super.initState();
    _isAdded = widget.isInCart;
  }

  @override
  void didUpdateWidget(PackageCard oldWidget) {
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

  // Helper method to format discount value (remove floating points and handle 0%)
  String _formatDiscount(String discountValue) {
    if (discountValue == null || discountValue.isEmpty) return '0';
    String formatted = discountValue;
    if (formatted.contains('.')) {
      // Remove .00, .0, or any decimal part if it's a whole number
      double? number = double.tryParse(formatted);
      if (number != null) {
        if (number == number.toInt()) {
          formatted = number.toInt().toString();
        } else {
          // Remove decimal points for non-whole numbers too
          formatted = number.toInt().toString();
        }
      }
    }
    return formatted;
  }

  // Helper method to check if discount should be shown
  bool _shouldShowDiscount(String discountValue) {
    if (discountValue == null || discountValue.isEmpty) return false;
    double? number = double.tryParse(discountValue);
    return number != null && number > 0;
  }

  // Helper method to get package image based on package type
  ImageProvider _getPackageImage() {
    final title = widget.title.toLowerCase();
    
    // Use reliable, working image URLs from different sources
    if (title.contains('diabetes') || title.contains('glucose') || title.contains('sugar')) {
      return const NetworkImage('https://picsum.photos/400/300?random=1');
    } else if (title.contains('fever') || title.contains('malaria') || title.contains('dengue') || title.contains('cancer')) {
      return const NetworkImage('https://picsum.photos/400/300?random=10');
    } else if (title.contains('full body') || title.contains('complete') || title.contains('comprehensive')) {
      return const NetworkImage('https://picsum.photos/400/300?random=');
    } else if (title.contains('thyroid') || title.contains('hormone')) {
      return const NetworkImage('https://picsum.photos/400/300?random=4');
    } else if (title.contains('heart') || title.contains('cardiac') || title.contains('lipid')) {
      return const NetworkImage('https://picsum.photos/400/300?random=5');
    } else if (title.contains('kidney') || title.contains('renal') || title.contains('creatinine')) {
      return const NetworkImage('https://picsum.photos/400/300?random=6');
    } else if (title.contains('liver') || title.contains('hepatic')) {
      return const NetworkImage('https://picsum.photos/400/300?random=7');
    } else if (title.contains('vitamin') || title.contains('nutrition')) {
      return const NetworkImage('https://picsum.photos/400/300?random=8');
    } else if (title.contains('women') || title.contains('pregnancy') || title.contains('prenatal')) {
      return const NetworkImage('https://picsum.photos/400/300?random=9');
    } else if (title.contains('men') || title.contains('male')) {
      return const NetworkImage('https://picsum.photos/400/300?random=10');
    } else {
      // Default medical image for any package that doesn't match above conditions
      return const NetworkImage('https://picsum.photos/400/300?random=11');
    }
  }

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
                            widget.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_shouldShowDiscount(widget.discount))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C32),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              '${_formatDiscount(widget.discount)}% Off',
                                                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          widget.price,
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
                          '${widget.parameters} parameters',
                                                      style: const TextStyle(
                              color: Color(0xFF2ECC71),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.science, color: Color(0xFF6C7A89), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.tests} tests',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.receipt_long, color: Color(0xFF6C7A89), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          widget.reportTime,
                          style: const TextStyle(
                            color: Color(0xFFFF8C32),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                      itemCount: widget.testNames.length,
                      separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      itemBuilder: (context, idx) => ListTile(
                        leading: const Icon(Icons.check, color: Color(0xFF2ECC71), size: 20),
                        title: Text(
                          widget.testNames[idx],
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
    return Container(
      width: widget.width ?? 340,
      height: 280, // Fixed height for full card
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Full height background image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _getPackageImage(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Gradient overlay for better text readability
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            
            // Top left - Package name
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Top right - Offer tag
            if (_shouldShowDiscount(widget.discount))
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_formatDiscount(widget.discount)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            
            // Bottom section - Left side (Rating and delivery details)
            Positioned(
              bottom: 8,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and reviews
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '4.5',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1K+ Reviews',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Delivery details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 14,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Home Collection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 14,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.reportTime,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bottom section - Right side (Price and Add to Cart button)
            Positioned(
              bottom: 8,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Starting from text
                  Text(
                    'Starting from',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Price without background
                  Text(
                    widget.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Add to cart button
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        try {
                          await widget.onAdd();
                          setState(() {
                            _isLoading = false;
                          });
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdded ? Colors.green : AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isAdded ? 'Added' : 'Add to Cart',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
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

// New PackageTestCard for tests tab with price and discount display
class PackageTestCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final bool isInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final Future<bool> Function(String packageName, String packageId, double originalPrice, {String? organizationId, String? organizationName, double? discountedPrice, double? discountedValue, String? discountType})? onAddToCartApi;
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
      // Remove all decimal points and trailing zeros
      double? number = double.tryParse(priceStr);
      if (number != null) {
        priceStr = number.toInt().toString();
      }
    }
    return priceStr;
  }

  String _formatDiscount(dynamic discount) {
    if (discount == null) return '0';
    String discountStr = discount.toString();
    if (discountStr.contains('.')) {
      // Remove .00, .0, or any decimal part if it's a whole number
      double? number = double.tryParse(discountStr);
      if (number != null) {
        if (number == number.toInt()) {
          discountStr = number.toInt().toString();
        } else {
          // Remove decimal points for non-whole numbers too
          discountStr = number.toInt().toString();
        }
      }
    }
    return discountStr;
  }

  // Helper method to check if discount should be shown
  bool _shouldShowDiscount(dynamic discountValue) {
    if (discountValue == null || discountValue.toString().isEmpty) return false;
    double? number = double.tryParse(discountValue.toString());
    return number != null && number > 0;
  }

  String _calculateDiscountedPrice() {
    final basePrice = double.tryParse(package['baseprice']?.toString() ?? '0') ?? 0.0;
    final discountValue = double.tryParse(package['discountvalue']?.toString() ?? '0') ?? 0.0;
    
    if (discountValue > 0) {
      final discountAmount = (basePrice * discountValue) / 100;
      final discountedPrice = basePrice - discountAmount;
      return _formatPrice(discountedPrice.toString());
    }
    
    return _formatPrice(basePrice.toString());
  }

  bool _shouldShowStrikeThrough() {
    // Check if discount exists and is not zero
    final discountValue = double.tryParse(package['discountvalue']?.toString() ?? '0') ?? 0.0;
    return discountValue > 0;
  }

  void _showLabSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return OrganizationSelectionSheet(
          package: package,
          onAddToCart: onAddToCart,
          onAddToCartApi: onAddToCartApi,
        );
      },
    );
  }

  void _showTestsBottomSheet(BuildContext context) {
    final tests = package['tests'] as List<dynamic>? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.science,
                    color: Color(0xFF3B5BFE),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Included Tests (${tests.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Package name
              Text(
                package['packagename'] ?? package['name'] ?? 'Package',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              
              // Tests list
              Expanded(
                child: tests.isEmpty
                    ? const Center(
                        child: Text(
                          'No tests included in this package',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tests.length,
                        itemBuilder: (context, index) {
                          final test = tests[index];
                          final testData = test['test'] ?? test;
                          final testName = testData['testname'] ?? testData['name'] ?? 'Test ${index + 1}';
                          final shortName = testData['shortname'] ?? testData['description'] ?? '';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[200]!, width: 1),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                                                 decoration: BoxDecoration(
                                   color: const Color(0xFF3B5BFE).withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: const Icon(
                                   Icons.science,
                                   color: Color(0xFF3B5BFE),
                                   size: 18,
                                 ),
                              ),
                              title: Text(
                                testName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: shortName.isNotEmpty
                                  ? Text(
                                      shortName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
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
                          fontSize: 18,
                          color: Colors.black87,
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_shouldShowStrikeThrough()) ...[
                                    Text(
                                      'Starts from ',
                                                                          style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                    ),
                                  ],
                                  Text(
                                    '₹${_calculateDiscountedPrice()}',
                                    style: const TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
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
                    GestureDetector(
                      onTap: () => _showTestsBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${package['tests']?.length ?? 0} Tests',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 10,
                            ),
                          ],
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
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_shouldShowDiscount(package['discountvalue'] ?? '0'))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          '${_formatDiscount(package['discountvalue'])}% OFF',
                          style: const TextStyle(
                            color: Color(0xFFFF8C32),
                            fontSize: 11,
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
                GestureDetector(
                  onTap: () => _showTestsBottomSheet(context),
                  child: Row(
                    children: [
                      Icon(Icons.science, color: Colors.grey[600], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${package['tests']?.length ?? 0} Tests',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 12),
                    ],
                  ),
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
                        fontSize: 11,
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
                          // Check if organization is null or lab name is emhealth
                          final organization = package['organization'];
                          final organizationName = organization?['name']?.toString().toLowerCase() ?? '';
                          
                          print('🏥 Package Organization Check:');
                          print('🏥 Organization: $organization');
                          print('🏥 Organization Name: $organizationName');
                          
                          if (organization == null || 
                              organizationName.contains('emhealth') ||
                              organizationName.isEmpty ||
                              organizationName == 'emhealth') {
                            print('🏥 Triggering lab selection - organization is null/emhealth/empty');
                            _showLabSelectionBottomSheet(context);
                            return;
                          }
                          
                          print('🏥 Using existing organization: $organizationName');
                          
                          if (onAddToCartApi != null) {
                            final packageName = package['packagename'] ?? package['name'] ?? 'Package';
                            final packageId = package['id'] ?? '';
                            final originalPrice = double.tryParse(package['baseprice']?.toString() ?? '0') ?? 0.0;
                            final discountedPrice = double.tryParse(package['discountedprice']?.toString() ?? package['baseprice']?.toString() ?? '0') ?? 0.0;
                            
                            // Get discount details
                            final discountedValue = double.tryParse(package['discountvalue']?.toString() ?? '0') ?? 0.0;
                            final discountType = package['discounttype']?.toString() ?? package['discount_type']?.toString() ?? 'percentage';
                            
                            // Pass organization details as lab_id and lab_name
                            final organizationId = package['organization']?['id']?.toString() ?? '';
                            final organizationName = package['organization']?['name']?.toString() ?? '';
                            
                            print('🛒 Adding package to cart with existing organization:');
                            print('🛒 Package: $packageName (ID: $packageId)');
                            print('🛒 Organization: $organizationName (ID: $organizationId)');
                            print('🛒 Original Price: $originalPrice, Discounted Price: $discountedPrice');
                            
                            try {
                              final success = await onAddToCartApi!(packageName, packageId, originalPrice, organizationId: organizationId, organizationName: organizationName, discountedPrice: discountedPrice, discountedValue: discountedValue, discountType: discountType);
                              // Only call onAddToCart if API call was successful
                              if (success) {
                                onAddToCart();
                              }
                            } catch (e) {
                              // If API call fails, don't update UI state
                              print('Failed to add package to cart: $e');
                            }
                          } else {
                            // If no API call needed, just update UI state
                            onAddToCart();
                          }
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

class OrganizationSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> package;
  final VoidCallback onAddToCart;
  final Future<bool> Function(String packageName, String packageId, double originalPrice, {String? organizationId, String? organizationName, double? discountedPrice, double? discountedValue, String? discountType})? onAddToCartApi;

  const OrganizationSelectionSheet({
    required this.package,
    required this.onAddToCart,
    this.onAddToCartApi,
  });

  @override
  State<OrganizationSelectionSheet> createState() => _OrganizationSelectionSheetState();
}

class _OrganizationSelectionSheetState extends State<OrganizationSelectionSheet> {
  List<Map<String, dynamic>> organizations = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  Map<String, bool> loadingStates = {};
  String? selectedOrganizationId;
  bool isAddingToCart = false;
  
  // Pagination variables
  int currentPage = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  final ScrollController scrollController = ScrollController();

  // Helper method to check if discount should be shown
  bool _shouldShowDiscount(dynamic discountValue) {
    if (discountValue == null || discountValue.toString().isEmpty) return false;
    double? number = double.tryParse(discountValue.toString());
    return number != null && number > 0;
  }

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
    
    // Add scroll listener for pagination
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData) {
        _loadMoreOrganizations();
      }
    }
  }

  Future<void> _loadOrganizations() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        currentPage = 1;
        hasMoreData = true;
      });

      // Get user's current location
      double? latitude;
      double? longitude;
      
      try {
        print('📍 Getting user location for package organizations...');
        final locationService = LocationService();
        final locationResult = await locationService.getCurrentLocation(context);
        
        if (locationResult['success'] == true) {
          final locationData = locationResult['data'];
          latitude = locationData['latitude'];
          longitude = locationData['longitude'];
          print('📍 User location obtained for package organizations - Lat: $latitude, Long: $longitude');
        } else {
          print('⚠️ Could not get user location for package organizations: ${locationResult['message']}');
          print('📍 Proceeding without location data');
        }
      } catch (e) {
        print('❌ Error getting user location for package organizations: $e');
        print('📍 Proceeding without location data');
      }

      final packageId = widget.package['id'] ?? '';
      final apiService = ApiService();
      final result = await apiService.getPackageOrganizations(
        packageId: packageId,
        packageIds: [packageId],
        testIds: [],
        latitude: latitude,
        longitude: longitude,
        page: currentPage,
        limit: pageSize,
      );

      if (result['success'] == true) {
        final data = result['data'];
        final orgsList = data['organizations'] as List<dynamic>;
        
        // Filter out EmHealth organizations
        final filteredOrgs = orgsList
            .map((org) => org as Map<String, dynamic>)
            .where((org) {
              final orgName = org['name']?.toString().toLowerCase() ?? '';
              return !orgName.contains('emhealth');
            })
            .toList();
        
        setState(() {
          organizations = filteredOrgs;
          isLoading = false;
          hasMoreData = filteredOrgs.length >= pageSize;
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

  Future<void> _loadMoreOrganizations() async {
    if (isLoadingMore || !hasMoreData) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      // Get user's current location
      double? latitude;
      double? longitude;
      
      try {
        final locationService = LocationService();
        final locationResult = await locationService.getCurrentLocation(context);
        
        if (locationResult['success'] == true) {
          final locationData = locationResult['data'];
          latitude = locationData['latitude'];
          longitude = locationData['longitude'];
        }
      } catch (e) {
        print('❌ Error getting user location for pagination: $e');
      }

      final packageId = widget.package['id'] ?? '';
      final apiService = ApiService();
      final result = await apiService.getPackageOrganizations(
        packageId: packageId,
        packageIds: [packageId],
        testIds: [],
        latitude: latitude,
        longitude: longitude,
        page: currentPage + 1,
        limit: pageSize,
      );

      if (result['success'] == true) {
        final data = result['data'];
        final orgsList = data['organizations'] as List<dynamic>;
        
        // Filter out EmHealth organizations
        final filteredOrgs = orgsList
            .map((org) => org as Map<String, dynamic>)
            .where((org) {
              final orgName = org['name']?.toString().toLowerCase() ?? '';
              return !orgName.contains('emhealth');
            })
            .toList();
        
        setState(() {
          organizations.addAll(filteredOrgs);
          currentPage++;
          hasMoreData = filteredOrgs.length >= pageSize;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
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
        final originalPrice = double.tryParse(organization['pricing']?['base_price']?.toString() ?? '0') ?? 0.0;
        final discountedPrice = double.tryParse(organization['pricing']?['final_price']?.toString() ?? '0') ?? 0.0;
        
        // Get discount details from organization pricing
        final discountedValue = double.tryParse(organization['pricing']?['discount_value']?.toString() ?? '0') ?? 0.0;
        final discountType = organization['pricing']?['discount_type']?.toString() ?? 'percentage';
        
        // Call API with package ID, organization ID, and organization name
        print('🛒 Adding package to cart with selected organization:');
        print('🛒 Package: $packageName (ID: $packageId)');
        print('🛒 Organization: $organizationName (ID: $organizationId)');
        print('🛒 Original Price: $originalPrice, Discounted Price: $discountedPrice');
        print('🛒 Discount value: $discountedValue, discount type: $discountType');
        
        await widget.onAddToCartApi!(packageName, packageId, originalPrice, organizationId: organizationId, organizationName: organizationName, discountedPrice: discountedPrice, discountedValue: discountedValue, discountType: discountType);
        
        // Only call onAddToCart for UI state update, not for API cart refresh
        widget.onAddToCart();
      } else {
        // Fallback if no API callback is provided
        widget.onAddToCart();
      }
      
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
      // Remove all decimal points and trailing zeros
      double? number = double.tryParse(priceStr);
      if (number != null) {
        priceStr = number.toInt().toString();
      }
    }
    return priceStr;
  }

  String _formatDiscount(dynamic discount) {
    if (discount == null) return '0';
    String discountStr = discount.toString();
    if (discountStr.contains('.')) {
      // Remove all decimal points and trailing zeros
      double? number = double.tryParse(discountStr);
      if (number != null) {
        discountStr = number.toInt().toString();
      }
    }
    return discountStr;
  }

  // Helper method to format distance value (converts meters to km)
  String _formatDistance(dynamic distance) {
    try {
      print('🔍 Package Card: Formatting distance: $distance (type: ${distance.runtimeType})');
      
      // Handle null or undefined values
      if (distance == null) {
        print('🔍 Package Card: Distance is null, returning "Nearby"');
        return 'Nearby';
      }
      
      double distanceInMeters;
      
      // Handle different data types with explicit type checking
      if (distance is double) {
        distanceInMeters = distance;
        print('🔍 Package Card: Distance is double: $distanceInMeters');
      } else if (distance is int) {
        distanceInMeters = distance.toDouble();
        print('🔍 Package Card: Distance is int, converted to double: $distanceInMeters');
      } else if (distance is String) {
        final parsed = double.tryParse(distance);
        if (parsed == null) {
          print('🔍 Package Card: Could not parse string distance value: "$distance", returning "Nearby"');
          return 'Nearby';
        }
        distanceInMeters = parsed;
        print('🔍 Package Card: Distance is string, parsed to double: $distanceInMeters');
      } else {
        // For any other type, try to convert safely
        try {
          final distanceString = distance.toString();
          final parsed = double.tryParse(distanceString);
          if (parsed == null) {
            print('🔍 Package Card: Could not parse distance value: "$distanceString", returning "Nearby"');
            return 'Nearby';
          }
          distanceInMeters = parsed;
          print('🔍 Package Card: Distance converted from ${distance.runtimeType} to double: $distanceInMeters');
        } catch (conversionError) {
          print('🔍 Package Card: Error converting distance to string: $conversionError, returning "Nearby"');
          return 'Nearby';
        }
      }
      
      // Validate the distance value
      if (distanceInMeters.isNaN || distanceInMeters.isInfinite || distanceInMeters < 0) {
        print('🔍 Package Card: Invalid distance value: $distanceInMeters, returning "Nearby"');
        return 'Nearby';
      }
      
      // Convert meters to kilometers
      final distanceInKm = distanceInMeters / 1000;
      print('🔍 Package Card: Distance in meters: $distanceInMeters, converted to km: $distanceInKm');
      
      String formattedDistance;
      if (distanceInKm < 1) {
        // Less than 1 km, show in meters
        final meters = distanceInMeters.round();
        formattedDistance = '${meters}m away';
      } else if (distanceInKm < 10) {
        // Less than 10 km, show with 1 decimal place
        formattedDistance = '${distanceInKm.toStringAsFixed(1)}km away';
      } else {
        // 10 km or more, show as whole number
        formattedDistance = '${distanceInKm.round()}km away';
      }
      
      print('🔍 Package Card: Formatted distance: $formattedDistance');
      return formattedDistance;
    } catch (e) {
      print('❌ Package Card: Unexpected error formatting distance: $e');
      return 'Nearby';
    }
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
                              itemCount: organizations.length + (hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the bottom
                                if (index == organizations.length) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: isLoadingMore 
                                        ? const CircularProgressIndicator()
                                        : const SizedBox.shrink(),
                                    ),
                                  );
                                }
                                
                                final organization = organizations[index];
                                final orgId = organization['id'] ?? '';
                                final isSelected = selectedOrganizationId == orgId;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF3B5BFE) : Colors.grey[200]!,
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
                                        selectedOrganizationId = orgId;
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
                                                  color: const Color(0xFF3B5BFE).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.local_hospital,
                                                  color: Color(0xFF3B5BFE),
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      organization['name'] ?? 'Lab',
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
                                                          _formatDistance(organization['distance']),
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
                                                    color: isSelected ? const Color(0xFF3B5BFE) : Colors.grey[400]!,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? Container(
                                                        margin: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Color(0xFF3B5BFE),
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
                                                        if (organization['pricing']?['base_price'] != null && 
                                                            organization['pricing']?['base_price'] != organization['pricing']?['final_price']) ...[
                                                          Text(
                                                            '₹${_formatPrice(organization['pricing']?['base_price'] ?? '0')}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey,
                                                              decoration: TextDecoration.lineThrough,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                        ],
                                                        Text(
                                                          '₹${_formatPrice(organization['pricing']?['final_price'] ?? '0')}',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF3B5BFE),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                if (_shouldShowDiscount(organization['pricing']?['discount_percentage']))
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '${_formatDiscount(organization['pricing']?['discount_percentage'] ?? '0')}% OFF',
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
                          ),
            
            // Bottom Add to Cart Button
            Container(
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
              child: ElevatedButton(
                onPressed: selectedOrganizationId != null && !isAddingToCart
                    ? () async {
                        setState(() {
                          isAddingToCart = true;
                        });
                        try {
                          final selectedOrg = organizations.firstWhere(
                            (org) => org['id'] == selectedOrganizationId,
                          );
                          await _addToCartWithOrganization(selectedOrg);
                        } finally {
                          if (mounted) {
                            setState(() {
                              isAddingToCart = false;
                            });
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedOrganizationId != null 
                      ? const Color(0xFF2ECC71) 
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isAddingToCart
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
                            'Adding to Cart...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        selectedOrganizationId != null 
                            ? 'Add to Cart' 
                            : 'Select a Lab',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}