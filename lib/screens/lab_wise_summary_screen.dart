import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'multi_lab_checkout_screen.dart';

class LabWiseSummaryScreen extends StatefulWidget {
  final Set<String> cartItems;
  final Map<String, double> testPrices;
  final Map<String, String> testDiscounts;
  final Map<String, dynamic> cartData;
  final List<Map<String, dynamic>> labsData;
  final VoidCallback? onCartChanged; // Callback to notify parent of cart changes

  const LabWiseSummaryScreen({
    super.key,
    required this.cartItems,
    required this.testPrices,
    required this.testDiscounts,
    required this.cartData,
    required this.labsData,
    this.onCartChanged, // Optional callback
  });

  @override
  State<LabWiseSummaryScreen> createState() => _LabWiseSummaryScreenState();
}

class _LabWiseSummaryScreenState extends State<LabWiseSummaryScreen> {
  Map<String, bool> labHomeCollection = {};
  Map<String, DateTime?> labSelectedDates = {};
  Map<String, String?> labSelectedTimes = {};
  Map<String, Map<String, dynamic>> labTimeslots = {};
  Map<String, bool> labLoadingTimeslots = {};
  Map<String, List<Map<String, dynamic>>> labServices = {};
  
  // Add/Remove functionality
  final ApiService _apiService = ApiService();
  Set<String> cartItems = {};
  Set<String> removingItems = {}; // Track items being removed
  
  // Validation state
  Map<String, bool> labDateErrors = {};
  Map<String, bool> labTimeErrors = {};
  
  // Helper method to format discount value (remove decimal points)
  String _formatDiscount(dynamic discountValue) {
    if (discountValue == null) return '0';
    String formatted = discountValue.toString();
    if (formatted.contains('.')) {
      // Remove all decimal points and trailing zeros
      double? number = double.tryParse(formatted);
      if (number != null) {
        formatted = number.toInt().toString();
      }
    }
    return formatted;
  }

  // Helper method to check if discount should be shown
  bool _shouldShowDiscount(dynamic discountValue) {
    if (discountValue == null || discountValue.toString().isEmpty) return false;
    double? number = double.tryParse(discountValue.toString());
    return number != null && number > 0;
  }
  
  @override
  void initState() {
    super.initState();
    cartItems = Set.from(widget.cartItems);
    _initializeLabData();
  }

  void _initializeLabData() {
    // Initialize lab settings and group services
    print('🔍 DEBUG: Initializing lab data with ${widget.labsData.length} labs');
    for (final lab in widget.labsData) {
      final labId = lab['id']?.toString() ?? '';
      final labName = lab['name']?.toString() ?? 'Unknown Lab';
      
      print('🔍 DEBUG: Lab ID: $labId, Lab Name: $labName');
      print('🔍 DEBUG: Full lab data: $lab');
      
      // Initialize lab settings
      labHomeCollection[labId] = true;
      // Don't set default date and time - let user select
      labSelectedDates[labId] = null;
      labSelectedTimes[labId] = null;
      labLoadingTimeslots[labId] = false;
      
      // Get services for this lab
      final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
      labServices[labId] = services;
      
      // Don't load timeslots until user selects a date
    }
    
    print('✅ Initialized ${widget.labsData.length} labs with services');
  }

