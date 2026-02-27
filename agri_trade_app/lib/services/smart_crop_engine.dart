import '../models/crop_prediction.dart';

class CropProfile {
  final String name;
  final String description;
  final List<String> advantages;
  final List<String> careTips;
  final List<String> suitableSoils; // e.g., ["Clay", "Loamy"]
  final List<String> suitableSeasons; // e.g., ["Kharif", "Summer"]
  final String waterRequirement; // "Low", "Medium", "High"
  final List<String> suitableIrrigation; // e.g., ["Rain-fed", "Drip"]
  final double minYield; // Tons per acre
  final double maxYield;
  final double minPrice; // ₹ per ton
  final double maxPrice;
  final double costOfCultivation; // ₹ per acre
  final int durationMin; // Days
  final int durationMax;
  final String riskProfile; // "Low", "Medium", "High" (Base risk)
  final bool isCommercial; // For large land logic
  final bool isIntensive; // For small land logic (high value)

  const CropProfile({
    required this.name,
    required this.description,
    required this.advantages,
    required this.careTips,
    required this.suitableSoils,
    required this.suitableSeasons,
    required this.waterRequirement,
    required this.suitableIrrigation,
    required this.minYield,
    required this.maxYield,
    required this.minPrice,
    required this.maxPrice,
    required this.costOfCultivation,
    required this.durationMin,
    required this.durationMax,
    required this.riskProfile,
    this.isCommercial = false,
    this.isIntensive = false,
  });
}

