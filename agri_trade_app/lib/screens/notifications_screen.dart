import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../models/notification.dart' as model;
import '../theme/app_theme.dart';
import '../widgets/navigation_helper.dart';
import '../widgets/app_gradient_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid ?? authService.phone ?? '';
    final ls = Provider.of<LanguageService>(context);

    if (userId.isEmpty) {
      return NavigationHelper(
        child: AppGradientScaffold(
          headerChildren: [
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ls.getLocalizedString('notifications'),
                style: AppTheme.headingMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
          bodyChildren: [
             Center(child: Text('Please log in to see notifications', style: AppTheme.bodyLarge)),
          ],
        ),
      );
    }

    final notificationService = Provider.of<NotificationService>(context, listen: false);

    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.2,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ls.getLocalizedString('notifications'),
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => notificationService.markAllAsRead(userId),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    ls.getLocalizedString('mark_all_read'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          StreamBuilder<List<model.AppNotification>>(
            stream: notificationService.streamNotificationsForUser(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ));
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorRed)),
                );
              }

              final notifications = snapshot.data ?? [];
              
              if (notifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 24),
                        Text(
                          ls.getLocalizedString('no_notifications'),
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      notificationService.deleteNotification(notification.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.cardDecoration.copyWith(
                        color: notification.isRead ? Colors.white : Colors.blue.shade50.withOpacity(0.5),
                        border: notification.isRead 
                            ? Border.all(color: Colors.grey.withOpacity(0.1))
                            : Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: AppTheme.headingSmall.copyWith(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            notification.body,
                            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ),
                        trailing: notification.isRead
                            ? null
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondaryAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () {
                          if (!notification.isRead) {
                            notificationService.markAsRead(notification.id);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return AppTheme.primaryGreen;
      case 'order_accepted':
        return Colors.blue;
      case 'order_rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.secondaryAmber;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.shopping_cart;
      case 'order_accepted':
        return Icons.check_circle;
      case 'order_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }
}
