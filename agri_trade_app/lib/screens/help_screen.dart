import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/navigation_helper.dart';
import '../widgets/app_gradient_scaffold.dart';

class HelpScreen extends StatelessWidget {
  final String userType; // 'farmer' | 'retailer' | 'general'
  const HelpScreen({super.key, this.userType = 'general'});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context).currentLanguage;
    final isTe = lang == 'te';
    final commands = _commandsFor(userType, isTe);
    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.2,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  isTe ? 'సహాయం' : 'Help',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              isTe ? 'వాయిస్ ఆదేశాలు' : 'Voice Commands',
              style: AppTheme.headingSmall,
            ),
          ),
          const SizedBox(height: 8),
          ...commands.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.cardDecoration,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: AppTheme.primaryGreen),
                  ),
                  title: Text(
                    c,
                    style: AppTheme.bodyLarge,
                  ),
                ),
              )),
          const SizedBox(height: 24),
          // Add some help contact info or description
           Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration.copyWith(
              color: AppTheme.secondaryAmber.withOpacity(0.1),
              border: Border.all(color: AppTheme.secondaryAmber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.secondaryAmber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isTe 
                        ? 'సహాయం కోసం మమ్మల్ని సంప్రదించండి.' 
                        : 'Contact support for further assistance.',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _commandsFor(String userType, bool isTe) {
    if (userType == 'farmer') {
      return isTe
          ? ['పంట సూచన', 'రిటైలర్లను వెతుకు', 'సెల్ క్రాప్', 'మార్కెట్ ధర', 'సహాయం']
          : ['Check crop prediction', 'Find retailers', 'Sell my crop', 'Check market prices', 'Help']; // Improved English commands for clarity
    }
    if (userType == 'retailer') {
      return isTe
          ? ['ఇన్వెంటరీ', 'ఆర్డర్లు', 'మార్కెట్ ఇన్‌సైట్స్', 'సహాయం']
          : ['Manage inventory', 'View orders', 'Market insights', 'Help'];
    }
    return isTe
        ? ['హోమ్', 'వెనక్కి', 'బయటకు']
        : ['Go home', 'Go back', 'Exit app'];
  }
}


