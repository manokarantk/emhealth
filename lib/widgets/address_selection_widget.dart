import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'add_address_bottom_sheet.dart';

class AddressSelectionWidget extends StatefulWidget {
  final String? selectedAddressId;
  final Function(String?) onAddressSelected;
  final bool showTitle;
  
  const AddressSelectionWidget({
    super.key,
    required this.selectedAddressId,
    required this.onAddressSelected,
    this.showTitle = true,
  });

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _addresses = [];
  bool isLoadingAddresses = false;
  String? addressesError;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    print('🔄 Loading addresses...');
    setState(() {
      isLoadingAddresses = true;
      addressesError = null;
    });

    try {
      final result = await _apiService.getUserAddresses(context);
      print('🏠 Addresses API Result: $result');
      
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        print('📋 Addresses data: $data');
        
        // Convert API data to the format expected by the UI
        final List<Map<String, dynamic>> convertedAddresses = [];
        
        for (final address in data) {
          final convertedAddress = {
            'id': address['id'],
            'type': address['type'] ?? 'Home',
            'name': address['name'] ?? address['full_name'],
            'address': '${address['address_line1'] ?? ''}${address['address_line2'] != null && address['address_line2'].toString().isNotEmpty ? ', ${address['address_line2']}' : ''}',
            'city': address['city'] ?? '',
            'state': address['state'] ?? '',
            'pincode': address['pincode'] ?? address['postal_code'] ?? '',
            'isDefault': address['is_primary'] == true,
            'contact_number': address['contact_number'],
            'country': address['country'],
          };
          convertedAddresses.add(convertedAddress);
          print('🏠 Converted address: $convertedAddress');
        }
        
        print('✅ Final converted addresses: $convertedAddresses');
        setState(() {
          _addresses = convertedAddresses;
          isLoadingAddresses = false;
        });
        
        // Auto-select primary address if no address is currently selected
        if (widget.selectedAddressId == null || widget.selectedAddressId!.isEmpty) {
          final primaryAddress = convertedAddresses.firstWhere(
            (address) => address['isDefault'] == true,
            orElse: () => convertedAddresses.isNotEmpty ? convertedAddresses.first : {},
          );
          
          if (primaryAddress.isNotEmpty && primaryAddress['id'] != null) {
            print('🏠 Auto-selecting primary address: ${primaryAddress['id']}');
            widget.onAddressSelected(primaryAddress['id'].toString());
          }
        }
        
        print('✅ Addresses loaded successfully. Count: ${_addresses.length}');
      } else {
        print('❌ Failed to load addresses: ${result['message']}');
        setState(() {
          addressesError = result['message'] ?? 'Failed to load addresses';
          isLoadingAddresses = false;
        });
      }
    } catch (e) {
      print('❌ Error loading addresses: $e');
      setState(() {
        addressesError = 'Network error occurred';
        isLoadingAddresses = false;
      });
    }
  }

  void _showAddAddressBottomSheet() {
    AddAddressBottomSheet.show(
      context: context,
      onAddressAdded: _loadAddresses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          if (widget.showTitle) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          if (isLoadingAddresses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (addressesError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    addressesError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadAddresses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_addresses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Addresses Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your delivery address to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (final address in _addresses)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.selectedAddressId == address['id']?.toString()
                            ? AppColors.primaryBlue
                            : Colors.grey.withOpacity(0.3),
                        width: widget.selectedAddressId == address['id']?.toString() ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: widget.selectedAddressId == address['id']?.toString()
                          ? AppColors.primaryBlue.withOpacity(0.05)
                          : Colors.white,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Radio<String>(
                        value: address['id']?.toString() ?? '',
                        groupValue: widget.selectedAddressId,
                        onChanged: (value) {
                          widget.onAddressSelected(value);
                        },
                        activeColor: AppColors.primaryBlue,
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              address['type']?.toString() ?? 'Address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          if (address['isDefault'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (address['name']?.toString().isNotEmpty == true) ...[
                            Text(
                              address['name'].toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            address['address']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${address['city']?.toString() ?? ''}, ${address['state']?.toString() ?? ''} ${address['pincode']?.toString() ?? ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (address['contact_number']?.toString().isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Contact: ${address['contact_number']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        widget.onAddressSelected(address['id']?.toString());
                      },
                    ),
                  ),
              ],
            ),
              
          const SizedBox(height: 16),
          
          // Add address button
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddAddressBottomSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Address'),
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
        ],
      ),
    );
  }
}