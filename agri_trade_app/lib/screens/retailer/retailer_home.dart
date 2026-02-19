import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import 'inventory_management.dart';
import '../market_insights.dart';
import 'orders_screen.dart';
import 'analytics_screen.dart';
import '../voice_settings_screen.dart';
import '../registration_profile_screen.dart';
import '../feedback_screen.dart';
import '../notifications_screen.dart';

import '../../widgets/app_gradient_scaffold.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/location_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/action_card.dart';
import '../../widgets/info_list_tile.dart';

class RetailerHome extends StatefulWidget {
  const RetailerHome({super.key});

  @override
  State<RetailerHome> createState() => _RetailerHomeState();
}

class _RetailerHomeState extends State<RetailerHome> {
  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final isTe = langService.isTelugu;

    return AppGradientScaffold(
      headerChildren: [
        AppHeaderBar(
          avatarIcon: Icons.store_rounded,
          greeting: langService.getLocalizedString('welcome'),
          userName: authService.name ?? langService.getLocalizedString('retailer'),
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
              title: langService.getLocalizedString('inventory'),
              icon: Icons.inventory_2_rounded,
              color: AppTheme.accentBlue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InventoryManagementScreen())),
            ),
            ActionCard(
              title: langService.getLocalizedString('orders'),
              icon: Icons.shopping_cart_rounded,
              color: AppTheme.secondaryAmber,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            ActionCard(
              title: langService.getLocalizedString('analytics'),
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
            ),
            ActionCard(
              title: langService.getLocalizedString('market_insights'),
              icon: Icons.trending_up_rounded,
              color: AppTheme.primaryGreenLight,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MarketInsightsScreen())),
            ),
          ],
        ),

        const SizedBox(height: 28),
        SectionHeader(title: langService.getLocalizedString('market_insights')),
        const SizedBox(height: 16),

        InfoListTile(
          icon: Icons.trending_up_rounded,
          color: AppTheme.secondaryAmber,
          title: langService.getLocalizedString('market_prices'),
          subtitle: isTe ? 'నేటి మార్కెట్ ధరలు తనిఖీ చేయండి' : 'Check today\'s mandi prices',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MarketInsightsScreen())),
        ),
        const SizedBox(height: 20),
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
                          Provider.of<AuthService>(context, listen: false)
                                  .phone ??
                              '',
                    )));
        break;
      case 'settings':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const VoiceSettingsScreen()));
        break;
      case 'feedback':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FeedbackScreen()));
        break;
      case 'signout':
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(ls.getLocalizedString('sign_out_confirm_title'),
                    style: AppTheme.headingSmall),
                content: Text(ls.getLocalizedString('sign_out_confirm_message'),
                    style: AppTheme.bodyMedium),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(ls.getLocalizedString('cancel_btn')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(ls.getLocalizedString('sign_out'),
                        style: TextStyle(color: AppTheme.errorRed)),
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
