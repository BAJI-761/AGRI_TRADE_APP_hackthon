import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  _FarmerHomeState createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, ls, _) => Text(ls.getLocalizedString('farmer_dashboard')),
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
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            '${ls.getLocalizedString('welcome')}, ${authService.name ?? ls.getLocalizedString('farmer')}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            '${ls.getLocalizedString('location')}: ${authService.address ?? '-'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
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
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('crop_prediction'),
                        Icons.agriculture,
                        Colors.green,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CropPredictionScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('create_order'),
                        Icons.point_of_sale,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateOrderScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('my_orders'),
                        Icons.shopping_cart,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FarmerOrdersScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('find_retailers'),
                        Icons.store_mall_directory,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RetailerSearchScreen(),
                          ),
                        ),
                      ),
                      _buildFeatureCard(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('market_prices'),
                        Icons.trending_up,
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
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('accessibility'),
                        Icons.accessibility_new,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccessibilityDemoScreen(),
                          ),
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
