import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'farmer/farmer_home.dart';
import 'retailer/retailer_home.dart';
import 'new_returning_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasSelectedLanguage = false;

  @override
  void initState() {
    super.initState();
    _checkLanguageSelection();
  }

  Future<void> _checkLanguageSelection() async {
    try {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      await languageService.loadLanguage();
      
      if (mounted) {
        setState(() {
          _hasSelectedLanguage = languageService.currentLanguage.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasSelectedLanguage = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.premiumGradient,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AgriTrade',
                  style: AppTheme.displayLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 2,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show language selection if not selected yet
    if (!_hasSelectedLanguage) {
      return const LanguageSelectionScreen();
    }

    // Show authentication flow
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          switch (authService.userType) {
            case 'farmer':
              return const FarmerHome();
            case 'retailer':
              return const RetailerHome();
            default:
              return const LoginScreen();
          }
        } else {
          return const NewReturningScreen();
        }
      },
    );
  }
}
