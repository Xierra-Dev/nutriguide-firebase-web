import 'package:flutter/material.dart';
import 'models/notification.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeNotificationsPage extends StatefulWidget {
  const HomeNotificationsPage({super.key});

  @override
  _HomeNotificationsPageState createState() => _HomeNotificationsPageState();
}

class _HomeNotificationsPageState extends State<HomeNotificationsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // Auto refresh setiap kali halaman difokuskan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          _loadNotifications();
        }
      });
      FocusScope.of(context).requestFocus(focusNode);
    });
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _firestoreService.markNotificationAsRead(notification.id);
      _loadNotifications(); // Reload notifications
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipe: recipe),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () async {
              try {
                await _firestoreService.markAllNotificationsAsRead();
                _loadNotifications(); // Reload setelah menandai semua sebagai dibaca
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error marking all as read: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: Colors.deepOrange,
              child: _notifications.isEmpty
                  ? ListView(  // Wrap empty state dalam ListView agar bisa di-refresh
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4, // Beri ruang di atas
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
    );
  }
}