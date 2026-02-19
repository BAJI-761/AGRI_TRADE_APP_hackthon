import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trade_enums.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  /// Simulates holding payment in escrow.
  /// Transitions tradeState to [TradeState.paymentHeld].
  Future<void> holdPayment(String orderId) async {
    try {
      debugPrint('Holding payment for order: $orderId');
      
      await _ordersCol.doc(orderId).update({
        'tradeState': TradeState.paymentHeld.name,
      });

      debugPrint('✅ Payment held successfully');
    } catch (e) {
      debugPrint('❌ Error holding payment: $e');
      rethrow;
    }
  }
}
