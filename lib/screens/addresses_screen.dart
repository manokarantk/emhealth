import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;
  String? errorMessage;

  // Form controllers
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();

  bool _isPrimary = true;
  bool _isAddingAddress = false;
  bool _isDeletingAddress = false;
  bool _isEditingAddress = false;

  // Force rebuild counter
  int _rebuildCounter = 0;
  
  // Edit mode variables
  Map<String, dynamic>? _editingAddress;

  /// Test location functionality directly
  Future<void> _testLocationDirectly(BuildContext context) async {
    try {
      print('🧪 Testing location directly...');
      
      // Simple test to check if geolocator is working
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Testing geolocator plugin...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Try to get the last known position first (this might work without permissions)
      try {
        Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          print('🧪 Last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Last known: ${lastKnownPosition.latitude.toStringAsFixed(6)}, ${lastKnownPosition.longitude.toStringAsFixed(6)}'),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }
      } catch (e) {
        print('🧪 Last known position error: $e');
      }
      
      // If no last known position, try to get current position
      print('🧪 Trying to get current position...');
      Position position = await Geolocator.getCurrentPosition();
      print('🧪 Position obtained: ${position.latitude}, ${position.longitude}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Current: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('❌ Location test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Location error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get current location and show it in a toast
  Future<void> _getCurrentLocationAndShowToast() async {
    try {
      // Show loading toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Getting your current location...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Get current location
      final result = await _locationService.getCurrentLocation(context);
      
      // Dismiss loading toast
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success']) {
        final data = result['data'];
        final latitude = data['latitude'];
        final longitude = data['longitude'];
        final accuracy = data['accuracy'];
        
        // Show location in toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📍 Current Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Latitude: ${latitude.toStringAsFixed(6)}'),
                Text('Longitude: ${longitude.toStringAsFixed(6)}'),
                Text('Accuracy: ${accuracy.toStringAsFixed(1)} meters'),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Show error toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading toast and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error getting location: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _apiService.getUserAddresses(context);

      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          addresses = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load addresses';
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

  Future<void> _addAddress() async {
    // Validate form
    if (_typeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter address type')),
      );
      return;
    }

    if (_addressLine1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter address line 1')),
      );
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter city')),
      );
      return;
    }

    if (_stateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter state')),
      );
      return;
    }

    if (_countryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter country')),
      );
      return;
    }

    if (_pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pincode')),
      );
      return;
    }

    if (_contactNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter contact number')),
      );
      return;
    }

    setState(() {
      _isAddingAddress = true;
    });

    try {
      if (_isEditingAddress && _editingAddress != null) {
        // Update existing address
        print('🔄 Edit mode - calling update API...');
        final result = await _apiService.updateAddress(
          addressId: _editingAddress!['id'],
          type: _typeController.text.trim(),
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim().isNotEmpty
              ? _addressLine2Controller.text.trim()
              : null,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          country: _countryController.text.trim(),
          pincode: _pincodeController.text.trim(),
          isPrimary: _isPrimary,
          contactNumber: _contactNumberController.text.trim(),
          context: context,
        );
        
        if (result['success'] == true) {
          Navigator.of(context).pop(); // Close bottom sheet
          _clearForm();
          _loadAddresses(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Add new address
        print('🔄 Add mode - calling add API...');
        final result = await _apiService.addAddress(
          type: _typeController.text.trim(),
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim().isNotEmpty
              ? _addressLine2Controller.text.trim()
              : null,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          country: _countryController.text.trim(),
          pincode: _pincodeController.text.trim(),
          isPrimary: _isPrimary,
          contactNumber: _contactNumberController.text.trim(),
          context: context,
        );
        print("result");
        print(result);
        if (result['success'] == true) {
          Navigator.of(context).pop(); // Close bottom sheet
          _clearForm();
          _loadAddresses(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingAddress = false;
      });
    }
  }

  void _clearForm() {
    _typeController.clear();
    _nameController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _countryController.clear();
    _pincodeController.clear();
    _contactNumberController.clear();
    _isPrimary = false;
  }

  void _showEditAddressDialog(Map<String, dynamic> address) {
    // Set edit mode and populate form with existing data
    setState(() {
      _isEditingAddress = true;
      _editingAddress = address;
    });
    
    // Populate form fields with existing data
    _typeController.text = address['type'] ?? '';
    _nameController.text = address['name'] ?? address['full_name'] ?? '';
    _addressLine1Controller.text = address['address_line1'] ?? address['address'] ?? '';
    _addressLine2Controller.text = address['address_line2'] ?? '';
    _cityController.text = address['city'] ?? '';
    _stateController.text = address['state'] ?? '';
    _countryController.text = address['country'] ?? '';
    _pincodeController.text = address['pincode'] ?? '';
    _contactNumberController.text = address['contact_number'] ?? address['phone'] ?? '';
    _isPrimary = address['is_primary'] == true || address['isDefault'] == true;
    
    _showAddressFormDialog('Edit Address');
  }

  void _showAddAddressDialog() {
    // Reset form for add mode
    setState(() {
      _isEditingAddress = false;
      _editingAddress = null;
    });
    
    _clearForm();
    _showAddressFormDialog('Add New Address');
  }

  void _showAddressFormDialog(String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _typeController.text.isEmpty
                            ? null
                            : _typeController.text,
                        decoration: InputDecoration(
                          labelText: 'Address Type',
                          prefixIcon: const Icon(Icons.home,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Home', child: Text('Home')),
                          DropdownMenuItem(
                              value: 'Office', child: Text('Office')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                          DropdownMenuItem(
                              value: 'registered', child: Text('Registered')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _typeController.text = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _contactNumberController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          prefixIcon: const Icon(Icons.phone,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressLine1Controller,
                        decoration: InputDecoration(
                          labelText: 'Address Line 1',
                          prefixIcon: const Icon(Icons.location_on,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressLine2Controller,
                        decoration: InputDecoration(
                          labelText: 'Address Line 2 (Optional)',
                          prefixIcon: const Icon(Icons.place,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          prefixIcon: const Icon(Icons.location_city,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _stateController,
                        decoration: InputDecoration(
                          labelText: 'State',
                          prefixIcon: const Icon(Icons.map,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: const Icon(Icons.public,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _pincodeController,
                        decoration: InputDecoration(
                          labelText: 'Pincode',
                          prefixIcon: const Icon(Icons.pin_drop,
                              color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.grey, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // Debug widget to show current state
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.yellow.withOpacity(0.3),
                        child: Text(
                          'DEBUG: _isPrimary = $_isPrimary',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        decoration: BoxDecoration(
                          color: _isPrimary
                              ? AppColors.primaryBlue.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPrimary
                                ? AppColors.primaryBlue.withOpacity(0.3)
                                : Colors.grey[200]!,
                            width: _isPrimary ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            print(
                                '🔄 Checkbox container tapped! Current value: $_isPrimary');
                            setState(() {
                              _isPrimary = !_isPrimary;
                              _rebuildCounter++;
                            });
                            print(
                                '🔄 Checkbox state toggled to: $_isPrimary, rebuild: $_rebuildCounter');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isPrimary ?? false,
                                  onChanged: (value) {
                                    print(
                                        '🔄 Checkbox clicked! Current value: $_isPrimary, New value: $value');
                                    setState(() {
                                      _isPrimary = value ?? false;
                                    });
                                    print(
                                        '🔄 Checkbox state updated to: $_isPrimary');
                                  },
                                  activeColor: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set as Primary Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: _isPrimary
                                              ? AppColors.primaryBlue
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isPrimary
                                            ? '✓ This address will be your default delivery address'
                                            : 'This address will be used as your default delivery address',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isPrimary
                                              ? AppColors.primaryBlue
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAddingAddress ? null : _addAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isAddingAddress
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isEditingAddress ? 'Update Address' : 'Add Address'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetDefaultDialog(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set as Default Address'),
          content: Text(
            'Are you sure you want to set "${address['type'] ?? 'Address'} - ${address['address_line1'] ?? address['address'] ?? ''}" as your default address?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Update all addresses to set the selected one as default
                  for (int i = 0; i < addresses.length; i++) {
                    addresses[i]['isDefault'] =
                        addresses[i]['id'] == address['id'];
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${address['type']} address is now your default address')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Set as Default'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAddressDialog(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delete Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${address['type'] ?? 'Address'} - ${address['address_line1'] ?? address['address'] ?? ''}"?',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone and the address will be permanently removed.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAddress(address);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    setState(() {
      _isDeletingAddress = true;
    });

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Deleting Address...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we remove ${address['type'] ?? 'Address'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      print('🗑️ Deleting address: ${address['id']}');
      
      final result = await _apiService.deleteAddress(
        addressId: address['id'],
        context: context,
      );
      
      // Hide loading overlay
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // Refresh the addresses list
        await _loadAddresses();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address['type']} address has been deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete address'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting address: $e');
      // Hide loading overlay
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error occurred. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isDeletingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'My Addresses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _getCurrentLocationAndShowToast,
            tooltip: 'Get Current Location',
          ),
          TextButton(
            onPressed: _showAddAddressDialog,
            child: const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading Addresses...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we fetch your addresses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAddresses,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Addresses Found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your delivery addresses to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAddresses,
                      color: AppColors.primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return _buildAddressCard(address);
                        },
                      ),
                    ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isDefault =
        address['isDefault'] == true || address['is_primary'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              address['type'] ?? 'Address',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              address['address_line1'] ?? address['address'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if ((address['address_line2'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                address['address_line2'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if ((address['contact_number'] ?? address['phone'] ?? '')
                .isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    address['contact_number'] ?? address['phone'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDefault) ...[
              IconButton(
                onPressed: () => _showSetDefaultDialog(address),
                icon: const Icon(
                  Icons.star,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                tooltip: 'Set as default address',
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: () => _showEditAddressDialog(address),
              icon: const Icon(
                Icons.edit,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              tooltip: 'Edit address',
            ),
            if (!isDefault) ...[
              const SizedBox(width: 8),
              _isDeletingAddress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : IconButton(
                      onPressed: () => _showDeleteAddressDialog(address),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'Delete address',
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
