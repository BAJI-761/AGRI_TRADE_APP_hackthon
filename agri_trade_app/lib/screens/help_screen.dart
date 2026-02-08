import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class HelpScreen extends StatelessWidget {
  final String userType; // 'farmer' | 'retailer' | 'general'
  const HelpScreen({super.key, this.userType = 'general'});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context).currentLanguage;
    final isTe = lang == 'te';
    final commands = _commandsFor(userType, isTe);
    return Scaffold(
      appBar: AppBar(
        title: Text(isTe ? 'సహాయం' : 'Help'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: commands.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = commands[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.mic),
              title: Text(c),
            ),
          );
        },
      ),
    );
  }

  List<String> _commandsFor(String userType, bool isTe) {
    if (userType == 'farmer') {
      return isTe
          ? ['పంట సూచన', 'రిటైలర్లను వెతుకు', 'సెల్ క్రాప్', 'మార్కెట్ ధర', 'సహాయం']
          : ['crop prediction', 'retailer search', 'sell crop', 'market insights', 'help'];
    }
    if (userType == 'retailer') {
      return isTe
          ? ['ఇన్వెంటరీ', 'ఆర్డర్లు', 'మార్కెట్ ఇన్‌సైట్స్', 'సహాయం']
          : ['inventory', 'orders', 'market insights', 'help'];
    }
    return isTe
        ? ['హోమ్', 'వెనక్కి', 'బయటకు']
        : ['home', 'back', 'exit'];
  }
}


