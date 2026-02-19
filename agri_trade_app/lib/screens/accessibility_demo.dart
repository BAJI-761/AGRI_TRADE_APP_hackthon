import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/offline_service.dart';
import '../services/language_service.dart';
import '../widgets/voice_assistant_widget.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/navigation_helper.dart';
import '../widgets/app_gradient_scaffold.dart';
import '../theme/app_theme.dart';
import 'voice_settings_screen.dart';
import 'farmer/crop_prediction.dart';
import 'farmer/create_order_screen.dart';
import 'farmer/farmer_orders_screen.dart';
import 'farmer/retailer_search.dart';
import 'market_insights.dart';
import '../services/auth_service.dart';

class AccessibilityDemoScreen extends StatefulWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  _AccessibilityDemoScreenState createState() => _AccessibilityDemoScreenState();
}

class _AccessibilityDemoScreenState extends State<AccessibilityDemoScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoiceService>(context, listen: false).initializeSpeech();
      Provider.of<OfflineService>(context, listen: false).initialize();
    });
  }

  void _handleVoiceCommand(String command) {
    Provider.of<VoiceService>(context, listen: false).speak(
      "You selected: $command. This feature is now accessible through voice commands!"
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userType = authService.userType ?? 'farmer';
    final ls = Provider.of<LanguageService>(context);
    
    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.25,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ls.getLocalizedString('accessibility'),
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings_voice, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              ls.getLocalizedString('voice_assistant'),
              style: AppTheme.bodyLarge.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
        bodyChildren: [
          // Voice Assistant Widget
          VoiceAssistantWidget(
            userType: userType,
            onCommandRecognized: _handleVoiceCommand,
            showVisualFeedback: true,
            showAdvancedControls: true,
          ),
          
          const SizedBox(height: 24),

          // Connectivity Status
          Consumer<OfflineService>(
            builder: (context, offlineService, _) => Container(
              decoration: AppTheme.cardDecoration.copyWith(
                color: offlineService.isOnline 
                    ? AppTheme.primaryGreen.withValues(alpha: 0.05) 
                    : AppTheme.secondaryAmber.withValues(alpha: 0.05),
                border: Border.all(
                  color: offlineService.isOnline 
                      ? AppTheme.primaryGreen.withValues(alpha: 0.2) 
                      : AppTheme.secondaryAmber.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: offlineService.isOnline 
                          ? AppTheme.primaryGreen.withValues(alpha: 0.1) 
                          : AppTheme.secondaryAmber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      offlineService.isOnline ? Icons.wifi : Icons.wifi_off,
                      color: offlineService.isOnline ? AppTheme.primaryGreen : AppTheme.secondaryAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offlineService.isOnline 
                              ? ls.getLocalizedString('online_mode')
                              : ls.getLocalizedString('offline_mode'),
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: offlineService.isOnline ? AppTheme.primaryGreen : AppTheme.secondaryAmber,
                          ),
                        ),
                        Text(
                          offlineService.getConnectivityStatus(),
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Voice Commands Section
          Text(
            ls.getLocalizedString('voice_commands'),
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            ls.getLocalizedString('say_commands_to_navigate'),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: userType == 'farmer' ? [
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('crop_prediction'),
                ls.getLocalizedString('say_what_to_plant'),
                Icons.agriculture,
                AppTheme.primaryGreen,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CropPredictionScreen()),
                ),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('find_retailers'),
                ls.getLocalizedString('say_find_retailers'),
                Icons.store_mall_directory,
                AppTheme.accentBlue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RetailerSearchScreen()),
                ),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('market_prices'),
                ls.getLocalizedString('say_market_price'),
                Icons.trending_up,
                AppTheme.secondaryAmber,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketInsightsScreen()),
                ),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('create_order'),
                ls.getLocalizedString('say_create_order'),
                Icons.point_of_sale,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                ),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('my_orders'),
                ls.getLocalizedString('say_my_orders'),
                Icons.shopping_cart,
                Colors.teal,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FarmerOrdersScreen()),
                ),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('help_menu'),
                ls.getLocalizedString('say_help'),
                Icons.help,
                Colors.indigo,
                () => _handleVoiceCommand('help'),
              ),
            ] : [
              // Retailer commands
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('inventory'),
                ls.getLocalizedString('say_my_inventory'),
                Icons.inventory_2,
                AppTheme.accentBlue,
                () => _handleVoiceCommand('inventory'),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('orders'),
                ls.getLocalizedString('say_orders'),
                Icons.shopping_cart,
                Colors.purple,
                () => _handleVoiceCommand('orders'),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('market_insights'),
                ls.getLocalizedString('say_market_insights'),
                Icons.show_chart,
                AppTheme.secondaryAmber,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarketInsightsScreen()),
                ),
              ),
              _buildVoiceCommandCard(
                context,
                ls.getLocalizedString('analytics'),
                ls.getLocalizedString('say_analytics'),
                Icons.bar_chart,
                Colors.teal,
                () => _handleVoiceCommand('analytics'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Simplified UI Section (Large Buttons)
          Text(
            ls.getLocalizedString('simplified_interface'),
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            ls.getLocalizedString('large_buttons_easy_navigation'),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          
          if (userType == 'farmer') ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildLargeActionButton(
                    icon: Icons.agriculture,
                    label: ls.getLocalizedString('crop_prediction'),
                    color: AppTheme.primaryGreen,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CropPredictionScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildLargeActionButton(
                    icon: Icons.store_mall_directory,
                    label: ls.getLocalizedString('find_retailers'),
                    color: AppTheme.accentBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RetailerSearchScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                   _buildLargeActionButton(
                    icon: Icons.trending_up,
                    label: ls.getLocalizedString('market_prices'),
                    color: AppTheme.secondaryAmber,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketInsightsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Offline Features
          Text(
            ls.getLocalizedString('offline_features'),
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            ls.getLocalizedString('features_work_offline'),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildOfflineFeature(
                  Icons.agriculture,
                  ls.getLocalizedString('crop_information'),
                  ls.getLocalizedString('view_crop_details'),
                  AppTheme.primaryGreen,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildOfflineFeature(
                  Icons.trending_up,
                  ls.getLocalizedString('market_prices'),
                  ls.getLocalizedString('check_cached_prices'),
                  AppTheme.secondaryAmber,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildOfflineFeature(
                  Icons.store_mall_directory,
                  ls.getLocalizedString('retailer_contacts'),
                  ls.getLocalizedString('access_saved_retailers'),
                  AppTheme.accentBlue,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Text(
                      ls.getLocalizedString('how_to_use'),
                      style: AppTheme.headingSmall.copyWith(fontSize: 18, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ls.getLocalizedString('accessibility_instructions'),
                  style: AppTheme.bodyMedium.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
        floatingActionButton: Consumer<AuthService>(
          builder: (context, authService, _) => FloatingVoiceButton(
            userType: authService.userType ?? 'farmer',
            onCommandRecognized: _handleVoiceCommand,
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceCommandCard(BuildContext context, String title, String command, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  command,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineFeature(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: AppTheme.primaryGreen.withValues(alpha: 0.8), size: 20),
      ],
    );
  }
  
  Widget _buildLargeActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 140,
      height: 140,
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(icon, size: 48, color: color),
               const SizedBox(height: 16),
               Text(
                 label,
                 style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
            ],
          ),
        ),
      ),
    );
  }
}

