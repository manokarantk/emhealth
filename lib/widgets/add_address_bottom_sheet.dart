import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AddAddressBottomSheet {
  static void show({
    required BuildContext context,
    required Function(String?) onAddressAdded,
    Map<String, dynamic>? addressToEdit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AddAddressForm(
        onAddressAdded: onAddressAdded,
        addressToEdit: addressToEdit,
      ),
    );
  }
}

class AddAddressForm extends StatefulWidget {
  final Function(String?) onAddressAdded;
  final Map<String, dynamic>? addressToEdit;

  const AddAddressForm({
    super.key,
    required this.onAddressAdded,
    this.addressToEdit,
  });

  @override
  State<AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _locationService = LocationService();
  final _scrollController = ScrollController();
  
  // Controllers
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  // State
  String? _selectedType;
  bool _isPrimary = false;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  
  final List<String> _addressTypes = ['Home', 'Office', 'Other'];
  
  bool get _isEditMode => widget.addressToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadEditData();
    }
  }

  void _loadEditData() {
    final data = widget.addressToEdit!;
    _selectedType = data['type'] ?? 'Home';
    _nameController.text = data['name'] ?? data['full_name'] ?? '';
    _address1Controller.text = data['address_line1'] ?? data['address'] ?? '';
    _address2Controller.text = data['address_line2'] ?? '';
    _cityController.text = data['city'] ?? '';
    _stateController.text = data['state'] ?? '';
    _pincodeController.text = data['pincode'] ?? '';
    _isPrimary = data['is_primary'] == true || data['isDefault'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getLocation() async {
    setState(() => _isLocationLoading = true);
    
    try {
      final result = await _locationService.getCurrentLocation(context);
      if (result['success'] && mounted) {
        final pos = result['data'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location: ${pos['latitude']}, ${pos['longitude']}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    
    if (mounted) setState(() => _isLocationLoading = false);
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = _isEditMode
          ? await _apiService.updateAddress(
              addressId: widget.addressToEdit!['id'],
              type: _selectedType!,
              name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
              addressLine1: _address1Controller.text.trim(),
              addressLine2: _address2Controller.text.trim().isEmpty ? null : _address2Controller.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              pincode: _pincodeController.text.trim(),
              isPrimary: _isPrimary,
              context: context,
            )
          : await _apiService.addAddress(
              type: _selectedType!,
              name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
              addressLine1: _address1Controller.text.trim(),
              addressLine2: _address2Controller.text.trim().isEmpty ? null : _address2Controller.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              pincode: _pincodeController.text.trim(),
              isPrimary: _isPrimary,
              context: context,
            );

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Address updated!' : 'Address added!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        // Pass the address ID from the API response
        final addressId = result['data']?['id']?.toString();
        print('🔄 AddAddressBottomSheet: New address ID from API: $addressId');
        widget.onAddressAdded(addressId);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: required
          ? (value) => value?.trim().isEmpty == true ? 'This field is required' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
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
                  _isEditMode ? 'Edit Address' : 'Add Address',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                      ? MediaQuery.of(context).viewInsets.bottom + 20 
                      : 20,
                ),
                child: Column(
                  children: [
                    // Location button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLocationLoading ? null : _getLocation,
                        icon: _isLocationLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(_isLocationLoading ? 'Getting Location...' : 'Use Current Location'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Address type
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Address Type *',
                        prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryBlue),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _addressTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedType = value),
                      validator: (value) => value == null ? 'Please select address type' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    
                    // Address Line 1
                    _buildTextField(
                      controller: _address1Controller,
                      label: 'Address Line 1',
                      icon: Icons.home,
                      required: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    
                    // Address Line 2
                    _buildTextField(
                      controller: _address2Controller,
                      label: 'Address Line 2',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    
                    // City
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // State
                    _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map,
                      required: true,
                      onTap: _scrollToBottom,
                    ),
                    const SizedBox(height: 16),
                    
                    // Pincode
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      icon: Icons.pin_drop,
                      required: true,
                      keyboardType: TextInputType.number,
                      onTap: _scrollToBottom,
                    ),
                    const SizedBox(height: 16),
                    
                    // Primary checkbox
                    CheckboxListTile(
                      value: _isPrimary,
                      onChanged: (value) => setState(() => _isPrimary = value ?? false),
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
          ),
          
          // Buttons
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primaryBlue),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.primaryBlue)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Saving...', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : Text(_isEditMode ? 'Update' : 'Add Address'),
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