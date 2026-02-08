import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../models/notification.dart' as model;
import '../widgets/navigation_helper.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid ?? authService.phone ?? '';
    
    if (userId.isEmpty) {
      return NavigationHelper(
        child: Scaffold(
          appBar: NavigationAppBar(
            title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('notifications'),
          ),
          body: const Center(child: Text('Please log in to see notifications')),
        ),
      );
    }

    final notificationService = Provider.of<NotificationService>(context, listen: false);

    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('notifications'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            Consumer<NotificationService>(
              builder: (context, ns, _) => TextButton(
                onPressed: () => ns.markAllAsRead(userId),
                child: Consumer<LanguageService>(
                  builder: (context, ls, _) => Text(
                    ls.getLocalizedString('mark_all_read'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      body: StreamBuilder<List<model.AppNotification>>(
        stream: notificationService.streamNotificationsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Consumer<LanguageService>(
                    builder: (context, ls, _) => Text(
                      ls.getLocalizedString('no_notifications'),
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  notificationService.deleteNotification(notification.id);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: notification.isRead ? Colors.white : Colors.blue.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(notification.type),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification.body),
                    trailing: notification.isRead
                        ? null
                        : const Icon(Icons.circle, color: Colors.blue, size: 12),
                    onTap: () {
                      if (!notification.isRead) {
                        notificationService.markAsRead(notification.id);
                      }
                      // Navigate to order details if orderId is available
                      if (notification.orderId != null) {
                        // You can navigate to order details screen here
                        // Navigator.push(context, ...);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.green;
      case 'order_accepted':
        return Colors.blue;
      case 'order_rejected':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.shopping_bag;
      case 'order_accepted':
        return Icons.check_circle;
      case 'order_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }
}
