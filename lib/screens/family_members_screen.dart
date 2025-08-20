import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../models/dependent.dart';
import '../widgets/add_family_member_bottom_sheet.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final ApiService _apiService = ApiService();
  List<Dependent> familyMembers = [];
  bool isLoading = true;
  String? errorMessage;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  
  String? _selectedRelationship;
  String? _selectedGender;
  bool _isAddingMember = false;
  bool _isDeletingMember = false;
  bool _isEditingMember = false;
  
  // Edit mode variables
  Dependent? _editingMember;
  
  // Relationships from API
  List<Map<String, dynamic>> _relationships = [];
  bool _isLoadingRelationships = false;
  String? _relationshipsError;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
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

  Future<void> _loadFamilyMembers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _apiService.getDependents(context);
      
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          familyMembers = data.map((json) => Dependent.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load family members';
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        errorMessage = 'Network error occurred';
        isLoading = false;
      });
    }
  }

  Future<void> _loadRelationships() async {
    setState(() {
      _isLoadingRelationships = true;
      _relationshipsError = null;
    });

    try {
      final result = await _apiService.getRelationships(context);
      print('👥 Relationships API Response: $result');
      if (result['success']) {
        final List<dynamic> data = result['data']['data'] ?? [];
        setState(() {
          _relationships = data.map((json) => {
            'id': json['id'],
            'name': json['name'],
          }).toList();
          _isLoadingRelationships = false;
        });
        print('👥 Loaded ${_relationships.length} relationships from API');
      } else {
        setState(() {
          _relationshipsError = result['message'] ?? 'Failed to load relationships';
          _isLoadingRelationships = false;
        });
      }
    } catch (e) {
      print('❌ Error loading relationships: $e');
      setState(() {
        _relationshipsError = 'Network error occurred';
        _isLoadingRelationships = false;
      });
    }
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
    print('🔄 _addFamilyMember called');
    
    // Validate form
    if (_firstNameController.text.trim().isEmpty) {
      print('❌ Validation failed: First name is empty');
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
      print('❌ Validation failed: Relationship is not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select relationship')),
      );
      return;
    }

    if (_contactNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter contact number')),
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

    setState(() {
      _isAddingMember = true;
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
                  Text(
                    _isEditingMember ? 'Updating Family Member...' : 'Adding Family Member...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditingMember 
                        ? 'Please wait while we update the information'
                        : 'Please wait while we save the information',
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
      print('🔄 Starting API call...');
      print('🔄 Form data:');
      print('  - First Name: ${_firstNameController.text.trim()}');
      print('  - Last Name: ${_lastNameController.text.trim()}');
      print('  - Relationship: $_selectedRelationship');
      print('  - Contact: ${_contactNumberController.text.trim()}');
      print('  - DOB: ${_dateOfBirthController.text.trim()}');
      print('  - Gender: $_selectedGender');
      print('  - Email: ${_emailController.text.trim()}');
      
      // Map relationship name to ID (you may need to adjust this based on your API)
      final relationshipId = _getRelationshipId(_selectedRelationship!);
      print('🔄 Relationship ID123: $relationshipId');
     
      if (_isEditingMember && _editingMember != null) {
        print('🔄 Edit mode - calling update API...');
        final result = await _apiService.updateDependent(
          dependentId: _editingMember!.id,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          relationshipId: relationshipId,
          contactNumber: _contactNumberController.text.trim(),
          dateOfBirth: _dateOfBirthController.text.trim(),
          gender: _selectedGender!,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          context: context,
        );
        print('✏️ Update Dependent API Response: $result');
        
        // Hide loading overlay
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          Navigator.of(context).pop(); // Close bottom sheet
          _clearForm();
          _loadFamilyMembers(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Family member updated successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update family member'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      } else {
        print('🔄 Add mode - calling addDependent API...');
        final result = await _apiService.addDependent(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          relationshipId: relationshipId,
          contactNumber: _contactNumberController.text.trim(),
          dateOfBirth: _dateOfBirthController.text.trim(),
          gender: _selectedGender!,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          context: context,
        );
        print('👥 Add Dependent API Response: $result');
        
        // Hide loading overlay
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          Navigator.of(context).pop(); // Close bottom sheet
          _clearForm();
          _loadFamilyMembers(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Family member added successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add family member'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _addFamilyMember: $e');
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
        _isAddingMember = false;
      });
    }
  }

  int _getRelationshipId(String relationshipName) {
    print('🔄 _getRelationshipId called with: $relationshipName');
    print('🔄 Available relationships: $_relationships');
    
    // Find the relationship by name in the API data
    final relationship = _relationships.firstWhere(
      (rel) => rel['name'] == relationshipName,
      orElse: () => {'id': 1, 'name': 'Other'}, // Default fallback
    );
    print('🔄 Found relationship: $relationship');
    return int.tryParse(relationship['id'].toString()) ?? 1;
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _contactNumberController.clear();
    _emailController.clear();
    _dateOfBirthController.clear();
    _selectedRelationship = null;
    _selectedGender = null;
  }

  void _showEditMemberDialog(Dependent member) {
    // Set edit mode and populate form with existing data
    setState(() {
      _isEditingMember = true;
      _editingMember = member;
    });
    
    // Populate form fields with existing data
    _firstNameController.text = member.firstName;
    _lastNameController.text = member.lastName;
    _contactNumberController.text = member.contactNumber;
    _emailController.text = member.email;
    _dateOfBirthController.text = member.dateOfBirth;
    _selectedRelationship = member.relationship.name;
    _selectedGender = member.gender;
    
    _showMemberFormDialog('Edit Family Member');
  }

  void _showAddMemberDialog() {
    // Reset form for add mode
    setState(() {
      _isEditingMember = false;
      _editingMember = null;
    });
    
    _clearForm();
    AddFamilyMemberBottomSheet.show(
      context: context,
      onMemberAdded: _loadFamilyMembers,
    );
  }

  void _showMemberFormDialog(String title) {
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
                                    _isEditingMember ? 'Updating...' : 'Adding...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _isEditingMember ? 'Update Member' : 'Add Member',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Family Members',
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _isLoadingRelationships ? null : _showAddMemberDialog,
            tooltip: _isLoadingRelationships ? 'Loading relationships...' : 'Add family member',
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
                    'Loading Family Members...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we fetch your family members',
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
                        onPressed: _loadFamilyMembers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : familyMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Family Members',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your family members to get started',
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
                      onRefresh: _loadFamilyMembers,
                      color: AppColors.primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: familyMembers.length,
                        itemBuilder: (context, index) {
                          final member = familyMembers[index];
                          return _buildMemberCard(member);
                        },
                      ),
                    ),
    );
  }

  Widget _buildMemberCard(Dependent member) {
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
            Expanded(
              child: Text(
                member.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${member.relationship.name} • ${member.age} years • ${member.gender}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (member.contactNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      member.contactNumber,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (member.email.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      member.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _isDeletingMember
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showEditMemberDialog(member),
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    tooltip: 'Edit family member',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDeleteDialog(member),
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Delete family member',
                  ),
                ],
              ),
      ),
    );
  }

  void _showDeleteDialog(Dependent member) {
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
                'Delete Family Member',
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
                'Are you sure you want to delete "${member.fullName}"?',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone and all associated data will be permanently removed.',
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
                await _deleteFamilyMember(member);
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

  Future<void> _deleteFamilyMember(Dependent member) async {
    setState(() {
      _isDeletingMember = true;
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
                    'Deleting Family Member...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we remove ${member.fullName}',
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
      print('🗑️ Deleting family member: ${member.id}');
      
      final result = await _apiService.deleteDependent(
        dependentId: member.id,
        context: context,
      );
      
      // Hide loading overlay
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        // Refresh the family members list
        await _loadFamilyMembers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} has been deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete family member'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting family member: $e');
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
        _isDeletingMember = false;
      });
    }
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'Male':
        return Icons.male;
      case 'Female':
        return Icons.female;
      default:
        return Icons.person;
    }
  }
} 