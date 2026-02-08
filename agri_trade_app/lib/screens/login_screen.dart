import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import 'phone_voice_input_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Speak gentle guidance once when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final voice = Provider.of<VoiceService>(context, listen: false);
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await voice.setLanguage(languageService.currentLanguage);
      await voice.speak(languageService.isTelugu
          ? 'ఫోన్ ద్వారా OTP తో లాగిన్ చేయడానికి కొనసాగించండి.'
          : 'Continue to login with your phone using OTP.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
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
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + MediaQuery.of(context).viewInsets.bottom),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 64,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageService.getLocalizedString('app_title'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(languageService.getLocalizedString('welcome_back'),
                            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 32),
                        // Voice language quick-setup and voice login CTA
                        _VoiceLoginControls(
                          onVoiceLogin: _handleVoiceLogin,
                          onVoiceGuide: _startLoginVoiceGuide,
                        ),
                        const SizedBox(height: 16),
                        // Instructions
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            languageService.isTelugu
                                ? 'OTP సహాయంతో మీ ఫోన్ ద్వారా లాగిన్ చేయండి.'
                                : 'Login with your phone via OTP.',
                            style: TextStyle(color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PhoneVoiceInputScreen(),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(languageService.getLocalizedString('login'), style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Secondary action: Voice Login button for accessibility
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : () => _handleVoiceLogin(context),
                            icon: Icon(Icons.mic, color: Colors.green.shade700),
                            label: Text(
                              languageService.getLocalizedString('voice_login'),
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Demo Login buttons for testing
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _demoLogin('farmer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(languageService.getLocalizedString('demo_farmer')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _demoLogin('retailer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(languageService.getLocalizedString('demo_retailer')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Text fallback for voice testing
                        Text(
                          'Note: Voice features work best on mobile devices. On web, use the mic buttons in each screen.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Registration toggle removed
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Future<void> _startLoginVoiceGuide(BuildContext ctx) async {
    final voice = Provider.of<VoiceService>(context, listen: false);
    final ls = Provider.of<LanguageService>(context, listen: false);
    try {
      await voice.initializeSpeech();
      await voice.setLanguage(ls.currentLanguage);
      await voice.speak(ls.isTelugu
          ? 'ఫోన్ ద్వారా OTP లాగిన్ ప్రారంభించడానికి వాయిస్ లాగిన్‌ను నొక్కండి. తరువాత, మీ ఫోన్ నంబర్‌ను చెప్పండి.'
          : 'Press Voice Login to start phone OTP login. Then say your phone number.');
    } catch (_) {}
  }

  // Username/password submit removed: login goes through OTP phone flow

  Future<void> _handleVoiceLogin(BuildContext ctx) async {
    final voice = Provider.of<VoiceService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      setState(() { _isLoading = true; });
      final ok = await voice.initializeSpeech();
      if (!ok) {
        return;
      }

      // Force voice service to current app language; do not ask user again
      final ls = Provider.of<LanguageService>(context, listen: false);
      await voice.setLanguage(ls.currentLanguage);

      // Ask for phone number only; then navigate to OTP flow
      const phonePromptEn = 'Please say your phone number.';
      const phonePromptTe = 'దయచేసి మీ ఫోన్ నంబర్ చెప్పండి.';
      var phoneSpoken = await voice.askAndListen(promptEn: phonePromptEn, promptTe: phonePromptTe, seconds: 16);
      if (phoneSpoken.isEmpty) {
        phoneSpoken = await voice.askAndListen(promptEn: phonePromptEn, promptTe: phonePromptTe, seconds: 20);
        if (phoneSpoken.isEmpty) {
          await voice.speak(voice.currentLanguage == 'te' ? 'ఫోన్ నంబర్ వినలేకపోయాను.' : 'I could not hear the phone number.');
          return;
        }
      }

      await voice.speak(voice.currentLanguage == 'te' ? 'OTP లాగిన్‌కు కొనసాగిస్తున్నాను.' : 'Continuing to OTP login.');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneVoiceInputScreen(),
          ),
        );
      }
    } catch (e) {
      final voice2 = Provider.of<VoiceService>(context, listen: false);
      final msg = e.toString();
      if (msg.contains('user-not-found')) {
        await voice2.speak(voice2.currentLanguage == 'te'
            ? 'మీ ఖాతా ఇంకా లింక్ కాలేదు. దయచేసి మీ ఫోన్‌ను ధృవీకరించండి.'
            : 'Your account is not linked yet. Please verify your phone.');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhoneVoiceInputScreen(),
            ),
          );
        }
      } else {
        await voice2.speak(voice2.currentLanguage == 'te' ? 'లాగిన్ విఫలమైంది.' : 'Login failed.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice login error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Email normalization no longer needed

  Future<void> _demoLogin(String userType) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create a mock user for demo purposes
      // This bypasses Firebase authentication for testing
      await authService.setDemoUser(userType);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo $userType login successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo login error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class _VoiceLoginControls extends StatelessWidget {
  final void Function(BuildContext) onVoiceLogin;
  final void Function(BuildContext) onVoiceGuide;
  const _VoiceLoginControls({required this.onVoiceLogin, required this.onVoiceGuide});

  @override
  Widget build(BuildContext context) {
    return Consumer2<VoiceService, LanguageService>(
      builder: (context, voice, languageService, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  languageService.getLocalizedString('try_voice_login'),
                  style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('English'),
                  onPressed: () => voice.setLanguage('en'),
                ),
                ActionChip(
                  label: const Text('తెలుగు'),
                  onPressed: () => voice.setLanguage('te'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.record_voice_over, size: 18),
                  label: const Text('Voice Guide'),
                  onPressed: () => onVoiceGuide(context),
                ),
                ActionChip(
                  avatar: const Icon(Icons.login, size: 18),
                  label: Text(languageService.getLocalizedString('voice_login')),
                  onPressed: () => onVoiceLogin(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
