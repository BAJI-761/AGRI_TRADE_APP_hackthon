import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'farmer/farmer_home.dart';
import 'retailer/retailer_home.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String? phoneNumber; // Optional if already in auth
  const UserTypeSelectionScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  String? _selectedUserType;
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Start voice prompt after animation delay
    Future.delayed(const Duration(milliseconds: 1000), _startVoicePrompt);
  }

  void _initializeAnimations() {
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(
        parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  String _getCurrentLanguage() {
    return Provider.of<LanguageService>(context, listen: false).currentLanguage;
  }

  Future<void> _startVoicePrompt() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final lang = _getCurrentLanguage();

    await voiceService.speak(lang == 'te'
        ? 'మీరు రైతు లేదా రిటైలర్? దయచేసి చెప్పండి లేదా ఎంచుకోండి.'
        : 'Are you a farmer or retailer? Please say or tap.');
  }

  Future<void> _handleVoiceInput() async {
    setState(() => _isListening = true);
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final lang = _getCurrentLanguage();

    try {
      await voiceService.speak(lang == 'te' ? 'చెప్పండి...' : 'Say Farmer or Retailer...');
      
      // Short pause
      await Future.delayed(const Duration(seconds: 1));

      final result = await voiceService.listenOnce(seconds: 5);

      if (mounted) {
        setState(() => _isListening = false);
        if (result.isNotEmpty) {
          _processUserTypeSelection(result);
        } else {
             await voiceService.speak(lang == 'te' 
                 ? 'వినపడలేదు. మళ్ళీ ప్రయత్నించండి.' 
                 : 'Could not hear. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _processUserTypeSelection(String spokenText) {
    String? selectedType;
    final text = spokenText.toLowerCase();

    if (text.contains('farmer') || text.contains('రైతు')) {
      selectedType = 'farmer';
    } else if (text.contains('retailer') ||
        text.contains('రిటైలర్') ||
        text.contains('shop') ||
        text.contains('store') ||
        text.contains('వ్యాపారి')) { // simplistic match
      selectedType = 'retailer';
    }

    if (selectedType != null) {
      _selectUserType(selectedType);
    } else {
        final lang = _getCurrentLanguage();
        final voiceService = Provider.of<VoiceService>(context, listen: false);
        voiceService.speak(lang == 'te' ? 'అర్థం కాలేదు.' : 'Did not understand.');
    }
  }

  Future<void> _selectUserType(String userType) async {
    setState(() => _selectedUserType = userType);
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final lang = _getCurrentLanguage();

    final confirmText = lang == 'te'
        ? (userType == 'farmer'
            ? 'రైతు ఎంచుకోబడింది. సేవ్ చేస్తున్నాము.'
            : 'రిటైలర్ ఎంచుకోబడింది. సేవ్ చేస్తున్నాము.')
        : (userType == 'farmer' ? 'Farmer selected.' : 'Retailer selected.');

    await voiceService.speak(confirmText);
    
    setState(() => _isLoading = true);

    try {
        if (widget.phoneNumber != null) {
             await authService.createUserWithPhone(widget.phoneNumber!, userType);
        } else {
             // If phone number is null, assume update current user
             await authService.updateUserType(userType); 
        }

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
    } catch (e) {
        if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed)
             );
        }
    } finally {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isTe = languageService.isTelugu;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.premiumGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                        Text(
                          isTe ? 'వినియోగదారు రకం' : 'Select Role',
                          style: AppTheme.displayMedium.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isTe
                              ? 'మీరు రైతు లేదా రిటైలర్?'
                              : 'Are you a Farmer or a Retailer?',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Cards Row
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Farmer Card
                        Expanded(
                          child: _UserTypeCard(
                            title: isTe ? 'రైతు' : 'Farmer',
                            subtitle: isTe ? 'పంటలు' : 'Grow Crops',
                            icon: Icons.agriculture_rounded,
                            isSelected: _selectedUserType == 'farmer',
                            onTap: () => _selectUserType('farmer'),
                            activeColor: AppTheme.primaryGreen,
                            textColor: AppTheme.primaryGreenDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Retailer Card
                        Expanded(
                          child: _UserTypeCard(
                            title: isTe ? 'రిటైలర్' : 'Retailer',
                            subtitle: isTe ? 'వ్యాపారం' : 'Trade Goods',
                            icon: Icons.store_rounded,
                            isSelected: _selectedUserType == 'retailer',
                            onTap: () => _selectUserType('retailer'),
                            activeColor: AppTheme.secondaryAmber,
                            textColor: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                 const SizedBox(height: 48),

                // Voice Trigger
                FadeTransition(
                     opacity: _fadeAnimation,
                     child: GestureDetector(
                        onTap: _handleVoiceInput,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                             color: _isListening ? AppTheme.errorRed : Colors.white.withOpacity(0.2),
                             shape: BoxShape.circle,
                             border: Border.all(color: Colors.white, width: 2),
                             boxShadow: [
                                 BoxShadow(
                                     color: Colors.black26, 
                                     blurRadius: 10, 
                                     offset: const Offset(0,4),
                                 )
                             ]
                          ),
                          child: Icon(
                             _isListening ? Icons.mic : Icons.mic_none,
                             color: Colors.white,
                             size: 32,
                          ),
                        ),
                     ),
                ),
                const SizedBox(height: 16),
                Text(
                     isTe ? 'నొక్కి చెప్పండి' : 'Tap to Speak',
                     style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                
                if(_isLoading)
                    const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color textColor;

  const _UserTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.3),
            width: isSelected ? 4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isSelected ? activeColor : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTheme.headingMedium.copyWith(
                color: isSelected ? textColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected ? textColor.withOpacity(0.7) : Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
                const SizedBox(height: 16),
                Icon(Icons.check_circle, color: activeColor, size: 24),
            ]
          ],
        ),
      ),
    );
  }
}
