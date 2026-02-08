import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String farmerId;
  final String crop;
  final double quantity;
  final String unit; // e.g., kg, ton, bag
  final double pricePerUnit;
  final DateTime availableDate; // the only date to go to retailer
  final String location;
  final String notes;
  final DateTime createdAt;
  final String status; // pending/accepted/rejected

  Order({
    required this.id,
    required this.farmerId,
    required this.crop,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.availableDate,
    required this.location,
    required this.notes,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'crop': crop,
      'quantity': quantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'availableDate': Timestamp.fromDate(availableDate),
      'location': location,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory Order.fromDoc(String id, Map<String, dynamic> data) {
    return Order(
      id: id,
      farmerId: data['farmerId'] as String,
      crop: data['crop'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'] as String,
      pricePerUnit: (data['pricePerUnit'] as num).toDouble(),
      availableDate: data['availableDate'] is Timestamp
          ? (data['availableDate'] as Timestamp).toDate()
          : DateTime.parse(data['availableDate'] as String),
      location: data['location'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] as String),
      status: (data['status'] as String?) ?? 'pending',
    );
  }
}


