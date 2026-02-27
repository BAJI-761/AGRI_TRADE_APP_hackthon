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
  
  // Phase 1: Trade Lifecycle Fields
  final String tradeState;
  
  // Phase 5: Reputation Impact
  final int reputationImpact;

  // Retailer Direct Request
  final String? retailerId;

  // Phase C: Crop Prediction (No changes to Order model, handled in separate service)

  // Phase D: Delivery Tracking
  final DeliveryTracking? deliveryTracking;

  // Phase B: Quality Transparency
  final List<String> cropImages;
  final String? videoUrl;
  final DateTime? cultivatedDate;
  final DateTime? harvestedDate;
  final String storageType; // 'Cold Storage', 'Warehouse', 'Open', 'Natural Dry'
  final int storageDuration; // in days
  final double moistureContent; // percentage
  final bool isOrganic;
  final String pesticidesUsed; // 'Yes - [Name]' or 'No'
  final String gstNumber;
  final String packaging; // 'Loose', 'Sack', 'Box'
  final String grade; // 'A', 'B', 'C'
  final double landArea; // in acres
  final String cropVariety;

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
    this.tradeState = 'pending', // Default
    this.reputationImpact = 0,
    this.retailerId,
    
    // Phase B defaults
    this.cropImages = const [],
    this.videoUrl,
    this.cultivatedDate,
    this.harvestedDate,
    this.storageType = 'Warehouse',
    this.storageDuration = 0,
    this.moistureContent = 0.0,
    this.isOrganic = false,
    this.pesticidesUsed = 'No',
    this.gstNumber = '',
    this.packaging = 'Sack',
    this.grade = 'B',
    this.landArea = 0.0,
    this.cropVariety = '',
    // Phase D
    this.deliveryTracking,
  });



  // Helper getter for display status — always returns tradeState
  String get displayStatus => tradeState;

  Map<String, dynamic> toMap() {
    final map = {
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
      
      // Phase B
      'cropImages': cropImages,
      'videoUrl': videoUrl,
      'cultivatedDate': cultivatedDate != null ? Timestamp.fromDate(cultivatedDate!) : null,
      'harvestedDate': harvestedDate != null ? Timestamp.fromDate(harvestedDate!) : null,
      'storageType': storageType,
      'storageDuration': storageDuration,
      'moistureContent': moistureContent,
      'isOrganic': isOrganic,
      'pesticidesUsed': pesticidesUsed,
      'gstNumber': gstNumber,
      'packaging': packaging,
      'grade': grade,
      'landArea': landArea,
      'cropVariety': cropVariety,
    };
    
    // Always include tradeState
    map['tradeState'] = tradeState;
    
    // Phase 5
    map['reputationImpact'] = reputationImpact;
    
    if (retailerId != null) {
      map['retailerId'] = retailerId;
    }

    if (deliveryTracking != null) {
      map['deliveryTracking'] = deliveryTracking!.toMap();
    }

    return map;
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
      tradeState: (data["tradeState"] as String?) ?? "pending",
      reputationImpact: (data['reputationImpact'] as int?) ?? 0,
      retailerId: data['retailerId'] as String?,
      
      // Phase B
      cropImages: List<String>.from(data['cropImages'] ?? []),
      videoUrl: data['videoUrl'] as String?,
      cultivatedDate: data['cultivatedDate'] != null 
          ? (data['cultivatedDate'] as Timestamp).toDate() 
          : null,
      harvestedDate: data['harvestedDate'] != null 
          ? (data['harvestedDate'] as Timestamp).toDate() 
          : null,
      storageType: (data['storageType'] as String?) ?? 'Warehouse',
      storageDuration: (data['storageDuration'] as int?) ?? 0,
      moistureContent: (data['moistureContent'] as num?)?.toDouble() ?? 0.0,
      isOrganic: (data['isOrganic'] as bool?) ?? false,
      pesticidesUsed: (data['pesticidesUsed'] as String?) ?? 'No',
      gstNumber: (data['gstNumber'] as String?) ?? '',
      packaging: (data['packaging'] as String?) ?? 'Sack',
      grade: (data['grade'] as String?) ?? 'B',
      landArea: (data['landArea'] as num?)?.toDouble() ?? 0.0,
      cropVariety: (data['cropVariety'] as String?) ?? '',
      
      // Phase D
      deliveryTracking: data['deliveryTracking'] != null
          ? DeliveryTracking.fromMap(data['deliveryTracking'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DeliveryTracking {
  final String status; // processing, shipped, inTransit, outForDelivery, delivered
  final String? trackingId;
  final String? carrierName;
  final DateTime? lastUpdated;

  DeliveryTracking({
    this.status = 'processing',
    this.trackingId,
    this.carrierName,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'trackingId': trackingId,
      'carrierName': carrierName,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory DeliveryTracking.fromMap(Map<String, dynamic> map) {
    return DeliveryTracking(
      status: map['status'] as String? ?? 'processing',
      trackingId: map['trackingId'] as String?,
      carrierName: map['carrierName'] as String?,
      lastUpdated: map['lastUpdated'] is Timestamp
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }
}
