import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository pattern wrapper for Firestore operations
class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user document by phone number (E.164 format)
  Future<Map<String, dynamic>?> getUser(String phoneNumber) async {
    try {
      final normalizedPhone = _normalizePhone(phoneNumber);
      final doc = await _firestore.collection('users').doc(normalizedPhone).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Create a new user document
  Future<bool> createUser({
    required String phoneNumber,
    required String name,
    required String address,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phoneNumber);
      final userData = {
        'phone': normalizedPhone,
        'name': name,
        'address': address,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };
      await _firestore.collection('users').doc(normalizedPhone).set(userData);
      debugPrint('✅ User created: $normalizedPhone');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      return false;
    }
  }

  /// Update existing user document
  Future<bool> updateUser({
    required String phoneNumber,
    String? name,
    String? address,
    String? userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phoneNumber);
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updateData['name'] = name;
      if (address != null) updateData['address'] = address;
      if (userType != null) updateData['userType'] = userType;
      if (additionalData != null) updateData.addAll(additionalData);

      await _firestore.collection('users').doc(normalizedPhone).update(updateData);
      debugPrint('✅ User updated: $normalizedPhone');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      return false;
    }
  }

  /// Create or update user (upsert operation)
  Future<bool> createOrUpdateUser({
    required String phoneNumber,
    required String name,
    required String address,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phoneNumber);
      final userData = {
        'phone': normalizedPhone,
        'name': name,
        'address': address,
        'userType': userType,
        'updatedAt': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      };
      // Use merge: true to update if exists, create if not
      await _firestore.collection('users').doc(normalizedPhone).set(
        {
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('✅ User upserted: $normalizedPhone');
      return true;
    } catch (e) {
      debugPrint('❌ Error upserting user: $e');
      return false;
    }
  }

  /// Add feedback to Firestore
  Future<bool> addFeedback({
    required String message,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final feedbackData = {
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        if (userId != null) 'userId': userId,
        if (additionalData != null) ...additionalData,
      };
      await _firestore.collection('feedback').add(feedbackData);
      debugPrint('✅ Feedback added');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding feedback: $e');
      return false;
    }
  }

  /// Normalize phone number to E.164 format
  String _normalizePhone(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
    return cleaned.startsWith('+') ? cleaned : '+$cleaned';
  }
}

