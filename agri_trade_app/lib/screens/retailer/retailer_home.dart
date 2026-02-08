import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_management.dart';
import '../market_insights.dart';
import 'orders_screen.dart';
import 'analytics_screen.dart';
import '../voice_settings_screen.dart';
import '../registration_profile_screen.dart';
import '../../services/language_service.dart';
import '../feedback_screen.dart';
import '../notifications_screen.dart';
import '../../services/notification_service.dart';

class RetailerHome extends StatefulWidget {
  const RetailerHome({super.key});

  @override
  State<RetailerHome> createState() => _RetailerHomeState();
}

class _RetailerHomeState extends State<RetailerHome> {
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, ls, _) => Text(ls.getLocalizedString('retailer_dashboard')),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, _) {
              final unreadCount = notificationService.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationProfileScreen(
                        phoneNumber: Provider.of<AuthService>(context, listen: false).phone ?? '',
                      ),
                    ),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoiceSettingsScreen(),
                    ),
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
                          title: Consumer<LanguageService>(
                            builder: (context, ls, _) => Text(ls.getLocalizedString('sign_out_confirm_title')),
                          ),
                          content: Consumer<LanguageService>(
                            builder: (context, ls, _) => Text(ls.getLocalizedString('sign_out_confirm_message')),
                          ),
                          actions: [
                            Consumer<LanguageService>(
                              builder: (context, ls, _) => TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(ls.getLocalizedString('cancel_btn')),
                              ),
                            ),
                            Consumer<LanguageService>(
                              builder: (context, ls, _) => TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(ls.getLocalizedString('sign_out')),
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) {
                    await Provider.of<AuthService>(context, listen: false).logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              final ls = Provider.of<LanguageService>(context, listen: false);
              return [
                PopupMenuItem(value: 'profile', child: Text(ls.getLocalizedString('profile'))),
                PopupMenuItem(value: 'settings', child: Text(ls.getLocalizedString('settings'))),
                PopupMenuItem(value: 'feedback', child: Text(ls.getLocalizedString('feedback'))),
                PopupMenuItem(value: 'signout', child: Text(ls.getLocalizedString('sign_out'))),
              ];
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${authService.name ?? 'Retailer'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${authService.address ?? 'Not set'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Features Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('inventory'),
                        Icons.inventory_2,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InventoryManagementScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('market_insights'),
                        Icons.show_chart,
                        Colors.orange,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MarketInsightsScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('orders'),
                        Icons.shopping_cart,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrdersScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('analytics'),
                        Icons.bar_chart,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                        ),
                      ),
                    ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      // Removed floating voice button to fix ParentDataWidget error
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
