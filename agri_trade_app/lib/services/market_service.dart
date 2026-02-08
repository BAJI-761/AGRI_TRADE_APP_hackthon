import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// Placeholder model
class RetailerOffer {
  final String crop;
  final double price;
  final double rating;
  final String retailerId;

  RetailerOffer(this.crop, this.price, this.rating, this.retailerId);
}

class MarketService {
  // --- Retailer offers remain demo for now ---
  List<RetailerOffer> get retailerOffers => [
        RetailerOffer('Wheat', 50.0, 4.2, 'retailer1'),
        RetailerOffer('Rice', 30.0, 4.5, 'retailer2'),
        RetailerOffer('Corn', 24.0, 4.0, 'retailer3'),
        RetailerOffer('Tomato', 28.0, 3.9, 'retailer4'),
        RetailerOffer('Onion', 32.0, 4.1, 'retailer5'),
        RetailerOffer('Soybeans', 45.8, 4.3, 'retailer6'),
        RetailerOffer('Cotton', 62.0, 4.0, 'retailer7'),
        RetailerOffer('Sugarcane', 18.5, 3.8, 'retailer8'),
      ];

  // --- Real-time market insights ---
  final StreamController<List<String>> _insightsController = StreamController.broadcast();
  Timer? _insightsTimer;
  bool _loggedConfigWarning = false;

  Stream<List<String>> get insightsStream => _insightsController.stream;

  Future<void> initializeInsightsPolling() async {
    if (!_isApiConfigured()) {
      if (!_loggedConfigWarning) {
        debugPrint('MarketService: Insights API not configured. Skipping polling.');
        _loggedConfigWarning = true;
      }
      _insightsController.add(const <String>[]);
      return;
    }
    // Fetch immediately, then poll periodically
    await fetchInsightsOnce();
    _insightsTimer?.cancel();
    _insightsTimer = Timer.periodic(
      const Duration(seconds: ApiConfig.insightsPollingSeconds),
      (_) => fetchInsightsOnce(),
    );
  }

  Future<void> dispose() async {
    _insightsTimer?.cancel();
    await _insightsController.close();
  }

  Future<void> fetchInsightsOnce() async {
    if (!_isApiConfigured()) {
      return;
    }
    try {
      final url = Uri.parse(ApiConfig.insightsUrl());
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> raw = data is List ? data : (data['insights'] as List<dynamic>? ?? []);
        final insights = raw.map((e) => e.toString()).toList(growable: false);
        _insightsController.add(insights);
      } else {
        // Avoid spamming logs for repeated failures
        if (!_loggedConfigWarning) {
          debugPrint('MarketService: Failed to fetch insights: ${response.statusCode}. Configure MARKET_API_BASE_URL or adjust endpoint.');
          _loggedConfigWarning = true;
        }
        _insightsController.add(const <String>[]);
      }
    } catch (e) {
      if (!_loggedConfigWarning) {
        debugPrint('MarketService: Error fetching insights: $e');
        _loggedConfigWarning = true;
      }
    }
  }

  void addReview(String retailerId, double rating) {
    // Placeholder: Simulate review update
    debugPrint('Added review for $retailerId with rating $rating');
  }

  void updateRetailerInventory(String retailerId, Map<String, int> inventory) {
    // Placeholder: Simulate inventory update
    debugPrint('Updated inventory for $retailerId: $inventory');
  }

  // --- Real price lookup via API ---
  Future<double?> getRealTimePrice(String crop, {String? location}) async {
    try {
      if (!_isApiConfigured()) {
        return null;
      }
      final url = Uri.parse(ApiConfig.priceUrl(crop: crop, location: location));
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['price'] != null) {
          return (data['price'] as num).toDouble();
        }
        if (data is num) {
          return data.toDouble();
        }
        // Try common shapes
        if (data is Map && data['data'] is Map && (data['data']['price'] != null)) {
          return (data['data']['price'] as num).toDouble();
        }
      } else {
        debugPrint('Failed to fetch price: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching price: $e');
    }
    return null;
  }

  bool _isApiConfigured() {
    final base = ApiConfig.baseUrl.trim();
    if (base.isEmpty) return false;
    if (base.contains('example.com')) return false;
    return true;
  }
}