class SmartCropEngine {
  static const List<CropProfile> cropDatabase = [
    CropProfile(
      name: "Rice (Paddy)",
      description: "Staple food crop requiring significant water.",
      advantages: ["High market demand", "Stable government procurement", "Suitable for clay soils"],
      careTips: ["Maintain standing water", "Monitor for stem borers", "Apply nitrogen fertilizer"],
      suitableSoils: ["Clay", "Silt", "Loamy"],
      suitableSeasons: ["Monsoon", "Kharif", "Summer"],
      waterRequirement: "High",
      suitableIrrigation: ["Canal", "Well", "Rain-fed"],
      minYield: 2.0,
      maxYield: 3.5,
      minPrice: 20000, // Per ton
      maxPrice: 25000,
      costOfCultivation: 25000, // Per acre
      durationMin: 120,
      durationMax: 150,
      riskProfile: "Low",
      isCommercial: true,
    ),
    CropProfile(
      name: "Wheat",
      description: "Major cereal grain adapted to cooler climates.",
      advantages: ["Less water than rice", "Mechanized harvesting easy", "Nutritious grain"],
      careTips: ["Irrigate at crown root initiation", "Check for rust disease", "Weed control is crucial"],
      suitableSoils: ["Loamy", "Clay", "Silt"],
      suitableSeasons: ["Winter", "Rabi", "Spring"],
      waterRequirement: "Medium",
      suitableIrrigation: ["Canal", "Well", "Sprinkler"],
      minYield: 1.5,
      maxYield: 2.5,
      minPrice: 21000,
      maxPrice: 24000,
      costOfCultivation: 18000,
      durationMin: 110,
      durationMax: 140,
      riskProfile: "Low",
      isCommercial: true,
    ),
     CropProfile(
      name: "Cotton",
      description: "Principal fiber crop, good for black soil.",
      advantages: ["High cash crop value", "Export demand", "Suitable for dry regions"],
      careTips: ["Monitor for bollworms", "Avoid waterlogging", "Timely picking"],
      suitableSoils: ["Black", "Loamy"],
      suitableSeasons: ["Kharif", "Monsoon"],
      waterRequirement: "Medium",
      suitableIrrigation: ["Drip", "Rain-fed", "Canal"],
      minYield: 0.8,
      maxYield: 1.5,
      minPrice: 50000,
      maxPrice: 70000,
      costOfCultivation: 22000,
      durationMin: 150,
      durationMax: 180,
      riskProfile: "Medium",
      isCommercial: true,
    ),
    CropProfile(
      name: "Millets (Ragi/Bajra)",
      description: "Hardy cereals suitable for dry lands.",
      advantages: ["Drought tolerant", "Low input cost", "High nutritional value"],
      careTips: ["Requires less fertilizer", "Thinning of seedlings", "Bird protection"],
      suitableSoils: ["Red", "Sandy", "Loamy", "Silt"],
      suitableSeasons: ["Kharif", "Summer", "Monsoon"],
      waterRequirement: "Low",
      suitableIrrigation: ["Rain-fed", "Sprinkler"],
      minYield: 0.6,
      maxYield: 1.2,
      minPrice: 25000,
      maxPrice: 35000,
      costOfCultivation: 8000,
      durationMin: 90,
      durationMax: 110,
      riskProfile: "Low",
    ),
    CropProfile(
      name: "Sugarcane",
      description: "Long duration cash crop.",
      advantages: ["High biomass", "Used for sugar and ethanol", "Sturdy crop"],
      careTips: ["Needs regular irrigation", "Propping to prevent lodging", "Earthing up"],
      suitableSoils: ["Loamy", "Clay", "Black"],
      suitableSeasons: ["Spring", "Autumn", "Year-round"],
      waterRequirement: "High",
      suitableIrrigation: ["Canal", "Well", "Drip"],
      minYield: 30,
      maxYield: 50,
      minPrice: 3000,
      maxPrice: 4000,
      costOfCultivation: 40000,
      durationMin: 300,
      durationMax: 360,
      riskProfile: "Low",
      isCommercial: true,
    ),
    CropProfile(
      name: "Tomato",
      description: "Short duration vegetable crop.",
      advantages: ["Short cycle", "High yield potential", "Everyday demand"],
      careTips: ["Staking required", "Pest control needed", "Frequent harvest"],
      suitableSoils: ["Red", "Loamy", "Black"],
      suitableSeasons: ["Winter", "Summer", "Spring"],
      waterRequirement: "Medium",
      suitableIrrigation: ["Drip", "Well"],
      minYield: 10,
      maxYield: 25,
      minPrice: 10000,
      maxPrice: 30000, // Highly volatile
      costOfCultivation: 30000,
      durationMin: 90,
      durationMax: 120,
      riskProfile: "High", // Due to price volatility and perishability
      isIntensive: true,
    ),
    CropProfile(
      name: "Groundnut",
      description: "Oilseed crop, fixes nitrogen.",
      advantages: ["Soil improvement", "Oil and fodder value", "Short duration"],
      careTips: ["Gypsum application", "Control tikka disease", "Loose soil for pegs"],
      suitableSoils: ["Sandy", "Red", "Loamy"],
      suitableSeasons: ["Kharif", "Summer"],
      waterRequirement: "Medium",
      suitableIrrigation: ["Sprinkler", "Rain-fed"],
      minYield: 0.8,
      maxYield: 1.5,
      minPrice: 45000,
      maxPrice: 60000,
      costOfCultivation: 15000,
      durationMin: 100,
      durationMax: 130,
      riskProfile: "Low",
    ),
    CropProfile(
      name: "Chilli",
      description: "High value spice crop.",
      advantages: ["Export potential", "Used fresh or dried", "High returns"],
      careTips: ["Nursery management", "Virus control", "Proper drying"],
      suitableSoils: ["Black", "Loamy", "Red"],
      suitableSeasons: ["Kharif", "Rabi"],
      waterRequirement: "Medium",
      suitableIrrigation: ["Drip", "Well"],
      minYield: 1.5, // Dried
      maxYield: 2.5,
      minPrice: 100000,
      maxPrice: 150000,
      costOfCultivation: 40000,
      durationMin: 150,
      durationMax: 180,
      riskProfile: "Medium",
      isIntensive: true,
    ),
     CropProfile(
      name: "Maize (Corn)",
      description: "Versatile cereal and fodder crop.",
      advantages: ["Wide adaptability", "Industrial use", "Biomass for fodder"],
      careTips: ["Avoid water stagnation", "Control fall armyworm", "Split fertilizer application"],
      suitableSoils: ["Loamy", "Silt", "Red", "Black"],
      suitableSeasons: ["Kharif", "Rabi", "Spring"],
      waterRequirement: "Medium",
      suitableIrrigation: ["Rain-fed", "Sprinkler", "Canal"],
      minYield: 2.0,
      maxYield: 3.5,
      minPrice: 18000,
      maxPrice: 22000,
      costOfCultivation: 15000,
      durationMin: 90,
      durationMax: 110,
      riskProfile: "Low",
      isCommercial: true,
    ),
    CropProfile(
      name: "Banana",
      description: "High energy fruit crop.",
      advantages: ["Year round income", "High biomass", "Intercropping possible"],
      careTips: ["Desucker removal", "Propping", "High nutrient needs"],
      suitableSoils: ["Loamy", "Clay", "Silt"],
      suitableSeasons: ["Year-round"],
      waterRequirement: "High",
      suitableIrrigation: ["Drip", "Canal"],
      minYield: 25,
      maxYield: 40,
      minPrice: 10000,
      maxPrice: 15000,
      costOfCultivation: 50000,
      durationMin: 300,
      durationMax: 360,
      riskProfile: "Medium",
      isIntensive: true,
    ),
  ];

