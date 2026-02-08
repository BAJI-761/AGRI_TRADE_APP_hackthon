import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
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
    // Defer language load and voice prompt until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLangAndPrompt();
      }
    });
  }

  Future<void> _loadLangAndPrompt() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    setState(() {
      _currentLanguage = languageService.currentLanguage;
    });
    final voice = Provider.of<VoiceService>(context, listen: false);
    final text = _currentLanguage == 'te'
        ? 'మీరు కొత్త వినియోగదారునా లేదా తిరిగి వస్తున్న వినియోగదారునా? కొత్త లేదా రిటర్నింగ్ అని చెప్పండి.'
        : 'Are you a new user or a returning user? Say New or Returning.';
    await voice.speak(text);
  }

  void _goToPhoneFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhoneVoiceInputScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _goToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationProfileScreen(phoneNumber: '')),
    );
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _currentLanguage == 'te' ? 'మీరు ఎవరు?' : 'Who are you?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _currentLanguage == 'te'
                        ? 'కొత్త లేదా తిరిగి వస్తున్న వినియోగదారుని ఎంపిక చేయండి'
                        : 'Choose whether you are new or returning',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ChoiceButton(
                        label: _currentLanguage == 'te' ? 'కొత్త వినియోగదారు' : 'I am New',
                        icon: Icons.person_add_alt_1,
                        onPressed: _goToRegistration,
                      ),
                      const SizedBox(height: 20),
                      _ChoiceButton(
                        label: _currentLanguage == 'te' ? 'తిరిగి వస్తున్నాను' : 'I am Returning',
                        icon: Icons.login,
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
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green.shade800,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


