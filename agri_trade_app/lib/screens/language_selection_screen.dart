import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

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
                colors: AppTheme.premiumGradient,
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                decoration: AppTheme.glassCard,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // App icon
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryGreenSurface,
                                            AppTheme.primaryGreenSurface.withOpacity(0.5),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/icon/app_icon.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.eco,
                                            size: 42,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Title
                                    Text(
                                      languageService.getLocalizedString('app_title'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryGreenDark,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      languageService.getLocalizedString('app_subtitle'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 36),

                                    // Language selection header
                                    Text(
                                      languageService.getLocalizedString('select_language'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      languageService.getLocalizedString('choose_language'),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 28),

                                    // Language options
                                    _buildLanguageOption(
                                      'English', 'en', '🇺🇸',
                                      'Continue with English',
                                      AppTheme.accentBlue,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildLanguageOption(
                                      'తెలుగు', 'te', '🇮🇳',
                                      'తెలుగులో కొనసాగించండి',
                                      AppTheme.secondaryAmber,
                                    ),

                                    const SizedBox(height: 32),

                                    // Continue button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _selectedLanguage != null && !_isLoading
                                            ? _handleLanguageSelection
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryGreen,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(
                                                    width: 20, height: 20,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white, strokeWidth: 2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text('Setting up...',
                                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    languageService.getLocalizedString('continue'),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Skip
                                    TextButton(
                                      onPressed: _isLoading ? null : _handleSkip,
                                      child: Text(
                                        languageService.getLocalizedString('skip_for_now'),
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textTertiary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Voice features info
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentBlue.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.accentBlue.withOpacity(0.12),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.mic_rounded,
                                                color: AppTheme.accentBlue, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                languageService.getLocalizedString('voice_features'),
                                                style: GoogleFonts.poppins(
                                                  color: AppTheme.accentBlue,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            languageService.getLocalizedString('voice_description'),
                                            style: GoogleFonts.inter(
                                              color: AppTheme.accentBlue.withOpacity(0.8),
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
  ) {
    final isSelected = _selectedLanguage == languageCode;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = languageCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : AppTheme.surfaceLight,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppTheme.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLanguageSelection() async {
    if (_selectedLanguage == null) return;
    setState(() => _isLoading = true);

    try {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await languageService.setLanguage(_selectedLanguage!);

      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.setLanguage(_selectedLanguage!);

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting language: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSkip() async {
    setState(() => _isLoading = true);

    try {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await languageService.setLanguage('en');

      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.setLanguage('en');

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
