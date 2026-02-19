import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart' as model;

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  NotificationService() {
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    // Local notifications disabled for web compatibility to fix compilation errors
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // Create notification for order created (for retailers)
  Future<void> notifyOrderCreated({
    required String orderId,
    required String farmerId,
    required String crop,
    required double quantity,
    required String unit,
    String? retailerId,
  }) async {
    try {
      if (retailerId != null) {
        // Notify specific retailer
        await _createNotification(
          userId: retailerId,
          userType: 'retailer',
          type: 'order_created',
          title: 'New Order Available',
          body: '$quantity $unit of $crop available from farmer',
          orderId: orderId,
          farmerId: farmerId,
        );
      } else {
        // Notify all retailers by querying users collection
        try {
          final retailersSnapshot = await _firestore
              .collection('users')
              .where('userType', isEqualTo: 'retailer')
              .get();
          
          final batch = _firestore.batch();
          final notificationsCol = _firestore.collection('notifications');
          
          for (var retailerDoc in retailersSnapshot.docs) {
            final retailerId = retailerDoc.id;
            final notificationRef = notificationsCol.doc();
            final notification = model.AppNotification(
              id: notificationRef.id,
              userId: retailerId,
              userType: 'retailer',
              type: 'order_created',
              title: 'New Order Available',
              body: '$quantity $unit of $crop available from farmer',
              orderId: orderId,
              farmerId: farmerId,
              createdAt: DateTime.now(),
            );
            batch.set(notificationRef, notification.toMap());
          }
          
          await batch.commit();
          debugPrint('✅ Notified ${retailersSnapshot.docs.length} retailers about new order');
          
          // Also show a local notification
          await _showLocalNotification(
            'New Order Available',
            '$quantity $unit of $crop available',
            orderId,
          );
        } catch (e) {
          debugPrint('Error notifying all retailers: $e');
          // Fallback: create a generic notification
          await _createNotification(
            userId: 'all_retailers',
            userType: 'retailer',
            type: 'order_created',
            title: 'New Order Available',
            body: '$quantity $unit of $crop available from farmer',
            orderId: orderId,
            farmerId: farmerId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating order notification: $e');
    }
  }

  // Create notification for order accepted/rejected (for farmers)
  Future<void> notifyOrderStatusChanged({
    required String orderId,
    required String farmerId,
    required String crop,
    required String status, // 'accepted' or 'rejected'
  }) async {
    try {
      final title = status == 'accepted' ? 'Order Accepted!' : 'Order Rejected';
      final body = status == 'accepted'
          ? 'Your order for $crop has been accepted by a retailer'
          : 'Your order for $crop has been rejected';

      await _createNotification(
        userId: farmerId,
        userType: 'farmer',
        type: 'order_$status',
        title: title,
        body: body,
        orderId: orderId,
        farmerId: farmerId,
      );
    } catch (e) {
      debugPrint('Error creating status notification: $e');
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String userType,
    required String type,
    required String title,
    required String body,
    String? orderId,
    String? farmerId,
    String? retailerId,
  }) async {
    try {
      final notification = model.AppNotification(
        id: '',
        userId: userId,
        userType: userType,
        type: type,
        title: title,
        body: body,
        orderId: orderId,
        farmerId: farmerId,
        retailerId: retailerId,
        createdAt: DateTime.now(),
      );

      await _notificationsCol.add(notification.toMap());
      
      // Show local notification
      await _showLocalNotification(title, body, orderId);
      
      debugPrint('✅ Notification created: $title');
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  Future<void> _showLocalNotification(String title, String body, String? payload) async {
    // Local notifications disabled for web compatibility
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'agri_trade_channel',
      'AgriTrade Notifications',
      channelDescription: 'Notifications for orders and updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // Stream notifications for a user
  Stream<List<model.AppNotification>> streamNotificationsForUser(String userId) {
    // Remove orderBy to avoid Firestore index requirement - sort client-side instead
    return _notificationsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error streaming notifications: $error');
        })
        .map((snapshot) {
          try {
            final notifications = snapshot.docs
                .map((d) {
                  try {
                    return model.AppNotification.fromDoc(d.id, d.data());
                  } catch (e) {
                    debugPrint('Error parsing notification ${d.id}: $e');
                    return null;
                  }
                })
                .where((n) => n != null)
                .cast<model.AppNotification>()
                .toList();
            
            // Sort by createdAt descending (client-side sorting)
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            // Update unread count
            _unreadCount = notifications.where((n) => !n.isRead).length;
            notifyListeners();
            
            return notifications;
          } catch (e) {
            debugPrint('Error in streamNotificationsForUser: $e');
            return <model.AppNotification>[];
          }
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).update({'isRead': true});
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsCol
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCol.doc(notificationId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
}

