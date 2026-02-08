import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import 'auth_wrapper.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String? _selectedLanguage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
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
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Card(
                                elevation: 16,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // App Icon and Title
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.agriculture,
                                          size: 48,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        languageService.getLocalizedString('app_title'),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        languageService.getLocalizedString('app_subtitle'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      
                                      // Language Selection Title
                                      Text(
                                        languageService.getLocalizedString('select_language'),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        languageService.getLocalizedString('choose_language'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      
                                      // Language Options
                                      _buildLanguageOption(
                                        'English',
                                        'en',
                                        '🇺🇸',
                                        'Continue with English',
                                        Colors.blue,
                                        languageService,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLanguageOption(
                                        'తెలుగు',
                                        'te',
                                        '🇮🇳',
                                        'తెలుగులో కొనసాగించండి',
                                        Colors.orange,
                                        languageService,
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Continue Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _selectedLanguage != null && !_isLoading
                                              ? _handleLanguageSelection
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: _isLoading
                                              ? const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Setting up...',
                                                      style: TextStyle(fontSize: 16),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.arrow_forward, size: 20),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      languageService.getLocalizedString('continue'),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Skip Option
                                      TextButton(
                                        onPressed: _isLoading ? null : _handleSkip,
                                        child: Text(
                                          languageService.getLocalizedString('skip_for_now'),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Voice Demo
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.mic, color: Colors.blue.shade700, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  languageService.getLocalizedString('voice_features'),
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              languageService.getLocalizedString('voice_description'),
                                              style: TextStyle(
                                                color: Colors.blue.shade600,
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    String title,
    String languageCode,
    String flag,
    String subtitle,
    Color color,
    LanguageService languageService,
  ) {
    final isSelected = _selectedLanguage == languageCode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = languageCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Language Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.grey.shade300,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLanguageSelection() async {
    if (_selectedLanguage == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Set language in language service
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await languageService.setLanguage(_selectedLanguage!);
      
      // Set voice service language
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.setLanguage(_selectedLanguage!);
      
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to auth wrapper (will route to New/Returning)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSkip() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Set default language to English
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await languageService.setLanguage('en');
      
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.setLanguage('en');
      
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Navigate to auth wrapper (will route to New/Returning)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
