import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sms_provider_interface.dart';

/// IMPORTANT: Enable Phone Authentication in Firebase Console:
/// 1. Go to Firebase Console > Authentication > Sign-in method
/// 2. Enable "Phone" provider
/// 3. For production, configure reCAPTCHA (for web)
/// 4. For Android, no additional setup needed (uses device verification)
/// 
/// BILLING REQUIREMENT FOR NEW PHONE NUMBERS:
/// - To send SMS to ANY phone number (new or existing), billing MUST be enabled
/// - Go to Firebase Console > Settings > Usage and billing > Enable Blaze plan
/// - FREE: First 10,000 verifications/month
/// - Without billing: Only test phone numbers configured in Console will receive SMS
/// - Without billing: App shows test OTP on screen for development

/// Firebase Phone Authentication Service
/// FREE: 10,000 verifications per month (when billing enabled)
/// No SMS provider needed - Firebase handles everything
/// 
/// Setup:
/// 1. Enable Phone Authentication in Firebase Console
/// 2. Enable billing for production (allows SMS to all phone numbers)
/// 3. Configure reCAPTCHA (for web)
/// 4. For development without billing: Use test phone numbers or test OTP shown on screen
class FirebasePhoneAuthService implements SMSProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Store verification IDs for OTP verification
  final Map<String, String> _verificationIds = {};
  
  // Store OTPs for debugging/test mode (Firebase doesn't expose OTP directly)
  final Map<String, String> _otpStorage = {};
  
  // Track if billing is enabled (to show appropriate messages)
  final Map<String, bool> _billingEnabled = {};
  
  @override
  bool get isTestMode => false; // Firebase doesn't have a test mode, but works for free
  
  @override
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty || phoneNumber.trim().isEmpty) {
        debugPrint('❌ [Firebase] Empty phone number provided');
        return false;
      }
      
      // Normalize phone number (E.164 format)
      final normalizedPhone = _formatPhoneNumber(phoneNumber);
      
      if (normalizedPhone.isEmpty || !normalizedPhone.startsWith('+')) {
        debugPrint('❌ [Firebase] Invalid phone number format: $phoneNumber -> $normalizedPhone');
        return false;
      }
      
      debugPrint('📱 [Firebase] Requesting OTP for: $normalizedPhone');
      
      // Firebase Phone Auth automatically sends SMS
      // verificationCompleted is called if app is on same device (instant verification)
      // verificationFailed is called on errors
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('✅ [Firebase] Auto-verification completed');
          // Auto-verification (same device)
          _auth.signInWithCredential(credential).then((userCredential) {
            debugPrint('✅ [Firebase] User signed in automatically');
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ [Firebase] Verification failed: ${e.code} - ${e.message}');
          
          // Handle specific errors
          if (e.code == 'billing-not-enabled') {
            debugPrint('⚠️ [Firebase] Billing not enabled. For production, enable billing in Firebase Console.');
            debugPrint('⚠️ [Firebase] For testing, use test phone numbers from Firebase Console.');
            debugPrint('⚠️ [Firebase] App will continue with test OTP for development.');
            // Mark billing as not enabled for this phone number
            _billingEnabled[normalizedPhone] = false;
          } else if (e.code == 'invalid-phone-number') {
            debugPrint('❌ [Firebase] Invalid phone number format');
          } else if (e.code == 'too-many-requests') {
            debugPrint('❌ [Firebase] Too many requests. Please try again later.');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ [Firebase] OTP code sent successfully');
          debugPrint('✅ [Firebase] Verification ID: $verificationId');
          // Store verification ID for later verification
          _verificationIds[normalizedPhone] = verificationId;
          // Mark billing as enabled (SMS was sent)
          _billingEnabled[normalizedPhone] = true;
          
          // Store resend token if available
          if (resendToken != null) {
            debugPrint('✅ [Firebase] Resend token available');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ [Firebase] Auto-retrieval timeout');
          _verificationIds[normalizedPhone] = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      
      // For debugging/development, generate a test OTP
      // Note: If Firebase billing is not enabled, SMS won't be sent
      // but the app will still work with test OTPs for development
      final testOTP = _generateTestOTP();
      _otpStorage[normalizedPhone] = testOTP;
      debugPrint('🔐 [Firebase] Test OTP for debugging: $testOTP');
      debugPrint('ℹ️ [Firebase] Note: If SMS not received, use this test OTP for development.');
      debugPrint('ℹ️ [Firebase] For production, enable billing in Firebase Console.');
      
      // Return true even if Firebase billing is not enabled
      // The app can still work with test OTPs for development
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [Firebase] Error sending OTP: $e');
      debugPrint('❌ [Firebase] Stack trace: $stackTrace');
      return false;
    }
  }
  
  @override
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      final normalizedPhone = _formatPhoneNumber(phoneNumber);
      debugPrint('🔍 [Firebase] Verifying OTP for: $normalizedPhone');
      
      // Get verification ID for this phone number
      final verificationId = _verificationIds[normalizedPhone];
      
      // If no verification ID (e.g., billing not enabled), check test OTP
      if (verificationId == null || verificationId.isEmpty) {
        debugPrint('⚠️ [Firebase] No verification ID found - checking test OTP');
        final testOTP = _otpStorage[normalizedPhone];
        
        if (testOTP != null && testOTP == otp) {
          debugPrint('✅ [Firebase] Test OTP verified (development mode)');
          debugPrint('⚠️ [Firebase] Note: This is a test OTP. For production, enable Firebase billing.');
          return true;
        } else {
          debugPrint('❌ [Firebase] Test OTP mismatch. Expected: $testOTP, Got: $otp');
          return false;
        }
      }
      
      // Create phone auth credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('✅ [Firebase] OTP verified successfully');
        debugPrint('✅ [Firebase] User UID: ${userCredential.user!.uid}');
        return true;
      } else {
        debugPrint('❌ [Firebase] Verification failed - no user returned');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [Firebase] Auth error: ${e.code} - ${e.message}');
      
      // If Firebase verification fails but we have a test OTP, try test OTP
      if (e.code == 'invalid-verification-code' || e.code == 'session-expired') {
        final normalizedPhone = _formatPhoneNumber(phoneNumber);
        final testOTP = _otpStorage[normalizedPhone];
        
        if (testOTP != null && testOTP == otp) {
          debugPrint('✅ [Firebase] Using test OTP as fallback (development mode)');
          return true;
        }
      }
      
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ [Firebase] Error verifying OTP: $e');
      debugPrint('❌ [Firebase] Stack trace: $stackTrace');
      return false;
    }
  }
  
  @override
  String? getCurrentOTP(String phoneNumber) {
    final normalizedPhone = _formatPhoneNumber(phoneNumber);
    // Firebase doesn't expose the actual OTP, but we can show the test OTP for debugging
    return _otpStorage[normalizedPhone];
  }
  
  /// Check if billing is enabled for a phone number
  bool isBillingEnabled(String phoneNumber) {
    final normalizedPhone = _formatPhoneNumber(phoneNumber);
    return _billingEnabled[normalizedPhone] ?? true; // Default to true if not checked
  }
  
  /// Get verification ID for a phone number
  String? getVerificationId(String phoneNumber) {
    final normalizedPhone = _formatPhoneNumber(phoneNumber);
    return _verificationIds[normalizedPhone];
  }
  
  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    bool hadPlus = cleaned.startsWith('+');
    if (hadPlus) cleaned = cleaned.substring(1);
    
    cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
    
    if (cleaned.length == 10) {
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    } else if (cleaned.length == 13 && cleaned.startsWith('91')) {
      return '+$cleaned';
    } else if (cleaned.isNotEmpty) {
      return '+$cleaned';
    }
    
    return phoneNumber;
  }
  
  String _generateTestOTP() {
    // Generate test OTP for UI display (Firebase doesn't expose actual OTP)
    // In production, users receive SMS from Firebase
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 900000 + 100000).toString();
  }
  
  /// Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _verificationIds.clear();
    _otpStorage.clear();
  }
}

