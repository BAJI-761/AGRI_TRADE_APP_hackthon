import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/offline_service.dart';
import '../services/language_service.dart';
import '../widgets/voice_assistant_widget.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/navigation_helper.dart';
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
    
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('accessibility'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_voice),
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
      body: Consumer2<VoiceService, OfflineService>(
        builder: (context, voiceService, offlineService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connectivity Status
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Card(
                    color: offlineService.isOnline ? Colors.green[50] : Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            offlineService.isOnline ? Icons.wifi : Icons.wifi_off,
                            color: offlineService.isOnline ? Colors.green : Colors.orange,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offlineService.isOnline 
                                      ? ls.getLocalizedString('online_mode')
                                      : ls.getLocalizedString('offline_mode'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: offlineService.isOnline ? Colors.green : Colors.orange,
                                  ),
                                ),
                                Text(
                                  offlineService.getConnectivityStatus(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Voice Commands Section
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ls.getLocalizedString('voice_commands'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ls.getLocalizedString('say_commands_to_navigate'),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Voice Commands Grid - Updated with current features
                Consumer<LanguageService>(
                  builder: (context, ls, _) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: userType == 'farmer' ? [
                      _buildVoiceCommandCard(
                        context,
                        ls.getLocalizedString('crop_prediction'),
                        ls.getLocalizedString('say_what_to_plant'),
                        Icons.agriculture,
                        Colors.green,
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
                        Colors.blue,
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
                        Colors.orange,
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
                        Colors.purple,
                        () => _handleVoiceCommand('help'),
                      ),
                    ] : [
                      // Retailer commands
                      _buildVoiceCommandCard(
                        context,
                        ls.getLocalizedString('inventory'),
                        ls.getLocalizedString('say_my_inventory'),
                        Icons.inventory_2,
                        Colors.blue,
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
                        Colors.orange,
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
                ),
                
                const SizedBox(height: 30),
                
                // Simplified UI Section
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ls.getLocalizedString('simplified_interface'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ls.getLocalizedString('large_buttons_easy_navigation'),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Large Action Buttons - Updated with current features
                Consumer<LanguageService>(
                  builder: (context, ls, _) => userType == 'farmer' ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SimpleIconButton(
                            icon: Icons.agriculture,
                            label: ls.getLocalizedString('crop_prediction'),
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CropPredictionScreen()),
                            ),
                          ),
                          SimpleIconButton(
                            icon: Icons.store_mall_directory,
                            label: ls.getLocalizedString('find_retailers'),
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RetailerSearchScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SimpleIconButton(
                            icon: Icons.trending_up,
                            label: ls.getLocalizedString('market_prices'),
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MarketInsightsScreen()),
                            ),
                          ),
                          SimpleIconButton(
                            icon: Icons.point_of_sale,
                            label: ls.getLocalizedString('create_order'),
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SimpleIconButton(
                            icon: Icons.shopping_cart,
                            label: ls.getLocalizedString('my_orders'),
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FarmerOrdersScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ) : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SimpleIconButton(
                            icon: Icons.inventory_2,
                            label: ls.getLocalizedString('inventory'),
                            color: Colors.blue,
                            onTap: () => _handleVoiceCommand('inventory'),
                          ),
                          SimpleIconButton(
                            icon: Icons.shopping_cart,
                            label: ls.getLocalizedString('orders'),
                            color: Colors.purple,
                            onTap: () => _handleVoiceCommand('orders'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SimpleIconButton(
                            icon: Icons.show_chart,
                            label: ls.getLocalizedString('market_insights'),
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MarketInsightsScreen()),
                            ),
                          ),
                          SimpleIconButton(
                            icon: Icons.bar_chart,
                            label: ls.getLocalizedString('analytics'),
                            color: Colors.teal,
                            onTap: () => _handleVoiceCommand('analytics'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Voice Assistant Widget
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ls.getLocalizedString('voice_assistant'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ls.getLocalizedString('use_voice_assistant_below'),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      VoiceAssistantWidget(
                        userType: userType,
                        onCommandRecognized: _handleVoiceCommand,
                        showVisualFeedback: true,
                        showAdvancedControls: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Offline Features
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ls.getLocalizedString('offline_features'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ls.getLocalizedString('features_work_offline'),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildOfflineFeature(
                                Icons.agriculture,
                                ls.getLocalizedString('crop_information'),
                                ls.getLocalizedString('view_crop_details'),
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildOfflineFeature(
                                Icons.trending_up,
                                ls.getLocalizedString('market_prices'),
                                ls.getLocalizedString('check_cached_prices'),
                                Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _buildOfflineFeature(
                                Icons.store_mall_directory,
                                ls.getLocalizedString('retailer_contacts'),
                                ls.getLocalizedString('access_saved_retailers'),
                                Colors.blue,
                              ),
                              if (userType == 'farmer') ...[
                                const SizedBox(height: 12),
                                _buildOfflineFeature(
                                  Icons.shopping_cart,
                                  ls.getLocalizedString('my_orders'),
                                  ls.getLocalizedString('view_order_history'),
                                  Colors.teal,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Instructions
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                ls.getLocalizedString('how_to_use'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ls.getLocalizedString('accessibility_instructions'),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
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
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                command,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
    );
  }

  Widget _buildOfflineFeature(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }
}

