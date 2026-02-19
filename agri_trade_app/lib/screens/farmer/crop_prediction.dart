import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/language_service.dart';
import '../../services/crop_service.dart';
import '../../models/crop_prediction.dart';
import '../../services/voice_service.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../widgets/primary_button.dart';

class CropPredictionScreen extends StatefulWidget {
  const CropPredictionScreen({super.key});

  @override
  _CropPredictionScreenState createState() => _CropPredictionScreenState();
}

class _CropPredictionScreenState extends State<CropPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _soilController = TextEditingController();
  final _weatherController = TextEditingController();
  final _seasonController = TextEditingController();
  final _locationController = TextEditingController();
  final _soilPhController = TextEditingController();
  final _rainfallController = TextEditingController();
  final cropService = CropService();
  
  List<CropPrediction>? _predictions;
  bool _isLoading = false;
  bool _isListening = false;

  final List<String> _soilTypes = [
    'Clay', 'Sandy', 'Loamy', 'Silt', 'Peaty', 'Chalky'
  ];

  final List<String> _weatherConditions = [
    'Sunny', 'Cloudy', 'Rainy', 'Humid', 'Dry', 'Windy'
  ];

  final List<String> _seasons = [
    'Spring', 'Summer', 'Autumn', 'Winter', 'Monsoon'
  ];

  @override
  void dispose() {
    _soilController.dispose();
    _weatherController.dispose();
    _seasonController.dispose();
    _locationController.dispose();
    _soilPhController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  Future<void> _handleVoicePrediction() async {
    setState(() => _isListening = true);
    try {
      final voice = Provider.of<VoiceService>(context, listen: false);
      final ok = await voice.initializeSpeech();
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice not available')));
        setState(() => _isListening = false);
        return;
      }

      // Soil type
      final soil = await voice.askAndListen(
        promptEn: 'Say your soil type like clay, sandy or loamy', 
        promptTe: 'మీ నేల రకం చెప్పండి (మట్టి, ఇసుక)', 
        seconds: 5
      );
      if (soil.isNotEmpty) {
        final match = _findBestMatch(soil, _soilTypes);
        setState(() => _soilController.text = match ?? soil);
      }

      // Weather
      final weather = await voice.askAndListen(
        promptEn: 'Say weather like sunny or rainy', 
        promptTe: 'వాతావరణం చెప్పండి (ఎండ, వర్షం)', 
        seconds: 5
      );
      if (weather.isNotEmpty) {
        final match = _findBestMatch(weather, _weatherConditions);
        setState(() => _weatherController.text = match ?? weather);
      }

      // Season
      final season = await voice.askAndListen(
        promptEn: 'Say season like summer or winter', 
        promptTe: 'ఋతువు చెప్పండి (వేసవి, చలికాలం)', 
        seconds: 5
      );
      if (season.isNotEmpty) {
        final match = _findBestMatch(season, _seasons);
        setState(() => _seasonController.text = match ?? season);
      }
      
      voice.speak(voice.currentLanguage == 'te' ? 'పంట సూచన సిద్ధం చేస్తున్నాను.' : 'Predicting crops now.');
      await _predictCrops();

    } catch (e) {
      debugPrint('Voice error: $e');
    } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  // Simple helper to match voice input to dropdown options
  String? _findBestMatch(String input, List<String> options) {
    input = input.toLowerCase();
    for (var opt in options) {
      if (opt.toLowerCase().contains(input) || input.contains(opt.toLowerCase())) {
        return opt;
      }
    }
    return null;
  }

  Future<void> _predictCrops() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final predictions = await cropService.predictCrop(
        soil: _soilController.text,
        weather: _weatherController.text,
        season: _seasonController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        soilPh: _soilPhController.text.isEmpty ? null : _soilPhController.text,
        rainfall: _rainfallController.text.isEmpty ? null : _rainfallController.text,
      );
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ls = Provider.of<LanguageService>(context);
    
    return AppGradientScaffold(
      headerHeightFraction: 0.2,
      headerChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                ls.getLocalizedString('crop_prediction'),
                style: AppTheme.headingMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
      bodyChildren: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Voice Card
              _buildVoiceCard(ls),
              const SizedBox(height: 24),
              
              // Form Fields
              DropdownButtonFormField<String>(
                initialValue: _soilTypes.contains(_soilController.text) ? _soilController.text : null,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('soil_type_required'),
                  prefixIcon: const Icon(Icons.landscape, color: AppTheme.primaryGreen),
                ),
                items: _soilTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _soilController.text = v ?? ''),
                validator: (v) => v == null ? ls.getLocalizedString('required') : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _weatherConditions.contains(_weatherController.text) ? _weatherController.text : null,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('weather_condition_required'),
                  prefixIcon: const Icon(Icons.wb_sunny, color: AppTheme.primaryGreen),
                ),
                items: _weatherConditions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _weatherController.text = v ?? ''),
                validator: (v) => v == null ? ls.getLocalizedString('required') : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _seasons.contains(_seasonController.text) ? _seasonController.text : null,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('season_required'),
                  prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                ),
                items: _seasons.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _seasonController.text = v ?? ''),
                validator: (v) => v == null ? ls.getLocalizedString('required') : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: 'Location (Optional)',
                  prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: ls.getLocalizedString('get_crop_recommendations'),
                isLoading: _isLoading,
                onPressed: _predictCrops,
              ),
              
              const SizedBox(height: 32),
              
              // Results
              if (_predictions != null) ...[
                 Text(
                  'Recommendations',
                  style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen),
                 ),
                 const SizedBox(height: 16),
                 ..._predictions!.map((p) => _buildPredictionCard(p)).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCard(LanguageService ls) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration.copyWith(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ls.currentLanguage == 'te' ? 'వాయిస్ సహాయం' : 'Voice Assistant',
                  style: AppTheme.headingSmall.copyWith(fontSize: 16),
                ),
                Text(
                  ls.currentLanguage == 'te' ? 'మాట్లాడి వివరాలు నింపండి' : 'Tap to fill details by voice',
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isListening ? null : _handleVoicePrediction,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppTheme.errorRed : AppTheme.primaryGreen,
                boxShadow: [
                  BoxShadow(color: (_isListening ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.3), blurRadius: 8),
                ],
              ),
              child: Icon(
                _isListening ? Icons.graphic_eq : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(CropPrediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Text('${(prediction.confidence * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(prediction.crop, style: AppTheme.headingSmall.copyWith(fontSize: 18)),
        subtitle: Text('Confidence: ${(prediction.confidence * 100).toStringAsFixed(0)}%'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Description', prediction.description),
                const SizedBox(height: 12),
                if (prediction.bestTimeToPlant.isNotEmpty) _buildInfoRow('Best Time', prediction.bestTimeToPlant),
                const SizedBox(height: 12),
                if (prediction.expectedYield.isNotEmpty) _buildInfoRow('Yield', prediction.expectedYield),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textDark))),
      ],
    );
  }
}
