/// Abstract interface for SMS OTP providers
/// This allows easy switching between different SMS providers
abstract class SMSProvider {
  /// Send OTP to the given phone number
  /// Returns true if OTP was successfully sent/stored
  Future<bool> sendOTP(String phoneNumber);
  
  /// Verify OTP for the given phone number
  /// Returns true if OTP is valid
  Future<bool> verifyOTP(String phoneNumber, String otp);
  
  /// Get the current OTP for a phone number (for debugging/testing)
  String? getCurrentOTP(String phoneNumber);
  
  /// Check if provider is in test mode
  bool get isTestMode;
}

