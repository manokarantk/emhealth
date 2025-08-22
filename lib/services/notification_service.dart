import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
  print('Background message notification: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _isInitialized = false;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase and notification services
  Future<void> initialize() async {
    try {
      print('🔄 Initializing Firebase notifications...');
      
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Request permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      _isInitialized = true;
      print('✅ Firebase notifications initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Firebase notifications: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        print('User granted permission: ${settings.authorizationStatus}');
      }
      
      // Request permission for Android
      if (Platform.isAndroid) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize local notifications
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');
      
      // Save token to local storage
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        // Send token to backend
        await _sendTokenToBackend(_fcmToken!);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        
        // Save new token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        
        // Send new token to backend
        await _sendTokenToBackend(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final apiService = ApiService();
      final result = await apiService.updateFCMToken(token);
      
      if (result['success']) {
        print('✅ FCM token sent to backend successfully');
      } else {
        print('❌ Failed to send FCM token to backend: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Received foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
      
      // Show local notification
      _showLocalNotification(message);
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification: ${message.messageId}');
      print('Message data: ${message.data}');
      
      // Handle navigation based on message data
      _handleNotificationNavigation(message.data);
    });

    // Handle initial message when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App opened from terminated state via notification: ${message.messageId}');
        print('Message data: ${message.data}');
        
        // Handle navigation based on message data
        _handleNotificationNavigation(message.data);
      }
    });
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
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
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'EmHealth',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: json.encode(message.data),
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final type = data['type']?.toString().toLowerCase();
      final id = data['id']?.toString();
      
      print('🧭 Navigating based on notification type: $type, id: $id');
      
      switch (type) {
        case 'order_update':
          // Navigate to order details
          _navigateToOrderDetails(id);
          break;
        case 'booking_reminder':
          // Navigate to booking details
          _navigateToBookingDetails(id);
          break;
        case 'wallet_update':
          // Navigate to wallet
          _navigateToWallet();
          break;
        case 'promo_offer':
          // Navigate to offers
          _navigateToOffers();
          break;
        default:
          // Navigate to home
          _navigateToHome();
          break;
      }
    } catch (e) {
      print('❌ Error handling notification navigation: $e');
      _navigateToHome();
    }
  }

  /// Navigation methods (to be implemented based on your app structure)
  void _navigateToOrderDetails(String? orderId) {
    // TODO: Implement navigation to order details
    print('🧭 Navigate to order details: $orderId');
  }

  void _navigateToBookingDetails(String? bookingId) {
    // TODO: Implement navigation to booking details
    print('🧭 Navigate to booking details: $bookingId');
  }

  void _navigateToWallet() {
    // TODO: Implement navigation to wallet
    print('🧭 Navigate to wallet');
  }

  void _navigateToOffers() {
    // TODO: Implement navigation to offers
    print('🧭 Navigate to offers');
  }

  void _navigateToHome() {
    // TODO: Implement navigation to home
    print('🧭 Navigate to home');
  }

  /// Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get stored FCM token
  Future<String?> getStoredFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('❌ Error getting stored FCM token: $e');
      return null;
    }
  }

  /// Clear stored FCM token
  Future<void> clearStoredFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      print('✅ Cleared stored FCM token');
    } catch (e) {
      print('❌ Error clearing stored FCM token: $e');
    }
  }

  /// Show custom local notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'emhealth_custom_channel',
        'EmHealth Custom Notifications',
        channelDescription: 'Custom notifications for EmHealth app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      print('✅ Custom notification shown: $title');
    } catch (e) {
      print('❌ Error showing custom notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      print('✅ Notification cancelled: $id');
    } catch (e) {
      print('❌ Error cancelling notification $id: $e');
    }
  }
}
