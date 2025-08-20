import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class AddFamilyMemberBottomSheet {
  static void show({
    required BuildContext context,
    required VoidCallback onMemberAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AddFamilyMemberForm(onMemberAdded: onMemberAdded);
      },
    );
  }
}

class _AddFamilyMemberForm extends StatefulWidget {
  final VoidCallback onMemberAdded;

  const _AddFamilyMemberForm({required this.onMemberAdded});

  @override
  State<_AddFamilyMemberForm> createState() => _AddFamilyMemberFormState();
}

class _AddFamilyMemberFormState extends State<_AddFamilyMemberForm> {
  final ApiService _apiService = ApiService();
  
  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  
  String? _selectedRelationship;
  String? _selectedGender;
  bool _isAddingMember = false;
  
  // Relationships from API
  List<Map<String, dynamic>> _relationships = [];
  bool _isLoadingRelationships = false;

  @override
  void initState() {
    super.initState();
    _loadRelationships();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadRelationships() async {
    print('🔄 Loading relationships...');
    setState(() {
      _isLoadingRelationships = true;
    });

    try {
      final result = await _apiService.getRelationships(context);
      print('👥 Relationships API Response: $result');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        print('📋 Relationships data: $data');
        setState(() {
          _relationships = data.map((json) => {
            'id': json['id'] is String ? int.tryParse(json['id']) ?? 1 : json['id'], // Ensure ID is int
            'name': json['name']?.toString() ?? '',
          }).toList();
        });
        print('✅ Loaded ${_relationships.length} relationships: $_relationships');
      } else {
        print('❌ Failed to load relationships: ${result['message']}');
      }
    } catch (e) {
      print('💥 Error loading relationships: $e');
    }

    setState(() {
      _isLoadingRelationships = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _addFamilyMember() async {
    // Validation
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter first name')),
      );
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter last name')),
      );
      return;
    }

    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select relationship')),
      );
      return;
    }

    if (_dateOfBirthController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender')),
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
      _isAddingMember = true;
    });

    try {
      print('🔄 Starting to add family member...');
      print('📋 Form data: firstName="${_firstNameController.text.trim()}", lastName="${_lastNameController.text.trim()}", relation="$_selectedRelationship", gender="$_selectedGender", phone="${_contactNumberController.text.trim()}", dob="${_dateOfBirthController.text.trim()}"');
      
      // Find the relationship ID and ensure it's an integer
      int relationshipId = 1; // default
      if (_relationships.isNotEmpty) {
        for (var rel in _relationships) {
          if (rel['name'] == _selectedRelationship) {
            // Ensure the ID is properly converted to int
            if (rel['id'] is int) {
              relationshipId = rel['id'];
            } else if (rel['id'] is String) {
              relationshipId = int.tryParse(rel['id']) ?? 1;
            }
            break;
          }
        }
        print('🔗 Relationship ID mapped: $_selectedRelationship -> $relationshipId (type: ${relationshipId.runtimeType})');
      } else {
        print('⚠️ No relationships loaded, using default ID: $relationshipId');
      }

      final result = await _apiService.addDependent(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        relationshipId: relationshipId, // This is now guaranteed to be an int
        contactNumber: _contactNumberController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
        gender: _selectedGender!,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        context: context,
      );

      print('📊 API Response: $result');

      if (result['success'] == true) {
        print('✅ Family member added successfully');
        
        // Store context before popping
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        
        // Close the bottom sheet first
        navigator.pop();
        
        // Refresh the list
        widget.onMemberAdded();
        
        // Show success message after a small delay to ensure context is valid
        Future.delayed(const Duration(milliseconds: 100), () {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Family member added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        });
      } else {
        print('❌ Failed to add family member: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add family member'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('💥 Exception during add family member: $e');
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
        _isAddingMember = false;
      });
    }
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
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Family Member',
                  style: TextStyle(
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
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
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
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
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
                  DropdownButtonFormField<String>(
                    value: _selectedRelationship,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: _isLoadingRelationships
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : const Icon(Icons.family_restroom, color: AppColors.primaryBlue),
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
                    items: _isLoadingRelationships
                        ? [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Loading relationships...'),
                                ],
                              ),
                            ),
                          ]
                        : _relationships.isEmpty
                            ? [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('No relationships available'),
                                ),
                              ]
                            : _relationships.map((relationship) {
                                return DropdownMenuItem<String>(
                                  value: relationship['name'] as String,
                                  child: Text(relationship['name'] as String),
                                );
                              }).toList(),
                    onChanged: _isLoadingRelationships ? null : (value) {
                      setState(() {
                        _selectedRelationship = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _dateOfBirthController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.cake, color: AppColors.primaryBlue),
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
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue),
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
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _contactNumberController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primaryBlue),
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
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (Optional)',
                      prefixIcon: const Icon(Icons.email, color: AppColors.primaryBlue),
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
                    keyboardType: TextInputType.emailAddress,
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
                    onPressed: _isAddingMember ? null : _addFamilyMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAddingMember
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
                                'Adding...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Add Member',
                            style: TextStyle(
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