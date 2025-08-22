# PayU Payment Integration for EmHealth App

This document explains how to set up and use the PayU payment gateway integration for adding money to the wallet in the EmHealth Flutter app.

## Overview

The PayU integration allows users to add money to their wallet using various payment methods including:
- UPI
- Credit Cards
- Debit Cards
- Net Banking
- Digital Wallets

## Setup Instructions

### 1. PayU Merchant Account Setup

1. **Create PayU Merchant Account**
   - Visit [PayU Business](https://business.payu.in/)
   - Sign up for a merchant account
   - Complete the verification process
   - Get your Merchant Key and Merchant Salt

2. **Configure PayU Credentials**
   - Open `lib/services/payu_integration_service.dart`
   - Replace the placeholder values:
   ```dart
   static const String _merchantKey = 'YOUR_MERCHANT_KEY'; // Replace with your actual merchant key
   static const String _merchantSalt = 'YOUR_MERCHANT_SALT'; // Replace with your actual merchant salt
   static const bool _isProduction = false; // Set to true for production
   ```

### 2. Backend API Setup

Ensure your backend has the following endpoints configured:

#### Add Money to Wallet with Payment
```
POST /mobile/wallet/add-money
Content-Type: application/json

{
  "amount": 1000.00,
  "payment_method": "PayU",
  "description": "Added money to wallet via PayU",
  "transaction_id": "TXN_1234567890",
  "payment_id": "PAY_1234567890"
}
```

#### Verify PayU Payment
```
POST /mobile/wallet/verify-payment
Content-Type: application/json

{
  "transaction_id": "TXN_1234567890",
  "payment_id": "PAY_1234567890",
  "amount": 1000.00
}
```

### 3. Success/Failure URLs

Configure the following URLs in your PayU merchant dashboard:

- **Success URL**: `https://your-domain.com/payment/success`
- **Failure URL**: `https://your-domain.com/payment/failure`

## How It Works

### 1. User Flow

1. User opens the "Add Money to Wallet" bottom sheet
2. User enters the amount and selects "PayU" as payment method
3. App fetches user profile data (email, name, phone)
4. App generates PayU payment URL with hash
5. App opens PayU payment gateway in external browser
6. User completes payment on PayU
7. PayU redirects to success/failure URL
8. Backend verifies payment and updates wallet balance

### 2. Payment Hash Generation

The app generates a secure hash for PayU using the following formula:
```
hash = SHA256(merchantKey|txnid|amount|productinfo|firstname|email|||||||||||merchantSalt)
```

### 3. Transaction Flow

```
User Input → Generate Hash → Create PayU URL → Launch Browser → 
Payment Gateway → Success/Failure → Verify Payment → Update Wallet
```

## Code Structure

### Key Files

1. **`lib/services/payu_integration_service.dart`**
   - Main PayU integration service
   - Handles hash generation and URL creation
   - Manages payment flow

2. **`lib/widgets/add_money_bottom_sheet.dart`**
   - UI for adding money to wallet
   - Integrates PayU payment option
   - Handles payment flow

3. **`lib/services/api_service.dart`**
   - API methods for wallet operations
   - Payment verification endpoints
   - Backend communication

### Key Methods

#### PayUIntegrationService
- `launchPayUPayment()` - Initiates PayU payment
- `verifyPayment()` - Verifies payment with backend
- `completeWalletTopUp()` - Completes wallet top-up

#### AddMoneyBottomSheet
- `_handlePayUPayment()` - Handles PayU payment flow
- `_addMoneyToWallet()` - Main payment method handler

## Testing

### Test Environment
- Use PayU test credentials
- Test with small amounts
- Verify payment flow end-to-end

### Test Cards (Test Environment)
- **Credit Card**: 4111 1111 1111 1111
- **CVV**: Any 3 digits
- **Expiry**: Any future date
- **OTP**: 123456

## Production Deployment

### 1. Update Credentials
- Set `_isProduction = true`
- Use production merchant key and salt
- Update success/failure URLs

### 2. Security Considerations
- Never commit real credentials to version control
- Use environment variables for sensitive data
- Implement proper error handling
- Add payment logging for debugging

### 3. Monitoring
- Monitor payment success rates
- Track failed transactions
- Set up alerts for payment issues

## Error Handling

The integration includes comprehensive error handling for:
- Network connectivity issues
- Invalid payment data
- Payment gateway errors
- Backend verification failures
- User cancellation

## Troubleshooting

### Common Issues

1. **Hash Mismatch**
   - Verify merchant key and salt
   - Check parameter order in hash generation
   - Ensure all required fields are present

2. **Payment Not Processing**
   - Check PayU merchant account status
   - Verify success/failure URLs
   - Check backend API endpoints

3. **Wallet Not Updated**
   - Verify payment verification endpoint
   - Check transaction ID format
   - Ensure proper error handling

### Debug Information

Enable debug logging by checking console output for:
- PayU URL generation
- Payment initiation
- Backend API calls
- Error messages

## Support

For PayU-related issues:
- Contact PayU support: support@payu.in
- Check PayU documentation: https://docs.payu.in/
- Review PayU merchant dashboard

For app integration issues:
- Check the code comments
- Review error logs
- Test with different payment amounts

## Security Notes

- Always use HTTPS for production
- Implement proper input validation
- Use secure hash generation
- Never expose merchant credentials
- Implement proper session management
- Add rate limiting for payment attempts

## Future Enhancements

Potential improvements:
- Add payment status tracking
- Implement payment retry logic
- Add payment history
- Support for recurring payments
- Integration with other payment gateways
- Enhanced error reporting
