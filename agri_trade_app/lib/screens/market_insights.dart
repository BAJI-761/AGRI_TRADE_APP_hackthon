import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/market_service.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../widgets/navigation_helper.dart';

class MarketInsightsScreen extends StatefulWidget {
  const MarketInsightsScreen({super.key});

  @override
  State<MarketInsightsScreen> createState() => _MarketInsightsScreenState();
}

class _MarketInsightsScreenState extends State<MarketInsightsScreen> {
  bool _voiceMode = false;
  String? _lastQueryCrop;
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
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('market_insights_title'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final ls = Provider.of<LanguageService>(context, listen: false);
                await marketService.fetchInsightsOnce();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ls.getLocalizedString('market_data_refreshed')),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            ls.getLocalizedString('market_overview'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: _buildMarketStat(
                            Provider.of<LanguageService>(context, listen: false).getLocalizedString('active_crops'),
                            '12',
                          ),
                        ),
                        Flexible(
                          child: _buildMarketStat(
                            Provider.of<LanguageService>(context, listen: false).getLocalizedString('avg_price'),
                            '\$38.25',
                          ),
                        ),
                        Flexible(
                          child: _buildMarketStat(
                            Provider.of<LanguageService>(context, listen: false).getLocalizedString('market_trend'),
                            '+2.3%',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text(
                ls.getLocalizedString('trending_crops'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildTrendingCrop('Wheat', '+5.2%', 52.50, Colors.green, context),
                  _buildTrendingCrop('Rice', '+2.1%', 30.75, Colors.green, context),
                  _buildTrendingCrop('Corn', '-1.8%', 24.20, Colors.red, context),
                  _buildTrendingCrop('Soybeans', '+3.4%', 45.80, Colors.green, context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text(
                ls.getLocalizedString('latest_news'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildNewsItem('Global wheat demand increases due to supply chain disruptions', context),
                  _buildNewsItem('Rice prices stabilize after recent fluctuations', context),
                  _buildNewsItem('New agricultural policies expected to impact crop prices', context),
                  _buildNewsItem('Weather conditions favorable for upcoming harvest season', context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text(
                ls.getLocalizedString('price_alerts'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildAlertItem('Wheat prices up 5% this week'),
                  _buildAlertItem('Rice demand remains stable'),
                  _buildAlertItem('Corn prices expected to rise next month'),
                  _buildAlertItem('Soybean exports increase by 15%'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text(
                ls.getLocalizedString('market_analysis'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: StreamBuilder<List<String>>(
                stream: marketService.insightsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final insights = snapshot.data ?? const <String>[];
                  if (insights.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No insights available.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: insights.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.analytics, color: Colors.white),
                        ),
                        title: Text(
                          insights[index],
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
              ],
            ),
          ),
          
        ],
      ),
    ),
    );
  }

  Widget _buildMarketStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCrop(String crop, String trend, double price, Color color, BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          trend.startsWith('+') ? Icons.trending_up : Icons.trending_down,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        crop,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Consumer<LanguageService>(
        builder: (context, ls, _) => Text(
          '${ls.getLocalizedString('current_price')}: ₹${price.toStringAsFixed(2)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          trend,
          style: const TextStyle(
            color: Colors.white,
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
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.article, color: Colors.white),
      ),
      title: Text(
        news,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      subtitle: Consumer<LanguageService>(
        builder: (context, ls, _) => Text(
          '2 ${ls.getLocalizedString('days_ago')}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        _showNewsDetail(context, news);
      },
    );
  }

  Widget _buildAlertItem(String alert) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.orange,
        child: Icon(Icons.notifications, color: Colors.white),
      ),
      title: Text(
        alert,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      subtitle: Consumer<LanguageService>(
        builder: (context, ls, _) => Text(
          ls.getLocalizedString('alert'),
          style: const TextStyle(fontSize: 12, color: Colors.orange),
        ),
      ),
    );
  }

  void _showNewsDetail(BuildContext context, String news) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LanguageService>(
          builder: (context, ls, _) => Text(ls.getLocalizedString('market_news')),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text(
                ls.getLocalizedString('news_info'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<LanguageService>(
            builder: (context, ls, _) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ls.getLocalizedString('close')),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Consumer<LanguageService>(
                    builder: (context, ls, _) => Text(ls.getLocalizedString('news_saved_favorites')),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Consumer<LanguageService>(
              builder: (context, ls, _) => Text(ls.getLocalizedString('save')),
            ),
          ),
        ],
      ),
    );
  }

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
