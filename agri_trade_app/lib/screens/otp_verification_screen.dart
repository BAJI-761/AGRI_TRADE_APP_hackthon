import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../services/firebase_phone_auth_service.dart';
import '../services/sms_provider_interface.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'registration_profile_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../widgets/glass_card_wrapper.dart';
import '../widgets/primary_button.dart';
import '../widgets/navigation_helper.dart';
import 'farmer/farmer_home.dart';
import 'retailer/retailer_home.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isListening = false;
  bool _hasVerifiedSuccessfully = false; // Prevent multiple verification attempts
  String _currentLanguage = 'en';
  int _resendCountdown = 60;
  bool _canResend = false;
  Timer? _countdownTimer;
  bool _isDisposed = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLanguage();
    _startCountdown();
    _startVoicePrompt();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );



    _fadeController.forward();
  }

  Future<void> _getCurrentLanguage() async {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final languageService = Provider.of<LanguageService>(context, listen: false);
        setState(() {
          _currentLanguage = languageService.currentLanguage;
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }
      _safeSetState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _startVoicePrompt() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prompt = _currentLanguage == 'te' 
        ? 'OTP పంపబడింది. దయచేసి OTP ని చెప్పండి లేదా టైప్ చేయండి.'
        : 'OTP has been sent. Please say the OTP or type it.';
    
    await voiceService.speak(prompt);
    
    if (!mounted || _isDisposed) return;
    _safeSetState(() {
      _isListening = true;
    });
    
    _pulseController.repeat(reverse: true);
    
    // Start listening for OTP
    _startListening();
  }

  Future<void> _startListening() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    // Listen for OTP with extended time
    final result = await voiceService.listenOnce(seconds: 40);
    
    if (!mounted || _isDisposed) return;
    _safeSetState(() {
      _isListening = false;
    });
    
    _pulseController.stop();
    
    if (result.isNotEmpty) {
      _processOTP(result);
    } else {
      _showRetryDialog();
    }
  }

  void _processOTP(String spokenText) {
    debugPrint('Processing OTP: $spokenText');
    
    // Convert Telugu numbers to English if needed
    String processedText = _convertTeluguToEnglishNumbers(spokenText);
    debugPrint('After Telugu conversion: $processedText');
    
    // Extract numbers from spoken text
    final numbers = processedText.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint('Extracted OTP numbers: $numbers');
    
    if (numbers.length == 6) {
      if (!mounted || _isDisposed) return;
      _otpController.text = numbers;
      _verifyOTP();
    } else {
      _showInvalidOTPDialog();
    }
  }

  String _convertTeluguToEnglishNumbers(String text) {
    // Convert Telugu numbers to English (removed duplicate keys)
    final teluguToEnglish = {
      'జీరో': '0',
      'ఒకటి': '1', 'ఒక': '1',
      'రెండు': '2',
      'మూడు': '3',
      'నాలుగు': '4',
      'ఐదు': '5', 'ఫైవ్': '5',
      'ఆరు': '6',
      'ఏడు': '7',
      'ఎనిమిది': '8',
      'తొమ్మిది': '9',
    };
    
    String result = text;
    teluguToEnglish.forEach((telugu, english) {
      result = result.replaceAll(telugu, english);
    });
    
    return result;
  }

  Future<void> _verifyOTP() async {
    // Prevent multiple verification attempts
    if (_hasVerifiedSuccessfully || _isVerifying) {
      debugPrint('🚫 Verification already completed or in progress');
      return;
    }

    final sanitized = _otpController.text.replaceAll(RegExp(r'\D'), '');
    if (sanitized.length != 6) {
      _showInvalidOTPDialog();
      return;
    }

    _safeSetState(() {
      _isVerifying = true;
    });

    try {
      final smsService = Provider.of<SMSProvider>(context, listen: false);
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Verify OTP
      final isValid = await smsService.verifyOTP(widget.phoneNumber, sanitized);
      
      if (isValid) {
        // Mark as successfully verified to prevent retries
        _hasVerifiedSuccessfully = true;
        
        // Firebase Auth automatically signs in user after verification
        // Check if Firebase user exists
        if (smsService is FirebasePhoneAuthService) {
          final firebaseUser = smsService.getCurrentUser();
          if (firebaseUser != null) {
            debugPrint('✅ Firebase user authenticated: ${firebaseUser.uid}');
            // Update AuthService with Firebase user phone
            final phone = firebaseUser.phoneNumber ?? widget.phoneNumber;
            debugPrint('📱 Firebase phone: $phone');
          }
        }
        
        // OTP success: try to fetch existing user profile
        final found = await authService.loadUserByPhone(widget.phoneNumber);

          if (found) {
            final text = _currentLanguage == 'te'
               ? 'స్వాగతం! మీ డాష్‌బోర్డ్‌కు వెళుతున్నాము.'
               : 'Welcome back! Taking you to your dashboard.';
            await voiceService.speak(text);
          
          if (!mounted) return;
          
          // Navigate based on user type
          final userType = authService.userType;
          debugPrint('Navigating to home for user type: $userType');
          
          if (userType == 'farmer') {
             Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const FarmerHome()), 
              (route) => false,
            );
          } else if (userType == 'retailer') {
             Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const RetailerHome()), 
              (route) => false,
            );
          } else {
            // Fallback if user type is missing or unknown
            debugPrint('Unknown user type: $userType');
             Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const NavigationHelper(child: SizedBox())), 
              (route) => false,
            );
          }
          
        } else {
          // User not found -> Registration
           final text = _currentLanguage == 'te'
              ? 'ధృవీకరణ విజయవంతమైంది. దయచేసి మీ ప్రొఫైల్‌ను పూర్తి చేయండి.'
              : 'Verification successful. Please complete your profile.';
           await voiceService.speak(text);
           
           if (!mounted) return;
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationProfileScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      } else {
         // Invalid OTP
         _showInvalidOTPDialog();
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      _showErrorDialog();
    } finally {
      _safeSetState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    
    // reset timer
    _safeSetState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _startCountdown();
    
    try {
       final smsService = Provider.of<SMSProvider>(context, listen: false);
       await smsService.sendOTP(widget.phoneNumber);
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_currentLanguage == 'te' ? 'OTP మళ్లీ పంపబడింది' : 'OTP Resent'))
       );
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
       );
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'వాయిస్ గుర్తించబడలేదు' : 'Voice Not Recognized'),
        content: Text(_currentLanguage == 'te'
            ? 'దయచేసి OTP ని స్పష్టంగా చెప్పండి లేదా టైప్ చేయండి.'
            : 'Please say the OTP clearly or type it manually.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startVoicePrompt(); // Retry listening
            },
            child: Text(_currentLanguage == 'te' ? 'మళ్లీ ప్రయత్నించండి' : 'Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == 'te' ? 'రద్దు చేయండి' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  void _showInvalidOTPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'తప్పు OTP' : 'Invalid OTP'),
        content: Text(_currentLanguage == 'te' 
            ? 'మీరు ఎంటర్ చేసిన OTP తప్పు. దయచేసి సరైన OTP ని ఎంటర్ చేయండి.'
            : 'The OTP you entered is incorrect. Please enter the correct OTP.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == 'te' ? 'సరే' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog([String? message]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'లోపం' : 'Error'),
        content: Text(message ?? (_currentLanguage == 'te' 
            ? 'కొంత లోపం జరిగింది. మళ్లీ ప్రయత్నించండి.'
            : 'Something went wrong. Please try again.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == 'te' ? 'సరే' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _otpController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isTelugu = languageService.isTelugu;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.premiumGradient),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCardWrapper(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 40,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isTelugu ? 'OTP ధృవీకరణ' : 'OTP Verification',
                      style: AppTheme.displayMedium.copyWith(
                        color: AppTheme.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTelugu
                          ? '${widget.phoneNumber} కి పంపిన OTP ని ఎంటర్ చేయండి'
                          : 'Enter the OTP sent to ${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      obscureText: false,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white.withValues(alpha: 0.5),
                        selectedFillColor: Colors.white,
                        activeColor: AppTheme.primaryGreen,
                        inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.3),
                        selectedColor: AppTheme.primaryGreenDark,
                      ),
                      animationDuration: const Duration(milliseconds: 300),
                      backgroundColor: Colors.transparent,
                      enableActiveFill: true,
                      keyboardType: TextInputType.number,
                      onCompleted: (v) {
                        _verifyOTP();
                      },
                      onChanged: (value) {},
                      beforeTextPaste: (text) {
                        return true;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_isVerifying)
                      const CircularProgressIndicator(color: AppTheme.primaryGreen)
                    else
                      PrimaryButton(
                        label: isTelugu ? 'ధృవీకరించండి' : 'Verify',
                        onPressed: _verifyOTP,
                      ),
                      
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: _canResend ? _resendOTP : null,
                      child: Text(
                        _canResend 
                            ? (isTelugu ? 'OTP ని మళ్లీ పంపండి' : 'Resend OTP')
                            : (isTelugu ? 'OTP మళ్లీ పంపండి ($_resendCountdown)' : 'Resend OTP in $_resendCountdown s'),
                        style: TextStyle(
                          color: _canResend ? AppTheme.primaryGreen : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      isTelugu ? 'లేదా, క్లిక్ చేసి OTP చెప్పండి' : 'Or, tap to speak OTP',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      width: 64,
                      child: FloatingActionButton(
                        onPressed: _startVoicePrompt,
                        backgroundColor: _isListening
                            ? AppTheme.errorRed
                            : AppTheme.primaryGreen,
                        child: Icon(_isListening ? Icons.mic_off : Icons.mic,
                            size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildDemoOTPDisplay(context),
    );
  }

  Widget? _buildDemoOTPDisplay(BuildContext context) {
    // Only show in debug mode or if explicitly enabled
    // Retrieving OTP from provider
    final smsService = Provider.of<SMSProvider>(context, listen: false);
    final otp = smsService.getCurrentOTP(widget.phoneNumber);
    
    if (otp == null) return null;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber.withValues(alpha: 0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.developer_mode, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'Demo OTP: $otp',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.orange),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: otp));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('OTP copied to clipboard'), duration: Duration(seconds: 1)),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
