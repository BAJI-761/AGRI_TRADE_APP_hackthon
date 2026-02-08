import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId; // phone number or uid
  final String userType; // 'farmer' or 'retailer'
  final String type; // 'order_created', 'order_accepted', 'order_rejected'
  final String title;
  final String body;
  final String? orderId;
  final String? farmerId;
  final String? retailerId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.userType,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    this.farmerId,
    this.retailerId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'type': type,
      'title': title,
      'body': body,
      'orderId': orderId,
      'farmerId': farmerId,
      'retailerId': retailerId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromDoc(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId'] as String,
      userType: data['userType'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      orderId: data['orderId'] as String?,
      farmerId: data['farmerId'] as String?,
      retailerId: data['retailerId'] as String?,
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] as String),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      userType: userType,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      farmerId: farmerId,
      retailerId: retailerId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

