import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_service.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../widgets/navigation_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/app_gradient_scaffold.dart';

class MarketInsightsScreen extends StatefulWidget {
  const MarketInsightsScreen({super.key});

  @override
  State<MarketInsightsScreen> createState() => _MarketInsightsScreenState();
}

class _MarketInsightsScreenState extends State<MarketInsightsScreen> {
  // ignore: unused_field
  final bool _voiceMode = false;
  // ignore: unused_field
  String? _lastQueryCrop;
  // ignore: unused_field
  String? _lastQueryLocation;
  late final MarketService _marketService;

  @override
  void initState() {
    super.initState();
    _marketService = MarketService();
    // Kick off insights polling
    _marketService.initializeInsightsPolling();
  }

  @override
  void dispose() {
    _marketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketService = _marketService;
    final ls = Provider.of<LanguageService>(context);

    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.2,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ls.getLocalizedString('market_insights_title'),
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () async {
                    await marketService.fetchInsightsOnce();
                    // ignore: use_build_context_synchronously
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ls.getLocalizedString('market_data_refreshed')),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          // Market Overview Card
          Container(
             padding: const EdgeInsets.all(16.0),
             decoration: AppTheme.cardDecoration,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: AppTheme.primaryGreen.withOpacity(0.1),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.trending_up, color: AppTheme.primaryGreen, size: 24),
                     ),
                     const SizedBox(width: 12),
                     Text(
                       ls.getLocalizedString('market_overview'),
                       style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     Expanded(
                       child: _buildMarketStat(
                         ls.getLocalizedString('active_crops'),
                         '12',
                       ),
                     ),
                     Expanded(
                       child: _buildMarketStat(
                         ls.getLocalizedString('avg_price'),
                         '\$38.25',
                       ),
                     ),
                     Expanded(
                       child: _buildMarketStat(
                         ls.getLocalizedString('market_trend'),
                         '+2.3%',
                         isPositive: true,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
          ),
          const SizedBox(height: 24),

          // Trending Crops
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ls.getLocalizedString('trending_crops'),
              style: AppTheme.headingSmall,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                _buildTrendingCrop('Wheat', '+5.2%', 52.50, AppTheme.primaryGreen, context),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildTrendingCrop('Rice', '+2.1%', 30.75, AppTheme.primaryGreen, context),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildTrendingCrop('Corn', '-1.8%', 24.20, AppTheme.errorRed, context),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildTrendingCrop('Soybeans', '+3.4%', 45.80, AppTheme.primaryGreen, context),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Latest News
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ls.getLocalizedString('latest_news'),
              style: AppTheme.headingSmall,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                _buildNewsItem('Global wheat demand increases due to supply chain disruptions', context),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildNewsItem('Rice prices stabilize after recent fluctuations', context),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildNewsItem('New agricultural policies expected to impact crop prices', context),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildNewsItem('Weather conditions favorable for upcoming harvest season', context),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Price Alerts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ls.getLocalizedString('price_alerts'),
              style: AppTheme.headingSmall,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                _buildAlertItem('Wheat prices up 5% this week', ls),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildAlertItem('Rice demand remains stable', ls),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildAlertItem('Corn prices expected to rise next month', ls),
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                _buildAlertItem('Soybean exports increase by 15%', ls),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Market Analysis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ls.getLocalizedString('market_analysis'),
              style: AppTheme.headingSmall,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppTheme.cardDecoration,
            child: StreamBuilder<List<String>>(
              stream: marketService.insightsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final insights = snapshot.data ?? const <String>[];
                if (insights.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No insights available.', style: TextStyle(color: Colors.grey))),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: insights.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.analytics, color: Colors.purple, size: 20),
                      ),
                      title: Text(
                        insights[index],
                        style: AppTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, {bool isPositive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(
            fontSize: 22,
            color: isPositive ? AppTheme.primaryGreen : AppTheme.textDark,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTrendingCrop(String crop, String trend, double price, Color color, BuildContext context) {
    final ls = Provider.of<LanguageService>(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          trend.startsWith('+') ? Icons.trending_up : Icons.trending_down,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        crop,
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${ls.getLocalizedString('current_price')}: ₹${price.toStringAsFixed(2)}',
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          trend,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: () {
        _showNewsDetail(context, '$crop trending: $trend');
      },
    );
  }

  Widget _buildNewsItem(String news, BuildContext context) {
    final ls = Provider.of<LanguageService>(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.article, color: Colors.blue, size: 20),
      ),
      title: Text(
        news,
        style: AppTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '2 ${ls.getLocalizedString('days_ago')}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
      onTap: () {
        _showNewsDetail(context, news);
      },
    );
  }

  Widget _buildAlertItem(String alert, LanguageService ls) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryAmber.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications, color: AppTheme.secondaryAmber, size: 20),
      ),
      title: Text(
        alert,
        style: AppTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      subtitle: Text(
        ls.getLocalizedString('alert'),
        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryAmber),
      ),
    );
  }

  void _showNewsDetail(BuildContext context, String news) {
    final ls = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ls.getLocalizedString('market_news'), style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news, style: AppTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(
              ls.getLocalizedString('news_info'),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ls.getLocalizedString('close'), style: const TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ls.getLocalizedString('news_saved_favorites')),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: AppTheme.primaryButtonStyle,
            child: Text(ls.getLocalizedString('save')),
          ),
        ],
      ),
    );
  }

  // Voice features can be re-enabled/integrated as needed, adapted to the new UI structure
  // For now, kept logic but UI triggers might need specific placement if not already present.
  // The original voice method is kept for reference or future use.
  // ignore: unused_element
  Future<void> _handleVoiceMarketQuery() async {
    final voice = Provider.of<VoiceService>(context, listen: false);
    final market = MarketService();
    final ok = await voice.initializeSpeech();
    if (!ok) return;

    const cropEn = 'Which crop price do you want to know?';
    const cropTe = 'ఏ పంట ధర తెలుసుకోవాలి?';
    final crop = await voice.askAndListen(promptEn: cropEn, promptTe: cropTe, seconds: 6);
    if (crop.isEmpty) {
      await voice.speak(voice.currentLanguage == 'te' ? 'పంట పేరు వినలేకపోయాను.' : 'Could not hear crop name.');
      return;
    }

    const locEn = 'Say your location or PIN code. You can also say skip.';
    const locTe = 'మీ స్థలం లేదా పిన్ కోడ్ చెప్పండి. లేకపోతే స్కిప్ అనండి.';
    final location = await voice.askAndListen(promptEn: locEn, promptTe: locTe, seconds: 6);
    final normalizedLocation = location.toLowerCase() == 'skip' ? null : location;
    final price = await market.getRealTimePrice(crop.trim(), location: normalizedLocation);
    _lastQueryCrop = crop;
    _lastQueryLocation = normalizedLocation;
    setState(() {});

    if (price == null) {
      await voice.speak(voice.currentLanguage == 'te' ? 'ధర లభ్యం కాలేదు.' : 'Price not available.');
      return;
    }

    final speakText = voice.currentLanguage == 'te'
        ? '${crop.trim()} ధర సుమారు రూ ${price.toStringAsFixed(0)}'
        : 'Approximate price of ${crop.trim()} is rupees ${price.toStringAsFixed(0)}';
    await voice.speak(speakText);
  }
}
