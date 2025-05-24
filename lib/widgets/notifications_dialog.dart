import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/firestore_service.dart';
import '../recipe_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsDialog extends StatefulWidget {
  final RelativeRect position;
  
  const NotificationsDialog({
    super.key,
    required this.position,
  });

  static Future<void> show(BuildContext context, RelativeRect position) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => NotificationsDialog(position: position),
    );
  }

  @override
  _NotificationsDialogState createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final notifications = await _firestoreService.getNotifications();
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _firestoreService.markNotificationAsRead(notification.id);
      _loadNotifications(); // Reload notifications
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notification as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read when tapped
    await _markAsRead(notification);

    // Handle navigation based on notification type
    if (notification.type == 'recipe' && notification.relatedId != null) {
      try {
        final recipe = await _firestoreService.getRecipeById(notification.relatedId!);
        if (recipe != null && mounted) {
          Navigator.pop(context); // Close dialog first
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipe: recipe),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading recipe: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    IconData iconData;
    Color iconColor;
    
    // Set icon based on notification type
    switch (notification.type) {
      case 'recipe':
        iconData = Icons.restaurant_menu;
        iconColor = Colors.orange;
        break;
      case 'reminder':
        iconData = Icons.alarm;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : Colors.grey[900],
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeago.format(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[850]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.done_all, color: Colors.white),
                        onPressed: () async {
                          try {
                            await _firestoreService.markAllNotificationsAsRead();
                            _loadNotifications();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error marking all as read: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepOrange,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: Colors.deepOrange,
                    child: _notifications.isEmpty
                      ? ListView( // Wrap empty state in ListView for RefreshIndicator
                          children: [
                            SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No notifications yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(_notifications[index]);
                          },
                        ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
} 