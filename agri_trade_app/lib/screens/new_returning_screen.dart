import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'phone_voice_input_screen.dart';
import 'login_screen.dart';
import 'registration_profile_screen.dart';

class NewReturningScreen extends StatefulWidget {
  const NewReturningScreen({super.key});

  @override
  State<NewReturningScreen> createState() => _NewReturningScreenState();
}

class _NewReturningScreenState extends State<NewReturningScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadLangAndPrompt();
    });
  }

  Future<void> _loadLangAndPrompt() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    setState(() => _currentLanguage = languageService.currentLanguage);
    final voice = Provider.of<VoiceService>(context, listen: false);
    final text = _currentLanguage == 'te'
        ? 'మీరు కొత్త వినియోగదారునా లేదా తిరిగి వస్తున్న వినియోగదారునా? కొత్త లేదా రిటర్నింగ్ అని చెప్పండి.'
        : 'Are you a new user or a returning user? Say New or Returning.';
    await voice.speak(text);
  }

  void _goToPhoneFlow() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PhoneVoiceInputScreen()));
  }

  void _goToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  void _goToRegistration() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationProfileScreen(phoneNumber: '')));
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
            colors: AppTheme.premiumGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _currentLanguage == 'te' ? 'మీరు ఎవరు?' : 'Welcome!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _currentLanguage == 'te'
                        ? 'కొత్త లేదా తిరిగి వస్తున్న వినియోగదారుని ఎంపిక చేయండి'
                        : 'Are you new here or returning?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChoiceCard(
                        label: _currentLanguage == 'te' ? 'కొత్త వినియోగదారు' : 'I am New',
                        subtitle: _currentLanguage == 'te' ? 'ఖాతా సృష్టించండి' : 'Create an account',
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppTheme.secondaryAmber,
                        onPressed: _goToRegistration,
                      ),
                      const SizedBox(height: 18),
                      _buildChoiceCard(
                        label: _currentLanguage == 'te' ? 'తిరిగి వస్తున్నాను' : 'I am Returning',
                        subtitle: _currentLanguage == 'te' ? 'లాగ్ ఇన్ అవ్వండి' : 'Sign in to your account',
                        icon: Icons.login_rounded,
                        color: AppTheme.accentBlue,
                        onPressed: _goToLogin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.white.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
