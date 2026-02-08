# AgriTrade App

A comprehensive Flutter-based mobile and web application designed to facilitate agricultural trade between farmers and retailers. The app provides crop prediction, inventory management, market insights, and retailer search functionality.

## Features

### For Farmers
- **Crop Prediction**: Get personalized crop recommendations based on soil type, weather conditions, and season
- **Retailer Search**: Find nearby retailers with ratings, prices, and contact information
- **Market Insights**: Access real-time market trends and price information
- **User Dashboard**: Personalized dashboard with quick access to all features

### For Retailers
- **Inventory Management**: Add, edit, and track crop inventory with pricing
- **Market Analysis**: View market trends, news, and price alerts
- **Business Dashboard**: Comprehensive overview of inventory and market data
- **Customer Management**: Track customer interactions and reviews

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **State Management**: Provider Pattern

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd agri_trade_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android and Web apps to your Firebase project
   - Download and place `google-services.json` in `android/app/`
   - Update Firebase configuration in `lib/firebase_options.dart`

4. **Run the application**
   ```bash
   # For web
   flutter run -d web-server
   
   # For Android
   flutter run
   
   # For iOS
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user.dart
│   ├── crop_prediction.dart
│   └── retailer_offer.dart
├── screens/                  # UI screens
│   ├── auth_wrapper.dart     # Authentication wrapper
│   ├── login_screen.dart     # Login/Registration
│   ├── farmer/              # Farmer-specific screens
│   │   ├── farmer_home.dart
│   │   ├── crop_prediction.dart
│   │   └── retailer_search.dart
│   ├── retailer/            # Retailer-specific screens
│   │   ├── retailer_home.dart
│   │   └── inventory_management.dart
│   └── market_insights.dart # Shared market insights
└── services/                # Business logic
    ├── auth_service.dart
    ├── crop_service.dart
    └── market_service.dart
```

## Firebase Configuration

The app uses Firebase for:
- **Authentication**: User registration and login
- **Firestore**: User data and application data storage
- **Analytics**: App usage tracking

### Required Firebase Services
1. **Authentication**: Enable Email/Password authentication
2. **Firestore**: Create database with appropriate security rules
3. **Analytics**: Enable for usage tracking

## Development Status

### Completed Features
- ✅ User authentication (login/registration)
- ✅ User type-based navigation (farmer/retailer)
- ✅ Crop prediction interface
- ✅ Retailer search with filtering
- ✅ Inventory management system
- ✅ Market insights dashboard
- ✅ Responsive UI design
- ✅ Firebase integration

### Planned Features
- 🔄 Real-time market data integration
- 🔄 Push notifications
- 🔄 Location-based services
- 🔄 Advanced analytics
- 🔄 Payment integration
- 🔄 Offline support

## Project Status (Oct 2025)

**Implemented**
- Flutter app with Material 3 and Provider
- Firebase Auth and Firestore integration
- Role-based navigation (farmer/retailer)
- Crop prediction via Gemini API
- Retailer search and basic market insights
- Voice commands and TTS guidance
- Offline caching with connectivity awareness
- EN/HI localization scaffolding

**Tech highlights**
- Flutter (Dart) multi-platform setup (Android, iOS, Web, Desktop scaffolding)
- Packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`, `speech_to_text`, `flutter_tts`, `shared_preferences`, `connectivity_plus`, `http`

**Risks / gaps**
- Gemini API key is hardcoded; move to secure config
- Market/retailer services use placeholders; integrate realtime sources/Firestore
- Define and enforce Firestore security rules
- Broaden localization and regional voice support

**Next steps**
- Replace placeholder market data with live API/Firestore
- Secure secrets (build-time config or remote config)
- Add push notifications and location services
- Implement payment flow and audit access rules
- Deepen offline sync and conflict resolution

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.
