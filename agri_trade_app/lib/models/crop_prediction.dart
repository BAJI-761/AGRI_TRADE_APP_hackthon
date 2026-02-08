class CropPrediction {
  final String crop;
  final double confidence;
  final String description;
  final List<String> advantages;
  final List<String> careTips;
  final String bestTimeToPlant;
  final String expectedYield;

  CropPrediction({
    required this.crop,
    required this.confidence,
    required this.description,
    required this.advantages,
    required this.careTips,
    required this.bestTimeToPlant,
    required this.expectedYield,
  });

  factory CropPrediction.fromJson(Map<String, dynamic> json) {
    return CropPrediction(
      crop: json['crop'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      advantages: List<String>.from(json['advantages'] ?? []),
      careTips: List<String>.from(json['careTips'] ?? []),
      bestTimeToPlant: json['bestTimeToPlant'] ?? '',
      expectedYield: json['expectedYield'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'confidence': confidence,
      'description': description,
      'advantages': advantages,
      'careTips': careTips,
      'bestTimeToPlant': bestTimeToPlant,
      'expectedYield': expectedYield,
    };
  }
}
