# 🔥 Firebase Push Notifications Setup Guide

This guide will help you set up Firebase push notifications for your EmHealth Flutter app.

## 📋 Prerequisites

- Flutter SDK installed
- Firebase project created
- Android Studio / Xcode for platform-specific setup

## 🚀 Step-by-Step Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `emhealth-app`
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Add Android App

1. In Firebase Console, click the Android icon
2. Enter Android package name: `com.example.emhealth_app`
3. Enter app nickname: `EmHealth Android`
4. Click "Register app"
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

### 3. Add iOS App

1. In Firebase Console, click the iOS icon
2. Enter iOS bundle ID: `com.example.emhealthApp`
3. Enter app nickname: `EmHealth iOS`
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place it in `ios/Runner/GoogleService-Info.plist`

### 4. Configure Firebase Cloud Messaging

1. In Firebase Console, go to "Project Settings"
2. Click "Cloud Messaging" tab
3. Note down the Server Key (you'll need this for backend)

### 5. Update Configuration Files

#### Replace Placeholder Files

Replace the placeholder configuration files with your actual Firebase files:

**Android:**
```bash
# Replace android/app/google-services.json with your actual file
```

**iOS:**
```bash
# Replace ios/Runner/GoogleService-Info.plist with your actual file
```

### 6. Install Dependencies

The required dependencies are already added to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.2
```

Run:
```bash
flutter pub get
```

### 7. Platform-Specific Configuration

#### Android Configuration

The Android configuration is already set up in:
- `android/app/build.gradle` - Added Google Services plugin
- `android/build.gradle` - Added Google Services classpath

#### iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add `GoogleService-Info.plist` to the Runner target
3. Enable push notifications capability:
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"

### 8. Backend API Integration

Add the FCM token update endpoint to your backend:

```php
// Example PHP endpoint
POST /mobile/user/update-fcm-token
{
    "fcm_token": "user_fcm_token_here"
}
```

## 🧪 Testing Notifications

### 1. Test Local Notifications

Use the test widget to verify local notifications:

```dart
// Navigate to NotificationTestWidget
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NotificationTestWidget()),
);
```

### 2. Test Firebase Notifications

#### Using Firebase Console

1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Enter notification details:
   - Title: "Test Notification"
   - Body: "This is a test message"
   - Target: Single device
   - FCM registration token: (get from app logs)
4. Click "Send"

#### Using cURL

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "USER_FCM_TOKEN",
       "notification": {
         "title": "Test Notification",
         "body": "This is a test message"
       },
       "data": {
         "type": "test",
         "id": "test_123"
       }
     }' \
     https://fcm.googleapis.com/fcm/send
```

## 📱 Notification Types

The app supports these notification types:

| Type | Description | Navigation |
|------|-------------|------------|
| `order_update` | Order status updates | Order details screen |
| `booking_reminder` | Appointment reminders | Booking details screen |
| `wallet_update` | Wallet balance updates | Wallet screen |
| `promo_offer` | Promotional offers | Offers screen |

## 🔧 Customization

### Notification Channels

The app creates two notification channels:

1. **emhealth_channel** - For Firebase notifications
2. **emhealth_custom_channel** - For custom local notifications

### Customizing Notification Appearance

Edit the notification details in `NotificationService`:

```dart
const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
  'emhealth_channel',
  'EmHealth Notifications',
  channelDescription: 'Notifications for EmHealth app',
  importance: Importance.max,
  priority: Priority.high,
  showWhen: true,
  enableVibration: true,
  playSound: true,
  // Add custom icon
  icon: '@mipmap/ic_launcher',
  // Add custom color
  color: Color(0xFF2196F3),
);
```

### Adding Custom Navigation

Update the navigation methods in `NotificationService`:

```dart
void _navigateToOrderDetails(String? orderId) {
  // Implement your navigation logic
  Navigator.pushNamed(context, '/order-details', arguments: orderId);
}
```

## 🚨 Troubleshooting

### Common Issues

1. **"Firebase not initialized"**
   - Check if `google-services.json` is in the correct location
   - Verify Firebase project configuration

2. **"Permission denied"**
   - Check notification permissions in device settings
   - Request permissions programmatically

3. **"Token not generated"**
   - Check internet connection
   - Verify Firebase project setup
   - Check device compatibility

4. **"Notifications not showing"**
   - Check notification channel settings
   - Verify app is not in battery optimization
   - Check notification permissions

### Debug Logs

Enable debug logging by checking console output:

```dart
// Look for these log messages:
print('📱 FCM Token: $_fcmToken');
print('✅ Firebase notifications initialized successfully');
print('📨 Received foreground message: ${message.messageId}');
```

## 📚 Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/docs/overview/)
- [Firebase Cloud Messaging Guide](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

## 🔐 Security Notes

1. **Server Key Protection**: Keep your Firebase Server Key secure
2. **Token Validation**: Validate FCM tokens on your backend
3. **User Consent**: Always request notification permissions
4. **Data Privacy**: Follow GDPR and local privacy laws

## ✅ Checklist

- [ ] Firebase project created
- [ ] Android app registered
- [ ] iOS app registered
- [ ] Configuration files added
- [ ] Dependencies installed
- [ ] Platform-specific setup completed
- [ ] Backend API endpoint created
- [ ] Local notifications tested
- [ ] Firebase notifications tested
- [ ] Navigation handlers implemented

## 🎯 Next Steps

1. **Production Setup**: Update Firebase project for production
2. **Analytics**: Enable Firebase Analytics for better insights
3. **A/B Testing**: Use Firebase A/B Testing for notification optimization
4. **Crashlytics**: Add Firebase Crashlytics for error tracking

---

**Note**: This setup provides a complete Firebase push notification system. Make sure to test thoroughly on both Android and iOS devices before deploying to production.
