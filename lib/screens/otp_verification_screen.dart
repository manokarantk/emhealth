import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int otpLength = 4;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;
  bool _canResendOtp = false;
  int _resendTimer = 30;
  Timer? _timer;
  String _phoneNumber = '';
  String _countryCode = '+91';
  bool _editingPhone = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (index) => TextEditingController());
    _focusNodes = List.generate(otpLength, (index) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is String) {
        final match = RegExp(r'^(\+\d+)(\d{10,})').firstMatch(args);
        if (match != null) {
          setState(() {
            _countryCode = match.group(1)!;
            _phoneNumber = match.group(2)!;
          });
        } else {
          setState(() {
            _phoneNumber = args;
          });
        }
      }
    });
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResendOtp = false;
      _resendTimer = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleOtpInput(String value, int index) {
    if (value.isNotEmpty) {
      if (index < otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  void _handleOtpKey(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  void _verifyOtp() async {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length == otpLength) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = ApiService();
        final phoneNumber = '$_countryCode$_phoneNumber';
        
        final result = await apiService.verifyOtp(phoneNumber, otp);
        
        if (result['success']) {
          // Save authentication token
          final userData = result['data'];
          if (userData != null && userData['token'] != null) {
            await TokenService.saveToken(userData['token']);
            print('DEBUG: Auth token saved successfully');
          }
          
          // Debug: Log user data for navigation decision
          print('DEBUG: User data from OTP verification: $userData');
          print('DEBUG: isNewUser value: ${userData?['isNewUser']}');
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'OTP verified successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Check if user is new and navigate accordingly
            if (userData != null && userData['isNewUser'] == true) {
              // User is new, navigate to profile completion
              print('DEBUG: User is new (isNewUser: true), navigating to profile completion');
        Navigator.pushReplacementNamed(context, '/profile-completion');
            } else {
              // User is existing, navigate to homepage
              print('DEBUG: User is existing (isNewUser: false/null), navigating to homepage');
              Navigator.pushReplacementNamed(context, '/landing');
            }
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Invalid OTP'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Clear OTP fields for retry
            for (var controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
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

  void _resendOtp() async {
    if (_canResendOtp) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final apiService = ApiService();
        final phoneNumber = '$_countryCode$_phoneNumber';
        
        final result = await apiService.requestOtp(phoneNumber);
        
        if (result['success']) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'OTP resent successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Clear OTP fields and start timer
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
            _startResendTimer();
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to resend OTP'),
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

  void _submitPhoneEdit(String phone, String code) {
    setState(() {
      _phoneNumber = phone;
      _countryCode = code;
      _editingPhone = false;
    });
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                SizedBox(
                  height: 160,
                  child: Image.asset(
                    'assets/logo.jpg',
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                // Headings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'OTP Verification',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We have sent a verification code to',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      _editingPhone
                          ? Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                            const SizedBox(width: 4),
                                            const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _phoneNumber,
                                          keyboardType: TextInputType.phone,
                                          decoration: const InputDecoration(
                                            hintText: 'Enter Mobile Number',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(10),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _phoneNumber = value;
                                              _countryCode = '+91';
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    _submitPhoneEdit(_phoneNumber, _countryCode);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_countryCode $_phoneNumber',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: AppColors.primaryBlue,
                                  onPressed: () {
                                    setState(() {
                                      _editingPhone = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // OTP input fields (no card background)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      otpLength,
                      (index) => SizedBox(
                        width: 48,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleOtpKey(event, index),
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.lightGrey,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _handleOtpInput(value, index),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Resend OTP
                Center(
                  child: TextButton(
                    onPressed: _canResendOtp ? _resendOtp : null,
                    child: Text(
                      _canResendOtp
                          ? 'Resend OTP'
                          : 'Resend OTP in $_resendTimer seconds',
                      style: TextStyle(
                        color: _canResendOtp
                            ? AppColors.primaryBlue
                            : AppColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Verify button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Verify',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.verified, size: 22),
                              ],
                            ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 