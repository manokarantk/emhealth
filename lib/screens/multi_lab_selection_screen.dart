import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class MultiLabSelectionScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final Map<String, dynamic> cartData;

  const MultiLabSelectionScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.cartData,
  });

  @override
  State<MultiLabSelectionScreen> createState() => _MultiLabSelectionScreenState();
}

class _MultiLabSelectionScreenState extends State<MultiLabSelectionScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> labs = [];
  Map<String, List<Map<String, dynamic>>> labServices = {};
  Map<String, bool> labHomeCollection = {};
  Map<String, DateTime?> labSelectedDates = {};
  Map<String, String?> labSelectedTimes = {};
  Map<String, Map<String, dynamic>> labTimeslots = {};
  Map<String, bool> labLoadingTimeslots = {};
  
  // Validation state
  Map<String, bool> labDateErrors = {};
  Map<String, bool> labTimeErrors = {};
  
  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  Future<void> _loadLabs() async {
    try {
      print('🔍 Loading SELECTED labs for multi-lab scheduling...');
      
      // Extract SELECTED labs from cart data instead of getting all available labs
      final Map<String, Map<String, dynamic>> selectedLabs = {};
      
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        print('Cart items for multi-lab: $items');
        
        for (final item in items) {
          // Extract SELECTED lab information
          String? labId = item['lab_id']?.toString();
          String? labName = item['lab_name']?.toString();
          String? testName = item['test_name']?.toString();
          String? price = item['price']?.toString();
          String? discountedAmount = item['discounted_amount']?.toString();
          String? discountValue = item['discount_value']?.toString();
          
          print('Multi-lab item - Lab ID: $labId, Lab Name: $labName, Test: $testName');
          
          if (labId != null && labId.isNotEmpty && labName != null && labName.isNotEmpty) {
            // Initialize lab if not already added
            if (!selectedLabs.containsKey(labId)) {
              selectedLabs[labId] = {
                'id': labId,
                'name': labName,
                'services': <Map<String, dynamic>>[],
              };
              print('✅ Added selected lab for multi-lab: $labName (ID: $labId)');
            }
            
            // Add service/test to this lab
            final service = {
              'id': item['id']?.toString() ?? '',
              'testname': testName ?? '',
              'name': testName ?? '',
              'baseprice': price ?? '0',
              'discountedprice': discountedAmount ?? price ?? '0',
              'discountvalue': discountValue ?? '0',
              'lab_test_id': item['lab_test_id']?.toString() ?? '',
              'lab_package_id': item['lab_package_id']?.toString() ?? '',
            };
            
            selectedLabs[labId]!['services'].add(service);
            print('✅ Added service to multi-lab $labName: $testName');
          }
        }
      }
      
      // Convert selected labs to list format
      final labsData = selectedLabs.values.toList();
      print('📊 Multi-lab Summary: ${labsData.length} selected labs');
      
      if (labsData.isNotEmpty && mounted) {
        
        // Group services by lab
        Map<String, List<Map<String, dynamic>>> groupedServices = {};
        
        for (final lab in labsData) {
          final labId = lab['id']?.toString() ?? '';
          
          // Initialize lab settings
          labHomeCollection[labId] = true;
          // Don't set default date and time - let user select
          labSelectedDates[labId] = null;
          labSelectedTimes[labId] = null;
          labLoadingTimeslots[labId] = false;
          
          // Get services for this lab
          final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
          groupedServices[labId] = services;
          
          // Don't load timeslots until user selects a date
        }
        
        setState(() {
          labs = labsData;
          labServices = groupedServices;
          isLoading = false;
        });
        
        print('✅ Loaded ${labs.length} labs with services');
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading labs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadTimeslotsForLab(String labId, DateTime date) async {
    try {
      setState(() {
        labLoadingTimeslots[labId] = true;
      });
      
      final apiService = ApiService();
      final result = await apiService.getOrganizationTimeslots(
        orgId: labId,
        date: date.toIso8601String().split('T')[0], // Convert to YYYY-MM-DD format
      );
      
      if (result['success'] && mounted) {
        setState(() {
          labTimeslots[labId] = result['data'] ?? {};
          labLoadingTimeslots[labId] = false;
        });
      } else {
        setState(() {
          labLoadingTimeslots[labId] = false;
        });
      }
    } catch (e) {
      print('❌ Error loading timeslots for lab $labId: $e');
      setState(() {
        labLoadingTimeslots[labId] = false;
      });
    }
  }

  void _onDateChanged(String labId, DateTime date) {
    setState(() {
      labSelectedDates[labId] = date;
      // Clear time selection when date changes
      labSelectedTimes[labId] = null;
      // Clear validation errors
      labDateErrors[labId] = false;
      labTimeErrors[labId] = false;
    });
    _loadTimeslotsForLab(labId, date);
  }

  void _onTimeChanged(String labId, String time) {
    setState(() {
      labSelectedTimes[labId] = time;
      // Clear validation error
      labTimeErrors[labId] = false;
    });
  }

  void _showCustomDatePicker(String labId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: CalendarDatePicker(
                    initialDate: labSelectedDates[labId] ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    onDateChanged: (DateTime date) {
                      _onDateChanged(labId, date);
                      Navigator.of(context).pop(); // Auto-dismiss
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onHomeCollectionChanged(String labId, bool value) {
    setState(() {
      labHomeCollection[labId] = value;
    });
  }

  void _proceedToCheckout() {
    // Reset validation errors
    setState(() {
      for (final lab in labs) {
        final labId = lab['id']?.toString() ?? '';
        labDateErrors[labId] = false;
        labTimeErrors[labId] = false;
      }
    });
    
    // Validate that all labs have date and time selected
    bool hasError = false;
    
    for (final lab in labs) {
      final labId = lab['id']?.toString() ?? '';
      if (labSelectedDates[labId] == null) {
        setState(() {
          labDateErrors[labId] = true;
        });
        hasError = true;
      }
      
      if (labSelectedTimes[labId] == null) {
        setState(() {
          labTimeErrors[labId] = true;
        });
        hasError = true;
      }
    }
    
    if (hasError) {
      return;
    }
    
    // Navigate to checkout with multi-lab data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: widget.cartItems,
          testPrices: widget.testPrices,
          testDiscounts: widget.testDiscounts,
          selectedLab: '', // Will be handled differently for multi-lab
          labOriginalPrice: 0.0, // Will be calculated per lab
          labDiscountedPrice: 0.0, // Will be calculated per lab
          labDiscount: '', // Will be calculated per lab
          organizationId: '', // Will be handled differently for multi-lab
          cartData: widget.cartData,
          multiLabData: {
            'labs': labs,
            'labServices': labServices,
            'labHomeCollection': labHomeCollection,
            'labSelectedDates': labSelectedDates,
            'labSelectedTimes': labSelectedTimes,
            'labTimeslots': labTimeslots,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: const Text(
          'Select Labs & Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : Column(
              children: [
                // Header with cart summary
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
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
                        'Your Selection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.cartItems.length} items selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ₹${_calculateTotalPrice().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Labs list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: labs.length,
                    itemBuilder: (context, index) {
                      final lab = labs[index];
                      final labId = lab['id']?.toString() ?? '';
                      final labName = lab['name']?.toString() ?? 'Unknown Lab';
                      final services = labServices[labId] ?? [];
                      
                      return _buildLabCard(lab, labId, labName, services);
                    },
                  ),
                ),
                
                // Proceed button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
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
              ],
            ),
    );
  }

  Widget _buildLabCard(Map<String, dynamic> lab, String labId, String labName, List<Map<String, dynamic>> services) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Lab header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '${services.length} service(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Services list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final serviceName = service['name']?.toString() ?? 'Unknown Service';
              final servicePrice = service['price']?.toString() ?? '0';
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '₹$servicePrice',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Lab options
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Home collection toggle
                Row(
                  children: [
                    Icon(
                      Icons.home,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Home Collection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: labHomeCollection[labId] ?? true,
                      onChanged: (value) => _onHomeCollectionChanged(labId, value),
                      activeColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Date selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showCustomDatePicker(labId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: labDateErrors[labId] == true 
                                ? Colors.red.withOpacity(0.1)
                                : AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: labDateErrors[labId] == true 
                                ? Border.all(color: Colors.red, width: 1)
                                : null,
                            ),
                            child: Text(
                              labSelectedDates[labId] != null 
                                ? '${labSelectedDates[labId]!.day}/${labSelectedDates[labId]!.month}/${labSelectedDates[labId]!.year}'
                                : 'Select Date',
                              style: TextStyle(
                                fontSize: 14,
                                color: labSelectedDates[labId] != null ? AppColors.primaryBlue : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (labDateErrors[labId] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 32),
                        child: Text(
                          'Please select a date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Time selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (labLoadingTimeslots[labId] == true)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: labTimeErrors[labId] == true 
                                ? Colors.red.withOpacity(0.1)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: labTimeErrors[labId] == true 
                                ? Border.all(color: Colors.red, width: 1)
                                : null,
                            ),
                            child: DropdownButton<String>(
                              value: labSelectedTimes[labId],
                              hint: Text(
                                'Select Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: labTimeErrors[labId] == true ? Colors.red[600] : Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  _onTimeChanged(labId, value);
                                }
                              },
                              items: [
                                '10:00 AM - 12:00 PM',
                                '12:00 PM - 2:00 PM',
                                '2:00 PM - 4:00 PM',
                                '4:00 PM - 6:00 PM',
                              ].map((time) => DropdownMenuItem(
                                value: time,
                                child: Text(time),
                              )).toList(),
                              underline: Container(),
                              style: TextStyle(
                                fontSize: 14,
                                color: labTimeErrors[labId] == true ? Colors.red[600] : AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (labTimeErrors[labId] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 32),
                        child: Text(
                          'Please select a time',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalPrice() {
    double total = 0.0;
    for (final lab in labs) {
      final labId = lab['id']?.toString() ?? '';
      final services = labServices[labId] ?? [];
      
      for (final service in services) {
        final price = double.tryParse(service['price']?.toString() ?? '0') ?? 0.0;
        total += price;
      }
    }
    return total;
  }
} 