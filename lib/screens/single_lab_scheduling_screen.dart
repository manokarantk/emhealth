import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class SingleLabSchedulingScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final Map<String, dynamic> cartData;
  final Map<String, dynamic> selectedLab;
  final double labOriginalPrice;
  final double labDiscountedPrice;
  final String labDiscount;
  final VoidCallback? onCartChanged; // Callback for cart changes

  const SingleLabSchedulingScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.cartData,
    required this.selectedLab,
    required this.labOriginalPrice,
    required this.labDiscountedPrice,
    required this.labDiscount,
    this.onCartChanged, // Optional callback for cart changes
  });

  @override
  State<SingleLabSchedulingScreen> createState() => _SingleLabSchedulingScreenState();
}

class _SingleLabSchedulingScreenState extends State<SingleLabSchedulingScreen> {
  bool isHomeCollection = true;
  DateTime? selectedDate;
  String? selectedTime;
  Map<String, dynamic>? timeslotData;
  bool isLoadingTimeslots = false;
  
  // Validation state
  bool showDateError = false;
  bool showTimeError = false;
  
  @override
  void initState() {
    super.initState();
    // Ensure no default date/time is set
    selectedDate = null;
    selectedTime = null;
    timeslotData = null;
    print('🔧 SingleLabSchedulingScreen initialized - selectedDate: $selectedDate, selectedTime: $selectedTime');
    // Don't load timeslots until user selects a date
  }

  Future<void> _loadTimeslots(DateTime date) async {
    try {
      setState(() {
        isLoadingTimeslots = true;
        // Clear selected time when loading new timeslots
        selectedTime = null;
        showTimeError = false;
      });
      
      final labId = widget.selectedLab['id']?.toString() ?? '';
      final apiService = ApiService();
      final result = await apiService.getOrganizationTimeslots(
        orgId: labId,
        date: date.toIso8601String().split('T')[0], // Convert to YYYY-MM-DD format
      );
      
      if (result['success'] && mounted) {
        setState(() {
          timeslotData = result['data'] ?? {};
          isLoadingTimeslots = false;
        });
      } else {
        setState(() {
          timeslotData = null;
          isLoadingTimeslots = false;
        });
      }
    } catch (e) {
      print('❌ Error loading timeslots: $e');
      setState(() {
        timeslotData = null;
        isLoadingTimeslots = false;
      });
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
      // Clear time selection when date changes
      selectedTime = null;
      // Clear validation errors
      showDateError = false;
      showTimeError = false;
    });
    _loadTimeslots(date);
  }

  void _onTimeChanged(String time) {
    setState(() {
      selectedTime = time;
      // Clear validation error
      showTimeError = false;
    });
  }

  List<DropdownMenuItem<String>> _getTimeslotItems() {
    if (selectedDate == null || timeslotData == null) {
      return [];
    }

    // Extract timeslots from API response
    final timeslots = timeslotData!['timeslots'] as List<dynamic>? ?? [];
    
    if (timeslots.isEmpty) {
      return [];
    }

    return timeslots.map((timeslot) {
      final startTime = timeslot['start_time']?.toString() ?? '';
      final endTime = timeslot['end_time']?.toString() ?? '';
      final isAvailable = timeslot['is_available'] == true;
      
      // Format time display
      String timeDisplay = '';
      if (startTime.isNotEmpty && endTime.isNotEmpty) {
        timeDisplay = '$startTime - $endTime';
      } else if (startTime.isNotEmpty) {
        timeDisplay = startTime;
      }
      
      return DropdownMenuItem<String>(
        value: timeDisplay,
        child: Text(
          timeDisplay,
          style: TextStyle(
            color: isAvailable ? Colors.black : Colors.grey,
          ),
        ),
      );
    }).toList();
  }

  void _showCustomDatePicker() {
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
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    onDateChanged: (DateTime date) {
                      _onDateChanged(date);
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

  void _onHomeCollectionChanged(bool value) {
    setState(() {
      isHomeCollection = value;
    });
  }

  void _proceedToCheckout() {
    // Reset validation errors
    setState(() {
      showDateError = false;
      showTimeError = false;
    });
    
    // Validate that date and time are selected
    bool hasError = false;
    
    if (selectedDate == null) {
      setState(() {
        showDateError = true;
      });
      hasError = true;
    }
    
    if (selectedTime == null) {
      setState(() {
        showTimeError = true;
      });
      hasError = true;
    }
    
    if (hasError) {
      return;
    }
    
    // Navigate to checkout with scheduling data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: widget.cartItems,
          testPrices: widget.testPrices,
          testDiscounts: widget.testDiscounts,
          selectedLab: widget.selectedLab['name']?.toString() ?? 'Unknown Lab',
          labOriginalPrice: widget.labOriginalPrice,
          labDiscountedPrice: widget.labDiscountedPrice,
          labDiscount: widget.labDiscount,
          organizationId: widget.selectedLab['id']?.toString() ?? '',
          cartData: widget.cartData,
          onCartChanged: () {
            // Notify parent that cart has been modified
            if (widget.onCartChanged != null) {
              print('🔄 Cart changed from single lab checkout - triggering parent cart refresh');
              widget.onCartChanged!();
            }
          },
          schedulingData: {
            'isHomeCollection': isHomeCollection,
            'selectedDate': selectedDate,
            'selectedTime': selectedTime,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labName = widget.selectedLab['name']?.toString() ?? 'Unknown Lab';
    final services = List<Map<String, dynamic>>.from(widget.selectedLab['services'] ?? []);
    
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: const Text(
          'Schedule Your Appointment',
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
      body: Column(
        children: [
          // Header with lab and service summary
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
                Row(
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
                              fontSize: 18,
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
                const SizedBox(height: 16),
                // Services list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final serviceName = service['name']?.toString() ?? 'Service';
                    final servicePrice = service['price']?.toString() ?? '0';
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
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
                const SizedBox(height: 16),
                Text(
                  'Total: ₹${widget.labDiscountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          
          // Scheduling options
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isHomeCollection,
                          onChanged: _onHomeCollectionChanged,
                          activeColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
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
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showCustomDatePicker(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: showDateError 
                                    ? Colors.red.withOpacity(0.1)
                                    : AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: showDateError 
                                    ? Border.all(color: Colors.red, width: 1)
                                    : null,
                                ),
                                child: Text(
                                  selectedDate != null 
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'Select Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedDate != null ? AppColors.primaryBlue : Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showDateError)
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
                    
                    const SizedBox(height: 20),
                    
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
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (isLoadingTimeslots)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: showTimeError 
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: showTimeError 
                                    ? Border.all(color: Colors.red, width: 1)
                                    : null,
                                ),
                                child: DropdownButton<String>(
                                  value: selectedTime,
                                  hint: Text(
                                    selectedDate == null 
                                      ? 'Select Date First'
                                      : timeslotData == null 
                                        ? 'No Timeslots Available'
                                        : 'Select Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: showTimeError ? Colors.red[600] : Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onChanged: selectedDate != null && timeslotData != null ? (value) {
                                    if (value != null) {
                                      _onTimeChanged(value);
                                    }
                                  } : null,
                                  items: _getTimeslotItems(),
                                  underline: Container(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: showTimeError ? Colors.red[600] : AppColors.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (showTimeError)
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
} 