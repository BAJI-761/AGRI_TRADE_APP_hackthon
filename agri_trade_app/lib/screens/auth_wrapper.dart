import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
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
      
      setState(() {
        // Language should already be selected since it comes after intro
        // But keep this check as a fallback safety measure
        _hasSelectedLanguage = languageService.currentLanguage.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      // If language is not set, show language selection (shouldn't happen normally)
      setState(() {
        _hasSelectedLanguage = false;
        _isLoading = false;
      });
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
              colors: [
                Colors.green.shade800,
                Colors.green.shade400,
                Colors.white,
              ],
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'AgriTrade',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
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
          // User is logged in, show appropriate home screen
          switch (authService.userType) {
            case 'farmer':
              return const FarmerHome();
            case 'retailer':
              return const RetailerHome();
            default:
              // Fallback to login screen if user type is not set
              return const LoginScreen();
          }
        } else {
          // User is not logged in: go to New/Returning selector → Phone → OTP
          return const NewReturningScreen();
        }
      },
    );
  }
} 