import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate loading notifications
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      notifications = [
        {
          'id': '1',
          'title': 'Order Confirmed',
          'message': 'Your blood test order has been confirmed and is being processed.',
          'type': 'order_update',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'isRead': false,
          'icon': Icons.check_circle,
          'iconColor': Colors.green,
        },
        {
          'id': '2',
          'title': 'Appointment Reminder',
          'message': 'You have an appointment tomorrow at 10:00 AM with City Lab.',
          'type': 'booking_reminder',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'isRead': false,
          'icon': Icons.schedule,
          'iconColor': Colors.blue,
        },
        {
          'id': '3',
          'title': 'Wallet Updated',
          'message': '₹500 has been added to your wallet. Current balance: ₹1,250.',
          'type': 'wallet_update',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'isRead': true,
          'icon': Icons.account_balance_wallet,
          'iconColor': Colors.orange,
        },
        {
          'id': '4',
          'title': 'Special Offer',
          'message': 'Get 20% off on all diabetes screening tests this week!',
          'type': 'promo_offer',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'isRead': true,
          'icon': Icons.local_offer,
          'iconColor': Colors.red,
        },
        {
          'id': '5',
          'title': 'Report Ready',
          'message': 'Your blood test report is ready. Click to view and download.',
          'type': 'report_ready',
          'timestamp': DateTime.now().subtract(const Duration(days: 2)),
          'isRead': true,
          'icon': Icons.description,
          'iconColor': Colors.purple,
        },
      ];
      isLoading = false;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final notification = notifications.firstWhere((n) => n['id'] == notificationId);
      notification['isRead'] = true;
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      notifications.removeWhere((n) => n['id'] == notificationId);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text('Are you sure you want to clear all notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  notifications.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead();
                    break;
                  case 'clear_all':
                    _clearAllNotifications();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final isRead = notification['isRead'] as bool;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: notification['iconColor'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            notification['icon'],
                            color: notification['iconColor'],
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'],
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 16,
                                  color: isRead ? Colors.grey[700] : Colors.black,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTimestamp(notification['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'mark_read':
                                if (!isRead) {
                                  _markAsRead(notification['id']);
                                }
                                break;
                              case 'delete':
                                _deleteNotification(notification['id']);
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            if (!isRead)
                              const PopupMenuItem<String>(
                                value: 'mark_read',
                                child: Row(
                                  children: [
                                    Icon(Icons.mark_email_read, color: Colors.grey, size: 18),
                                    SizedBox(width: 8),
                                    Text('Mark as read'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(notification['id']);
                          }
                          // Handle notification tap based on type
                          _handleNotificationTap(notification);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    
    switch (type) {
      case 'order_update':
        // Navigate to order details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigating to order details...')),
        );
        break;
      case 'booking_reminder':
        // Navigate to appointments
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigating to appointments...')),
        );
        break;
      case 'wallet_update':
        // Navigate to wallet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigating to wallet...')),
        );
        break;
      case 'promo_offer':
        // Navigate to offers
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigating to offers...')),
        );
        break;
      case 'report_ready':
        // Navigate to medical history
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigating to medical history...')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification tapped')),
        );
    }
  }
}
