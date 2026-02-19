import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../services/sms_provider_interface.dart';
import '../theme/app_theme.dart';
import 'otp_verification_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/glass_card_wrapper.dart';

class PhoneVoiceInputScreen extends StatefulWidget {
  const PhoneVoiceInputScreen({super.key});

  @override
  State<PhoneVoiceInputScreen> createState() => _PhoneVoiceInputScreenState();
}

class _PhoneVoiceInputScreenState extends State<PhoneVoiceInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isListening = false;
  bool _isValidating = false;
  bool _isLoading = false;
  String _currentLanguage = 'en';
  bool _hasCheckedUser = false; // Prevent infinite loops
  int _retryCount = 0;
  String _completePhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLanguage();
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

  Future<void> _startVoicePrompt() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ensure voice features are enabled, engine is initialized, and language aligned to UI
    try {
      await voiceService.setVoiceEnabled(true);
      await voiceService.initializeSpeech();
    } catch (_) {}
    try {
      final ls = Provider.of<LanguageService>(context, listen: false);
      await voiceService.setLanguage(ls.currentLanguage);
    } catch (_) {}

    final prompt = _currentLanguage == 'te' 
        ? 'దయచేసి మీ ఫోన్ నంబర్ చెప్పండి.'
        : 'Please say your phone number.';
    
    await voiceService.speak(prompt);

    // Wait for TTS to finish before starting the microphone to avoid auto-cancel
    int waited = 0;
    while (voiceService.isSpeaking && waited < 4000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
    
    setState(() {
      _isListening = true;
    });
    
    _pulseController.repeat(reverse: true);
    
    // Start listening for phone number
    _startListening();
  }

  Future<void> _startListening() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    // Listen for phone number with extended time
    final result = await voiceService.listenOnce(seconds: 25);
    
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      _pulseController.stop();
    }
    
    if (result.isNotEmpty) {
      _processPhoneNumber(result);
    } else {
      if (mounted) _showRetryDialog();
    }
  }

  void _processPhoneNumber(String spokenText) {
    debugPrint('Processing phone number: $spokenText');
    
    // Normalize multilingual and word-based digits to 0-9
    String processedText = _normalizeSpokenNumber(spokenText);
    debugPrint('After normalization: $processedText');
    
    // Extract digits only
    final numbers = processedText.replaceAll(RegExp(r'[^\d]'), '');
    debugPrint('Extracted numbers: $numbers');
    
    if (numbers.length >= 10) {
      setState(() {
        _phoneController.text = numbers.substring(numbers.length - 10); // last 10 digits
      });
      _validateAndCheckUser();
    } else {
      _showInvalidNumberDialog();
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

  // Converts English word digits, Hindi/Devanagari numerals, and common phrases like 'double' to Arabic numerals
  String _normalizeSpokenNumber(String text) {
    String t = text.toLowerCase();
    
    // Replace separators/words often inserted by STT
    t = t
      .replaceAll(RegExp(r'[\-–—]'), ' ') // dashes to space
      .replaceAll('plus', ' ')
      .replaceAll('space', ' ')
      .replaceAll('dot', ' ')
      .replaceAll('point', ' ')
      .replaceAll('number', ' ');

    // Handle 'double'/'triple' patterns (e.g., double nine -> 99)
    final Map<String, String> wordToDigit = {
      'zero': '0', 'oh': '0', 'o': '0',
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'for': '4',
      'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'ate': '8', 'nine': '9',
    };
    // Expand doubles/triples first
    t = t.replaceAllMapped(RegExp(r'(double|triple)\s+(zero|oh|o|one|two|three|four|for|five|six|seven|eight|ate|nine)'), (m) {
      final count = m.group(1) == 'triple' ? 3 : 2;
      final d = wordToDigit[m.group(2)!] ?? '';
      return d * count;
    });
    
    // Telugu words to digits
    t = _convertTeluguToEnglishNumbers(t);

    // Hindi/Devanagari numerals ०१२३४५६७८९ to 0-9
    const devanagari = {
      '०': '0','१': '1','२': '2','३': '3','४': '4','५': '5','६': '6','७': '7','८': '8','९': '9'
    };
    devanagari.forEach((k, v) { t = t.replaceAll(k, v); });

    // English word digits to numerals
    wordToDigit.forEach((k, v) {
      t = t.replaceAll(RegExp('\\b$k\\b'), v);
    });

    // Collapse multiple spaces
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t.trim();
  }

  Future<void> _validateAndCheckUser() async {
    if (_phoneController.text.length < 10) {
      _showInvalidNumberDialog();
      return;
    }

    // Prevent infinite loops - don't check again if already checked
    if (_hasCheckedUser || _isValidating) {
      debugPrint('🚫 Already checking or checked user, skipping...');
      return;
    }

    setState(() {
      _isValidating = true;
      _hasCheckedUser = true;
    });

    try {
      final smsService = Provider.of<SMSProvider>(context, listen: false);
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      final phoneNumber = _completePhoneNumber.isNotEmpty 
          ? _completePhoneNumber 
          : '+91${_phoneController.text}'; // Fallback
      
      debugPrint('📞 Sending OTP to phone: $phoneNumber');
      
      final sent = await smsService.sendOTP(phoneNumber);
      if (sent) {
        final text = _currentLanguage == 'te' 
            ? 'OTP పంపబడింది. దయచేసి OTPని ఎంటర్ చేయండి.'
            : 'OTP sent. Please enter the OTP.';
        await voiceService.speak(text);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                phoneNumber: phoneNumber,
              ),
            ),
          );
        }
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      debugPrint('❌ Error checking user: $e');
      // Reset the flag so user can retry
      _hasCheckedUser = false;
      
      // Only show error for actual exceptions (timeouts)
      // If loadUserByPhone returns false, it means proceed to registration (not an error)
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timed out')) {
        _showOfflineErrorDialog();
      } else {
        // For other errors, show error and allow retry
        debugPrint('⚠️ OTP send/check failed');
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _verifyPhoneNumber() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await _validateAndCheckUser();
      setState(() => _isLoading = false);
    }
  }

  void _handleVoiceInput() {
    if (_isListening) {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      _startVoicePrompt();
    }
  }

  void _showInvalidNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'చెల్లని నంబర్' : 'Invalid Number'),
        content: Text(_currentLanguage == 'te' 
            ? 'దయచేసి 10 అంకెల ఫోన్ నంబర్ చెప్పండి.'
            : 'Please say a valid 10-digit phone number.'),
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
    _retryCount += 1;
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
              if (_retryCount >= 2) {
                // Switch to manual entry after two failed attempts
                FocusScope.of(context).requestFocus(_phoneFocusNode);
              } else {
                _startVoicePrompt();
              }
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
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_currentLanguage == 'te' ? 'సరే' : 'OK'),
          ),
          if (message == null) TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hasCheckedUser = false; // Reset flag before retry
              _validateAndCheckUser(); // Retry
            },
            child: Text(_currentLanguage == 'te' ? 'మళ్లీ ప్రయత్నించండి' : 'Retry'),
          ),
        ],
      ),
    );
  }

  void _showOfflineErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentLanguage == 'te' ? 'ఇంటర్నెట్ లేదు' : 'No Internet'),
        content: Text(_currentLanguage == 'te' 
            ? 'ఇంటర్నెట్ కనెక్షన్ లేదు. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ను తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.'
            : 'No internet connection. Please check your internet and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_currentLanguage == 'te' ? 'సరే' : 'OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hasCheckedUser = false; // Reset flag before retry
              _validateAndCheckUser(); // Retry
            },
            child: Text(_currentLanguage == 'te' ? 'మళ్లీ ప్రయత్నించండి' : 'Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isTelugu = languageService.isTelugu;

    return Scaffold(
      body: Container(
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
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: GlassCardWrapper(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_iphone,
                        size: 40,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isTelugu ? 'లాగిన్' : 'Login',
                      style: AppTheme.displayMedium.copyWith(
                        color: AppTheme.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTelugu
                          ? 'కొనసాగించడానికి మీ ఫోన్ నంబర్ ఎంటర్ చేయండి'
                          : 'Enter your phone number to continue',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    
                    Form(
                      key: _formKey,
                      child: IntlPhoneField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: isTelugu ? 'ఫోన్ నంబర్' : 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(),
                          ),
                          counterText: ""
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (phone) {
                          _completePhoneNumber = phone.completeNumber;
                        },
                        onCountryChanged: (country) {
                          // Optional: update hint or validation logic
                        },
                        style: AppTheme.headingMedium.copyWith(fontSize: 18),
                        flagsButtonPadding: const EdgeInsets.only(left: 10),
                        showDropdownIcon: false, // Cleaner look
                        dropdownIconPosition: IconPosition.trailing,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: isTelugu ? 'OTP ని పంపండి' : 'Send OTP',
                      onPressed: _isLoading ? null : _verifyPhoneNumber,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      isTelugu ? 'లేదా, క్లిక్ చేసి నంబర్ చెప్పండి' : 'Or, tap to speak number',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      width: 64,
                      child: FloatingActionButton(
                        onPressed: _handleVoiceInput,
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
    );
  }
}
