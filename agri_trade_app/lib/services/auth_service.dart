import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  String? _name;
  String? _address;
  String? _userType;
  String? _phone;
  bool _hasUsername = false;

  User? get user => _user;
  String? get name => _name;
  String? get address => _address;
  String? get userType => _userType;
  String? get phone => _phone;
  bool get hasUsername => _hasUsername;
  bool get isAuthenticated => _user != null || (_name != null && _userType != null);

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _clearUserData();
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        debugPrint('Loading user data for UID: ${_user!.uid}');
        final phone = _user!.phoneNumber;
        if (phone != null) {
          _phone = _formatPhoneNumber(phone);
          debugPrint('Firebase user phone: $_phone');
        }
        
        // Try to load from Firestore using UID first (for Firebase Auth users)
        var doc = await _firestore.collection('users').doc(_user!.uid).get();
        
        // If not found and we have phone number, try loading by phone
        if (!doc.exists && phone != null) {
          final phoneDocId = _formatPhoneNumber(phone);
          doc = await _firestore.collection('users').doc(phoneDocId).get();
        }
        
        if (doc.exists) {
          final data = doc.data()!;
          _name = data['name'];
          _address = data['address'];
          _userType = data['userType'];
          _hasUsername = (data['username'] ?? '').toString().isNotEmpty;
          if (_phone == null && data['phone'] != null) {
            _phone = data['phone'] as String;
          }
          debugPrint('User data loaded: name=$_name, type=$_userType, address=$_address, phone=$_phone');
          notifyListeners();
        } else {
          debugPrint('User document does not exist in Firestore');
          // If Firebase user exists but no Firestore doc, keep Firebase auth but mark as unregistered
          if (phone != null) {
            _phone = _formatPhoneNumber(phone);
            // User is authenticated via Firebase but needs to complete profile
            debugPrint('Firebase user authenticated but profile not completed');
          }
          _hasUsername = false;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        // Don't clear if Firebase user exists - they're still authenticated
        if (_user == null) {
          _clearUserData();
        }
        notifyListeners();
      }
    }
  }

  void _clearUserData() {
    _name = null;
    _address = null;
    _userType = null;
    _phone = null;
    _hasUsername = false;
  }

  // Map displayed username (full name) + phone to a deterministic synthetic email
  // This lets us keep Firebase Auth email/password while showing username/password to users
  String usernameToEmail({
    required String fullName,
    required String phoneNumber,
  }) {
    final normalizedName = fullName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.').replaceAll(RegExp(r'\.+'), '.');
    final normalizedPhone = _formatPhoneNumber(phoneNumber).replaceAll('+', '');
    // Domain is internal-only; not used for real email
    return '$normalizedName+$normalizedPhone@agri.local';
  }

  // Link username/password (mapped to synthetic email + phone) to currently signed-in phone user
  // Requires that Firebase Phone Auth has already authenticated the user (via OTP)
  Future<void> linkUsernamePasswordToCurrentUser({
    required String fullName,
    required String phoneNumber,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('No authenticated user to link credentials. Complete phone verification first.');
    }
    final email = usernameToEmail(fullName: fullName, phoneNumber: phoneNumber);
    final password = _formatPhoneNumber(phoneNumber);
    final credential = EmailAuthProvider.credential(email: email, password: password);
    try {
      await _auth.currentUser!.linkWithCredential(credential);
      debugPrint('✅ Linked email/password to phone user');
    } on FirebaseAuthException catch (e) {
      // If already linked or email exists, try sign-in to ensure continuity
      if (e.code == 'provider-already-linked' || e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        debugPrint('ℹ️ Credentials already linked or in use, skipping link');
        return;
      }
      rethrow;
    }
  }

  // Backfill username in Firestore and link email/password for existing phone users
  Future<void> backfillUsernameAndLinkCredentials({
    required String fullName,
    required String phoneNumber,
  }) async {
    final docId = _formatPhoneNumber(phoneNumber);
    try {
      // Update Firestore username if missing
      await _firestore.collection('users').doc(docId).set({
        'username': fullName,
        'name': fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // If authenticated with Firebase (e.g., phone), link email/password
      try {
        await linkUsernamePasswordToCurrentUser(fullName: fullName, phoneNumber: phoneNumber);
      } catch (e) {
        debugPrint('Backfill link skipped: $e');
      }

      _hasUsername = true;
      if (_name == null || (_name?.isEmpty ?? true)) {
        _name = fullName;
      }
      if (_phone == null || (_phone?.isEmpty ?? true)) {
        _phone = docId;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error backfilling username/link: $e');
      rethrow;
    }
  }

  // Sign in using displayed username (full name) and password (phone number)
  Future<void> loginWithUsernamePassword({
    required String fullName,
    required String passwordPhoneNumber,
  }) async {
    // Use Firebase Email/Password with synthetic email derived from username + phone
    final email = usernameToEmail(fullName: fullName, phoneNumber: passwordPhoneNumber);
    await login(email, _formatPhoneNumber(passwordPhoneNumber));
  }

  Future<void> register(String name, String address, String userType, String email, String password) async {
    try {
      email = email.trim();
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'address': address,
        'userType': userType,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _name = name;
      _address = address;
      _userType = userType;
      notifyListeners();
    } catch (e) {
      debugPrint('Error registering: $e');
      // Provide more specific error messages
      if (e.toString().contains('email-already-in-use')) {
        throw Exception('An account with this email already exists.');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Password is too weak. Please use a stronger password.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Please enter a valid email address.');
      } else {
        throw Exception('Registration failed. Please try again.');
      }
    }
  }

  Future<void> login(String email, String password) async {
    try {
      email = email.trim();
      debugPrint('Attempting login for email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Login successful for user: ${userCredential.user?.uid}');
      
      // The auth state listener should automatically trigger _loadUserData
      // But let's ensure user data is loaded
      if (userCredential.user != null) {
        await _loadUserData();
      }
      
    } catch (e) {
      debugPrint('Error logging in: $e');
      // Provide more specific error messages
      if (e.toString().contains('user-not-found')) {
        throw Exception('No account found with this email address.');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Please enter a valid email address.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many failed attempts. Please try again later.');
      } else if (e.toString().contains('network-request-failed')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Login failed. Please check your credentials and try again.');
      }
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      // Ensure local state is cleared even in mock/demo modes
      _clearUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
      // Don't throw on logout errors as they're usually not critical
    }
  }

  // Demo method for testing without Firebase
  Future<void> setDemoUser(String userType) async {
    // Set demo user data without creating a complex User object
    _name = userType == 'farmer' ? 'Demo Farmer' : 'Demo Retailer';
    _address = userType == 'farmer' ? 'Punjab, India' : 'Mumbai, India';
    _userType = userType;
    _phone = '+910000000000';
    
    // Create a simple mock user for authentication state
    _user = _createSimpleMockUser();
    notifyListeners();
  }

  User? _createSimpleMockUser() {
    // Return null to indicate demo mode, but set the user data manually
    // This bypasses Firebase authentication while maintaining app functionality
    return null;
  }

  // Clear demo user data
  void clearDemoUser() {
    _user = null;
    _name = null;
    _address = null;
    _userType = null;
    notifyListeners();
  }

  // Create user with phone number (for phone-only auth)
  Future<void> createUserWithPhone(String phoneNumber, String userType) async {
    try {
      // For now, we'll create a simple user object
      // In production, you'd store this in Firestore
      _name = userType == 'farmer' ? 'Farmer User' : 'Retailer User';
      _address = 'Not set';
      _userType = userType;
      _phone = _formatPhoneNumber(phoneNumber);
      
      // Create a mock user for phone-based authentication
      _user = _createPhoneBasedUser(phoneNumber);
      notifyListeners();
      
      debugPrint('User created with phone: $phoneNumber, type: $userType');
    } catch (e) {
      debugPrint('Error creating user with phone: $e');
      throw Exception('Failed to create user account');
    }
  }

  User? _createPhoneBasedUser(String phoneNumber) {
    // Return null to indicate phone-based auth, but set the user data manually
    // This bypasses Firebase authentication while maintaining app functionality
    return null;
  }

  // Complete phone sign-in with provided profile (used after fetch or create)
  void completePhoneSignin({
    required String phone,
    required String name,
    required String address,
    required String userType,
  }) {
    _phone = phone;
    _name = name;
    _address = address;
    _userType = userType;
    
    // Use Firebase Auth user if available, otherwise create mock user
    if (_auth.currentUser != null) {
      _user = _auth.currentUser;
      if (kDebugMode) debugPrint('Using Firebase Auth user: ${_user!.uid}');
    } else {
      _user = _createPhoneBasedUser(phone);
      if (kDebugMode) debugPrint('Using mock user (no Firebase Auth user)');
    }
    
    notifyListeners();
  }

  // Load user profile from Firestore using phone as doc id (E.164)
  // Also checks Firebase Auth current user
  // Returns false for user not found, throws only for persistent network errors
  Future<bool> loadUserByPhone(String phoneNumber) async {
    final docId = _formatPhoneNumber(phoneNumber);
    try {
      // First check if Firebase Auth user exists with matching phone
      if (_auth.currentUser != null && _auth.currentUser!.phoneNumber != null) {
        final firebasePhone = _formatPhoneNumber(_auth.currentUser!.phoneNumber!);
        if (firebasePhone == docId) {
          debugPrint('✅ Firebase user authenticated with phone: $firebasePhone');
          _user = _auth.currentUser;
          _phone = firebasePhone;
          
          // Try to load profile using Firebase UID first (default source like email login)
          var doc = await _firestore.collection('users').doc(_user!.uid).get();
          
          // If not found, try loading by phone number (default source)
          if (!doc.exists) {
            doc = await _firestore.collection('users').doc(docId).get();
          }
          
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final loadedName = data['name'] as String?;
            final loadedAddress = data['address'] as String?;
            final loadedType = data['userType'] as String?;
            _hasUsername = (data['username'] ?? '').toString().isNotEmpty;
            if (loadedName != null && loadedType != null) {
              _name = loadedName;
              _address = loadedAddress ?? '';
              _userType = loadedType;
              notifyListeners();
              return true;
            }
          }
          
          // Firebase user exists but profile not complete
          notifyListeners();
          return false; // Profile needs to be completed
        }
      }
      
      // Fallback: Try loading from Firestore by phone number
      // Note: This check happens BEFORE authentication, so Firestore rules may block it
      // If it fails, we'll proceed to registration which is the safe default
      try {
        // Use default source - Firestore will try server first, fall back to cache
        // This matches the behavior of email login which worked
        final doc = await _firestore.collection('users').doc(docId).get();
        
        if (!doc.exists) {
          debugPrint('📝 User document not found in Firestore');
          return false;
        }
        
        final data = doc.data() as Map<String, dynamic>;
        final loadedName = data['name'] as String?;
        final loadedAddress = data['address'] as String?;
        final loadedType = data['userType'] as String?;
        _hasUsername = (data['username'] ?? '').toString().isNotEmpty;
        
        if (loadedName == null || loadedType == null) {
          debugPrint('📝 User document exists but missing required fields');
          return false;
        }
        
        debugPrint('✅ Found existing user in Firestore: $loadedName');
        completePhoneSignin(
          phone: docId,
          name: loadedName,
          address: loadedAddress ?? '',
          userType: loadedType,
        );
        return true;
      } on FirebaseException catch (e) {
        debugPrint('Firestore error checking user: ${e.code} - ${e.message}');
        
        // Permission denied means security rules block unauthenticated reads
        // This is expected - we'll proceed to registration
        if (e.code == 'permission-denied') {
          debugPrint('⚠️ Permission denied - Firestore rules require authentication. Proceeding to registration.');
          return false; // Treat as new user, proceed to registration
        }
        
        // Unavailable might be Firestore persistence issue or network
        // Try cache as fallback, but if that fails, proceed to registration
        if (e.code == 'unavailable') {
          try {
            final doc = await _firestore.collection('users').doc(docId).get(
              const GetOptions(source: Source.cache),
            );
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final loadedName = data['name'] as String?;
              final loadedAddress = data['address'] as String?;
              final loadedType = data['userType'] as String?;
              if (loadedName != null && loadedType != null) {
                debugPrint('✅ Found user in cache');
                completePhoneSignin(
                  phone: docId,
                  name: loadedName,
                  address: loadedAddress ?? '',
                  userType: loadedType,
                );
                return true;
              }
            }
            // Cache empty or no user - proceed to registration (treat as new user)
            return false;
          } catch (_) {
            // Cache check failed - proceed to registration (treat as new user)
            return false;
          }
        }
        
        // For timeout errors, still treat as "proceed to registration" 
        // (don't block user flow for transient network issues)
        if (e.code == 'deadline-exceeded' || e.code == 'aborted') {
          debugPrint('⚠️ Request timed out, proceeding to registration');
          return false;
        }
        
        // Any other error - proceed to registration (safe default)
        debugPrint('⚠️ Unknown Firestore error, proceeding to registration');
        return false;
      }
    } catch (e) {
      debugPrint('Error loading user by phone: $e');
      // Only throw for actual network timeouts, not for unavailable/cache issues
      if (e is Exception && e.toString().contains('timed out')) {
        throw e;
      }
      // For other errors including unavailable, treat as user not found
      return false;
    }
  }

  // Create or update user profile in Firestore by phone
  // If Firebase Auth user exists, also save using UID
  // After saving, completes phone sign-in to set authentication state
  Future<void> createOrUpdateUserProfile({
    required String phoneNumber,
    required String name,
    required String address,
    required String userType,
  }) async {
    final docId = _formatPhoneNumber(phoneNumber);
    try {
      final profileData = {
        'phone': docId,
        'name': name,
        'username': name, // Displayed username equals full name per requirements
        'address': address,
        'userType': userType,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // If Firebase Auth user exists, save using UID (preferred)
      if (_auth.currentUser != null) {
        final uid = _auth.currentUser!.uid;
        debugPrint('Saving profile with Firebase UID: $uid');
        
        // Save with UID
        await _firestore.collection('users').doc(uid).set(profileData, SetOptions(merge: true));
        
        // Also save with phone for backward compatibility and easy lookup
        await _firestore.collection('users').doc(docId).set({
          ...profileData,
          'uid': uid, // Link to Firebase UID
        }, SetOptions(merge: true));
        
        // Update local state
        _user = _auth.currentUser;
      } else {
        // No Firebase user, save using phone as doc ID (legacy mode)
        debugPrint('No Firebase user, saving profile with phone as doc ID');
        await _firestore.collection('users').doc(docId).set(profileData, SetOptions(merge: true));
      }
      
      completePhoneSignin(
        phone: docId,
        name: name,
        address: address,
        userType: userType,
      );
      
      debugPrint('✅ Profile saved successfully');
    } catch (e) {
      debugPrint('Error creating/updating user profile: $e');
      rethrow;
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
    return cleaned.startsWith('+') ? cleaned : '+$cleaned';
  }
}
