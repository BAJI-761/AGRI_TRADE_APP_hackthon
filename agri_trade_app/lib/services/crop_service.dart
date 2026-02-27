import '../models/crop_prediction.dart';
import 'smart_crop_engine.dart';

class CropService {
  Future<List<CropPrediction>> predictCrop({
    required String soil,
    required String weather,
    required String season,
    required String totalLand,
    required String irrigationType,
    required String waterAvailability,
    required String previousCrop,
    required String marketDemand,
    required String budgetRange,
    required String laborAvailability,
    String? location,
    String? soilPh,
    String? rainfall,
  }) async {
    // Artificial delay to simulate "thinking" (optional, but good for UX)
    await Future.delayed(const Duration(seconds: 1));
    
    // Debug print
    print("Calling SmartCropEngine with: land=$totalLand, budget=$budgetRange");

    return SmartCropEngine.predict(
      soilType: soil,
      season: season,
      waterAvailability: waterAvailability,
      irrigationType: irrigationType,
      totalLand: totalLand,
      budgetRange: budgetRange,
      marketDemand: marketDemand,
      previousCrop: previousCrop,
    );
  }

  List<CropPrediction> _getFallbackPredictions(String soil, String weather, String season) {
    // Basic fallback logic based on common agricultural knowledge
    List<CropPrediction> predictions = [];
    
    if (soil.toLowerCase() == 'clay' && season.toLowerCase() == 'monsoon') {
      predictions.add(CropPrediction(
        crop: 'Rice',
        confidence: 0.85,
        description: 'Rice thrives in clay soil with high water retention during monsoon',
        advantages: ['High water retention', 'Good for paddy cultivation', 'Stable yield'],
        careTips: ['Maintain water level', 'Use organic fertilizers', 'Control pests regularly'],
        bestTimeToPlant: 'Early monsoon season',
        expectedYield: '3-4 tons per hectare',
      ));
    }
    
    if (soil.toLowerCase() == 'sandy' && weather.toLowerCase() == 'sunny') {
      predictions.add(CropPrediction(
        crop: 'Groundnut',
        confidence: 0.80,
        description: 'Groundnut grows well in sandy soil with good drainage and sunny weather',
        advantages: ['Good drainage', 'Drought resistant', 'High oil content'],
        careTips: ['Ensure proper spacing', 'Control weeds', 'Harvest at right time'],
        bestTimeToPlant: 'Summer season',
        expectedYield: '2-3 tons per hectare',
      ));
    }
    
    if (soil.toLowerCase() == 'loamy' && season.toLowerCase() == 'spring') {
      predictions.add(CropPrediction(
        crop: 'Wheat',
        confidence: 0.90,
        description: 'Wheat is ideal for loamy soil during spring with moderate temperature',
        advantages: ['Versatile soil type', 'Good nutrient retention', 'High market demand'],
        careTips: ['Sow at right depth', 'Apply balanced fertilizers', 'Monitor for diseases'],
        bestTimeToPlant: 'Early spring',
        expectedYield: '4-5 tons per hectare',
      ));
    }
    
    // Add more fallback predictions if needed
    if (predictions.isEmpty) {
      predictions.add(CropPrediction(
        crop: 'Mixed Vegetables',
        confidence: 0.70,
        description: 'General recommendation for mixed vegetable farming',
        advantages: ['Diversified income', 'Year-round cultivation', 'Local market demand'],
        careTips: ['Crop rotation', 'Organic farming', 'Proper irrigation'],
        bestTimeToPlant: 'Based on local climate',
        expectedYield: 'Varies by crop type',
      ));
    }
    
    return predictions;
  }
}
