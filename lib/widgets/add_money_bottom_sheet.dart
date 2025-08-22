import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/payu_payment_service.dart';
import '../constants/colors.dart';

class AddMoneyBottomSheet extends StatefulWidget {
  final VoidCallback? onMoneyAdded;

  const AddMoneyBottomSheet({super.key, this.onMoneyAdded});

  @override
  State<AddMoneyBottomSheet> createState() => _AddMoneyBottomSheetState();
}

class _AddMoneyBottomSheetState extends State<AddMoneyBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'UPI';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _paymentMethods = [
    'PayU',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'PayPal',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addMoneyToWallet() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedPaymentMethod == 'PayU') {
        // Handle PayU payment
        await _handlePayUPayment(amount);
      } else {
        // Handle other payment methods
        final apiService = ApiService();
        final result = await apiService.addMoneyToWallet(
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          description: 'Added money to wallet',
        );

        if (result['success'] && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Money added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Close bottom sheet
          Navigator.of(context).pop();
          
          // Callback to refresh wallet data
          widget.onMoneyAdded?.call();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to add money to wallet';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePayUPayment(double amount) async {
    try {
      // Get user profile data for PayU payment
      final apiService = ApiService();
      final profileResult = await apiService.getMobileProfile(context);
      
      if (!profileResult['success']) {
        setState(() {
          _errorMessage = 'Failed to get user profile';
          _isLoading = false;
        });
        return;
      }

      final userProfile = profileResult['data'];
      final userEmail = userProfile['email'] ?? 'user@example.com';
      final userName = userProfile['first_name'] ?? userProfile['name'] ?? 'User';
      final userPhone = userProfile['phone'] ?? '9999999999';

              // Check PayU configuration first
        final configStatus = PayUPaymentService.getConfigurationStatus();
        if (!configStatus['isConfigured']) {
          setState(() {
            _errorMessage = configStatus['message'];
            _isLoading = false;
          });
          
          // Show setup instructions dialog
          _showPayUSetupDialog();
          return;
        }

        // Launch PayU payment
        final paymentResult = await PayUPaymentService.createPayUPayment(
        context: context,
        amount: amount,
        userEmail: userEmail,
        userName: userName,
        userPhone: userPhone,
        description: 'Wallet top-up for EmHealth app',
      );

      if (paymentResult['success'] && mounted) {
        // Verify payment with backend
        final verifyResult = await apiService.verifyPayUPayment(
          transactionId: paymentResult['data']['transaction_id'],
          paymentId: paymentResult['data']['payment_id'],
          amount: amount,
        );

        if (verifyResult['success']) {
          // Complete wallet top-up
          final walletResult = await apiService.addMoneyToWalletWithPayment(
            amount: amount,
            paymentMethod: 'PayU',
            description: 'Added money to wallet via PayU',
            transactionId: paymentResult['data']['transaction_id'],
            paymentId: paymentResult['data']['payment_id'],
          );

          if (walletResult['success'] && mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment successful! Money added to wallet'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Close bottom sheet
            Navigator.of(context).pop();
            
            // Callback to refresh wallet data
            widget.onMoneyAdded?.call();
          } else {
            setState(() {
              _errorMessage = walletResult['message'] ?? 'Failed to add money to wallet';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = verifyResult['message'] ?? 'Payment verification failed';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = paymentResult['message'] ?? 'Payment failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment error: $e';
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Money to Wallet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 20),
            
            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      method,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Add Money Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addMoneyToWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPayUSetupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PayU Setup Required'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PayU payment gateway is not configured. Please follow these steps:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Get PayU Credentials:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('   • Visit https://business.payu.in/'),
                const Text('   • Sign up for a merchant account'),
                const Text('   • Get your Merchant Key and Salt'),
                const SizedBox(height: 8),
                const Text(
                  '2. Update Code:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('   • Open lib/services/payu_integration_service.dart'),
                const Text('   • Replace placeholder values with real credentials'),
                const SizedBox(height: 8),
                const Text(
                  '3. Test:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('   • Test with small amounts first'),
                const Text('   • Verify payment flow'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
} 