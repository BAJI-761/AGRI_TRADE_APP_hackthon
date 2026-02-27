import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


class TradeLifecycleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  /// Confirms delivery and completes the trade.
  /// Updates tradeState to 'completed' and reputationImpact to 1.
  Future<void> confirmDelivery(String orderId) async {
    try {
      debugPrint('Confirming delivery for order $orderId');
      await _ordersCol.doc(orderId).update({
        'tradeState': 'completed',
        'reputationImpact': 1,
      });
      debugPrint('Delivery confirmed. Trade completed.');
    } catch (e) {
      debugPrint('❌ Error confirming delivery: $e');
      rethrow;
    }
  }

  /// Raises a dispute for an order.
  /// Updates tradeState to 'disputed', sets dispute details, and reputationImpact to -1.
  Future<void> raiseDispute(
    String orderId,
    String reason, {
    String category = 'other',
    String transportCostBearer = 'farmer',
    double estimatedReturnCost = 0,
    double refundAmount = 0,
    double totalOrderAmount = 0,
  }) async {
    try {
      debugPrint('Raising dispute for order $orderId');
      await _ordersCol.doc(orderId).update({
        'tradeState': 'disputed',
        'disputeReason': reason,
        'disputeCategory': category,
        'disputeDetails': {
          'category': category,
          'reason': reason,
          'transportCostBearer': transportCostBearer,
          'estimatedReturnCost': estimatedReturnCost,
          'refundAmount': refundAmount,
          'totalOrderAmount': totalOrderAmount,
          'raisedAt': FieldValue.serverTimestamp(),
        },
        'reputationImpact': -1,
      });
      debugPrint('Dispute raised successfully.');
    } catch (e) {
      debugPrint('❌ Error raising dispute: $e');
      rethrow;
    }
  }
}