  static List<CropPrediction> predict({
    required String soilType,
    required String season,
    required String waterAvailability,
    required String irrigationType,
    required String totalLand,
    required String budgetRange,
    String? marketDemand,
    String? previousCrop,
  }) {
    List<Map<String, dynamic>> scoredCrops = [];

    // 1. Scoring Logic
    for (var crop in cropDatabase) {
      int score = 0;
      Map<String, int> breakdown = {};

      // Soil Match (+20 Exact, +10 Compatible)
      if (crop.suitableSoils.contains(soilType)) {
        score += 20;
        breakdown['Soil Match'] = 20;
      } else {
        // Simple compatibility check (e.g. Loamy is generally good)
        if (soilType == 'Loamy' || crop.suitableSoils.contains('Loamy')) {
           score += 10;
           breakdown['Soil Compatible'] = 10;
        }
      }

      // Season Match (+20)
      if (crop.suitableSeasons.contains(season) || crop.suitableSeasons.contains("Year-round")) {
        score += 20;
        breakdown['Season Match'] = 20;
      }

      // Water Match (+20, -30 Penalty)
      bool waterMatch = false;
      if (crop.waterRequirement == waterAvailability) {
        score += 20;
        breakdown['Water Match'] = 20;
        waterMatch = true;
      } else if (crop.waterRequirement == 'Low' && waterAvailability != 'Low') {
         // Crop needs low water, but we have more. Good.
         score += 20;
         breakdown['Water Sufficient'] = 20;
         waterMatch = true;
      } else if (crop.waterRequirement == 'High' && waterAvailability == 'Low') {
        score -= 30; // Severe penalty
        breakdown['Water Mismatch'] = -30;
      } else {
        score += 5; // Moderate match
        breakdown['Water Partial'] = 5;
      }

      // Irrigation Match (+10)
      if (crop.suitableIrrigation.contains(irrigationType)) {
        score += 10;
        breakdown['Irrigation Match'] = 10;
      }

      // Land Size Logic
      double acres = double.tryParse(totalLand.split(' ')[0]) ?? 0;
      if (acres > 5 && crop.isCommercial) {
        score += 10;
        breakdown['Large Land Bonus'] = 10;
      }
      if (acres < 2 && crop.isIntensive) {
        score += 10;
        breakdown['Small Land Bonus'] = 10;
      }

      // Market Demand
      if (marketDemand == 'High') {
        score += 10;
        breakdown['Market Demand'] = 10;
      }
      
      // Previous Crop Rotation (Simple logic)
      if (previousCrop != null && previousCrop.isNotEmpty && previousCrop.toLowerCase() != crop.name.toLowerCase()) {
         score += 5;
         breakdown['Rotation Bonus'] = 5;
      }

      scoredCrops.add({
        'crop': crop,
        'score': score,
        'breakdown': breakdown,
        'waterSevereMismatch': (crop.waterRequirement == 'High' && waterAvailability == 'Low'),
      });
    }

    // 2. Sort by Score
    scoredCrops.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // 3. Take Top 3
    final topCrops = scoredCrops.take(3).toList();

    // 4. Convert to CropPrediction objects
    return topCrops.map((item) {
      final crop = item['crop'] as CropProfile;
      final score = item['score'] as int;
      final breakdown = item['breakdown'] as Map<String, int>;
      final isWaterSevereMismatch = item['waterSevereMismatch'] as bool;
      double acres = double.tryParse(totalLand.split(' ')[0]) ?? 1;

      // Financials
      double avgYield = (crop.minYield + crop.maxYield) / 2;
      double avgPrice = (crop.minPrice + crop.maxPrice) / 2;
      double revenue = acres * avgYield * avgPrice;
      double cost = acres * crop.costOfCultivation;
      double profit = revenue - cost;

      // Risk Logic
      String finalRisk = crop.riskProfile; // Base risk
      if (isWaterSevereMismatch) {
        finalRisk = 'High (Water Shortage)';
      } else if (!crop.suitableIrrigation.contains(irrigationType)) {
        if (finalRisk == 'Low') finalRisk = 'Medium (Irrigation Mismatch)';
      }

      // Confidence Score
      double confidence = (score + 10).clamp(0, 95) / 100.0;
      if (confidence < 0.5) confidence = 0.5; // Base confidence

      return CropPrediction(
        crop: crop.name,
        confidence: confidence,
        description: crop.description,
        advantages: crop.advantages,
        careTips: crop.careTips,
        bestTimeToPlant: crop.suitableSeasons.join(', '),
        expectedYield: '${crop.minYield}-${crop.maxYield} tons/acre',
        riskLevel: finalRisk,
        marketTrendScore: (marketDemand == 'High') ? 8 : (marketDemand == 'Medium' ? 6 : 4),
        estimatedProfit: '₹${(profit * 0.9).toStringAsFixed(0)} - ₹${(profit * 1.1).toStringAsFixed(0)}', // +/- 10% range
      );
    }).toList();
  }
}
