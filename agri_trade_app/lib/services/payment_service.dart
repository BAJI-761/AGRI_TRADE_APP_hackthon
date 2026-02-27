import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  /// Simulates holding payment in escrow.
  /// Updates tradeState to 'paymentHeld'.
  Future<void> holdPayment(String orderId) async {
    try {
      debugPrint('Proceed clicked - Updating Payment State directly');
      await _firestore.collection("orders").doc(orderId).update({
        "tradeState": "paymentHeld",
      });
      debugPrint('Payment state updated to paymentHeld');
    } catch (e) {
      debugPrint('❌ Error holding payment: $e');
      rethrow;
    }
  }

}
