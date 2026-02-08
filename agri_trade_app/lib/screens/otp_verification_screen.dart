import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../services/firebase_phone_auth_service.dart';
import '../services/sms_provider_interface.dart';
import '../services/auth_service.dart';
import 'registration_profile_screen.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

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
    final result = await voiceService.listenOnce(seconds: 20);
    
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
          // Navigate to root (AuthWrapper will decide based on auth state)
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else {
          // New user: go to profile registration
          final text = _currentLanguage == 'te'
              ? 'OTP ధృవీకరించబడింది. దయచేసి మీ వివరాలను పూర్తి చేయండి.'
              : 'OTP verified. Please complete your profile.';
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
        _showInvalidOTPDialog();
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      _safeSetState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    _safeSetState(() {
      _isVerifying = true;
      _canResend = false;
      _resendCountdown = 60;
    });

    try {
      final smsService = Provider.of<SMSProvider>(context, listen: false);
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      
      final success = await smsService.sendOTP(widget.phoneNumber);
      
      if (success) {
        final confirmText = _currentLanguage == 'te' 
            ? 'కొత్త OTP పంపబడింది.'
            : 'New OTP sent successfully.';
        
        await voiceService.speak(confirmText);
        _startCountdown();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      _safeSetState(() {
        _isVerifying = false;
      });
    }
  }

  void _showInvalidOTPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'చెల్లని OTP' : 'Invalid OTP'),
        content: Text(_currentLanguage == 'te' 
            ? 'దయచేసి సరైన 6 అంకెల OTP ని ఎంటర్ చేయండి.'
            : 'Please enter a valid 6-digit OTP.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startVoicePrompt();
            },
            child: Text(_currentLanguage == 'te' ? 'మళ్లీ ప్రయత్నించండి' : 'Try Again'),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'మళ్లీ ప్రయత్నించండి' : 'Try Again'),
        content: Text(_currentLanguage == 'te' 
            ? 'నేను వినలేకపోయాను. మళ్లీ ప్రయత్నించండి.'
            : 'I couldn\'t hear you. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startVoicePrompt();
            },
            child: Text(_currentLanguage == 'te' ? 'మళ్లీ ప్రయత్నించండి' : 'Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_currentLanguage == 'te' ? 'మాన్యువల్ ఎంటర్' : 'Enter Manually'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'లోపం' : 'Error'),
        content: Text(_currentLanguage == 'te' 
            ? 'ఏదో లోపం జరిగింది. మళ్లీ ప్రయత్నించండి.'
            : 'Something went wrong. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_currentLanguage == 'te' ? 'సరే' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    try {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      voiceService.stopListening();
    } catch (_) {}
    _fadeController.dispose();
    _pulseController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade800,
              Colors.green.shade400,
              Colors.green.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _currentLanguage == 'te' ? 'OTP ధృవీకరణ' : 'Verify OTP',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _currentLanguage == 'te' 
                        ? 'మీ ఫోన్ ${widget.phoneNumber}కి పంపబడిన OTP ని ఎంటర్ చేయండి'
                        : 'Enter the OTP sent to ${widget.phoneNumber}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Voice Interface
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Microphone Animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isListening ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening 
                                    ? Colors.red.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: _isListening 
                                      ? Colors.red
                                      : Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                Icons.mic,
                                size: 80,
                                color: _isListening ? Colors.red : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Status Text
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          _isListening 
                              ? (_currentLanguage == 'te' 
                                  ? 'వినికిడి... OTP నెమ్మదిగా చెప్పండి (20 సెకన్లు)'
                                  : 'Listening... Say the OTP slowly (20 seconds)')
                              : _isVerifying
                                  ? (_currentLanguage == 'te' 
                                      ? 'OTP ధృవీకరిస్తోంది...'
                                      : 'Verifying OTP...')
                                  : (_currentLanguage == 'te' 
                                      ? 'OTP నెమ్మదిగా చెప్పండి లేదా టైప్ చేయండి'
                                      : 'Say the OTP slowly or type it'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // OTP Input Field
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(15),
                            fieldHeight: 60,
                            fieldWidth: 50,
                            activeFillColor: Colors.white.withValues(alpha: 0.9),
                            inactiveFillColor: Colors.white.withValues(alpha: 0.1),
                            selectedFillColor: Colors.white.withValues(alpha: 0.9),
                            activeColor: Colors.green,
                            inactiveColor: Colors.white.withValues(alpha: 0.5),
                            selectedColor: Colors.green,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          enableActiveFill: true,
                          onCompleted: (value) {
                            final sanitized = value.replaceAll(RegExp(r'\D'), '');
                            if (sanitized != value) {
                              _otpController.text = sanitized;
                            }
                            _verifyOTP();
                          },
                          onChanged: (value) {
                            final sanitized = value.replaceAll(RegExp(r'\D'), '');
                            if (sanitized != value) {
                              _otpController.text = sanitized;
                            }
                            // Auto-verify when 6 digits are entered
                            if (sanitized.length == 6) {
                              _verifyOTP();
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                        // Resend OTP Button
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentLanguage == 'te' 
                                    ? 'OTP రీసెండ్ చేయండి'
                                    : 'Resend OTP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _canResend ? _resendOTP : null,
                                child: Text(
                                  _canResend 
                                      ? (_currentLanguage == 'te' ? 'పంపండి' : 'Send')
                                      : '${_resendCountdown}s',
                                  style: TextStyle(
                                    color: _canResend ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Show OTP info for debugging (Firebase sends SMS automatically)
                        Consumer<SMSProvider>(
                          builder: (context, smsService, child) {
                            final storedOTP = smsService.getCurrentOTP(widget.phoneNumber);
                            final showOTP = smsService.isTestMode || storedOTP != null;
                            
                            if (showOTP && storedOTP != null) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '📱 Firebase Phone Auth',
                                        style: TextStyle(
                                          color: Colors.blue.shade300,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Check if billing is enabled (only for Firebase service)
                                      Builder(
                                        builder: (context) {
                                          final smsService = Provider.of<SMSProvider>(context, listen: false);
                                          bool billingEnabled = true;
                                          
                                          // Try to check billing status if it's Firebase service
                                          if (smsService is FirebasePhoneAuthService) {
                                            billingEnabled = smsService.isBillingEnabled(widget.phoneNumber);
                                          }
                                          
                                          return Column(
                                            children: [
                                              if (!billingEnabled)
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.orange,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _currentLanguage == 'te'
                                                        ? '⚠️ Firebase బిల్లింగ్ ప్రారంభించబడలేదు. దయచేసి క్రింద ఇచ్చిన టెస్ట్ OTPని ఉపయోగించండి.'
                                                        : '⚠️ Firebase billing not enabled. Please use the test OTP below.',
                                                    style: TextStyle(
                                                      color: Colors.orange.shade200,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              Text(
                                                billingEnabled
                                                    ? (_currentLanguage == 'te'
                                                        ? 'OTP SMS Firebase ద్వారా పంపబడుతుంది. మీ ఫోన్‌లో OTP తనిఖీ చేయండి.'
                                                        : 'OTP SMS sent by Firebase. Check your phone for the OTP.')
                                                    : (_currentLanguage == 'te'
                                                        ? 'టెస్ట్ OTP (డెవలప్మెంట్ మోడ్)'
                                                        : 'Test OTP (Development Mode)'),
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.3),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.green,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  _currentLanguage == 'te'
                                                      ? 'OTP: $storedOTP'
                                                      : 'OTP: $storedOTP',
                                                  style: TextStyle(
                                                    color: Colors.green.shade100,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              if (!billingEnabled)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    _currentLanguage == 'te'
                                                        ? 'దయచేసి ఈ OTPని ఉపయోగించి వెరిఫై చేయండి.'
                                                        : 'Please use this OTP to verify.',
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.7),
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _startVoicePrompt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            _currentLanguage == 'te' ? 'మళ్లీ చెప్పండి' : 'Speak Again',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                )
                              : Text(
                                  _currentLanguage == 'te' ? 'ధృవీకరించండి' : 'Verify',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
