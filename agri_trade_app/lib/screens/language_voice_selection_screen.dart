import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import 'phone_voice_input_screen.dart';

class LanguageVoiceSelectionScreen extends StatefulWidget {
  const LanguageVoiceSelectionScreen({super.key});

  @override
  State<LanguageVoiceSelectionScreen> createState() => _LanguageVoiceSelectionScreenState();
}

class _LanguageVoiceSelectionScreenState extends State<LanguageVoiceSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  String? _selectedLanguage;
  bool _isListening = false;
  bool _hasSpoken = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  Future<void> _startVoicePrompt() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    // Initialize voice service
    await voiceService.initializeSpeech();
    
    // Speak the language selection prompt
    await voiceService.speak(
      'Welcome to AgriTrade! Please say your preferred language. Say English or Telugu.'
    );
    
    setState(() {
      _hasSpoken = true;
    });
    
    // Start listening for language selection
    _startListening();
  }

  Future<void> _startListening() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    setState(() {
      _isListening = true;
    });
    
    _pulseController.repeat(reverse: true);
    
    // Listen for language selection
    final result = await voiceService.listenOnce(seconds: 15);
    
    setState(() {
      _isListening = false;
    });
    
    _pulseController.stop();
    
    if (result.isNotEmpty) {
      _processLanguageSelection(result.toLowerCase());
    } else {
      // If no response, show manual selection
      _showManualSelection();
    }
  }

  void _processLanguageSelection(String spokenText) {
    String? selectedLang;
    
    if (spokenText.contains('english') || spokenText.contains('inglish')) {
      selectedLang = 'en';
    } else if (spokenText.contains('telugu') || spokenText.contains('తెలుగు')) {
      selectedLang = 'te';
    }
    
    if (selectedLang != null) {
      _selectLanguage(selectedLang);
    } else {
      // Try again or show manual selection
      _showRetryDialog();
    }
  }

  void _selectLanguage(String languageCode) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    await languageService.setLanguage(languageCode);
    await voiceService.setLanguage(languageCode);
    
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    // Confirm selection with voice
    final confirmText = languageCode == 'te' 
        ? 'తెలుగు భాష ఎంచుకోబడింది. ఇప్పుడు మీ ఫోన్ నంబర్ చెప్పండి.'
        : 'English language selected. Now please say your phone number.';
    
    await voiceService.speak(confirmText);
    
    // Navigate to phone input screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneVoiceInputScreen(),
        ),
      );
    }
  }

  void _showManualSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                _selectLanguage('en');
              },
            ),
            ListTile(
              leading: const Text('🇮🇳'),
              title: const Text('తెలుగు'),
              onTap: () {
                Navigator.pop(context);
                _selectLanguage('te');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Try Again'),
        content: const Text('I didn\'t understand. Please try again or select manually.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startListening();
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualSelection();
            },
            child: const Text('Select Manually'),
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
                  child: const Text(
                    'Choose Your Language',
                    style: TextStyle(
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
                    'Please say your preferred language',
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
                              ? 'Listening... Say "English" or "Telugu"'
                              : _hasSpoken
                                  ? 'Speak now...'
                                  : 'Preparing voice recognition...',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Language Options
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLanguageOption('🇺🇸', 'English', 'en'),
                            _buildLanguageOption('🇮🇳', 'తెలుగు', 'te'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Manual Selection Button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: _showManualSelection,
                    child: Text(
                      'Select Manually',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
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

  Widget _buildLanguageOption(String flag, String name, String code) {
    final isSelected = _selectedLanguage == code;
    
    return GestureDetector(
      onTap: () => _selectLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
