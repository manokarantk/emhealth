import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationBadgeService extends ChangeNotifier {
  static final NotificationBadgeService _instance = NotificationBadgeService._internal();
  factory NotificationBadgeService() => _instance;
  NotificationBadgeService._internal();

  int _unreadCount = 3; // Default count for demo
  Timer? _timer;

  int get unreadCount => _unreadCount;

  bool get hasUnreadNotifications => _unreadCount > 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initialize the notification badge service
  void initialize() {
    // Simulate real-time notification updates
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Simulate new notifications coming in
      if (_unreadCount < 10) {
        _addNotification();
      }
    });
  }

  /// Add a new notification
  void addNotification() {
    _unreadCount++;
    notifyListeners();
  }

  /// Mark a notification as read
  void markAsRead() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// Set notification count manually
  void setNotificationCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  /// Get notification count for display
  String get displayCount {
    if (_unreadCount == 0) return '';
    if (_unreadCount > 99) return '99+';
    return _unreadCount.toString();
  }

  /// Check if badge should be shown
  bool get shouldShowBadge => _unreadCount > 0;

  // Private method for demo purposes
  void _addNotification() {
    _unreadCount++;
    notifyListeners();
  }
}
