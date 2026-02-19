import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card_wrapper.dart';
import '../widgets/primary_button.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final voice = Provider.of<VoiceService>(context, listen: false);
      final languageService =
          Provider.of<LanguageService>(context, listen: false);
      await voice.speak(languageService.isTelugu
          ? 'ఫోన్ ద్వారా OTP తో లాగిన్ చేయడానికి కొనసాగించండి.'
          : 'Continue to login with your phone using OTP.');
    });
  }



  Future<void> _startLoginVoiceGuide(BuildContext context) async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    String text = languageService.isTelugu
        ? 'నమస్కారం! అగ్రి ట్రేడ్ యాప్‌కి స్వాగతం. లాగిన్ చేయడానికి స్క్రీన్ మధ్యలో ఉన్న వాయిస్ లాగిన్ బటన్ నొక్కండి.'
        : 'Hello! Welcome to Agri Trade App. To login, tap the voice login button in the center.';
        
    await voiceService.speak(text);
  }

  Future<void> _handleVoiceLogin(BuildContext context) async {
    final voice = Provider.of<VoiceService>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      // Prompt user
      await voice.speak(voice.currentLanguage == 'te' 
          ? 'దయచేసి "లాగిన్" అని చెప్పండి లేదా తెరపై నొక్కండి.' 
          : 'Please say "login" or tap the screen.');

      // Listen for command
      final command = await voice.listenOnce();
      
      if (command.toLowerCase().contains('login') || 
          command.contains('లాగిన్') || 
          command.isNotEmpty) { // Accept any input for now as intent to move forward
          
        await voice.speak(voice.currentLanguage == 'te' ? 'OTP లాగిన్‌కు కొనసాగిస్తున్నాను.' : 'Continuing to OTP login.');
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneVoiceInputScreen(),
          ),
        );
      } else {
        await voice.speak(voice.currentLanguage == 'te' ? 'క్షమించండి, అర్థం కాలేదు.' : 'Sorry, did not understand.');
      }

    } catch (e) {
      final voice2 = Provider.of<VoiceService>(context, listen: false);
      await voice2.speak(voice2.currentLanguage == 'te' ? 'లాగిన్ విఫలమైంది.' : 'Login failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice login error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper for safe language access
    final languageService = Provider.of<LanguageService>(context);

    // Localized strings wrapper
    String t(String key) {
      if (key == 'app_title') return 'AgriTrade';
      if (key == 'welcome_back') return languageService.isTelugu ? 'మళ్ళీ స్వాగతం' : 'Welcome Back';
      if (key == 'login') return languageService.isTelugu ? 'లాగిన్' : 'Login';
      if (key == 'voice_login') return languageService.isTelugu ? 'వాయిస్ లాగిన్' : 'Voice Login';
      if (key == 'demo_farmer') return languageService.isTelugu ? 'డెమో రైతు' : 'Demo Farmer';
      if (key == 'demo_retailer') return languageService.isTelugu ? 'డెమో రిటైలర్' : 'Demo Retailer';
      return key;
    }

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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24.0, 24.0, 24.0, 24.0 + MediaQuery.of(context).viewInsets.bottom),
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
                        Icons.agriculture,
                        size: 48,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('app_title'),
                      style: AppTheme.displayMedium.copyWith(
                        color: AppTheme.primaryGreenDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('welcome_back'),
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Voice controls
                    _VoiceControlSection(
                      onVoiceLogin: () => _handleVoiceLogin(context),
                      onVoiceGuide: () => _startLoginVoiceGuide(context),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      languageService.isTelugu
                          ? 'OTP సహాయంతో మీ ఫోన్ ద్వారా లాగిన్ చేయండి.'
                          : 'Login with your phone via OTP.',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: t('login'),
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
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 12),
                    Text(
                      'Note: Voice features work best on mobile devices.',
                      style: AppTheme.bodySmall.copyWith(fontSize: 11),
                      textAlign: TextAlign.center,
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

class _VoiceControlSection extends StatelessWidget {
  final Future<void> Function() onVoiceLogin;
  final Future<void> Function() onVoiceGuide;
  const _VoiceControlSection({required this.onVoiceLogin, required this.onVoiceGuide});

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
                  onPressed: onVoiceGuide,
                ),
                ActionChip(
                  avatar: const Icon(Icons.login, size: 18),
                  label: Text(languageService.getLocalizedString('voice_login')),
                  onPressed: onVoiceLogin,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
