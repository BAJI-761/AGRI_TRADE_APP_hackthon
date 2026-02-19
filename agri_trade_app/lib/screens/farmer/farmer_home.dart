import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../accessibility_demo.dart';
import 'crop_prediction.dart';
import 'retailer_search.dart';
import 'create_order_screen.dart';
import 'farmer_orders_screen.dart';
import '../market_insights.dart';
import '../voice_settings_screen.dart';
import '../../services/language_service.dart';
import '../registration_profile_screen.dart';
import '../feedback_screen.dart';
import '../notifications_screen.dart';
import '../../services/notification_service.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/location_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/action_card.dart';
import '../../widgets/info_list_tile.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  _FarmerHomeState createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final isTe = langService.isTelugu;

    return AppGradientScaffold(
      headerChildren: [
        AppHeaderBar(
          avatarIcon: Icons.person_rounded,
          greeting: langService.getLocalizedString('welcome'),
          userName: authService.name ?? langService.getLocalizedString('farmer'),
          unreadCount: notificationService.unreadCount,
          onNotificationTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          ),
          menuItems: [
            _buildMenuItem('profile', Icons.person_outline,
                langService.getLocalizedString('profile')),
            _buildMenuItem('settings', Icons.settings_outlined,
                langService.getLocalizedString('settings')),
            _buildMenuItem('feedback', Icons.feedback_outlined,
                langService.getLocalizedString('feedback')),
            _buildMenuItem('signout', Icons.logout,
                langService.getLocalizedString('sign_out')),
          ],
          onMenuSelected: (value) => _handleMenuSelection(context, value),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LocationBadge(
            location: authService.address ?? 'Unknown Location',
          ),
        ),
      ],
      bodyChildren: [
        SectionHeader(title: langService.getLocalizedString('quick_actions')),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          children: [
            ActionCard(
              title: langService.getLocalizedString('create_order'),
              icon: Icons.add_circle_outline,
              color: AppTheme.primaryGreen,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
            ),
            ActionCard(
              title: langService.getLocalizedString('crop_prediction'),
              icon: Icons.psychology_outlined,
              color: AppTheme.secondaryAmber,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CropPredictionScreen())),
            ),
            ActionCard(
              title: langService.getLocalizedString('my_orders'),
              icon: Icons.list_alt,
              color: AppTheme.accentBlue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FarmerOrdersScreen())),
            ),
            ActionCard(
              title: langService.getLocalizedString('find_retailers'),
              icon: Icons.store_outlined,
              color: Colors.purple,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RetailerSearchScreen())),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(title: langService.getLocalizedString('market_insights')),
        const SizedBox(height: 16),
        
        InfoListTile(
          icon: Icons.trending_up,
          color: Colors.orange,
          title: langService.getLocalizedString('market_prices'),
          subtitle: isTe ? 'నేటి మార్కెట్ ధరలు తనిఖీ చేయండి' : 'Check today\'s mandi prices',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MarketInsightsScreen())),
        ),
        
        const SizedBox(height: 16),
        const SectionHeader(title: 'More'),
        const SizedBox(height: 16),
        
        InfoListTile(
          icon: Icons.accessibility_new,
          color: Colors.purple,
          title: langService.getLocalizedString('accessibility'),
          subtitle: 'Accessibility Demo',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccessibilityDemoScreen())),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(text, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _handleMenuSelection(BuildContext context, String value) async {
    final ls = Provider.of<LanguageService>(context, listen: false);

    switch (value) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationProfileScreen(
              phoneNumber:
                  Provider.of<AuthService>(context, listen: false).phone ?? '',
            ),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VoiceSettingsScreen()),
        );
        break;
      case 'feedback':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedbackScreen()),
        );
        break;
      case 'signout':
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(ls.getLocalizedString('sign_out_confirm_title'), style: AppTheme.headingSmall),
                content:
                    Text(ls.getLocalizedString('sign_out_confirm_message'), style: AppTheme.bodyMedium),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(ls.getLocalizedString('cancel_btn')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(ls.getLocalizedString('sign_out'), style: TextStyle(color: AppTheme.errorRed)),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirmed) {
          if (!mounted) return;
          await Provider.of<AuthService>(context, listen: false).logout();
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
        break;
    }
  }
}
