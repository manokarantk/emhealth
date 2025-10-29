import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../constants/colors.dart';
import '../services/api_service.dart';

class AddFamilyMemberBottomSheet {
  static bool _isShowing = false;
  
  static void show({
    required BuildContext context,
    required Function(String?) onMemberAdded,
  }) {
    // Prevent multiple simultaneous calls
    if (_isShowing) return;
    
    _isShowing = true;
    
    // Dismiss keyboard before showing bottom sheet
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      // Android-specific configuration
      elevation: Platform.isAndroid ? 0 : null,
      shape: Platform.isAndroid 
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            )
          : null,
      builder: (BuildContext context) {
        return PopScope(
          canPop: true,
          onPopInvoked: (didPop) {
            if (didPop) {
              _isShowing = false;
            }
          },
          child: _AddFamilyMemberForm(
            key: const ValueKey('add_family_member_form'),
            onMemberAdded: onMemberAdded,
          ),
        );
      },
    ).then((_) {
      // Reset the flag when the bottom sheet is closed
      _isShowing = false;
    }).catchError((error) {
      // Reset flag even if there's an error
      _isShowing = false;
    });
  }
}

class _AddFamilyMemberForm extends StatefulWidget {
  final Function(String?) onMemberAdded;

  const _AddFamilyMemberForm({required this.onMemberAdded, Key? key}) : super(key: key);

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
  
  // Validation error states
  String? _firstNameError;
  String? _lastNameError;
  String? _relationshipError;
  String? _dateOfBirthError;
  String? _genderError;
  String? _contactNumberError;
  String? _emailError;
  
  // Scroll controller for keyboard handling
  final ScrollController _scrollController = ScrollController();
  
  // Focus nodes for better focus management
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  
  // Global key for email field to ensure it's visible
  final GlobalKey _emailFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadRelationships();
    
    // Add focus listeners for automatic scrolling
    _contactFocus.addListener(() {
      if (_contactFocus.hasFocus) {
        _scrollToShowField();
      }
    });
    
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _scrollToShowEmailField();
      }
    });
    
    // Add listener for keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure proper focus handling
        FocusScope.of(context).unfocus();
      }
    });
  }


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _scrollController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _contactFocus.dispose();
    _emailFocus.dispose();
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
        _dateOfBirthError = null; // Clear error when date is selected
      });
    }
  }

  // Clear all validation errors
  void _clearValidationErrors() {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _relationshipError = null;
      _dateOfBirthError = null;
      _genderError = null;
      _contactNumberError = null;
      _emailError = null;
    });
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  // Scroll to show focused field when keyboard appears
  void _scrollToShowField() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients && mounted) {
        // Scroll to show the focused field without going to the very bottom
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetScroll = maxScroll * 0.8; // Scroll to 80% of max to keep some content visible
        
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Special scroll function for email field (bottom field)
  void _scrollToShowEmailField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Try to ensure the email field is visible
        if (_emailFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _emailFieldKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.8, // Position the field at 80% from top of visible area
          );
        } else if (_scrollController.hasClients) {
          // Fallback to scroll to bottom
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _addFamilyMember() async {
    // Clear previous validation errors
    _clearValidationErrors();
    
    bool hasErrors = false;
    
    // Validate First Name
    if (_firstNameController.text.trim().isEmpty) {
      setState(() {
        _firstNameError = 'First name is required';
        hasErrors = true;
      });
    }
    
    // Validate Last Name
    if (_lastNameController.text.trim().isEmpty) {
      setState(() {
        _lastNameError = 'Last name is required';
        hasErrors = true;
      });
    }
    
    // Validate Relationship
    if (_selectedRelationship == null) {
      setState(() {
        _relationshipError = 'Please select a relationship';
        hasErrors = true;
      });
    }
    
    // Validate Date of Birth
    if (_dateOfBirthController.text.trim().isEmpty) {
      setState(() {
        _dateOfBirthError = 'Date of birth is required';
        hasErrors = true;
      });
    }
    
    // Validate Gender
    if (_selectedGender == null) {
      setState(() {
        _genderError = 'Please select gender';
        hasErrors = true;
      });
    }
    
    // Validate Contact Number
    if (_contactNumberController.text.trim().isEmpty) {
      setState(() {
        _contactNumberError = 'Contact number is required';
        hasErrors = true;
      });
    } else if (!_isValidPhoneNumber(_contactNumberController.text.trim())) {
      setState(() {
        _contactNumberError = 'Please enter a valid 10-digit phone number';
        hasErrors = true;
      });
    }
    
    // Validate Email (optional but if provided, should be valid)
    if (_emailController.text.trim().isNotEmpty && !_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = 'Please enter a valid email address';
        hasErrors = true;
      });
    }
    
    // If there are validation errors, don't proceed
    if (hasErrors) {
      // Scroll to the first error field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill in all required fields correctly'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
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
        
        // Construct the family member name and pass it to the callback
        final memberName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        print('🔄 AddFamilyMemberBottomSheet: New family member name: $memberName');
        widget.onMemberAdded(memberName);
        
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Use a fixed height that doesn't change when keyboard appears
    // This prevents the bottom sheet from shrinking when text fields are focused
    final maxHeight = (screenHeight * 0.85).clamp(500.0, screenHeight * 0.85);
    
    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Form content
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                  TextFormField(
                    controller: _firstNameController,
                    focusNode: _firstNameFocus,
                    onChanged: (value) {
                      if (_firstNameError != null) {
                        setState(() {
                          _firstNameError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'First Name *',
                      prefixIcon: const Icon(Icons.person, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _firstNameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _firstNameError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _firstNameError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _firstNameError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _lastNameController,
                    focusNode: _lastNameFocus,
                    onChanged: (value) {
                      if (_lastNameError != null) {
                        setState(() {
                          _lastNameError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Last Name *',
                      prefixIcon: const Icon(Icons.person, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _lastNameError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _lastNameError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _lastNameError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _lastNameError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedRelationship,
                    decoration: InputDecoration(
                      labelText: 'Relationship *',
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
                      errorText: _relationshipError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _relationshipError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _relationshipError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _relationshipError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
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
                        if (_relationshipError != null) {
                          _relationshipError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _dateOfBirthController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth *',
                      prefixIcon: const Icon(Icons.cake, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _dateOfBirthError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _dateOfBirthError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _dateOfBirthError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _dateOfBirthError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _genderError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _genderError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _genderError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _genderError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
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
                        if (_genderError != null) {
                          _genderError = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _contactNumberController,
                    focusNode: _contactFocus,
                    onChanged: (value) {
                      if (_contactNumberError != null) {
                        setState(() {
                          _contactNumberError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Contact Number *',
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _contactNumberError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _contactNumberError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _contactNumberError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _contactNumberError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: _emailFieldKey,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    onTap: _scrollToShowEmailField,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Email (Optional)',
                      prefixIcon: const Icon(Icons.email, color: AppColors.primaryBlue),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: _emailError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.red : Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.red : AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  // Add extra padding at the bottom for better keyboard handling
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 150 : 60),
                    ],
                  ),
                ),
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
      ),
    );
  }
}