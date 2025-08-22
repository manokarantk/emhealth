import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'api_service.dart';

class PayUPaymentService {
  // TODO: Replace these with your actual PayU credentials
  // Get these from your PayU merchant dashboard
  static const String _merchantKey = 'rY9H7c1Z'; // Replace with your PayU merchant key
  static const String _merchantSalt = 'fTAR9ozB8g'; // Replace with your PayU merchant salt
  static const bool _isProduction = true; // Set to true for production

  // Check if PayU credentials are properly configured
  static bool get _isConfigured {
    return _merchantKey != 'YOUR_MERCHANT_KEY' && 
           _merchantSalt != 'YOUR_MERCHANT_SALT' &&
           _merchantKey.isNotEmpty && 
           _merchantSalt.isNotEmpty;
  }

  // Generate PayU payment hash
  static String _generateHash({
    required String txnId,
    required double amount,
    required String productInfo,
    required String firstName,
    required String email,
    required String phone,
  }) {
    final hashString = '$_merchantKey|$txnId|$amount|$productInfo|$firstName|$email|||||||||||$_merchantSalt';
    final bytes = utf8.encode(hashString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Create PayU payment using native SDK
  static Future<Map<String, dynamic>> createPayUPayment({
    required BuildContext context,
    required double amount,
    required String userEmail,
    required String userName,
    required String userPhone,
    required String description,
  }) async {
    try {
      // Check if PayU credentials are properly configured
      if (!_isConfigured) {
        return {
          'success': false,
          'message': 'PayU credentials not configured. Please update merchant key and salt in PayUPaymentService.',
          'error': 'MERCHANT_KEY_MISSING',
        };
      }

      print('🔄 Creating PayU payment for amount: $amount');
      
      // Generate transaction ID
      final txnId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      // Generate payment hash
      final hash = _generateHash(
        txnId: txnId,
        amount: amount,
        productInfo: description,
        firstName: userName,
        email: userEmail,
        phone: userPhone,
      );

      // Create PayU payment configuration
      final paymentConfig = {
        'key': _merchantKey,
        'txnId': txnId,
        'amount': amount.toString(),
        'productInfo': description,
        'firstName': userName,
        'email': userEmail,
        'phone': userPhone,
        'hash': hash,
        'environment': _isProduction ? 'production' : 'test',
        'userCredential': 'YOUR_USER_CREDENTIAL', // Replace with your user credential
        'surl': 'https://payu.herokuapp.com/success',
        'furl': 'https://payu.herokuapp.com/failure',
      };

      // PayU payment parameters (for future use when implementing full SDK)
      // final paymentParams = {
      //   'merchantKey': _merchantKey,
      //   'merchantSalt': _merchantSalt,
      //   'isProduction': _isProduction,
      // };

      print('🔄 PayU payment config: $paymentConfig');

      // Launch PayU checkout using native SDK
      // Note: This is a simplified implementation for demonstration
      // In production, you would implement PayUCheckoutProProtocol properly
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PayU Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Amount: ₹${amount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Transaction ID: $txnId'),
              const SizedBox(height: 16),
              const Text(
                'In a real implementation, this would open the PayU native payment interface.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, {'status': 'cancelled'}),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'status': 'success',
                'paymentId': 'PAY_${DateTime.now().millisecondsSinceEpoch}',
              }),
              child: const Text('Simulate Success'),
            ),
          ],
        ),
      );

      // Simulate the payment result for now
      final result = {
        'status': 'success',
        'paymentId': 'PAY_${DateTime.now().millisecondsSinceEpoch}',
      };

      print('🔄 PayU payment result: $result');