  Future<void> _loadTimeslotsForLab(String labId, DateTime date) async {
    try {
      setState(() {
        labLoadingTimeslots[labId] = true;
      });
      
      // Try to load from API first to get session parameters
      final apiService = ApiService();
      final result = await apiService.getOrganizationTimeslots(
        orgId: labId,
        date: date.toIso8601String().split('T')[0], // Convert to YYYY-MM-DD format
      );
      
      print('🔄 [LabSummary] API result for lab $labId: $result');
      
      // Extract session parameters from API response or use defaults
      String sessionStart = '09:00:00';
      String sessionEnd = '19:00:00';
      int slotDurationMin = 30;
      String sessionName = 'Working Hours';
      
      if (result['success'] && result['data'] != null && result['data']['timeslots'] != null) {
        final timeslots = List<Map<String, dynamic>>.from(result['data']['timeslots']);
        if (timeslots.isNotEmpty) {
          final firstSession = timeslots[0];
          sessionStart = firstSession['session_start'] ?? '09:00:00';
          sessionEnd = firstSession['session_end'] ?? '19:00:00';
          slotDurationMin = firstSession['slot_duration_min'] ?? 30;
          sessionName = firstSession['session_name'] ?? 'Working Hours';
          
          // Ensure session times have seconds if missing
          if (!sessionStart.contains(':') || sessionStart.split(':').length < 3) {
            sessionStart = sessionStart.contains(':') ? '$sessionStart:00' : '09:00:00';
          }
          if (!sessionEnd.contains(':') || sessionEnd.split(':').length < 3) {
            sessionEnd = sessionEnd.contains(':') ? '$sessionEnd:00' : '19:00:00';
          }
          
          print('🔄 [LabSummary] Extracted session parameters for lab $labId:');
          print('🔄 [LabSummary] Session Start: $sessionStart');
          print('🔄 [LabSummary] Session End: $sessionEnd');
          print('🔄 [LabSummary] Slot Duration: ${slotDurationMin}min');
        }
      }
      
      // Generate time slots based on dynamic session parameters
      final generatedSlots = _generateTimeSlots(
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
        slotDurationMin: slotDurationMin,
      );
      
      // Create timeslot data structure with generated slots
      final generatedTimeslotData = {
        'timeslots': [
          {
            'session_name': sessionName,
            'session_start': sessionStart.substring(0, 5), // Remove seconds for display
            'session_end': sessionEnd.substring(0, 5),     // Remove seconds for display
            'slot_duration_min': slotDurationMin,
            'slots': generatedSlots,
          }
        ]
      };
      
      // Merge with API data if available
      Map<String, dynamic> finalData = generatedTimeslotData;
      if (result['success'] && result['data'] != null) {
        finalData = _mergeTimeslotData(generatedTimeslotData, result['data']);
      }
      
      if (mounted) {
        setState(() {
          labTimeslots[labId] = finalData;
          labLoadingTimeslots[labId] = false;
        });
        print('✅ [LabSummary] Timeslots loaded for lab $labId');
      }
    } catch (e) {
      print('❌ [LabSummary] Error loading timeslots for lab $labId: $e');
      if (mounted) {
        // Show generated slots as fallback
        final fallbackSlots = _generateTimeSlots(
          sessionStart: '09:00:00',
          sessionEnd: '19:00:00',
          slotDurationMin: 30,
        );
        
        setState(() {
          labTimeslots[labId] = {
            'timeslots': [
              {
                'session_name': 'Working Hours',
                'session_start': '09:00',
                'session_end': '19:00',
                'slot_duration_min': 30,
                'slots': fallbackSlots,
              }
            ]
          };
          labLoadingTimeslots[labId] = false;
        });
      }
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

  // Check if time selection is enabled for a lab
  bool _isTimeSelectionEnabled(String labId) {
    return labSelectedDates[labId] != null && 
           labTimeslots[labId] != null && 
           !labLoadingTimeslots[labId]!;
  }

  // Get the appropriate text for time selection
  String _getTimeSelectionText(String labId) {
    if (labSelectedTimes[labId] != null) {
      return _getDisplayTime(labSelectedTimes[labId]!);
    } else if (labSelectedDates[labId] == null) {
      return 'Select Date First';
    } else if (labLoadingTimeslots[labId] == true) {
      return 'Loading Times...';
    } else if (labTimeslots[labId] == null) {
      return 'No Times Available';
    } else {
      return 'Select Time';
    }
  }

  // Get the appropriate color for time selection text
  Color _getTimeSelectionTextColor(String labId) {
    if (labSelectedTimes[labId] != null) {
      return Colors.black;
    } else if (labSelectedDates[labId] == null) {
      return Colors.grey[400]!;
    } else if (labLoadingTimeslots[labId] == true) {
      return Colors.grey[500]!;
    } else if (labTimeslots[labId] == null) {
      return Colors.grey[400]!;
    } else {
      return Colors.grey[500]!;
    }
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

  // Generate time slots based on session parameters (same as checkout screen)
  List<Map<String, dynamic>> _generateTimeSlots({
    required String sessionStart, // '09:00:00'
    required String sessionEnd,   // '19:00:00'
    required int slotDurationMin, // 30
  }) {
    print('🔄 [LabSummary] Generating time slots from $sessionStart to $sessionEnd with ${slotDurationMin}min intervals');
    
    List<Map<String, dynamic>> slots = [];
    
    try {
      // Parse start and end times
      final startParts = sessionStart.split(':');
      final endParts = sessionEnd.split(':');
      
      if (startParts.length < 2 || endParts.length < 2) {
        print('❌ [LabSummary] Invalid time format');
        return slots;
      }
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      // Create DateTime objects for easier calculation
      final today = DateTime.now();
      var currentSlotStart = DateTime(today.year, today.month, today.day, startHour, startMinute);
      final sessionEndTime = DateTime(today.year, today.month, today.day, endHour, endMinute);
      
      print('🔄 [LabSummary] Session start: $currentSlotStart');
      print('🔄 [LabSummary] Session end: $sessionEndTime');
      
      int slotIndex = 1;
      
      // Generate slots until we reach the session end time
      while (currentSlotStart.add(Duration(minutes: slotDurationMin)).isBefore(sessionEndTime) || 
             currentSlotStart.add(Duration(minutes: slotDurationMin)).isAtSameMomentAs(sessionEndTime)) {
        
        final slotEnd = currentSlotStart.add(Duration(minutes: slotDurationMin));
        
        // Format times as HH:mm for consistency with API
        final startTimeStr = '${currentSlotStart.hour.toString().padLeft(2, '0')}:${currentSlotStart.minute.toString().padLeft(2, '0')}';
        final endTimeStr = '${slotEnd.hour.toString().padLeft(2, '0')}:${slotEnd.minute.toString().padLeft(2, '0')}';
        
        // Convert to 12-hour format for display
        final displayTime = '${_formatTimeTo12Hour(startTimeStr)} - ${_formatTimeTo12Hour(endTimeStr)}';
        
        slots.add({
          'id': slotIndex,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'time': displayTime, // For compatibility with existing UI
          'slot': displayTime, // Alternative field name
          'available': true, // Default to available
          'status': 'available',
          'doctor': {
            'name': 'Available', // Default doctor name
            'id': 'default',
          },
        });
        
        print('🔄 [LabSummary] Generated slot ${slotIndex}: $displayTime');
        
        // Move to next slot
        currentSlotStart = slotEnd;
        slotIndex++;
      }
      
      print('✅ [LabSummary] Generated ${slots.length} time slots');
      return slots;
      
    } catch (e) {
      print('❌ [LabSummary] Error generating time slots: $e');
      return slots;
    }
  }

  String _formatTimeTo12Hour(String time24) {
    if (time24.isEmpty) return '';
    
    try {
      // Parse 24-hour format (e.g., "09:00", "14:30")
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) hour -= 12;
      
      // More compact format: remove leading zero and use shorter format
      String hourStr = hour.toString();
      String minuteStr = minute.toString().padLeft(2, '0');
      
      // If minute is 00, just show hour with AM/PM
      if (minute == 0) {
        return '$hourStr$period';
      } else {
        return '$hourStr:$minuteStr$period';
      }
    } catch (e) {
      return time24; // Return original if parsing fails
    }
  }

  // Get compact time slot format for single line display
  String _getCompactTimeSlot(String timeSlot) {
    // If it's a range like "09:00 AM - 09:30 AM", show both start and end time
    if (timeSlot.contains(' - ')) {
      final parts = timeSlot.split(' - ');
      final startTime = parts[0].trim();
      final endTime = parts[1].trim();
      return '${_makeTimeCompact(startTime)}-${_makeTimeCompact(endTime)}';
    }
    return _makeTimeCompact(timeSlot);
  }

  // Make time format more compact (e.g., "09:00 AM" -> "9AM", "09:30 AM" -> "9:30AM")
  String _makeTimeCompact(String time) {
    String compact = time
        .replaceAll(' AM', 'AM')
        .replaceAll(' PM', 'PM')
        .replaceAll(':00', ''); // Remove :00 for exact hours
    
    // Remove leading zero if present
    if (compact.startsWith('0') && compact.length > 1) {
      compact = compact.substring(1);
    }
    
    return compact;
  }

  // Merge generated timeslot data with API response to preserve availability information
  Map<String, dynamic> _mergeTimeslotData(Map<String, dynamic> generatedData, Map<String, dynamic> apiData) {
    print('🔄 [LabSummary] Merging generated slots with API data');
    
    try {
      // Start with generated data as base
      final mergedData = Map<String, dynamic>.from(generatedData);
      
      // If API data has timeslots, use it to update availability
      if (apiData['timeslots'] != null) {
        final apiTimeslots = List<Map<String, dynamic>>.from(apiData['timeslots']);
        final generatedTimeslots = List<Map<String, dynamic>>.from(mergedData['timeslots']);
        
        // For each generated session, check if API has corresponding data
        for (int i = 0; i < generatedTimeslots.length; i++) {
          final generatedSession = generatedTimeslots[i];
          final generatedSlots = List<Map<String, dynamic>>.from(generatedSession['slots']);
          
          // Find matching session in API data (if any)
          final matchingApiSession = apiTimeslots.firstWhere(
            (session) => session['session_name'] == generatedSession['session_name'],
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingApiSession.isNotEmpty && matchingApiSession['slots'] != null) {
            final apiSlots = List<Map<String, dynamic>>.from(matchingApiSession['slots']);
            
            // Update generated slots with API availability data
            for (int j = 0; j < generatedSlots.length; j++) {
              final generatedSlot = generatedSlots[j];
              
              // Find matching slot in API data
              final matchingApiSlot = apiSlots.firstWhere(
                (apiSlot) => apiSlot['start_time'] == generatedSlot['start_time'] && 
                            apiSlot['end_time'] == generatedSlot['end_time'],
                orElse: () => <String, dynamic>{},
              );
              
              if (matchingApiSlot.isNotEmpty) {
                // Update with API data (status, doctor, etc.)
                generatedSlots[j] = {
                  ...generatedSlot,
                  'available': matchingApiSlot['status'] == 'available' || matchingApiSlot['available'] == true,
                  'status': matchingApiSlot['status'] ?? 'available',
                  'doctor': matchingApiSlot['doctor'] ?? generatedSlot['doctor'],
                };
              }
            }
            
            // Update the session with merged slots
            generatedTimeslots[i] = {
              ...generatedSession,
              'slots': generatedSlots,
            };
          }
        }
        
        mergedData['timeslots'] = generatedTimeslots;
      }
      
      print('✅ [LabSummary] Successfully merged timeslot data');
      return mergedData;
      
    } catch (e) {
      print('❌ [LabSummary] Error merging timeslot data: $e');
      // Return generated data as fallback
      return generatedData;
    }
  }

  // Filter timeslots to show only future times (same as checkout screen)
  List<Map<String, dynamic>> _filterFutureSlots(List<Map<String, dynamic>> slots, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slotDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // If selected date is not today, return all slots
    if (!slotDate.isAtSameMomentAs(today)) {
      return slots;
    }
    
    // If it's today, filter out past slots
    return slots.where((slot) {
      try {
        final startTime = slot['start_time']?.toString() ?? '';
        if (startTime.isEmpty) return false;
        
        final timeParts = startTime.split(':');
        if (timeParts.length < 2) return false;
        
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        
        final slotDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
        
        // Show slots that are at least 30 minutes in the future
        return slotDateTime.isAfter(now.add(const Duration(minutes: 30)));
      } catch (e) {
        print('❌ [LabSummary] Error filtering slot: $e');
        return true; // Keep slot if there's an error
      }
    }).toList();
  }

  void _proceedToCheckout() {
    // Reset validation errors
    setState(() {
      for (final labId in labServices.keys) {
        labDateErrors[labId] = false;
        labTimeErrors[labId] = false;
      }
    });
    
    // Validate that all labs have date and time selected
    bool hasError = false;
    List<String> missingFields = [];
    
    for (final labId in labServices.keys) {
      if (labSelectedDates[labId] == null) {
        setState(() {
          labDateErrors[labId] = true;
        });
        hasError = true;
        missingFields.add('date');
      }
      
      if (labSelectedTimes[labId] == null) {
        setState(() {
          labTimeErrors[labId] = true;
        });
        hasError = true;
        missingFields.add('time');
      }
    }
    
    if (hasError) {
      // Show toast message for missing mandatory fields
      String errorMessage = 'Please select ';
      if (missingFields.contains('date') && missingFields.contains('time')) {
        errorMessage += 'date and time for all labs';
      } else if (missingFields.contains('date')) {
        errorMessage += 'date for all labs';
      } else if (missingFields.contains('time')) {
        errorMessage += 'time for all labs';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Navigate to multi-lab checkout with refreshed cart data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiLabCheckoutScreen(
          cartItems: cartItems, // Use refreshed cart items
          testPrices: widget.testPrices,
          testDiscounts: widget.testDiscounts,
          cartData: _getRefreshedCartData(), // Use refreshed cart data
          multiLabData: {
            'labs': _getRefreshedLabsData(), // Use refreshed labs data
            'labServices': labServices,
            'labHomeCollection': labHomeCollection,
            'labSelectedDates': labSelectedDates,
            'labSelectedTimes': labSelectedTimes,
            'labTimeslots': labTimeslots,
          },
          onCartCleared: () {
            // Notify parent that entire cart has been cleared
            if (widget.onCartChanged != null) {
              print('🔄 Cart cleared from multi-lab - triggering parent cart refresh');
              widget.onCartChanged!();
            }
          },
        ),
      ),
    );
  }

  String _getDisplayTime(String fullTime) {
    // Convert "10:00 AM - 12:00 PM" to "10AM - 12PM"
    return fullTime
        .replaceAll(':00', '')
        .replaceAll(' AM', 'AM')
        .replaceAll(' PM', 'PM');
  }

  // Get refreshed cart data for checkout
  Map<String, dynamic> _getRefreshedCartData() {
    // Create a fresh cart data structure from current state
    final items = <Map<String, dynamic>>[];
    
    for (final labId in labServices.keys) {
      final services = labServices[labId] ?? [];
      for (final service in services) {
        items.add({
          'id': service['id'] ?? '',
          'test_name': service['name'] ?? service['testname'] ?? '',
          'price': service['baseprice'] ?? '0',
          'discounted_amount': service['discountedprice'] ?? '0',
          'discount_value': service['discountvalue'] ?? '0',
          'lab_id': labId,
          'lab_name': _getLabNameById(labId),
          'lab_test_id': service['lab_test_id'] ?? '',
          'lab_package_id': service['lab_package_id'] ?? '',
        });
      }
    }
    
    return {
      'items': items,
      'total_items': items.length,
    };
  }

  // Get refreshed labs data for checkout
  List<Map<String, dynamic>> _getRefreshedLabsData() {
    final labs = <Map<String, dynamic>>[];
    
    for (final labId in labServices.keys) {
      final services = labServices[labId] ?? [];
      labs.add({
        'id': labId,
        'name': _getLabNameById(labId),
        'services': services,
      });
    }
    
    return labs;
  }

  // Helper method to get lab name by ID
  String _getLabNameById(String labId) {
    // Try to find lab name from original widget data
    for (final lab in widget.labsData) {
      if (lab['id']?.toString() == labId) {
        return lab['name']?.toString() ?? 'Unknown Lab';
      }
    }
    return 'Unknown Lab';
  }

  // Build price row widget (matching multi lab checkout screen style)
  Widget _buildPriceRow(String label, String amount, {Color? color, bool isTotal = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color != null ? color.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: color ?? const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 15,
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? const Color(0xFF475569),
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.primaryBlue : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeSlotBottomSheet(String labId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                  Icon(
                    Icons.access_time,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Time Slot',
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
            
            // Selected date info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labSelectedDates[labId] != null 
                      ? 'Selected Date: ${labSelectedDates[labId]!.day}/${labSelectedDates[labId]!.month}/${labSelectedDates[labId]!.year}'
                      : 'Please select a date',
                    style: TextStyle(
                      fontSize: 14,
                      color: labSelectedDates[labId] != null ? AppColors.primaryBlue : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Time slots
            Expanded(
              child: labLoadingTimeslots[labId] == true
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _buildTimeSlotsList(labId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsList(String labId) {
    // Get available time slots from generated/merged data
    final timeslots = labTimeslots[labId];
    List<Map<String, dynamic>> availableSlots = [];
    
    if (timeslots != null && timeslots['timeslots'] != null) {
      // Extract slots from the timeslots sessions
      final timeslotSessions = List<Map<String, dynamic>>.from(timeslots['timeslots']);
      for (final session in timeslotSessions) {
        if (session['slots'] != null) {
          final sessionSlots = List<Map<String, dynamic>>.from(session['slots']);
          availableSlots.addAll(sessionSlots);
        }
      }
      print('🔄 [LabSummary] Found ${availableSlots.length} slots for lab $labId');
    } else {
      // Use generated default time slots as fallback
      availableSlots = _generateTimeSlots(
        sessionStart: '09:00:00',
        sessionEnd: '19:00:00',
        slotDurationMin: 30,
      );
      print('🔄 [LabSummary] Using fallback generated slots for lab $labId: ${availableSlots.length}');
    }
    
    // Filter future slots and create 3-per-row grid
    final selectedDate = labSelectedDates[labId] ?? DateTime.now();
    final futureSlots = _filterFutureSlots(availableSlots, selectedDate);
    
    if (futureSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No available time slots for this date',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          (futureSlots.length / 3).ceil(),
          (rowIndex) {
            final startIndex = rowIndex * 3;
            final endIndex = (startIndex + 3 <= futureSlots.length) ? startIndex + 3 : futureSlots.length;
            final rowSlots = futureSlots.sublist(startIndex, endIndex);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ...rowSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    final timeSlot = slot['time'] ?? slot['slot'] ?? 'Unknown Time';
                    final isAvailable = slot['available'] ?? true;
                    final isSelected = labSelectedTimes[labId] == timeSlot;
                    
                    return [
                      Expanded(
                        child: InkWell(
                          onTap: isAvailable ? () {
                            _onTimeChanged(labId, timeSlot);
                            Navigator.pop(context);
                          } : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primaryBlue 
                                  : isAvailable 
                                      ? Colors.white
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primaryBlue 
                                    : isAvailable
                                        ? AppColors.primaryBlue.withOpacity(0.3)
                                        : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                                                         child: Center(
                               child: Text(
                                 _getCompactTimeSlot(timeSlot),
                                 style: TextStyle(
                                   fontSize: 10,
                                   fontWeight: FontWeight.w600,
                                   color: isSelected 
                                       ? Colors.white 
                                       : isAvailable 
                                           ? AppColors.primaryBlue 
                                           : Colors.grey[500],
                                 ),
                                 textAlign: TextAlign.center,
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                          ),
                        ),
                      ),
                      if (index < rowSlots.length - 1) const SizedBox(width: 8),
                    ];
                  }).expand((element) => element),
                  // Fill remaining space if less than 3 slots in this row
                  ...List.generate(
                    3 - rowSlots.length,
                    (index) => const Expanded(child: SizedBox()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          // User navigated back - notify parent that cart might have changed
          print('🔙 User navigated back from lab-wise summary - notifying parent of potential cart changes');
          _notifyCartChanged();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        title: const Text(
          'Summary and Schedule',
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
          // Simple header with pricing
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: labServices.isEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No items in cart',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          
          // Labs list
          Expanded(
            child: labServices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items in cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add some tests or packages to continue',
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
                    itemCount: _getActiveLabsData().length,
                    itemBuilder: (context, index) {
                      final lab = _getActiveLabsData()[index];
                      final labId = lab['id']?.toString() ?? '';
                      final labName = lab['name']?.toString() ?? 'Unknown Lab';
                      final services = labServices[labId] ?? [];
                      
                      return _buildLabCard(lab, labId, labName, services);
                    },
                  ),
          ),
          
          // Final amount display (only when cart has items)
          if (!labServices.isEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                //color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.payment,
                          color: AppColors.primaryBlue,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Final Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${_calculateTotalPrice().toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Proceed button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: labServices.isEmpty ? null : _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: labServices.isEmpty ? Colors.grey : AppColors.white,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                labServices.isEmpty ? 'Cart is Empty' : 'Proceed to Checkout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
      ), // Close PopScope child (Scaffold)
    ); // Close PopScope
  }

  Widget _buildLabCard(Map<String, dynamic> lab, String labId, String labName, List<Map<String, dynamic>> services) {
    print('🔍 DEBUG: _buildLabCard called');
    print('🔍 DEBUG: Lab ID: $labId, Lab Name: $labName');
    print('🔍 DEBUG: Full lab object: $lab');
    print('🔍 DEBUG: Services count: ${services.length}');
    
    // Calculate lab totals
    double labOriginalPrice = 0.0;
    double labDiscountedPrice = 0.0;
    int testCount = 0;
    int packageCount = 0;
    
    print('🔍 Lab: $labName - Analyzing ${services.length} services');
    print('🔍 Available service fields: ${services.isNotEmpty ? services.first.keys.toList() : "No services"}');
    
    for (final service in services) {
      final originalPrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
      final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
      
      labOriginalPrice += originalPrice;
      labDiscountedPrice += discountedPrice;
      
      // Count tests vs packages - improved logic
      final testId = service['lab_test_id']?.toString() ?? '';
      final packageId = service['lab_package_id']?.toString() ?? '';
      final serviceName = service['name']?.toString() ?? service['testname']?.toString() ?? 'Service';
      
      print('📊 Service: $serviceName');
      print('🔍 Full service data: $service');
      print('🔍 TestID: "$testId" | PackageID: "$packageId"');
      
      // Check original cart data for more reliable test/package identification
      String? originalTestId = '';
      String? originalPackageId = '';
      
      // Try to find this service in the original cart data to get the correct IDs
      if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
        for (final item in items) {
          final itemName = item['test_name']?.toString() ?? '';
          if (itemName == serviceName || itemName.toLowerCase() == serviceName.toLowerCase()) {
            originalTestId = item['lab_test_id']?.toString() ?? '';
            originalPackageId = item['lab_package_id']?.toString() ?? '';
            break;
          }
        }
      }
      
      print('🔍 Original cart data - TestID: "$originalTestId" | PackageID: "$originalPackageId"');
      
      // Use original cart data if available, otherwise use service data
      final finalTestId = (originalTestId?.isNotEmpty == true) ? originalTestId! : testId;
      final finalPackageId = (originalPackageId?.isNotEmpty == true) ? originalPackageId! : packageId;
      
      // Priority: Check for package first (packages are more specific)
      if (finalPackageId.isNotEmpty && finalPackageId != 'null' && finalPackageId != '0') {
        packageCount++;
        print('✅ Counted as PACKAGE (has package ID: $finalPackageId)');
      } else if (finalTestId.isNotEmpty && finalTestId != 'null' && finalTestId != '0') {
        // Even if test ID exists, double-check if it's actually a package by name
        final serviceNameLower = serviceName.toLowerCase();
        final testNameLower = service['testname']?.toString().toLowerCase() ?? '';
        
        if (serviceNameLower.contains('package') || serviceNameLower.contains('combo') || 
            serviceNameLower.contains('panel') || serviceNameLower.contains('profile') ||
            testNameLower.contains('package') || testNameLower.contains('combo') ||
            testNameLower.contains('panel') || testNameLower.contains('profile')) {
          packageCount++;
          print('✅ Counted as PACKAGE (has test ID but name indicates package: $finalTestId)');
        } else {
          testCount++;
          print('✅ Counted as TEST (has test ID: $finalTestId)');
        }
      } else {
        // No IDs available, determine purely by service name
        final serviceNameLower = serviceName.toLowerCase();
        final testNameLower = service['testname']?.toString().toLowerCase() ?? '';
        
        // Expanded package keywords
        if (serviceNameLower.contains('package') || serviceNameLower.contains('combo') || 
            serviceNameLower.contains('panel') || serviceNameLower.contains('profile') ||
            serviceNameLower.contains('checkup') || serviceNameLower.contains('screen') ||
            testNameLower.contains('package') || testNameLower.contains('combo') ||
            testNameLower.contains('panel') || testNameLower.contains('profile') ||
            testNameLower.contains('checkup') || testNameLower.contains('screen')) {
          packageCount++;
          print('✅ Counted as PACKAGE (by name keywords)');
        } else {
          testCount++;
          print('✅ Counted as TEST (by name, no package keywords)');
        }
      }
    }
    
    print('📈 Final count for $labName: $testCount Tests, $packageCount Packages');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lab header with white background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                                        Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$testCount Tests • $packageCount Packages',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryBlue.withOpacity(0.8),
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
          
          // Services list with better design
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _buildServiceItem(service);
                  },
                ),
                
                // Action buttons row
                Row(
                  children: [
                    // Add More Tests button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showAddMoreItemsBottomSheet(labId, labName),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Add More Tests',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
          
          // Lab scheduling options with better design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                
                // Home collection toggle
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.home_outlined,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Home Collection',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: labHomeCollection[labId] ?? true,
                          onChanged: (value) => _onHomeCollectionChanged(labId, value),
                          activeColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Modern date and time selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Date selection
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showCustomDatePicker(labId),
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: labDateErrors[labId] == true 
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: labDateErrors[labId] == true 
                                    ? Colors.red 
                                    : Colors.grey.withOpacity(0.2)
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Date',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: labDateErrors[labId] == true 
                                              ? Colors.red[600] 
                                              : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          labSelectedDates[labId] != null 
                                            ? '${labSelectedDates[labId]!.day}/${labSelectedDates[labId]!.month}/${labSelectedDates[labId]!.year}'
                                            : 'Select Date',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: labSelectedDates[labId] != null ? Colors.black : Colors.grey[500],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Time selection
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Only allow time selection if date is selected and timeslots are loaded
                          if (labSelectedDates[labId] != null && 
                              labTimeslots[labId] != null && 
                              !labLoadingTimeslots[labId]!) {
                            _showTimeSlotBottomSheet(labId);
                          }
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isTimeSelectionEnabled(labId)
                              ? (labTimeErrors[labId] == true 
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.grey[50])
                              : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: labTimeErrors[labId] == true 
                                ? Colors.red 
                                : (_isTimeSelectionEnabled(labId) 
                                    ? Colors.grey.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.3))
                            ),
                          ),
                          child: labLoadingTimeslots[labId] == true
                            ? Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Time',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: labTimeErrors[labId] == true 
                                              ? Colors.red[600] 
                                              : (_isTimeSelectionEnabled(labId) 
                                                  ? Colors.grey[600] 
                                                  : Colors.grey[400]),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _getTimeSelectionText(labId),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getTimeSelectionTextColor(labId),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: _isTimeSelectionEnabled(labId) 
                                        ? Colors.grey[400] 
                                        : Colors.grey[300],
                                    size: 20,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                        ],
                    ),
                    
                    // Validation error messages
                    if (labDateErrors[labId] == true || labTimeErrors[labId] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (labDateErrors[labId] == true)
                              Expanded(
                                child: Text(
                                  'Please select a date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (labTimeErrors[labId] == true)
                              Expanded(
                                child: Text(
                                  'Please select a time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w500,
                                  ),
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
        ],
      ),
    );
  }



  Widget _buildServiceItem(Map<String, dynamic> service) {
    final serviceName = service['name']?.toString() ?? service['testname']?.toString() ?? 'Service';
    final originalPrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
    final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
    final discountValue = service['discountvalue']?.toString() ?? '0';
    
    // Improved package detection logic - prioritize package detection
    bool isPackage = false;
    final testId = service['lab_test_id']?.toString() ?? '';
    final packageId = service['lab_package_id']?.toString() ?? '';
    
    // Check original cart data for more reliable test/package identification
    String? originalTestId = '';
    String? originalPackageId = '';
    
    // Try to find this service in the original cart data to get the correct IDs
    if (widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (final item in items) {
        final itemName = item['test_name']?.toString() ?? '';
        if (itemName == serviceName || itemName.toLowerCase() == serviceName.toLowerCase()) {
          originalTestId = item['lab_test_id']?.toString() ?? '';
          originalPackageId = item['lab_package_id']?.toString() ?? '';
          break;
        }
      }
    }
    
    // Use original cart data if available, otherwise use service data
    final finalTestId = (originalTestId?.isNotEmpty == true) ? originalTestId! : testId;
    final finalPackageId = (originalPackageId?.isNotEmpty == true) ? originalPackageId! : packageId;
    
    // Priority: Check for package first (packages are more specific)
    if (finalPackageId.isNotEmpty && finalPackageId != 'null' && finalPackageId != '0') {
      isPackage = true;
    } else if (finalTestId.isNotEmpty && finalTestId != 'null' && finalTestId != '0') {
      // Even if test ID exists, double-check if it's actually a package by name
      final serviceNameLower = serviceName.toLowerCase();
      final testNameLower = service['testname']?.toString().toLowerCase() ?? '';
      
      // Check for package keywords even when test ID exists
      if (serviceNameLower.contains('package') || serviceNameLower.contains('combo') || 
          serviceNameLower.contains('panel') || serviceNameLower.contains('profile') ||
          testNameLower.contains('package') || testNameLower.contains('combo') ||
          testNameLower.contains('panel') || testNameLower.contains('profile')) {
        isPackage = true;
      } else {
        isPackage = false;
      }
    } else {
      // No IDs available, determine purely by service name with expanded keywords
      final serviceNameLower = serviceName.toLowerCase();
      final testNameLower = service['testname']?.toString().toLowerCase() ?? '';
      
      isPackage = serviceNameLower.contains('package') || serviceNameLower.contains('combo') ||
                  serviceNameLower.contains('panel') || serviceNameLower.contains('profile') ||
                  serviceNameLower.contains('checkup') || serviceNameLower.contains('screen') ||
                  testNameLower.contains('package') || testNameLower.contains('combo') ||
                  testNameLower.contains('panel') || testNameLower.contains('profile') ||
                  testNameLower.contains('checkup') || testNameLower.contains('screen');
    }
    
    print('🏷️ Service Item: $serviceName -> ${isPackage ? "PACKAGE" : "TEST"} (TestID: $testId, PackageID: $packageId)');
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Icon based on type
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPackage ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isPackage ? Icons.inventory_2_outlined : Icons.science_outlined,
              color: isPackage ? Colors.orange : Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          
          // Service details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPackage ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPackage ? 'Package' : 'Test',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isPackage ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                    if (discountValue != '0' && discountValue.isNotEmpty) ...[
                      if (_shouldShowDiscount(discountValue)) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_formatDiscount(discountValue)}% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (originalPrice != discountedPrice && discountValue != '0') ...[
                Text(
                  '₹${originalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 1),
              ],
              Text(
                '₹${discountedPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 8),
          
          // Remove button
          GestureDetector(
            onTap: removingItems.contains(serviceName) ? null : () => _removeItemFromCart(service),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: removingItems.contains(serviceName) 
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: removingItems.contains(serviceName)
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3), 
                  width: 1,
                ),
              ),
              child: removingItems.contains(serviceName)
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  : const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 14,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalPrice() {
    double total = 0.0;
    int serviceCount = 0;
    
    for (final lab in widget.labsData) {
      final labId = lab['id']?.toString() ?? '';
      final services = labServices[labId] ?? [];
      
      for (final service in services) {
        final discountedPrice = double.tryParse(service['discountedprice']?.toString() ?? '0') ?? 0.0;
        total += discountedPrice;
        serviceCount++;
      }
    }
    
    print('💰 _calculateTotalPrice: ₹$total (from $serviceCount services)');
    return total;
  }

  double _calculateOriginalPrice() {
    double total = 0.0;
    int serviceCount = 0;
    
    for (final lab in widget.labsData) {
      final labId = lab['id']?.toString() ?? '';
      final services = labServices[labId] ?? [];
      
      for (final service in services) {
        final originalPrice = double.tryParse(service['baseprice']?.toString() ?? '0') ?? 0.0;
        total += originalPrice;
        serviceCount++;
      }
    }
    
    print('💰 _calculateOriginalPrice: ₹$total (from $serviceCount services)');
    return total;
  }

  // Get only labs that still have services after updates
  List<Map<String, dynamic>> _getActiveLabsData() {
    print('🔍 DEBUG: _getActiveLabsData called');
    print('🔍 DEBUG: widget.labsData length: ${widget.labsData.length}');
    
    final activeLabs = widget.labsData.where((lab) {
      final labId = lab['id']?.toString() ?? '';
      final labName = lab['name']?.toString() ?? 'Unknown Lab';
      final services = labServices[labId] ?? [];
      
      print('🔍 DEBUG: Checking lab - ID: $labId, Name: $labName, Services: ${services.length}');
      
      return services.isNotEmpty;
    }).toList();
    
    print('🔍 DEBUG: Active labs count: ${activeLabs.length}');
    for (final lab in activeLabs) {
      print('🔍 DEBUG: Active lab - ID: ${lab['id']}, Name: ${lab['name']}');
    }
    
    return activeLabs;
  }

  // Notify parent screens that cart has changed
  void _notifyCartChanged() {
    if (widget.onCartChanged != null) {
      print('📢 Notifying parent screens that cart has changed');
      widget.onCartChanged!();
    } else {
      print('⚠️ No cart change callback available');
    }
  }



  // Remove item from cart
  Future<void> _removeItemFromCart(Map<String, dynamic> service) async {
          final serviceName = service['name']?.toString() ?? service['testname']?.toString() ?? 'Service';
    
    // Prevent multiple removal attempts
    if (removingItems.contains(serviceName)) {
      return;
    }
    
    setState(() {
      removingItems.add(serviceName);
    });
    
    // Find the cart item ID from the current cart data
    String? cartItemId;
    
    // First try to get fresh cart data from API
    try {
      final cartResult = await _apiService.getCart();
      if (cartResult['success'] && cartResult['data'] != null) {
        final freshCartData = cartResult['data'];
        if (freshCartData['items'] != null) {
          final items = List<Map<String, dynamic>>.from(freshCartData['items']);
          for (final item in items) {
            final itemName = item['test_name']?.toString() ?? '';
            if (itemName == serviceName || itemName.toLowerCase() == serviceName.toLowerCase()) {
              cartItemId = item['id']?.toString() ?? item['cart_id']?.toString();
              print('✅ Found cart item ID: $cartItemId for service: $serviceName');
              break;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching fresh cart data: $e');
    }
    
    // Fallback to widget.cartData if fresh data didn't work
    if (cartItemId == null && widget.cartData.isNotEmpty && widget.cartData['items'] != null) {
      final items = List<Map<String, dynamic>>.from(widget.cartData['items']);
      for (final item in items) {
        final itemName = item['test_name']?.toString() ?? '';
        if (itemName == serviceName || itemName.toLowerCase() == serviceName.toLowerCase()) {
          cartItemId = item['id']?.toString() ?? item['cart_id']?.toString();
          print('✅ Found cart item ID from widget data: $cartItemId for service: $serviceName');
          break;
        }
      }
    }
    
    if (cartItemId == null) {
      setState(() {
        removingItems.remove(serviceName);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to find item in cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('🗑️ Removing item from cart: $serviceName (ID: $cartItemId)');
    
    try {
      final result = await _apiService.removeFromCart(cartItemId);
      
      if (result['success']) {        
        // Item removed from cart - no toast message needed
        
        print('✅ Item removal successful - triggering cart refresh');
        // Refresh the screen data
        await _refreshCartData();
        print('✅ Cart refresh completed - UI should be updated');
        
        // Notify parent screens that cart has changed
        _notifyCartChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to remove item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        removingItems.remove(serviceName);
      });
    }
  }

  // Show add more items bottom sheet
  void _showAddMoreItemsBottomSheet(String labId, String labName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AddMoreItemsBottomSheet(
          labId: labId,
          labName: labName,
          cartItems: cartItems,
          onItemAdded: _onItemAddedToCart,
        );
      },
    );
  }

  // Wrapper method for when items are added to cart
  Future<void> _onItemAddedToCart() async {
    await _refreshCartData();
    _notifyCartChanged(); // Notify parent screens
  }

  // Refresh cart data after changes
  Future<void> _refreshCartData() async {
    print('🔄 Refreshing cart data and lab services...');
    
    try {
      // Fetch fresh cart data from API
      final cartResult = await _apiService.getCart();
      
      if (cartResult['success']) {
        final freshCartData = cartResult['data'];
        print('✅ Fresh cart data received: $freshCartData');
        
        // Extract updated cart items
        final newCartItems = <String>{};
        final newLabsData = <Map<String, dynamic>>[];
        final Map<String, Map<String, dynamic>> labsMap = {};
        
        if (freshCartData != null && freshCartData['items'] != null) {
          final items = List<Map<String, dynamic>>.from(freshCartData['items']);
          
          for (final item in items) {
            final testName = item['test_name']?.toString() ?? '';
            if (testName.isNotEmpty) {
              newCartItems.add(testName);
            }
            
            // Group items by lab
            final labId = item['lab_id']?.toString();
            final labName = item['lab_name']?.toString();
            
            if (labId != null && labId.isNotEmpty && labName != null && labName.isNotEmpty) {
              if (!labsMap.containsKey(labId)) {
                labsMap[labId] = {
                  'id': labId,
                  'name': labName,
                  'services': <Map<String, dynamic>>[],
                };
              }
              
              // Add service to lab
              final service = {
                'id': item['id']?.toString() ?? '',
                'testname': testName,
                'name': testName,
                'baseprice': item['price']?.toString() ?? '0',
                'discountedprice': item['discounted_amount']?.toString() ?? item['price']?.toString() ?? '0',
                'discountvalue': item['discount_value']?.toString() ?? '0',
                'lab_test_id': item['lab_test_id']?.toString() ?? '',
                'lab_package_id': item['lab_package_id']?.toString() ?? '',
              };
              
              labsMap[labId]!['services'].add(service);
            }
          }
        }
        
        // Convert labs map to list
        newLabsData.addAll(labsMap.values);
        
        print('✅ Processed ${newLabsData.length} labs with services');
        print('✅ Updated cart items: ${newCartItems.length}');
        
        // Update state with fresh data
        setState(() {
          cartItems = newCartItems;
          
          // Update lab services
          labServices.clear();
          for (final lab in newLabsData) {
            final labId = lab['id']?.toString() ?? '';
            final services = List<Map<String, dynamic>>.from(lab['services'] ?? []);
            if (labId.isNotEmpty && services.isNotEmpty) {
              labServices[labId] = services;
            }
          }
          
          // Remove empty labs from other related maps
          final activeLabIds = labServices.keys.toSet();
          labHomeCollection.removeWhere((key, value) => !activeLabIds.contains(key));
          labSelectedDates.removeWhere((key, value) => !activeLabIds.contains(key));
          labSelectedTimes.removeWhere((key, value) => !activeLabIds.contains(key));
          labTimeslots.removeWhere((key, value) => !activeLabIds.contains(key));
          labLoadingTimeslots.removeWhere((key, value) => !activeLabIds.contains(key));
        });
        
        print('📊 Cart summary should now update:');
        print('   - Cart items: ${newCartItems.length}');
        print('   - Active labs: ${labServices.keys.length}');
        print('   - Original price: ₹${_calculateOriginalPrice()}');
        print('   - Final price: ₹${_calculateTotalPrice()}');
        
        // Check if cart is now empty
        if (newCartItems.isEmpty || labServices.isEmpty) {
          print('⚠️ Cart is now empty - navigating back');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cart is now empty. Returning to previous screen.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cart data refreshed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        print('✅ Cart data refresh completed successfully');
      } else {
        throw Exception(cartResult['message'] ?? 'Failed to refresh cart data');
      }
    } catch (e) {
      print('❌ Error refreshing cart data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh cart data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// Add More Items Bottom Sheet Widget
class _AddMoreItemsBottomSheet extends StatefulWidget {
  final String labId;
  final String labName;
  final Set<String> cartItems;
  final VoidCallback onItemAdded;

  const _AddMoreItemsBottomSheet({
    required this.labId,
    required this.labName,
    required this.cartItems,
    required this.onItemAdded,
  });

  @override
  State<_AddMoreItemsBottomSheet> createState() => _AddMoreItemsBottomSheetState();
}

class _AddMoreItemsBottomSheetState extends State<_AddMoreItemsBottomSheet> {
  final ApiService _apiService = ApiService();

  
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _packages = [];
  bool _isLoadingTests = false;
  bool _isLoadingPackages = false;
  bool _showTests = true; // true for tests, false for packages
  Set<String> _loadingItems = {};

  // Helper method to check if an item is available at this organization
  bool _isItemAvailableAtOrganization(Map<String, dynamic> item, bool isPackage) {
    // This is a placeholder implementation
    // You can implement more sophisticated logic based on:
    // 1. Organization's actual test/package catalog
    // 2. Geographic availability
    // 3. Equipment availability
    // 4. Specialization areas
    
    if (isPackage) {
      // For packages, you might want to check if the organization
      // has the capability to perform all tests in the package
      // Example implementation:
      // final packageTests = item['tests'] as List<dynamic>? ?? [];
      // return packageTests.every((test) => _isTestAvailableAtOrganization(test));
      return true; // For now, assume all packages are available
    } else {
      // For individual tests, you might want to check:
      // - Test category compatibility
      // - Equipment availability
      // - Staff expertise
      // Example implementation:
      // final testCategory = item['category']?.toString().toLowerCase() ?? '';
      // final organizationSpecializations = ['blood', 'urine', 'imaging']; // Get from API
      // return organizationSpecializations.any((spec) => testCategory.contains(spec));
      return true; // For now, assume all tests are available
    }
  }

  // Helper method to format discount value (remove decimal points)
  String _formatDiscount(dynamic discountValue) {
    if (discountValue == null) return '0';
    String formatted = discountValue.toString();
    if (formatted.contains('.')) {
      // Remove all decimal points and trailing zeros
      double? number = double.tryParse(formatted);
      if (number != null) {
        formatted = number.toInt().toString();
      }
    }
    return formatted;
  }

  // Helper method to check if discount should be shown
  bool _shouldShowDiscount(dynamic discountValue) {
    if (discountValue == null || discountValue.toString().isEmpty) return false;
    double? number = double.tryParse(discountValue.toString());
    return number != null && number > 0;
  }

  // Show package tests bottom sheet
  void _showPackageTestsBottomSheet(BuildContext context, Map<String, dynamic> package) {
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
  void initState() {
    super.initState();
    _loadTests();
    _loadPackages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoadingTests = true;
    });

    try {
      // Get organization-specific tests using the new API endpoint
      final result = await _apiService.getOrganizationTests(
        organizationId: widget.labId,
        search: '',
        sortBy: 'testname',
        sortOrder: 'asc',
      );

      if (result['success'] && mounted) {
        final responseData = result['data'];
        final organizationTests = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        
        // Transform the organization-specific test data to match the expected format
        final transformedTests = organizationTests.map((orgTest) {
          final test = orgTest['test'] as Map<String, dynamic>? ?? {};
          return {
            'id': test['id'] ?? orgTest['test_id'],
            'testname': test['name'] ?? '',
            'shortname': test['short_name'] ?? '',
            'name': test['name'] ?? '',
            'description': test['description'] ?? '',
            'baseprice': orgTest['baseprice'] ?? '0',
            'discountedprice': orgTest['discountedprice'] ?? orgTest['baseprice'] ?? '0',
            'discountvalue': orgTest['discountvalue'] ?? '0',
            'discounttype': orgTest['discounttype'] ?? 'percentage',
            'category': test['category']?['name'] ?? '',
            'is_home_collection': test['is_home_collection'] ?? false,
            'service_id': orgTest['service_id'],
            'test_id': orgTest['test_id'],
          };
        }).toList();
        
        setState(() {
          _tests = transformedTests;
          _isLoadingTests = false;
        });
        
        print('✅ Loaded ${transformedTests.length} organization-specific tests for ${widget.labName}');
        print('🏥 Organization: ${responseData['organization']?['name']}');
      } else {
        setState(() {
          _isLoadingTests = false;
        });
        print('❌ Failed to load organization tests: ${result['message']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTests = false;
        });
      }
      print('❌ Error loading organization tests: $e');
    }
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoadingPackages = true;
    });

    try {
      // Get organization-specific packages using the new API endpoint
      final result = await _apiService.getOrganizationPackages(
        organizationId: widget.labId,
      );

      if (result['success'] && mounted) {
        final organizationPackages = List<Map<String, dynamic>>.from(result['data'] ?? []);
        
        // Transform the organization-specific package data to match the expected format
        final transformedPackages = organizationPackages.map((orgPackage) {
          final package = orgPackage['package'] as Map<String, dynamic>? ?? {};
          return {
            'id': orgPackage['id'],
            'packagename': package['packagename'] ?? '',
            'name': package['packagename'] ?? '',
            'description': package['description'] ?? '',
            'baseprice': orgPackage['baseprice'] ?? '0',
            'discountvalue': orgPackage['discountvalue'] ?? '0',
            'discounttype': orgPackage['discounttype'] ?? 'percentage',
            'discountedprice': orgPackage['discountedprice'] ?? orgPackage['baseprice'] ?? '0',
            'package_id': orgPackage['package_id'],
            'org_id': orgPackage['org_id'],
            'status': orgPackage['status'],
            'tests': [], // Empty tests array for now, can be populated if needed
          };
        }).toList();
        
        setState(() {
          _packages = transformedPackages;
          _isLoadingPackages = false;
        });
        
        print('✅ Loaded ${transformedPackages.length} organization-specific packages for ${widget.labName}');
      } else {
        setState(() {
          _isLoadingPackages = false;
        });
        print('❌ Failed to load organization packages: ${result['message']}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPackages = false;
        });
      }
      print('❌ Error loading organization packages: $e');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item, bool isPackage) async {
    final itemName = isPackage 
        ? (item['packagename'] ?? item['name'] ?? 'Package')
        : (item['testname'] ?? item['shortname'] ?? item['name'] ?? 'Test');
    
    // If item is already in cart, remove it instead
    if (widget.cartItems.contains(itemName)) {
      await _removeFromCart(item, isPackage);
      return;
    }
    
    setState(() {
      _loadingItems.add(itemName);
    });

    try {
      // Get both original and discounted prices
      final originalPrice = double.tryParse(item['baseprice']?.toString() ?? '0') ?? 0.0;
      final discountedPrice = double.tryParse(item['discountedprice']?.toString() ?? item['baseprice']?.toString() ?? '0') ?? 0.0;
      
      // Get discount details
      final discountedValue = double.tryParse(item['discountvalue']?.toString() ?? '0') ?? 0.0;
      final discountType = item['discounttype']?.toString() ?? item['discount_type']?.toString() ?? 'percentage';
      
      print('🛒 Adding item to cart with original price: $originalPrice, discounted price: $discountedPrice');
      print('🛒 Discount value: $discountedValue, discount type: $discountType');
      
      // For organization-specific tests, use test_id for lab_test_id key
      final labTestId = isPackage ? '' : (item['test_id']?.toString() ?? item['id']?.toString() ?? '');
      final packageId = isPackage ? (item['package_id']?.toString() ?? '') : null;

      final result = await _apiService.addToCart(
        price: originalPrice,
        testName: itemName,
        labTestId: labTestId,
        packageId: packageId,
        organizationId: widget.labId,
        organizationName: widget.labName,
        discountedPrice: discountedPrice,
        discountedValue: discountedValue,
        discountType: discountType,
      );

      if (result['success']) {
        // Item added to cart - no toast message needed
        
        widget.onItemAdded();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _loadingItems.remove(itemName);
    });
  }

  Future<void> _removeFromCart(Map<String, dynamic> item, bool isPackage) async {
    final itemName = isPackage 
        ? (item['packagename'] ?? item['name'] ?? 'Package')
        : (item['testname'] ?? item['shortname'] ?? item['name'] ?? 'Test');
    
    setState(() {
      _loadingItems.add(itemName);
    });

    try {
      // Get cart data to find the item ID
      final cartResult = await _apiService.getCart();
      
      if (cartResult['success'] && cartResult['data'] != null) {
        final cartItems = List<Map<String, dynamic>>.from(cartResult['data']['items'] ?? []);
        
        // Find the item in cart by name
        final cartItem = cartItems.firstWhere(
          (cartItem) => cartItem['test_name']?.toString() == itemName,
          orElse: () => <String, dynamic>{},
        );
        
        if (cartItem.isNotEmpty && cartItem['id'] != null) {
          final removeResult = await _apiService.removeFromCart(cartItem['id'].toString());
          
          if (removeResult['success']) {
            // Item removed from cart - no toast message needed
            
            widget.onItemAdded();
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(removeResult['message'] ?? 'Failed to remove item'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item not found in cart'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get cart data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _loadingItems.remove(itemName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add More Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'to ${widget.labName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          

          
          // Tab switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showTests = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showTests ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tests',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _showTests ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showTests = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showTests ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Packages',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_showTests ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _showTests ? _buildTestsList() : _buildPackagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList() {
    if (_isLoadingTests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tests.isEmpty) {
      return const Center(
        child: Text(
          'No tests available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _tests.length,
      itemBuilder: (context, index) {
        final test = _tests[index];
        final testName = test['testname'] ?? test['shortname'] ?? test['name'] ?? 'Test';
        final basePrice = double.tryParse(test['baseprice']?.toString() ?? '0') ?? 0.0;
        final discountedPrice = double.tryParse(test['discountedprice']?.toString() ?? '0') ?? 0.0;
        final discountValue = _formatDiscount(test['discountvalue']?.toString() ?? '0');
        final isInCart = widget.cartItems.contains(testName);
        final isLoading = _loadingItems.contains(testName);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: isInCart ? 4 : 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isInCart ? AppColors.primaryBlue : Colors.grey[200]!,
              width: isInCart ? 2 : 1,
            ),
          ),
                      child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          testName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isInCart ? AppColors.primaryBlue : Colors.black87,
                          ),
                        ),
                      ),
                      if (isInCart)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
                    if (test['is_home_collection'] == true || test['ishomecollection'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Home Collection',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (test['collectioninstruction'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Text(
                          test['collectioninstruction'],
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
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
                            onPressed: isLoading ? null : () => _addToCart(test, false),
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
                            onPressed: isLoading ? null : () => _addToCart(test, false),
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
      },
    );
  }

  Widget _buildPackagesList() {
    if (_isLoadingPackages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_packages.isEmpty) {
      return const Center(
        child: Text(
          'No packages available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final package = _packages[index];
        final packageName = package['packagename'] ?? package['name'] ?? 'Package';
        final price = double.tryParse(package['baseprice']?.toString() ?? '0') ?? 0.0;
        final discountValue = _formatDiscount(package['discountvalue']?.toString() ?? '0');
        final isInCart = widget.cartItems.contains(packageName);
        final isLoading = _loadingItems.contains(packageName);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isInCart ? 4 : 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isInCart ? AppColors.primaryBlue : Colors.grey[200]!,
              width: isInCart ? 2 : 1,
            ),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  packageName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isInCart ? AppColors.primaryBlue : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isInCart)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'SELECTED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                            if (discountValue != '0' && discountValue.isNotEmpty) ...[
                              Text(
                                'Starts from ',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            Text(
                              '₹${price.toStringAsFixed(0)}',
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
                        GestureDetector(
                          onTap: () => _showPackageTestsBottomSheet(context, package),
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
                                    fontSize: 10,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_shouldShowDiscount(discountValue))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF8C32).withOpacity(0.3), width: 0.5),
                            ),
                            child: Text(
                              '${_formatDiscount(discountValue)}% OFF',
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
                    GestureDetector(
                      onTap: () => _showPackageTestsBottomSheet(context, package),
                      child: Row(
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
                            onPressed: isLoading ? null : () => _addToCart(package, true),
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
                            onPressed: isLoading ? null : () => _addToCart(package, true),
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
      },
    );
  }
} 