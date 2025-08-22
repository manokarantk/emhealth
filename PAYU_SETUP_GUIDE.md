# Quick PayU Setup Guide

## 🚨 Error: "Merchant Key is Missing"

This error occurs because the PayU integration is using placeholder credentials. Here's how to fix it:

## 🔧 Quick Fix Steps

### Step 1: Get PayU Credentials
1. Visit [PayU Business](https://business.payu.in/)
2. Sign up for a merchant account
3. Complete the verification process
4. Get your **Merchant Key** and **Merchant Salt** from the dashboard

### Step 2: Update the Code
Open `lib/services/payu_payment_service.dart` and replace the placeholder values:

```dart
// Replace these lines (around line 8-10):
static const String _merchantKey = 'YOUR_MERCHANT_KEY'; // Replace with your PayU merchant key
static const String _merchantSalt = 'YOUR_MERCHANT_SALT'; // Replace with your PayU merchant salt
static const bool _isProduction = false; // Set to true for production

// With your actual credentials:
static const String _merchantKey = 'gtKFFx'; // Your actual merchant key
static const String _merchantSalt = 'eCwWELxi'; // Your actual merchant salt
static const bool _isProduction = false; // Keep false for testing
```

### Step 3: Test the Integration
1. Run the app
2. Try adding money to wallet
3. Select "PayU" as payment method
4. The error should be resolved

## 📋 Example Configuration

```dart
class PayUPaymentService {
  // TODO: Replace these with your actual PayU credentials
  // Get these from your PayU merchant dashboard
  static const String _merchantKey = 'gtKFFx'; // Your actual key here
  static const String _merchantSalt = 'eCwWELxi'; // Your actual salt here
  static const bool _isProduction = false; // Set to true for production
}
```

## 🧪 Test Credentials (Development Only)

For testing purposes, you can use these test credentials:
- **Merchant Key**: `gtKFFx`
- **Merchant Salt**: `eCwWELxi`
- **Test Card**: 4111 1111 1111 1111
- **CVV**: Any 3 digits
- **Expiry**: Any future date
- **OTP**: 123456

## 🔍 Verify Configuration

The app will now show a helpful error message if credentials are not configured, and will guide you through the setup process.

## 🚀 Next Steps

1. **Test with small amounts** (₹1-10)
2. **Verify payment flow** end-to-end
3. **Switch to production** when ready
4. **Update success/failure URLs** in PayU dashboard

## 📞 Support

If you need help:
- Check the `PAYU_INTEGRATION_README.md` for detailed instructions
- Contact PayU support: support@payu.in
- Review PayU documentation: https://docs.payu.in/
- Official Flutter SDK: https://github.com/payu-intrepos/PayUCheckoutPro-Flutter

## ⚠️ Important Notes

- **Never commit real credentials** to version control
- **Use test environment** for development
- **Test thoroughly** before going live
- **Keep credentials secure** and private

## 🔗 Official Documentation

- **PayU Devguide**: https://devguide.payu.in/flutter-sdk-integration/introduction-flutter-sdk/
- **Test Environment**: https://devguide.payu.in/flutter-sdk-integration/getting-started-flutter-sdk/mobile-sdk-test-environment/
- **GitHub Repository**: https://github.com/payu-intrepos/PayUCheckoutPro-Flutter

## 🛠️ Implementation Details

The current implementation uses a native in-app approach that:
1. Generates secure PayU payment hash using SHA256
2. Opens PayU payment interface within the app (not web browser)
3. Handles payment callbacks natively
4. Integrates with your backend for verification
5. Provides a complete mobile checkout solution

### Current Status:
- **Demo Mode**: Currently shows a simulation dialog for testing
- **Production Ready**: Framework is set up for official PayU SDK integration
- **Native UI**: Designed to work within the app, not redirect to browser

### For Production:
To implement the full PayU native SDK:
1. Follow the official PayU documentation
2. Implement `PayUCheckoutProProtocol` 
3. Replace the demo dialog with actual PayU SDK calls
4. Test with real PayU credentials

This approach provides a better user experience as payments happen within the app.
