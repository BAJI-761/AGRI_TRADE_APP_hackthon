import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import 'farmer/farmer_home.dart';
import 'retailer/retailer_home.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String phoneNumber;
  
  const UserTypeSelectionScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  String? _selectedUserType;
  bool _isListening = false;
  String _currentLanguage = 'en';

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
    final languageService = Provider.of<LanguageService>(context, listen: false);
    setState(() {
      _currentLanguage = languageService.currentLanguage;
    });
  }

  Future<void> _startVoicePrompt() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prompt = _currentLanguage == 'te' 
        ? 'మీరు రైతు లేదా రిటైలర్? దయచేసి చెప్పండి.'
        : 'Are you a farmer or retailer? Please say.';
    
    await voiceService.speak(prompt);
    
    setState(() {
      _isListening = true;
    });
    
    _pulseController.repeat(reverse: true);
    
    // Start listening for user type
    _startListening();
  }

  Future<void> _startListening() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    // Listen for user type
    final result = await voiceService.listenOnce(seconds: 15);
    
    setState(() {
      _isListening = false;
    });
    
    _pulseController.stop();
    
    if (result.isNotEmpty) {
      _processUserTypeSelection(result);
    } else {
      _showRetryDialog();
    }
  }

  void _processUserTypeSelection(String spokenText) {
    String? selectedType;
    final text = spokenText.toLowerCase();
    
    if (text.contains('farmer') || text.contains('రైతు') || text.contains('farmer')) {
      selectedType = 'farmer';
    } else if (text.contains('retailer') || text.contains('రిటైలర్') || text.contains('shop')) {
      selectedType = 'retailer';
    }
    
    if (selectedType != null) {
      _selectUserType(selectedType);
    } else {
      _showRetryDialog();
    }
  }

  void _selectUserType(String userType) async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _selectedUserType = userType;
    });
    
    // Confirm selection with voice
    final confirmText = _currentLanguage == 'te' 
        ? (userType == 'farmer' 
            ? 'రైతు ఎంచుకోబడింది. మీ డాష్‌బోర్డ్‌కు వెళుతున్నాము.'
            : 'రిటైలర్ ఎంచుకోబడింది. మీ డాష్‌బోర్డ్‌కు వెళుతున్నాము.')
        : (userType == 'farmer' 
            ? 'Farmer selected. Going to your dashboard.'
            : 'Retailer selected. Going to your dashboard.');
    
    await voiceService.speak(confirmText);
    
    // Create user account with phone number
    await authService.createUserWithPhone(
      widget.phoneNumber,
      userType,
    );
    
    // Navigate to appropriate home screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => userType == 'farmer' 
              ? const FarmerHome()
              : const RetailerHome(),
        ),
      );
    }
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
            child: Text(_currentLanguage == 'te' ? 'మాన్యువల్ ఎంచుకోండి' : 'Select Manually'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    _currentLanguage == 'te' ? 'వినియోగదారు రకం' : 'User Type',
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
                        ? 'మీరు రైతు లేదా రిటైలర్?'
                        : 'Are you a farmer or retailer?',
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
                                  ? 'వినికిడి... రైతు లేదా రిటైలర్ చెప్పండి'
                                  : 'Listening... Say farmer or retailer')
                              : (_currentLanguage == 'te' 
                                  ? 'రైతు లేదా రిటైలర్ చెప్పండి'
                                  : 'Say farmer or retailer'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // User Type Options
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildUserTypeOption(
                                Icons.agriculture,
                                _currentLanguage == 'te' ? 'రైతు' : 'Farmer',
                                'farmer',
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildUserTypeOption(
                                Icons.store,
                                _currentLanguage == 'te' ? 'రిటైలర్' : 'Retailer',
                                'retailer',
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _startVoicePrompt,
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption(IconData icon, String title, String type, Color color) {
    final isSelected = _selectedUserType == type;
    
    return GestureDetector(
      onTap: () => _selectUserType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _currentLanguage == 'te' 
                  ? (type == 'farmer' ? 'పంటలు పండించండి' : 'వ్యాపారం చేయండి')
                  : (type == 'farmer' ? 'Grow crops' : 'Sell products'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
