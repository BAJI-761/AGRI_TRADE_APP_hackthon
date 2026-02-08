import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/crop_service.dart';
import '../../models/crop_prediction.dart';
import '../../services/voice_service.dart';
import '../../services/language_service.dart';
import '../../widgets/navigation_helper.dart';

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
  bool _voiceMode = false;

  final List<String> _soilTypes = [
    'Clay',
    'Sandy',
    'Loamy',
    'Silt',
    'Peaty',
    'Chalky'
  ];

  final List<String> _weatherConditions = [
    'Sunny',
    'Cloudy',
    'Rainy',
    'Humid',
    'Dry',
    'Windy'
  ];

  final List<String> _seasons = [
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
    'Monsoon'
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('crop_prediction'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [],
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
        children: [
          Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom),
            children: [
              
              Consumer<LanguageService>(
                builder: (context, ls, _) => Text(
                  ls.getLocalizedString('get_crop_recommendations'),
                  style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              ),
              const SizedBox(height: 8),
              Consumer<LanguageService>(
                builder: (context, ls, _) => Text(
                  ls.getLocalizedString('enter_farming_conditions'),
                  style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              ),
              const SizedBox(height: 24),
              
              // Soil Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _soilController.text.isEmpty ? null : _soilController.text,
                decoration: InputDecoration(
                  labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('soil_type_required'),
                  prefixIcon: const Icon(Icons.landscape),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _soilTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _soilController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LanguageService>(context, listen: false).getLocalizedString('please_select_soil_type');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Weather Condition Dropdown
              DropdownButtonFormField<String>(
                initialValue: _weatherController.text.isEmpty ? null : _weatherController.text,
                decoration: InputDecoration(
                  labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('weather_condition_required'),
                  prefixIcon: const Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _weatherConditions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _weatherController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LanguageService>(context, listen: false).getLocalizedString('please_select_weather_condition');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Season Dropdown
              DropdownButtonFormField<String>(
                initialValue: _seasonController.text.isEmpty ? null : _seasonController.text,
                decoration: InputDecoration(
                  labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('season_required'),
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _seasons.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _seasonController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return Provider.of<LanguageService>(context, listen: false).getLocalizedString('please_select_season');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'e.g., North India, Coastal Region',
                ),
              ),
              const SizedBox(height: 16),
              
              // Row for Soil pH and Rainfall
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _soilPhController,
                      decoration: InputDecoration(
                        labelText: 'Soil pH (Optional)',
                        prefixIcon: const Icon(Icons.science),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'e.g., 6.5',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _rainfallController,
                      decoration: InputDecoration(
                        labelText: 'Rainfall (Optional)',
                        prefixIcon: const Icon(Icons.water_drop),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'e.g., 1200mm',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Predict Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _predictCrops,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology),
                            SizedBox(width: 8),
                            Text(
                              'Get AI Predictions',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Results Section
              if (_predictions != null) ...[
                const Text(
                  'AI Crop Recommendations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _predictions!.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions![index];
                    return _buildCropCard(prediction);
                  },
                ),
              ],
            ],
          ),
        ),
        
        ],
      ),
      ),
    ),
    );
  }

  Widget _buildCropCard(CropPrediction prediction) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            '${(prediction.confidence * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          prediction.crop,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(
          Icons.agriculture,
          color: Colors.green,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (prediction.description.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prediction.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Advantages
                if (prediction.advantages.isNotEmpty) ...[
                  const Text(
                    'Advantages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...prediction.advantages.map((advantage) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(advantage)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                
                // Care Tips
                if (prediction.careTips.isNotEmpty) ...[
                  const Text(
                    'Care Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...prediction.careTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                
                // Best Time to Plant
                if (prediction.bestTimeToPlant.isNotEmpty) ...[
                  const Text(
                    'Best Time to Plant',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(prediction.bestTimeToPlant),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Expected Yield
                if (prediction.expectedYield.isNotEmpty) ...[
                  const Text(
                    'Expected Yield',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Text(prediction.expectedYield),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _predictCrops() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting predictions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    final voice = Provider.of<VoiceService>(context, listen: false);
    final ok = await voice.initializeSpeech();
    if (!ok) return;

    // Soil type
    const soilEn = 'Say your soil type like clay, sandy or loamy';
    const soilTe = 'మీ నేల రకం చెప్పండి, ఉదా: మట్టి, ఇసుక లేదా లోమీ';
    final soil = await voice.askAndListen(promptEn: soilEn, promptTe: soilTe, seconds: 6);
    if (soil.isEmpty) return;
    _soilController.text = _capitalize(soil);

    // Weather condition
    const weatherEn = 'Say your weather condition like sunny, rainy or humid';
    const weatherTe = 'మీ వాతావరణం చెప్పండి, ఉదా: ఎండ, వర్షం లేదా తేమ';
    final weather = await voice.askAndListen(promptEn: weatherEn, promptTe: weatherTe, seconds: 6);
    if (weather.isEmpty) return;
    _weatherController.text = _capitalize(weather);

    // Season
    const seasonEn = 'Say current season like summer, monsoon or winter';
    const seasonTe = 'ప్రస్తుత ఋతువు చెప్పండి, ఉదా: వేసవి, వర్షాకాలం లేదా శీతకాలం';
    final season = await voice.askAndListen(promptEn: seasonEn, promptTe: seasonTe, seconds: 6);
    if (season.isEmpty) return;
    _seasonController.text = _capitalize(season);

    // Optional location
    const locEn = 'Say your location or say skip';
    const locTe = 'మీ స్థలం చెప్పండి లేదా స్కిప్ అనండి';
    final location = await voice.askAndListen(promptEn: locEn, promptTe: locTe, seconds: 5);
    if (location.toLowerCase() != 'skip') {
      _locationController.text = location;
    }

    // Confirm and run prediction
    await voice.speak(voice.currentLanguage == 'te' ? 'పంట సూచన సిద్ధం చేస్తున్నాను.' : 'Preparing crop prediction.');
    await _predictCrops();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
