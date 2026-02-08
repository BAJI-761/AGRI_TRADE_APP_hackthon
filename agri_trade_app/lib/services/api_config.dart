import 'package:flutter/foundation.dart';

/// Centralized API configuration for market data.
/// Replace the base URLs with your backend endpoints or provide via --dart-define.
class ApiConfig {
	static final String baseUrl = const String.fromEnvironment(
			'MARKET_API_BASE_URL',
			defaultValue: '',
	);

	static String insightsUrl() => '$baseUrl/market/insights';
	static String priceUrl({required String crop, String? location}) {
		final encodedCrop = Uri.encodeComponent(crop);
		final encodedLoc = location == null || location.isEmpty ? '' : '&location=${Uri.encodeComponent(location)}';
		return '$baseUrl/market/price?crop=$encodedCrop$encodedLoc';
	}

	// Polling interval for real-time updates (in seconds)
	static const int insightsPollingSeconds = 20;
}


