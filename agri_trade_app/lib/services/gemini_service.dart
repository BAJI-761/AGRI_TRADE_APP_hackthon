import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crop_prediction.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String _apiKey = 'AIzaSyDUKoW66CEDmscvUbhi7kmr-JZxc-L0eOk';

  Future<List<CropPrediction>> getCropPredictions({
    required String soilType,
    required String weatherCondition,
    required String season,
    String? location,
    String? soilPh,
    String? rainfall,
  }) async {
    try {
      final prompt = _buildPrompt(
        soilType: soilType,
        weatherCondition: weatherCondition,
        season: season,
        location: location,
        soilPh: soilPh,
        rainfall: rainfall,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGeminiResponse(data);
      } else {
        throw Exception('Failed to get predictions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calling Gemini AI: $e');
    }
  }

  String _buildPrompt({
    required String soilType,
    required String weatherCondition,
    required String season,
    String? location,
    String? soilPh,
    String? rainfall,
  }) {
    String prompt = '''
You are an expert agricultural scientist. Based on the following farming conditions, recommend 3-5 suitable crops with detailed information.

Farming Conditions:
- Soil Type: $soilType
- Weather Condition: $weatherCondition
- Season: $season
${location != null ? '- Location: $location' : ''}
${soilPh != null ? '- Soil pH: $soilPh' : ''}
${rainfall != null ? '- Rainfall: $rainfall' : ''}

Please provide recommendations in the following JSON format for each crop:
[
  {
    "crop": "Crop Name",
    "confidence": 0.85,
    "description": "Brief description of why this crop is suitable",
    "advantages": ["Advantage 1", "Advantage 2", "Advantage 3"],
    "careTips": ["Care tip 1", "Care tip 2", "Care tip 3"],
    "bestTimeToPlant": "Specific timing information",
    "expectedYield": "Expected yield information"
  }
]

Focus on crops that are:
1. Well-suited for the given soil type
2. Appropriate for the weather conditions
3. Suitable for the specified season
4. Economically viable
5. Relatively easy to grow

Provide realistic confidence scores and practical advice.
''';

    return prompt;
  }

  List<CropPrediction> _parseGeminiResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List;
      if (candidates.isEmpty) {
        throw Exception('No response from Gemini AI');
      }

      final content = candidates.first['content'];
      final parts = content['parts'] as List;
      final text = parts.first['text'];

      // Extract JSON from the response text
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('Invalid response format from Gemini AI');
      }

      final jsonText = text.substring(jsonStart, jsonEnd);
      final List<dynamic> cropsData = jsonDecode(jsonText);

      return cropsData.map((cropData) {
        return CropPrediction.fromJson(cropData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to parse Gemini AI response: $e');
    }
  }
}
