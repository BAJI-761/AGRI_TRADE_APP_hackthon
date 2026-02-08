import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineService extends ChangeNotifier {
  static const String _cropDataKey = 'crop_data';
  static const String _marketDataKey = 'market_data';
  static const String _retailerDataKey = 'retailer_data';
  
  bool _isOnline = true;
  bool _isInitialized = false;
  
  // Getters
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;
  
  // Sample offline data for demonstration
  final Map<String, dynamic> _offlineCropData = {
    'crops': [
      {
        'name': 'Rice',
        'season': 'Kharif',
        'soil_type': 'Clay',
        'water_requirement': 'High',
        'duration': '120-150 days',
        'price_range': '₹1800-2200 per quintal',
        'image': '🌾',
      },
      {
        'name': 'Wheat',
        'season': 'Rabi',
        'soil_type': 'Loamy',
        'water_requirement': 'Medium',
        'duration': '100-120 days',
        'price_range': '₹2000-2400 per quintal',
        'image': '🌾',
      },
      {
        'name': 'Cotton',
        'season': 'Kharif',
        'soil_type': 'Black',
        'water_requirement': 'Medium',
        'duration': '150-180 days',
        'price_range': '₹6000-8000 per quintal',
        'image': '🌿',
      },
      {
        'name': 'Sugarcane',
        'season': 'Year-round',
        'soil_type': 'Alluvial',
        'water_requirement': 'High',
        'duration': '12-18 months',
        'price_range': '₹300-350 per quintal',
        'image': '🎋',
      },
    ],
    'last_updated': DateTime.now().toIso8601String(),
  };
  
  final Map<String, dynamic> _offlineMarketData = {
    'prices': [
      {'crop': 'Rice', 'price': '₹2100', 'unit': 'per quintal', 'trend': 'up'},
      {'crop': 'Wheat', 'price': '₹2200', 'unit': 'per quintal', 'trend': 'stable'},
      {'crop': 'Cotton', 'price': '₹7000', 'unit': 'per quintal', 'trend': 'up'},
      {'crop': 'Sugarcane', 'price': '₹325', 'unit': 'per quintal', 'trend': 'down'},
    ],
    'last_updated': DateTime.now().toIso8601String(),
  };
  
  final Map<String, dynamic> _offlineRetailerData = {
    'retailers': [
      {
        'name': 'Green Valley Store',
        'location': 'Village Center',
        'rating': 4.5,
        'phone': '9876543210',
        'crops': ['Rice', 'Wheat'],
        'distance': '2 km',
      },
      {
        'name': 'Farm Fresh Mart',
        'location': 'Main Road',
        'rating': 4.2,
        'phone': '9876543211',
        'crops': ['Cotton', 'Sugarcane'],
        'distance': '5 km',
      },
    ],
    'last_updated': DateTime.now().toIso8601String(),
  };
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check connectivity
    await _checkConnectivity();
    
    // Load offline data
    await _loadOfflineData();
    
    // Set up connectivity listener
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectivityStatus(result);
    });
    
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(connectivityResult);
  }
  
  void _updateConnectivityStatus(ConnectivityResult result) {
    bool wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (wasOnline != _isOnline) {
      notifyListeners();
      
      if (_isOnline) {
        // Sync data when coming back online
        _syncOfflineData();
      }
    }
  }
  
  Future<void> _loadOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load crop data
      String? cropDataJson = prefs.getString(_cropDataKey);
      if (cropDataJson == null) {
        // Store default offline data
        await _storeOfflineData(_cropDataKey, _offlineCropData);
      }
      
      // Load market data
      String? marketDataJson = prefs.getString(_marketDataKey);
      if (marketDataJson == null) {
        await _storeOfflineData(_marketDataKey, _offlineMarketData);
      }
      
      // Load retailer data
      String? retailerDataJson = prefs.getString(_retailerDataKey);
      if (retailerDataJson == null) {
        await _storeOfflineData(_retailerDataKey, _offlineRetailerData);
      }
    } catch (e) {
      debugPrint('Error loading offline data: $e');
    }
  }
  
  Future<void> _storeOfflineData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Error storing offline data: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getOfflineData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? dataJson = prefs.getString(key);
      if (dataJson != null) {
        return jsonDecode(dataJson);
      }
    } catch (e) {
      debugPrint('Error getting offline data: $e');
    }
    return null;
  }
  
  Future<List<Map<String, dynamic>>> getOfflineCrops() async {
    final data = await getOfflineData(_cropDataKey);
    if (data != null && data['crops'] != null) {
      return List<Map<String, dynamic>>.from(data['crops']);
    }
    return [];
  }
  
  Future<List<Map<String, dynamic>>> getOfflineMarketPrices() async {
    final data = await getOfflineData(_marketDataKey);
    if (data != null && data['prices'] != null) {
      return List<Map<String, dynamic>>.from(data['prices']);
    }
    return [];
  }
  
  Future<List<Map<String, dynamic>>> getOfflineRetailers() async {
    final data = await getOfflineData(_retailerDataKey);
    if (data != null && data['retailers'] != null) {
      return List<Map<String, dynamic>>.from(data['retailers']);
    }
    return [];
  }
  
  Future<void> updateOfflineData(String key, Map<String, dynamic> data) async {
    await _storeOfflineData(key, data);
    notifyListeners();
  }

  Future<void> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cropDataKey);
      await prefs.remove(_marketDataKey);
      await prefs.remove(_retailerDataKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
    }
  }
  
  Future<void> _syncOfflineData() async {
    // This would sync with online data when connection is restored
    // For now, we'll just update the timestamp
    try {
      final now = DateTime.now().toIso8601String();
      
      // Update crop data timestamp
      final cropData = await getOfflineData(_cropDataKey);
      if (cropData != null) {
        cropData['last_updated'] = now;
        await updateOfflineData(_cropDataKey, cropData);
      }
      
      // Update market data timestamp
      final marketData = await getOfflineData(_marketDataKey);
      if (marketData != null) {
        marketData['last_updated'] = now;
        await updateOfflineData(_marketDataKey, marketData);
      }
      
      // Update retailer data timestamp
      final retailerData = await getOfflineData(_retailerDataKey);
      if (retailerData != null) {
        retailerData['last_updated'] = now;
        await updateOfflineData(_retailerDataKey, retailerData);
      }
    } catch (e) {
      debugPrint('Error syncing offline data: $e');
    }
  }
  
  String getConnectivityStatus() {
    if (_isOnline) {
      return "Online - All features available";
    } else {
      return "Offline - Using cached data";
    }
  }
  
  String getLastUpdatedTime(String key) {
    // This would return the last updated time for specific data
    return "Last updated: Recently";
  }
}