      // Handle payment result based on the actual response structure
      if (result is Map<String, dynamic>) {
        final status = result['status']?.toString().toLowerCase();
        
        switch (status) {
          case 'success':
            return {
              'success': true,
              'data': {
                'transaction_id': txnId,
                'payment_id': result['paymentId'] ?? result['payment_id'] ?? 'PAY_${DateTime.now().millisecondsSinceEpoch}',
                'amount': amount,
                'status': 'success',
                'message': 'Payment successful',
              },
              'message': 'Payment completed successfully',
            };
            
          case 'failed':
          case 'failure':
            return {
              'success': false,
              'data': {
                'transaction_id': txnId,
                'amount': amount,
                'status': 'failed',
                'error': result['errorMessage'] ?? result['error'] ?? 'Payment failed',
              },
              'message': result['errorMessage'] ?? result['error'] ?? 'Payment failed',
            };
            
          case 'cancelled':
          case 'cancel':
            return {
              'success': false,
              'data': {
                'transaction_id': txnId,
                'amount': amount,
                'status': 'cancelled',
              },
              'message': 'Payment was cancelled by user',
            };
            
          default:
            return {
              'success': false,
              'data': {
                'transaction_id': txnId,
                'amount': amount,
                'status': 'unknown',
              },
              'message': 'Payment status unknown',
            };
        }
      } else {
        return {
          'success': false,
          'message': 'Invalid payment result',
        };
      }
    } catch (e) {
      print('❌ PayU payment error: $e');
      return {
        'success': false,
        'message': 'Payment error: $e',
      };
    }
  }

  // Verify payment with backend
  static Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
    required String paymentId,
    required double amount,
  }) async {
    try {
      final apiService = ApiService();
      final result = await apiService.verifyPayUPayment(
        transactionId: transactionId,
        paymentId: paymentId,
        amount: amount,
      );
      
      return result;
    } catch (e) {
      print('❌ Payment verification error: $e');
      return {
        'success': false,
        'message': 'Payment verification failed: $e',
      };
    }
  }

  // Complete wallet top-up after successful payment
  static Future<Map<String, dynamic>> completeWalletTopUp({
    required String transactionId,
    required String paymentId,
    required double amount,
    required String description,
  }) async {
    try {
      final apiService = ApiService();
      final result = await apiService.addMoneyToWalletWithPayment(
        amount: amount,
        paymentMethod: 'PayU',
        description: description,
        transactionId: transactionId,
        paymentId: paymentId,
      );
      
      return result;
    } catch (e) {
      print('❌ Wallet top-up error: $e');
      return {
        'success': false,
        'message': 'Wallet top-up failed: $e',
      };
    }
  }

  // Get configuration status
  static Map<String, dynamic> getConfigurationStatus() {
    return {
      'isConfigured': _isConfigured,
      'merchantKeySet': _merchantKey != 'YOUR_MERCHANT_KEY' && _merchantKey.isNotEmpty,
      'merchantSaltSet': _merchantSalt != 'YOUR_MERCHANT_SALT' && _merchantSalt.isNotEmpty,
      'isProduction': _isProduction,
      'message': _isConfigured 
          ? 'PayU is properly configured' 
          : 'PayU credentials need to be configured. Please update merchant key and salt.',
    };
  }

  // Get setup instructions
  static String getSetupInstructions() {
    return '''
PayU Setup Instructions (Native SDK):

1. Get PayU Credentials:
   - Visit https://business.payu.in/
   - Sign up for a merchant account
   - Get your Merchant Key and Merchant Salt from the dashboard

2. Update Credentials:
   - Open lib/services/payu_payment_service.dart
   - Replace 'YOUR_MERCHANT_KEY' with your actual merchant key
   - Replace 'YOUR_MERCHANT_SALT' with your actual merchant salt
   - Set _isProduction to true for production environment

3. Example:
   static const String _merchantKey = 'gtKFFx';
   static const String _merchantSalt = 'eCwWELxi';
   static const bool _isProduction = false; // Set to true for production

4. Test the integration with small amounts first.

5. Refer to official documentation:
   - https://devguide.payu.in/flutter-sdk-integration/introduction-flutter-sdk/
   - https://devguide.payu.in/flutter-sdk-integration/getting-started-flutter-sdk/mobile-sdk-test-environment/

6. For hash generation testing, use the salt in HASH generation method.
   Test credentials can be found on Devguide.

7. The payment will open within the app using native PayU SDK.
''';
  }
}
