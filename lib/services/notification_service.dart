import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;

  /// Initialize notification services
  Future<void> initialize() async {
    try {
      print('🔄 Initializing local notifications...');
      
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      _isInitialized = true;
      print('✅ Local notifications initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize local notifications: $e');
      rethrow;
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
