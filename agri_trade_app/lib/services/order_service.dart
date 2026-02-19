import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trade_enums.dart';
import '../models/order.dart' as model;
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  NotificationService? _notificationService;

  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  Future<String> createOrder(model.Order order) async {
    try {
      final data = order.toMap();
      // Ensure status present
      data['status'] = data['status'] ?? 'pending';
      
      debugPrint('Creating order with data: $data');
      final doc = await _ordersCol.add(data);
      debugPrint('✅ Order created successfully with ID: ${doc.id}');
      
      // Notify retailers about new order
      if (_notificationService != null) {
        await _notificationService!.notifyOrderCreated(
          orderId: doc.id,
          farmerId: order.farmerId,
          crop: order.crop,
          quantity: order.quantity,
          unit: order.unit,
        );
      }
      
      return doc.id;
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  Stream<List<model.Order>> streamOrdersForRetailer() {
    // Show all orders sorted by creation date (newest first)
    // Filtering by status can be done client-side if needed
    return _ordersCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((d) {
                  try {
                    return model.Order.fromDoc(d.id, d.data());
                  } catch (e) {
                    debugPrint('Error parsing order ${d.id}: $e');
                    return null;
                  }
                })
                .where((o) => o != null)
                .cast<model.Order>()
                .toList();
          } catch (e) {
            debugPrint('Error in streamOrdersForRetailer: $e');
            return <model.Order>[];
          }
        });
  }

  Future<List<model.Order>> listOrdersForFarmer(String farmerId) async {
    // Remove orderBy to avoid index requirement - sort client-side instead
    final qs = await _ordersCol
        .where('farmerId', isEqualTo: farmerId)
        .get();
    final orders = qs.docs.map((d) => model.Order.fromDoc(d.id, d.data())).toList();
    // Sort client-side by createdAt descending
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  // Real-time stream for farmer orders
  Stream<List<model.Order>> streamOrdersForFarmer(String farmerId) {
    // Remove orderBy to avoid Firestore index requirement - sort client-side instead
    return _ordersCol
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
          try {
            final orders = snapshot.docs
                .map((d) {
                  try {
                    return model.Order.fromDoc(d.id, d.data());
                  } catch (e) {
                    debugPrint('Error parsing order ${d.id}: $e');
                    return null;
                  }
                })
                .where((o) => o != null)
                .cast<model.Order>()
                .toList();
            // Sort client-side by createdAt descending (newest first)
            orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return orders;
          } catch (e) {
            debugPrint('Error in streamOrdersForFarmer: $e');
            return <model.Order>[];
          }
        });
  }

  Future<void> acceptOrder(String orderId) async {
    await _ordersCol.doc(orderId).update({
      'status': 'accepted',
      'tradeState': TradeState.accepted.name,
    });
    
    // Notify farmer about order acceptance
    if (_notificationService != null) {
      try {
        final orderDoc = await _ordersCol.doc(orderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data()!;
          await _notificationService!.notifyOrderStatusChanged(
            orderId: orderId,
            farmerId: orderData['farmerId'] as String,
            crop: orderData['crop'] as String,
            status: 'accepted',
          );
        }
      } catch (e) {
        debugPrint('Error notifying order acceptance: $e');
      }
    }
  }

  Future<void> rejectOrder(String orderId) async {
    await _ordersCol.doc(orderId).update({'status': 'rejected'});
    
    // Notify farmer about order rejection
    if (_notificationService != null) {
      try {
        final orderDoc = await _ordersCol.doc(orderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data()!;
          await _notificationService!.notifyOrderStatusChanged(
            orderId: orderId,
            farmerId: orderData['farmerId'] as String,
            crop: orderData['crop'] as String,
            status: 'rejected',
          );
        }
      } catch (e) {
        debugPrint('Error notifying order rejection: $e');
      }
    }
  }
}


