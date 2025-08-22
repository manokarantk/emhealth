import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../constants/api_config.dart';
import '../services/token_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _referralCodeController = TextEditingController();
  DateTime? _dob;
  final List<String> _cities = [
    'Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Tiruchirappalli', 'Vellore', 
    'Erode', 'Tiruppur', 'Thoothukkudi', 'Dindigul', 'Thanjavur', 'Kanchipuram', 
    'Nagercoil', 'Kumbakonam', 'Cuddalore', 'Villupuram', 'Krishnagiri', 
    'Namakkal', 'Karur', 'Pudukkottai', 'Sivaganga', 'Ramanathapuram', 
    'Virudhunagar', 'Tirunelveli', 'Theni', 'Ariyalur', 'Perambalur', 
    'Tiruvannamalai', 'Nagapattinam', 'Tiruvarur', 'Other'
  ];
  String? _selectedCity;
  String? _selectedGender;
  final List<String> _genders = ['male', 'female', 'other'];
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Request location permission and get current location immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermissionAndGetLocation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  /// Extract city name from coordinates (simplified)
  String _extractCityFromCoordinates(double latitude, double longitude) {
    // For now, return a default city based on coordinates
    // In a real app, you would use reverse geocoding API
    if (latitude >= 12.9716 && latitude <= 13.0827 && 
        longitude >= 80.2707 && longitude <= 80.2707) {
      return 'Chennai';
    } else if (latitude >= 11.0168 && latitude <= 11.0168 && 
               longitude >= 76.9558 && longitude <= 76.9558) {
      return 'Coimbatore';
    } else if (latitude >= 9.9252 && latitude <= 9.9252 && 
               longitude >= 78.1198 && longitude <= 78.1198) {
      return 'Madurai';
    } else {
      return 'Chennai'; // Default fallback
    }
  }

  /// Request location permission and get current location immediately
  Future<void> _requestLocationPermissionAndGetLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog to enable location services
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location Services Disabled'),
                content: const Text(
                  'Please enable location services to automatically detect your city. You can also manually select your city from the dropdown.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedCity = 'Chennai';
                        _cityController.text = 'Chennai';
                        _isLoadingLocation = false;
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission with explanation
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location Permission Required'),
                content: const Text(
                  'We need access to your location to automatically detect your city and provide better service. This helps us show relevant labs and services near you.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedCity = 'Chennai';
                        _cityController.text = 'Chennai';
                        _isLoadingLocation = false;
                      });
                    },
                    child: const Text('Not Now'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.whileInUse || 
                          permission == LocationPermission.always) {
                        await _getCurrentLocation();
                      } else {
                        setState(() {
                          _selectedCity = 'Chennai';
                          _cityController.text = 'Chennai';
                          _isLoadingLocation = false;
                        });
                      }
                    },
                    child: const Text('Allow'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever, show dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location Permission Denied'),
                content: const Text(
                  'Location permission has been permanently denied. You can manually select your city from the dropdown below.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedCity = 'Chennai';
                        _cityController.text = 'Chennai';
                        _isLoadingLocation = false;
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Permission granted, get current location
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        await _getCurrentLocation();
      }

    } catch (e) {
      print('Error in location permission flow: $e');
      setState(() {
        _selectedCity = 'Chennai';
        _cityController.text = 'Chennai';
        _isLoadingLocation = false;
      });
    }
  }

  /// Get current location and set as default city
  Future<void> _getCurrentLocation() async {
    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Extract city from coordinates
      String cityFromCoordinates = _extractCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedCity = cityFromCoordinates;
        _cityController.text = cityFromCoordinates;
        _isLoadingLocation = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location detected: $cityFromCoordinates'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      print('Error getting location: $e');
      // Set default city on error
      setState(() {
        _selectedCity = 'Chennai';
        _cityController.text = 'Chennai';
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please select your city manually.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryBlue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = ApiService();
        
        // Prepare profile data according to API specification
        final profileData = {
          // Remove invalid profile image URL - let backend handle default
          'name': _nameController.text.trim(),
          'dateofbirth': _dob?.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
          'gender': _selectedGender ?? 'male', // Use selected gender or default
          'location': {
            'latitude': 40.7128, // Default coordinates, you can add location picker if needed
            'longitude': -74.006,
            'address': _selectedCity ?? _cityController.text.trim(),
          },
          // Add referral code if provided
          if (_referralCodeController.text.trim().isNotEmpty)
            'referred_by': _referralCodeController.text.trim(),
        };
        
        final result = await apiService.post(ApiConfig.completeProfile, profileData);
        
        if (result['success']) {
          // Save authentication token if returned
          final responseData = result['data'];
          if (responseData != null && responseData['token'] != null) {
            await TokenService.saveToken(responseData['token']);
            print('DEBUG: Auth token saved after profile completion');
          }
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Profile completed successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Navigate to landing page (homepage) after profile completion
            Navigator.pushReplacementNamed(context, '/landing');
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update profile'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        // Show error message for network issues
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Network error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// Show searchable city selection dialog
  void _showCitySearchDialog() {
    String searchQuery = '';
    List<String> filteredCities = List.from(_cities);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Select Your City',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search TextField
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search cities...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width:2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                          filteredCities = _cities
                              .where((city) => city.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Cities List
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: filteredCities.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No cities found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = filteredCities[index];
                                final isSelected = _selectedCity == city;
                                
                                return ListTile(
                                  title: Text(
                                    city,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected ? AppColors.primaryBlue : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  leading: Icon(
                                    isSelected ? Icons.check_circle : Icons.location_city,
                                    color: isSelected ? AppColors.primaryBlue : Colors.grey,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedCity = city;
                                      if (city != 'Other') {
                                        _cityController.text = city;
                                      } else {
                                        _cityController.text = '';
                                      }
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FB), Color(0xFFD2E5F6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Illustration
                    SizedBox(
                      height: 120,
                      child: Image.asset(
                        'assets/profile_illustration.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.account_circle,
                          size: 100,
                          color: AppColors.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Heading
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Let\'s get to know you!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // DOB
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            prefixIcon: const Icon(Icons.cake),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            hintText: 'Select your date of birth',
                          ),
                          controller: TextEditingController(
                            text: _dob == null ? '' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                          ),
                          validator: (value) {
                            if (_dob == null) {
                              return 'Please select your date of birth';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Gender
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: _genders.map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender[0].toUpperCase() + gender.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Email (optional)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email (optional)',
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // City (searchable dropdown)
                    GestureDetector(
                      onTap: _isLoadingLocation ? null : () => _showCitySearchDialog(),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: _selectedCity ?? (_isLoadingLocation ? 'Getting your location...' : ''),
                          ),
                          decoration: InputDecoration(
                            labelText: 'City',
                            prefixIcon: const Icon(Icons.location_city),
                            suffixIcon: _isLoadingLocation 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.my_location),
                                        onPressed: _getCurrentLocation,
                                        tooltip: 'Use current location',
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          ),
                          validator: (value) {
                            if ((_cityController.text.isEmpty && (_selectedCity == null || _selectedCity == 'Other')) || (_selectedCity == null)) {
                              return 'Please select or enter your city';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    if (_selectedCity == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'Enter your city',
                            prefixIcon: const Icon(Icons.location_on),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          ),
                          validator: (value) {
                            if (_selectedCity == 'Other' && (value == null || value.trim().isEmpty)) {
                              return 'Please enter your city';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Referred By (Referral Code)
                    TextFormField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        labelText: 'Referred By (Optional)',
                        prefixIcon: const Icon(Icons.card_giftcard),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        hintText: 'Enter referral code if you have one',
                      ),
                      validator: (value) {
                        // Referral code is optional, so no validation required
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 