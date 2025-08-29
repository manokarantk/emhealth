import 'package:flutter/material.dart';

class TestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final bool isInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final Function(String testName, String labTestId, double originalPrice, {double? discountedPrice, double? discountedValue, String? discountType})? onAddToCartApi;
  final Function(String itemId)? onRemoveFromCartApi;
  final bool isLoading;

  const TestCard({
    super.key,
    required this.test,
    required this.isInCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.onAddToCartApi,
    this.onRemoveFromCartApi,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
              test['testname'] ?? test['name'] ?? 'Test',
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
                if (test['ishomecollection'] == true || test['homeCollection'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Home Collection',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (test['collectioninstruction'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      test['collectioninstruction'],
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF6C7A89), size: 18),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports within',
                          style: TextStyle(
                            color: Color(0xFF6C7A89),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '6 Hrs',
                          style: TextStyle(
                            color: Color(0xFFFF8C32),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isInCart
                    ? ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          if (onRemoveFromCartApi != null) {
                            final itemId = test['id'] ?? '';
                            await onRemoveFromCartApi!(itemId);
                          }
                          onRemoveFromCart();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
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
                            : const Text(
                                'Added',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                                           : OutlinedButton(
                           onPressed: isLoading ? null : () async {
                             if (onAddToCartApi != null) {
                               final testName = test['testname'] ?? test['name'] ?? 'Test';
                               final labTestId = test['id'] ?? '';
                               final originalPrice = double.tryParse(test['baseprice']?.toString() ?? '0') ?? 0.0;
                               final discountedPrice = double.tryParse(test['discountedprice']?.toString() ?? test['baseprice']?.toString() ?? '0') ?? 0.0;
                               final discountedValue = double.tryParse(test['discountvalue']?.toString() ?? '0') ?? 0.0;
                               final discountType = test['discounttype']?.toString() ?? test['discount_type']?.toString() ?? 'percentage';
                               
                               await onAddToCartApi!(testName, labTestId, originalPrice, discountedPrice: discountedPrice, discountedValue: discountedValue, discountType: discountType);
                             }
                             onAddToCart();
                           },
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
  }
} 