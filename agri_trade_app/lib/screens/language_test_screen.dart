import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';

class LanguageTestScreen extends StatelessWidget {
  const LanguageTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Language: ${languageService.currentLanguage}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                const Text(
                  'Test Strings:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                Text('App Title: ${languageService.getLocalizedString('app_title')}'),
                Text('Welcome Back: ${languageService.getLocalizedString('welcome_back')}'),
                Text('Create Account: ${languageService.getLocalizedString('create_account')}'),
                Text('Login: ${languageService.getLocalizedString('login')}'),
                Text('Register: ${languageService.getLocalizedString('register')}'),
                Text('Farmer: ${languageService.getLocalizedString('farmer')}'),
                Text('Retailer: ${languageService.getLocalizedString('retailer')}'),
                
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => languageService.setLanguage('en'),
                      child: const Text('Set English'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => languageService.setLanguage('te'),
                      child: const Text('Set Telugu'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('app_language');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language preference cleared. Restart app to see language selection.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear Language Preference'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

