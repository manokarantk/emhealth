import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String? appointmentId;

  const OrderDetailScreen({
    super.key,
    this.appointmentId,
  });

  // Named constructor for when we have an appointment ID
  const OrderDetailScreen.withAppointmentId({
    super.key,
    required String appointmentId,
  }) : appointmentId = appointmentId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? appointmentData;
  bool isLoading = true;
  String? errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    // Check if appointmentId is available
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) {
      setState(() {
        errorMessage = 'No appointment ID provided';
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final result = await _apiService.getAppointmentDetails(
        appointmentId: widget.appointmentId!,
        context: context,
      );

      if (result['success'] && mounted) {
        setState(() {
          appointmentData = result['data']['appointment'];
          print('📍 appointmentData: $appointmentData');
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load appointment details';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (appointmentData != null) ...[
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                // TODO: Share order details
              },
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) ...[
                  ElevatedButton(
                    onPressed: _loadAppointmentDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (appointmentData == null) {
      return const Center(
        child: Text('No appointment data available'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Appointment Status Header
          _buildAppointmentStatusHeader(),
          
          const SizedBox(height: 20),
          
          // Basic Appointment Information
          _buildAppointmentInfoSection(),
          
          const SizedBox(height: 20),
          
          // Patient Information
          _buildPatientInfoSection(),
          
          const SizedBox(height: 20),
          
          // Tests & Packages
          _buildItemsSection(),
          
          const SizedBox(height: 20),
          
          // Organization Information
          _buildOrganizationSection(),
          
          const SizedBox(height: 20),
          
          // Payment Information
          _buildPaymentSection(),
          
          const SizedBox(height: 20),
          
          // Collection Details
          _buildCollectionSection(),
          
          const SizedBox(height: 100), // Space for bottom actions
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusHeader() {
    final appointment = appointmentData!;
    final status = appointment['status'];
    final payment = appointment['payment'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Appointment ID and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['appointment_alias'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_formatAppointmentDate(appointment['appointment_datetime'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Time: ${_formatAppointmentTime(appointment['appointment_datetime'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status['status_name']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status['status_name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status['status_name']),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(payment['payment_status_name']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      payment['payment_status_name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getPaymentStatusColor(payment['payment_status_name']),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfoSection() {
    final appointment = appointmentData!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Appointment ID', appointment['appointment_alias'] ?? 'N/A'),
          _buildInfoRow('Date & Time', '${_formatAppointmentDate(appointment['appointment_datetime'])} at ${_formatAppointmentTime(appointment['appointment_datetime'])}'),
          _buildInfoRow('Status', appointment['status']['status_name'] ?? 'N/A'),
          if (appointment['notes'] != null && appointment['notes'].toString().isNotEmpty)
            _buildInfoRow('Notes', appointment['notes']),
        ],
      ),
    );
  }

  // Helper method to extract relationship name
  String _getRelationshipName(dynamic relationshipData) {
    print('🔍 Relationship data type: ${relationshipData.runtimeType}');
    print('🔍 Relationship data value: $relationshipData');
    
    if (relationshipData == null) return 'N/A';
    
    // If it's already a string, return it
    if (relationshipData is String) {
      print('✅ Returning string: $relationshipData');
      return relationshipData;
    }
    
    // If it's a Map/JSON object, try different possible field names
    if (relationshipData is Map) {
      // Try common field names for relationship
      String? name = relationshipData['name']?.toString() ?? 
                    relationshipData['title']?.toString() ??
                    relationshipData['label']?.toString() ??
                    relationshipData['value']?.toString();
      
      if (name != null && name.isNotEmpty) {
        print('✅ Extracted name from Map: $name');
        return name;
      }
      
      // If no standard field found, try to find any string value
      for (var key in relationshipData.keys) {
        var value = relationshipData[key];
        if (value is String && value.isNotEmpty) {
          print('✅ Found string value "$value" for key "$key"');
          return value;
        }
      }
    }
    
    // If it's any other type, convert to string but clean it up
    String result = relationshipData.toString();
    
    // Remove common JSON artifacts
    result = result.replaceAll(RegExp(r'[{}\"]'), '');
    result = result.replaceAll(':', ': ');
    result = result.replaceAll(',', ', ');
    
    print('⚠️ Converting to string: $result');
    return result.isNotEmpty ? result : 'N/A';
  }

  // Helper method to calculate age from date of birth
  String _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty || dobString == 'N/A') {
      return 'N/A';
    }
    
    try {
      DateTime? dob;
      
      // Try different date formats
      List<String> formats = [
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy/MM/dd',
      ];
      
      for (String format in formats) {
        try {
          if (format == 'yyyy-MM-dd') {
            dob = DateTime.parse(dobString);
          } else if (format == 'dd-MM-yyyy') {
            List<String> parts = dobString.split('-');
            if (parts.length == 3) {
              dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            }
          } else if (format == 'MM-dd-yyyy') {
            List<String> parts = dobString.split('-');
            if (parts.length == 3) {
              dob = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
            }
          } else if (format == 'dd/MM/yyyy') {
            List<String> parts = dobString.split('/');
            if (parts.length == 3) {
              dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            }
          } else if (format == 'MM/dd/yyyy') {
            List<String> parts = dobString.split('/');
            if (parts.length == 3) {
              dob = DateTime(int.parse(parts[2]), int.parse(parts[0]), int.parse(parts[1]));
            }
          } else if (format == 'yyyy/MM/dd') {
            List<String> parts = dobString.split('/');
            if (parts.length == 3) {
              dob = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          }
          
          if (dob != null) break;
        } catch (e) {
          // Continue to next format
          continue;
        }
      }
      
      if (dob == null) {
        print('⚠️ Could not parse DOB: $dobString');
        return 'N/A';
      }
      
      // Calculate age
      DateTime now = DateTime.now();
      int age = now.year - dob.year;
      
      // Check if birthday has occurred this year
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      
      return '$age years';
    } catch (e) {
      print('❌ Error calculating age from DOB: $dobString, Error: $e');
      return 'N/A';
    }
  }

  Widget _buildPatientInfoSection() {
    final patient = appointmentData!['patient'];
    print('👤 Full patient data: $patient');
    print('🔗 Patient relationship field: ${patient['relationship']}');
    print('📅 Patient DOB field: ${patient['dob']}');
    print('📅 Patient date_of_birth field: ${patient['date_of_birth']}');
    print('📅 Patient dateOfBirth field: ${patient['dateOfBirth']}');
    print('📅 Patient birth_date field: ${patient['birth_date']}');
    print('📅 Patient birthDate field: ${patient['birthDate']}');
    
    final dobValue = patient['dob'] ?? patient['date_of_birth'] ?? patient['dateOfBirth'] ?? patient['birth_date'] ?? patient['birthDate'];
    print('🎯 Final DOB value being used: $dobValue');
    print('🎂 Calculated age: ${_calculateAge(dobValue)}');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
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
                      patient['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _getRelationshipName(patient['relationship']),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Phone', patient['phone'] ?? 'N/A'),
          _buildInfoRow('Email', patient['email'] ?? 'N/A'),
          _buildInfoRow('Age', _calculateAge(patient['dob'] ?? patient['date_of_birth'] ?? patient['dateOfBirth'] ?? patient['birth_date'] ?? patient['birthDate'])),
          _buildInfoRow('Gender', patient['gender'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final items = appointmentData!['items'];
    final tests = List<Map<String, dynamic>>.from(items['tests'] ?? []);
    final packages = List<Map<String, dynamic>>.from(items['packages'] ?? []);
    final totalItems = items['total_items'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tests & Packages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$totalItems items',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tests
          if (tests.isNotEmpty) ...[
            const Text(
              'Individual Tests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...tests.map((test) => _buildTestItem(test, isPackage: false)),
            const SizedBox(height: 16),
          ],
          
          // Packages
          if (packages.isNotEmpty) ...[
            const Text(
              'Packages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...packages.map((package) => _buildTestItem(package, isPackage: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildTestItem(Map<String, dynamic> item, {bool isPackage = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPackage 
                    ? Colors.purple.withOpacity(0.1) 
                    : AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPackage ? Icons.inventory_2 : Icons.science,
                  color: isPackage ? Colors.purple : AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['test_name'] ?? item['package_name'] ?? 'Test/Package',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (item['test_code'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${item['test_code']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quantity display
                  if (item['quantity'] != null && item['quantity'] > 1) ...[
                    Text(
                      'Qty: ${item['quantity']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  
                  // Price display with discount information
                  _buildItemPricing(item),
                  
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getItemStatusColor(item['status_name']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status_name'] ?? 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getItemStatusColor(item['status_name']),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item['comments'] != null && item['comments'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['comments'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item['report_url'] != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open report URL
                },
                icon: const Icon(Icons.file_download, size: 16),
                label: const Text('Download Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganizationSection() {
    final organization = appointmentData!['organization'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: organization['logo'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        organization['logo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.local_hospital,
                          color: AppColors.primaryBlue,
                          size: 30,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.local_hospital,
                      color: AppColors.primaryBlue,
                      size: 30,
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (organization['member_since'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${_formatDate(organization['member_since'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (organization['address_details'] != null && organization['address_details']['address_line1'] != null && organization['address_details']['address_line1'].toString().isNotEmpty)
            _buildInfoRow('Address', organization['address_details']['address_line1']),
          if (organization['address_details'] != null && organization['address_details']['address_line2'] != null && organization['address_details']['address_line2'].toString().isNotEmpty)
            _buildInfoRow('Address', organization['address_details']['address_line2']),
          if (organization['address_details'] != null && organization['address_details']['city'] != null && organization['address_details']['city'].toString().isNotEmpty)
            _buildInfoRow('City', organization['address_details']['city']),
          if (organization['address_details'] != null && organization['address_details']['state'] != null && organization['address_details']['state'].toString().isNotEmpty)
            _buildInfoRow('State', organization['address_details']['state']),
          if (organization['address_details'] != null && organization['address_details']['pincode'] != null && organization['address_details']['pincode'].toString().isNotEmpty)
            _buildInfoRow('Pincode', organization['address_details']['pincode']),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final payment = appointmentData!['payment'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Payment Method', payment['payment_mode'] ?? 'N/A'),
          _buildInfoRow('Payment Status', payment['payment_status_name'] ?? 'N/A'),
          if (payment['coupon_code'] != null)
            _buildInfoRow('Coupon Used', payment['coupon_code']),
          
          const SizedBox(height: 16),
          
          // Price Breakdown
          const Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Total Amount', '₹${payment['total_amount']}'),
          if (payment['discount_amount'] != null && payment['discount_amount'] > 0)
            _buildPriceRow('Discount', '-₹${payment['discount_amount']}', isDiscount: true),
          
          // Home Collection Fee
          if (_isHomeCollection() && _getHomeCollectionFee() > 0)
            _buildPriceRow('Home Collection Fee', '₹${_getHomeCollectionFee().toStringAsFixed(0)}'),
          
          _buildPriceRow('Final Amount', '₹${payment['final_amount']}', isTotal: true),
          _buildPriceRow('Paid Amount', '₹${payment['paid_amount']}', isPaid: true),
        ],
      ),
    );
  }

  Widget _buildCollectionSection() {
    final collection = appointmentData!['collection'];
    final isHomeCollection = collection['is_home_collection'] ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHomeCollection ? Icons.home : Icons.local_hospital,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isHomeCollection ? 'Home Collection' : 'Lab Collection',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (isHomeCollection && collection['address'] != null) ...[
            const Text(
              'Collection Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildAddressCard(collection['address']),
          ] else ...[
            const Text(
              'Please visit the lab for sample collection',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address['address_line1'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (address['address_line2'] != null && address['address_line2'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              address['address_line2'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${address['city']}, ${address['state']} - ${address['pincode']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (address['landmark'] != null && address['landmark'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Landmark: ${address['landmark']}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to check if appointment is for home collection
  bool _isHomeCollection() {
    if (appointmentData == null) return false;
    final collection = appointmentData!['collection'];
    return collection['is_home_collection'] ?? false;
  }

  // Helper method to get home collection fee
  double _getHomeCollectionFee() {
    if (appointmentData == null) return 0.0;
    
    
    // Try to get fee from payment data first
    final payment = appointmentData!['payment'];
    print('📍 payment: $payment');
    if (payment != null && payment['home_collection_fee'] != null) {
      return double.tryParse(payment['home_collection_fee'].toString()) ?? 0.0;
    }
    
    // Try to get fee from collection data
    final collection = appointmentData!['collection'];
    if (collection != null && collection['collection_fee'] != null) {
      return double.tryParse(collection['collection_fee'].toString()) ?? 0.0;
    }
    

    
    // Default fallback fee
    return 100.0;
  }

  Widget _buildItemPricing(Map<String, dynamic> item) {
    final currentPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice = double.tryParse(item['original_price']?.toString() ?? item['base_price']?.toString() ?? '0') ?? 0.0;
    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    
    // Calculate if there's a discount
    final hasDiscount = originalPrice > 0 && originalPrice > currentPrice;
    final savings = hasDiscount ? (originalPrice - currentPrice) * quantity : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Current price (main price)
        Text(
          '₹${(currentPrice * quantity).toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        
        // Original price with strikethrough if there's a discount
        if (hasDiscount) ...[
          const SizedBox(height: 2),
          Text(
            '₹${(originalPrice * quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        
        // Savings amount if there's a discount
        if (hasDiscount && savings > 0) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Save ₹${savings.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false, bool isTotal = false, bool isPaid = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal || isPaid ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.green : 
                     isPaid ? Colors.blue :
                     (isTotal ? AppColors.primaryBlue : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.orange;
      case 'scheduled':
        return AppColors.primaryBlue;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getItemStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.primaryBlue;
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatAppointmentDate(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = months[dateTime.month - 1];
      final year = dateTime.year;
      
      return '$day $month $year';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAppointmentTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      
      // Convert to 12-hour format
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      
      return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return 'N/A';
    }
  }
}