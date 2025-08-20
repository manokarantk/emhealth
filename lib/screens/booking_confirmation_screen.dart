import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'landing_page.dart';
import 'order_detail_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String? appointmentId;
  final Map<String, dynamic>? multiLabData;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingData,
    this.appointmentId,
    this.multiLabData,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? appointmentDetails;
  bool isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _loadAppointmentDetails();
    }
  }

  Future<void> _loadAppointmentDetails() async {
    if (widget.appointmentId == null) return;

    setState(() {
      isLoadingDetails = true;
    });

    try {
      final result = await _apiService.getAppointmentDetails(
        appointmentId: widget.appointmentId!,
        context: context,
      );

      if (result['success'] && mounted) {
        setState(() {
          appointmentDetails = result['data']['appointment'];
          isLoadingDetails = false;
        });
      } else {
        setState(() {
          isLoadingDetails = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Booking Confirmation',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Animation and Message
            _buildSuccessSection(),
            const SizedBox(height: 30),
            
            // Booking Summary
            _buildBookingSummary(),
            const SizedBox(height: 30),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          
          // Success Title
          const Text(
            'Booking Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          
          // Success Message
          Text(
                              'Your appointment has been booked successfully. You will receive a confirmation email shortly.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          
          // Booking ID
          if (widget.appointmentId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Booking ID: ${widget.appointmentId}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Patient Information
          if (widget.bookingData['patient'] != null) ...[
            _buildInfoRow('Patient', widget.bookingData['patient']['name'] ?? 'N/A'),
            const SizedBox(height: 8),
          ],
          
          // Total Amount
          if (widget.bookingData['total_amount'] != null) ...[
            _buildInfoRow('Total Amount', '₹${widget.bookingData['total_amount']}'),
            const SizedBox(height: 8),
          ],
          
          // Payment Method
          if (widget.bookingData['payment_method'] != null) ...[
            _buildInfoRow('Payment Method', widget.bookingData['payment_method']),
            const SizedBox(height: 8),
          ],
          
          // Number of Labs
          if (widget.multiLabData != null && widget.multiLabData!['labs'] != null) ...[
            _buildInfoRow('Number of Labs', _getLabCount().toString()),
            const SizedBox(height: 8),
          ],
          
          // Booking Date
          _buildInfoRow('Booking Date', _formatDateTime(DateTime.now())),
          const SizedBox(height: 8),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Confirmed',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    // Convert to 12-hour format
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$day $month $year ${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  int _getLabCount() {
    try {
      final labsData = widget.multiLabData!['labs'];
      if (labsData is List) {
        return labsData.length;
      } else if (labsData is Map) {
        return labsData.length;
      } else if (labsData is String) {
        // If it's a string, try to parse it as JSON or return 1 as fallback
        return 1;
      } else {
        return 0;
      }
    } catch (e) {
      print('❌ Error getting lab count: $e');
      return 0;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Order Details Button
        if (widget.appointmentId != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailScreen.withAppointmentId(
                      appointmentId: widget.appointmentId!,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Order Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Back to Home Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LandingPage(),
                ),
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
