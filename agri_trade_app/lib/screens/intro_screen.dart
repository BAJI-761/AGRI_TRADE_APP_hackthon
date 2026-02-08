import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/app_theme.dart';
import 'language_selection_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startIntroSequence();
  }

  void _initializeAnimations() {
    // Logo animation - smooth scale and rotation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _logoRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // Text animation - elegant fade and slide
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Particle animation - continuous subtle movement
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.linear,
      ),
    );
  }

  Future<void> _startIntroSequence() async {
    // Start logo animation
    _logoController.forward();
    
    // Start text animation after a short delay
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    
    // Navigate after 2.5 seconds (smooth and quick)
    await Future.delayed(const Duration(milliseconds: 2100));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LanguageSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background particles
              AnimatedBuilder(
                animation: _particleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticlePainter(_particleAnimation.value),
                    size: Size.infinite,
                  );
                },
              ),
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with smooth animations
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value,
                            child: Opacity(
                              opacity: _logoOpacity.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.secondaryAmber,
                                      AppTheme.secondaryAmberLight,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.secondaryAmber.withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceWhite,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.agriculture,
                                    size: 70,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // App name with elegant animation
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      AppTheme.surfaceWhite,
                                      AppTheme.surfaceWhite.withOpacity(0.9),
                                    ],
                                  ).createShader(bounds),
                                  child: AutoSizeText(
                                    'AgriTrade',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.surfaceWhite,
                                      letterSpacing: 2.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Voice-Powered Agricultural Trading',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.surfaceWhite.withOpacity(0.9),
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Subtle loading indicator
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _textFade,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.surfaceWhite.withOpacity(0.8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Subtle particle painter for background animation
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.surfaceWhite.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw subtle floating particles
    for (int i = 0; i < 8; i++) {
      final angle = (animationValue * 2 * 3.14159) + (i * 3.14159 / 4);
      final radius = 20 + (i % 3) * 15;
      final x = size.width * 0.2 + (i % 2) * size.width * 0.6;
      final y = size.height * 0.3 + (i % 3) * size.height * 0.4;
      
      final offsetX = x + radius * math.cos(angle * 0.5);
      final offsetY = y + radius * math.sin(angle * 0.5);
      
      canvas.drawCircle(
        Offset(offsetX, offsetY),
        3 + (i % 2) * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
