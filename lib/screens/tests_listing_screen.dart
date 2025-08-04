import 'package:flutter/material.dart';
import '../constants/colors.dart';

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
    {
      'name': 'Cardiac Markers',
      'description': 'Heart health indicators',
      'price': 1299.0,
      'discount': '35% OFF',
      'requiresFasting': true,
    },
    {
      'name': 'Cancer Screening',
      'description': 'Early cancer detection',
      'price': 2499.0,
      'discount': '30% OFF',
      'requiresFasting': true,
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
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Tests List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableTests.length,
              itemBuilder: (context, index) {
                final test = _availableTests[index];
                final isInCart = widget.cartItems.contains(test['name']);
                
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
                          test['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Also known as: ${test['description']}',
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
                            if (test['requiresFasting'] == true) _buildTag('Fasting Required'),
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
                                        widget.onRemoveFromCart(test['name']);
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
                                        widget.onAddToCart(test['name']);
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