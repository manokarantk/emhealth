import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AddAddressBottomSheet {
  static void show({
    required BuildContext context,
    required VoidCallback onAddressAdded,
    Map<String, dynamic>? addressToEdit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AddAddressForm(
          onAddressAdded: onAddressAdded,
          addressToEdit: addressToEdit,
        );
      },
    );
  }
}

class _AddAddressForm extends StatefulWidget {
  final VoidCallback onAddressAdded;
  final Map<String, dynamic>? addressToEdit;

  const _AddAddressForm({
    required this.onAddressAdded,
    this.addressToEdit,
  });

  @override
  State<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<_AddAddressForm> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  
  // Form controllers
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  
  bool _isPrimary = false;
  bool _isAddingAddress = false;
  bool _isLoadingLocation = false;
  
  String? _selectedAddressType;
  
  // Predefined address types
  final List<String> _addressTypes = [
    'Home',
    'Office',
    'Other',
  ];

  // Check if in edit mode
  bool get _isEditMode => widget.addressToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateEditData();
    }
  }

  void _populateEditData() {
    final address = widget.addressToEdit!;
    final addressType = address['type'] ?? '';
    // Only set selected type if it exists in our predefined list
    _selectedAddressType = _addressTypes.contains(addressType) ? addressType : null;
    _typeController.text = addressType;
    _nameController.text = address['name'] ?? address['full_name'] ?? '';
    _addressLine1Controller.text = address['address_line1'] ?? address['address'] ?? '';
    _addressLine2Controller.text = address['address_line2'] ?? '';
    _cityController.text = address['city'] ?? '';
    _stateController.text = address['state'] ?? '';
    _pincodeController.text = address['pincode'] ?? '';
    _isPrimary = address['is_primary'] == true || address['isDefault'] == true;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final result = await _locationService.getCurrentLocation(context);

      if (result['success']) {
        final position = result['data'];
        final latitude = position['latitude'];
        final longitude = position['longitude'];

        // For now, just show the coordinates and let user manually enter address
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location detected: $latitude, $longitude\nPlease enter address details manually.'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to get current location');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _submitAddress() async {
    // Validation
    if (_selectedAddressType == null || _selectedAddressType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select address type')),
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

    if (_pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pincode')),
      );
      return;
    }

    setState(() {
      _isAddingAddress = true;
    });

    try {
      final Map<String, dynamic> result;
      
      if (_isEditMode) {
        // Update existing address
        result = await _apiService.updateAddress(
          addressId: widget.addressToEdit!['id'],
          type: _selectedAddressType!,
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim().isNotEmpty ? _addressLine2Controller.text.trim() : null,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          isPrimary: _isPrimary,
          context: context,
        );
      } else {
        // Add new address
        result = await _apiService.addAddress(
          type: _selectedAddressType!,
          name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim().isNotEmpty ? _addressLine2Controller.text.trim() : null,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          isPrimary: _isPrimary,
          context: context,
        );
      }

      if (result['success'] == true) {
        // Store context before popping
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        
        // Close the bottom sheet first
        navigator.pop();
        
        // Refresh the list
        widget.onAddressAdded();
        
        // Show success message after a small delay to ensure context is valid
        Future.delayed(const Duration(milliseconds: 100), () {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'Address updated successfully!' : 'Address added successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (_isEditMode ? 'Failed to update address' : 'Failed to add address')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isAddingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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
                  _isEditMode ? 'Edit Address' : 'Add New Address',
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
                  // Current location button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation 
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(_isLoadingLocation ? 'Getting Location...' : 'Use Current Location'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Address Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedAddressType,
                    decoration: InputDecoration(
                      labelText: 'Address Type',
                      prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    items: _addressTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAddressType = value;
                        _typeController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Name (Optional)
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name (Optional)',
                      prefixIcon: const Icon(Icons.person, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Address Line 1
                  TextFormField(
                    controller: _addressLine1Controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 1',
                      prefixIcon: const Icon(Icons.home, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  
                  // Address Line 2 (Optional)
                  TextFormField(
                    controller: _addressLine2Controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 2 (Optional)',
                      prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // City
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: const Icon(Icons.location_city, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // State
                  TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: const Icon(Icons.map, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Pincode
                  TextFormField(
                    controller: _pincodeController,
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      prefixIcon: const Icon(Icons.pin_drop, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  

                  
                  // Primary Address Checkbox
                  CheckboxListTile(
                    value: _isPrimary,
                    onChanged: (value) {
                      setState(() {
                        _isPrimary = value ?? false;
                      });
                    },
                    title: const Text('Set as primary address'),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primaryBlue,
                    contentPadding: EdgeInsets.zero,
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
                    onPressed: _isAddingAddress ? null : _submitAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAddingAddress
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditMode ? 'Updating...' : 'Adding...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _isEditMode ? 'Update Address' : 'Add Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}