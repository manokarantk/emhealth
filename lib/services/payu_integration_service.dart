import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class PayUIntegrationService {
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

  // Create PayU payment URL
  static String _createPayUUrl({
    required String txnId,
    required double amount,
    required String productInfo,
    required String firstName,
    required String email,
    required String phone,
  }) {
    final hash = _generateHash(
      txnId: txnId,
      amount: amount,
      productInfo: productInfo,
      firstName: firstName,
      email: email,
      phone: phone,
    );

    final baseUrl = _isProduction 
        ? 'https://secure.payu.in/_payment'
        : 'https://test.payu.in/_payment';

    final params = {
      'key': _merchantKey,
      'txnid': txnId,
      'amount': amount.toString(),
      'productinfo': productInfo,
      'firstname': firstName,
      'email': email,
      'phone': phone,
      'hash': hash,
      'surl': 'https://payu.herokuapp.com/success',
      'furl': 'https://payu.herokuapp.com/failure',
      'service_provider': 'payu_paisa',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  // Launch PayU payment
  static Future<Map<String, dynamic>> launchPayUPayment({
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
          'message': 'PayU credentials not configured. Please update merchant key and salt in PayUIntegrationService.',
          'error': 'MERCHANT_KEY_MISSING',
        };
      }

      print('🔄 Launching PayU payment for amount: $amount');
      
      // Generate transaction ID
      final txnId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create PayU URL
      final payuUrl = _createPayUUrl(
        txnId: txnId,
        amount: amount,
        productInfo: description,
        firstName: userName,
        email: userEmail,
        phone: userPhone,
      );

      print('🔄 PayU URL: $payuUrl');

      // Launch PayU payment in browser
      final uri = Uri.parse(payuUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        // Return success response (in real implementation, you'd handle the callback)
        return {
          'success': true,
          'data': {
            'transaction_id': txnId,
            'payment_id': 'PAY_${DateTime.now().millisecondsSinceEpoch}',
            'amount': amount,
            'status': 'pending',
            'message': 'Payment initiated successfully',
          },
          'message': 'Payment initiated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Could not launch PayU payment',
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
PayU Setup Instructions:

1. Get PayU Credentials:
   - Visit https://business.payu.in/
   - Sign up for a merchant account
   - Get your Merchant Key and Merchant Salt from the dashboard

2. Update Credentials:
   - Open lib/services/payu_integration_service.dart
   - Replace 'YOUR_MERCHANT_KEY' with your actual merchant key
   - Replace 'YOUR_MERCHANT_SALT' with your actual merchant salt
   - Set _isProduction to true for production environment

3. Example:
   static const String _merchantKey = 'gtKFFx';
   static const String _merchantSalt = 'eCwWELxi';
   static const bool _isProduction = false; // Set to true for production

4. Test the integration with small amounts first.
''';
  }
}
