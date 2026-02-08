import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _currentLanguage = 'en';
  
  // Localized strings
  final Map<String, Map<String, String>> _localizations = {
    'en': {
      // App
      'app_title': 'AgriTrade',
      'app_subtitle': 'Agricultural Trading Platform',
      
      // Language Selection
      'select_language': 'Select Your Language',
      'choose_language': 'Choose your preferred language for the app',
      'continue': 'Continue',
      'skip_for_now': 'Skip for now',
      'voice_features': 'Voice Features Available',
      'voice_description': 'This app supports voice commands in both languages for better accessibility.',
      
      // Login Screen
      'welcome_back': 'Welcome Back!',
      'create_account': 'Create Account',
      'full_name': 'Full Name',
      'address': 'Address',
      'user_type': 'User Type',
      'email': 'Email',
      'password': 'Password',
      'username_fullname': 'Username (Full name)',
      'password_phone': 'Password (Your phone number)',
      'login': 'Login',
      'register': 'Register',
      'voice_login': 'Voice Login',
      'demo_farmer': 'Demo Farmer',
      'demo_retailer': 'Demo Retailer',
      'dont_have_account': 'Don\'t have an account? Register',
      'already_have_account': 'Already have an account? Login',
      'try_voice_login': 'Try voice login',
      'remember_credentials_title': 'Your Login Details',
      'remember_credentials_message': 'Please remember these:',
      'username': 'Username',
      
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      
      // User Types
      'farmer': 'Farmer',
      'retailer': 'Retailer',
      
      // Voice Commands
      'crop_prediction': 'Crop Prediction',
      'find_retailers': 'Find Retailers',
      'market_price': 'Market Price',
      'inventory': 'Inventory',
      'orders': 'Orders',
      'help': 'Help',
      'home': 'Home',
      'back': 'Back',
      'exit': 'Exit',

      // Dashboards
      'farmer_dashboard': 'Farmer Dashboard',
      'retailer_dashboard': 'Retailer Dashboard',
      'welcome': 'Welcome',
      'location': 'Location',

      // Features
      'create_order': 'Create Order',
      'market_prices': 'Market Prices',
      'market_insights': 'Market Insights',
      'accessibility': 'Accessibility',
      'online_mode': 'Online Mode',
      'offline_mode': 'Offline Mode',
      'voice_commands': 'Voice Commands',
      'say_commands_to_navigate': 'Say these commands to navigate the app:',
      'say_what_to_plant': 'Say: "What to plant"',
      'say_find_retailers': 'Say: "Find retailers"',
      'say_market_price': 'Say: "Market price"',
      'say_create_order': 'Say: "Create order"',
      'say_my_orders': 'Say: "My orders"',
      'say_help': 'Say: "Help"',
      'say_my_inventory': 'Say: "My inventory"',
      'say_orders': 'Say: "Orders"',
      'say_market_insights': 'Say: "Market insights"',
      'say_analytics': 'Say: "Analytics"',
      'simplified_interface': 'Simplified Interface',
      'large_buttons_easy_navigation': 'Large buttons and icons for easy navigation:',
      'voice_assistant': 'Voice Assistant',
      'use_voice_assistant_below': 'Use the voice assistant below to control the app:',
      'offline_features': 'Offline Features',
      'features_work_offline': 'These features work even without internet:',
      'crop_information': 'Crop Information',
      'view_crop_details': 'View crop details and planting advice',
      'check_cached_prices': 'Check cached market prices',
      'retailer_contacts': 'Retailer Contacts',
      'access_saved_retailers': 'Access saved retailer information',
      'view_order_history': 'View your order history',
      'how_to_use': 'How to Use',
      'accessibility_instructions': '1. Tap the microphone button to start voice commands\n'
          '2. Say any of the commands shown above\n'
          '3. The app will speak back to confirm your action\n'
          '4. Large buttons make it easy to tap without precision\n'
          '5. All features work offline with cached data',
      'go_back': 'Go Back',
      'go_forward': 'Go Forward',
      'swipe_to_navigate': 'Swipe left/right to navigate',
      'analytics': 'Analytics',
      'coming_soon': 'Coming soon!',

      // Retailer Search
      'find_retailers_title': 'Find Retailers',
      'search_retailers_hint': 'Search retailers...',
      'filter_by_crop': 'Filter by crop:',
      'all': 'All',
      'no_retailers_found': 'No retailers found',
      'retailer_label': 'Retailer',
      'crop_label': 'Crop',
      'price_label': 'Price',
      'contact': 'Contact',
      'rate': 'Rate',
      'rate_retailer': 'Rate Retailer',
      'select_rating': 'Select Rating',
      'write_review_optional': 'Write Review (Optional)',
      'review_hint': 'Share your experience...',
      'submit': 'Submit',
      'review_submitted': 'Review submitted!',
      'contact_retailer': 'Contact Retailer',
      'contact_information': 'Contact Information:',
      'phone': 'Phone',
      'email': 'Email',
      'address_label': 'Address',
      'close': 'Close',
      'send_request': 'Send Request',
      'contact_request_sent': 'Contact request sent!',

      // Auth/menu
      'profile': 'Profile',
      'settings': 'Settings',
      'help_menu': 'Help',
      'feedback': 'Feedback',
      'sign_out': 'Sign out',
      'sign_out_confirm_title': 'Sign out',
      'sign_out_confirm_message': 'Are you sure you want to sign out?',
      'cancel_btn': 'Cancel',

      // Market Insights
      'market_insights_title': 'Market Insights',
      'market_data_refreshed': 'Market data refreshed!',
      'voice_market_query': 'Voice Market Query',
      'ask_price_by_voice': 'Ask Price by Voice',
      'last_query': 'Last query',
      'your_area': 'your area',
      'market_overview': 'Market Overview',
      'active_crops': 'Active Crops',
      'avg_price': 'Avg Price',
      'market_trend': 'Market Trend',
      'trending_crops': 'Trending Crops',
      'latest_news': 'Latest News',
      'price_alerts': 'Price Alerts',
      'market_analysis': 'Market Analysis',
      'speak': 'Speak',
      'current_price': 'Current Price',
      'days_ago': 'days ago',
      'alert': 'Alert',
      'market_news': 'Market News',
      'news_info': 'This news may impact crop prices and market trends. Stay updated for more information.',
      'save': 'Save',
      'news_saved_favorites': 'News saved to favorites!',

      // Create Order / Sell Crop
      'voice_sell_mode': 'Voice Sell Mode',
      'start_voice_sell': 'Start Voice Sell',
      'required': 'Required',
      'enter_valid_number': 'Enter valid number',
      'unit': 'Unit',
      'price_per_unit': 'Price per Unit',
      'enter_valid_amount': 'Enter valid amount',
      'available_date': 'Available Date',
      'select_date': 'Select date',
      'notes': 'Notes',
      'submitting': 'Submitting...',
      'order_created': 'Order created',
      'failed': 'Failed',
      'no_orders_yet': 'No orders yet',
      'my_orders': 'My Orders',
      'create_order_to_start': 'Create an order to get started',
      'please_login_again': 'Please log in again',
      'created_at': 'Created At',
      'accepted': 'Accepted',
      'per': 'per',
      'status': 'Status',
      'quantity': 'Quantity',
      'accept': 'Accept',
      'reject': 'Reject',
      // Notifications
      'notifications': 'Notifications',
      'mark_all_read': 'Mark all read',
      'no_notifications': 'No notifications yet',
      'new_order_available': 'New Order Available',
      'order_accepted': 'Order Accepted!',
      'order_rejected': 'Order Rejected',
      // Inventory
      'total_items': 'Total Items',
      'total_value': 'Total Value',
      'add_new_item': 'Add New Item',
      'crop_type': 'Crop Type',
      'please_select_crop_type': 'Please select crop type',
      'quantity_kg': 'Quantity (kg)',
      'please_enter_quantity': 'Please enter quantity',
      'quantity_greater_than_zero': 'Quantity must be greater than 0',
      'price_per_kg': 'Price per kg (₹)',
      'please_enter_price': 'Please enter price',
      'add_to_inventory': 'Add to Inventory',
      'total': 'Total',
      'edit': 'Edit',
      'delete': 'Delete',
      'delete_item': 'Delete Item',
      'delete_item_confirm': 'Are you sure you want to delete',
      'item_deleted': 'Item deleted!',
      'item_added_to_inventory': 'Item added to inventory!',
      'item_updated': 'Item updated successfully!',
      // Crop Prediction
      'voice_crop_prediction': 'Voice Crop Prediction',
      'start_voice_prediction': 'Start Voice Prediction',
      'get_crop_recommendations': 'Get Crop Recommendations',
      'enter_farming_conditions': 'Enter your farming conditions to get AI-powered crop suggestions',
      'soil_type_required': 'Soil Type *',
      'please_select_soil_type': 'Please select soil type',
      'weather_condition_required': 'Weather Condition *',
      'please_select_weather_condition': 'Please select weather condition',
      'season_required': 'Season *',
      'please_select_season': 'Please select season',
      'location_optional': 'Location (Optional)',
      'location_hint': 'e.g., North India, Coastal Region',
      'soil_ph_optional': 'Soil pH (Optional)',
      'soil_ph_hint': 'e.g., 6.5',
      'rainfall_optional': 'Rainfall (Optional)',
      'rainfall_hint': 'e.g., 1200mm',
      'get_ai_predictions': 'Get AI Predictions',
      'ai_crop_recommendations': 'AI Crop Recommendations',
    },
    'te': {
      // App
      'app_title': 'అగ్రీట్రేడ్',
      'app_subtitle': 'వ్యవసాయ వ్యాపార వేదిక',
      
      // Language Selection
      'select_language': 'మీ భాషను ఎంచుకోండి',
      'choose_language': 'అనువర్తనం కోసం మీరు ఇష్టపడే భాషను ఎంచుకోండి',
      'continue': 'కొనసాగించండి',
      'skip_for_now': 'ఇప్పుడు దాటవేయండి',
      'voice_features': 'వాయిస్ సౌలభ్యాలు అందుబాటులో ఉన్నాయి',
      'voice_description': 'మెరుగైన అందుబాటుత్వం కోసం ఈ అనువర్తనం రెండు భాషలలో వాయిస్ ఆదేశాలను మద్దతు ఇస్తుంది.',
      
      // Login Screen
      'welcome_back': 'మళ్లీ స్వాగతం!',
      'create_account': 'ఖాతా సృష్టించండి',
      'full_name': 'పూర్తి పేరు',
      'address': 'చిరునామా',
      'user_type': 'వినియోగదారు రకం',
      'email': 'ఈమెయిల్',
      'password': 'పాస్‌వర్డ్',
      'username_fullname': 'యూసర్ నేమ్ (పూర్తి పేరు)',
      'password_phone': 'పాస్‌వర్డ్ (మీ ఫోన్ నంబర్)',
      'login': 'లాగిన్',
      'register': 'నమోదు',
      'voice_login': 'వాయిస్ లాగిన్',
      'demo_farmer': 'డెమో రైతు',
      'demo_retailer': 'డెమో రిటైలర్',
      'dont_have_account': 'ఖాతా లేదా? నమోదు చేయండి',
      'already_have_account': 'ఇప్పటికే ఖాతా ఉందా? లాగిన్ చేయండి',
      'try_voice_login': 'వాయిస్ లాగిన్ ప్రయత్నించండి',
      'remember_credentials_title': 'మీ లాగిన్ వివరాలు',
      'remember_credentials_message': 'దయచేసి వీటిని గుర్తుంచుకోండి:',
      'username': 'యూసర్ నేమ్',
      
      // Common
      'loading': 'లోడ్ అవుతోంది...',
      'error': 'లోపం',
      'success': 'విజయం',
      'cancel': 'రద్దు చేయండి',
      'ok': 'సరే',
      'yes': 'అవును',
      'no': 'కాదు',
      
      // User Types
      'farmer': 'రైతు',
      'retailer': 'రిటైలర్',
      
      // Voice Commands
      'crop_prediction': 'పంట సూచన',
      'find_retailers': 'రిటైలర్లను వెతుకు',
      'market_price': 'మార్కెట్ ధర',
      'inventory': 'ఇన్వెంటరీ',
      'orders': 'ఆర్డర్లు',
      'help': 'సహాయం',
      'home': 'హోమ్',
      'back': 'వెనక్కి',
      'exit': 'బయటకు',

      // Dashboards
      'farmer_dashboard': 'రైతు డాష్‌బోర్డ్',
      'retailer_dashboard': 'రిటైలర్ డాష్‌బోర్డ్',
      'welcome': 'స్వాగతం',
      'location': 'ప్రాంతం',

      // Features
      'create_order': 'ఆర్డర్ సృష్టించండి',
      'market_prices': 'మార్కెట్ ధరలు',
      'market_insights': 'మార్కెట్ ఇన్‌సైట్స్',
      'accessibility': 'అందుబాటుతనం',
      'online_mode': 'ఆన్‌లైన్ మోడ్',
      'offline_mode': 'ఆఫ్‌లైన్ మోడ్',
      'voice_commands': 'వాయిస్ కమాండ్‌లు',
      'say_commands_to_navigate': 'అనువర్తనంలో నావిగేట్ చేయడానికి ఈ కమాండ్‌లను చెప్పండి:',
      'say_what_to_plant': 'చెప్పండి: "ఏమి నాటాలి"',
      'say_find_retailers': 'చెప్పండి: "రిటైలర్లను కనుగొనండి"',
      'say_market_price': 'చెప్పండి: "మార్కెట్ ధర"',
      'say_create_order': 'చెప్పండి: "ఆర్డర్ సృష్టించండి"',
      'say_my_orders': 'చెప్పండి: "నా ఆర్డర్లు"',
      'say_help': 'చెప్పండి: "సహాయం"',
      'say_my_inventory': 'చెప్పండి: "నా ఇన్వెంటరీ"',
      'say_orders': 'చెప్పండి: "ఆర్డర్లు"',
      'say_market_insights': 'చెప్పండి: "మార్కెట్ ఇన్‌సైట్స్"',
      'say_analytics': 'చెప్పండి: "విశ్లేషణ"',
      'simplified_interface': 'సరళమైన ఇంటర్‌ఫేస్',
      'large_buttons_easy_navigation': 'సులభమైన నావిగేషన్ కోసం పెద్ద బటన్‌లు మరియు చిహ్నాలు:',
      'voice_assistant': 'వాయిస్ అసిస్టెంట్',
      'use_voice_assistant_below': 'అనువర్తనాన్ని నియంత్రించడానికి క్రింద ఉన్న వాయిస్ అసిస్టెంట్‌ను ఉపయోగించండి:',
      'offline_features': 'ఆఫ్‌లైన్ లక్షణాలు',
      'features_work_offline': 'ఇంటర్నెట్ లేకుండా కూడా ఈ లక్షణాలు పనిచేస్తాయి:',
      'crop_information': 'పంట సమాచారం',
      'view_crop_details': 'పంట వివరాలు మరియు నాటడం సలహా వీక్షించండి',
      'check_cached_prices': 'క్యాచ్ చేసిన మార్కెట్ ధరలను తనిఖీ చేయండి',
      'retailer_contacts': 'రిటైలర్ సంప్రదింపులు',
      'access_saved_retailers': 'సేవ్ చేసిన రిటైలర్ సమాచారాన్ని యాక్సెస్ చేయండి',
      'view_order_history': 'మీ ఆర్డర్ చరిత్రను వీక్షించండి',
      'how_to_use': 'ఎలా ఉపయోగించాలి',
      'accessibility_instructions': '1. వాయిస్ కమాండ్‌లను ప్రారంభించడానికి మైక్రోఫోన్ బటన్‌ను నొక్కండి\n'
          '2. పైన చూపబడిన ఏదైనా కమాండ్‌ను చెప్పండి\n'
          '3. మీ చర్యను నిర్ధారించడానికి అనువర్తనం మాట్లాడుతుంది\n'
          '4. పెద్ద బటన్‌లు ఖచ్చితత్వం లేకుండా నొక్కడం సులభం చేస్తాయి\n'
          '5. క్యాచ్ చేసిన డేటాతో అన్ని లక్షణాలు ఆఫ్‌లైన్‌లో పనిచేస్తాయి',
      'go_back': 'వెనక్కి వెళ్ళు',
      'go_forward': 'ముందుకు వెళ్ళు',
      'swipe_to_navigate': 'నావిగేట్ చేయడానికి ఎడమ/కుడి స్వైప్ చేయండి',
      'analytics': 'విశ్లేషణ',
      'coming_soon': 'త్వరలో రాబోతుంది!',

      // Retailer Search
      'find_retailers_title': 'రిటైలర్లను వెతుకు',
      'search_retailers_hint': 'రిటైలర్లను వెతకండి...',
      'filter_by_crop': 'పంట ద్వారా ఫిల్టర్:',
      'all': 'అన్ని',
      'no_retailers_found': 'రిటైలర్లు కనబడలేదు',
      'retailer_label': 'రిటైలర్',
      'crop_label': 'పంట',
      'price_label': 'ధర',
      'contact': 'కాంటాక్ట్',
      'rate': 'రేట్',
      'rate_retailer': 'రిటైలర్‌ను రేట్ చేయండి',
      'select_rating': 'రేటింగ్ ఎంచుకోండి',
      'write_review_optional': 'రివ్యూ వ్రాయండి (ఐచ్ఛికం)',
      'review_hint': 'మీ అనుభవాన్ని భాగస్వామ్యం చేయండి...',
      'submit': 'సమర్పించండి',
      'review_submitted': 'రివ్యూ సమర్పించబడింది!',
      'contact_retailer': 'రిటైలర్‌ను సంప్రదించండి',
      'contact_information': 'సంప్రదింపు సమాచారం:',
      'phone': 'ఫోన్',
      'email': 'ఈమెయిల్',
      'address_label': 'చిరునామా',
      'close': 'మూసివేయి',
      'send_request': 'అభ్యర్థన పంపండి',
      'contact_request_sent': 'సంప్రదింపు అభ్యర్థన పంపబడింది!',

      // Auth/menu
      'profile': 'ప్రొఫైల్',
      'settings': 'సెట్టింగ్స్',
      'help_menu': 'సహాయం',
      'feedback': 'అభిప్రాయం',
      'sign_out': 'సైన్ అవుట్',
      'sign_out_confirm_title': 'సైన్ అవుట్',
      'sign_out_confirm_message': 'మీరు నిజంగా సైన్ అవుట్ కావాలనుకుంటున్నారా?',
      'cancel_btn': 'రద్దు',

      // Market Insights
      'market_insights_title': 'మార్కెట్ ఇన్‌సైట్స్',
      'market_data_refreshed': 'మార్కెట్ డేటా రిఫ్రెష్ చేయబడింది!',
      'voice_market_query': 'వాయిస్ మార్కెట్ క్వెరీ',
      'ask_price_by_voice': 'వాయిస్ ద్వారా ధర అడగండి',
      'last_query': 'గత క్వెరీ',
      'your_area': 'మీ ప్రాంతం',
      'market_overview': 'మార్కెట్ అవలోకనం',
      'active_crops': 'సక్రియ పంటలు',
      'avg_price': 'సగటు ధర',
      'market_trend': 'మార్కెట్ ట్రెండ్',
      'trending_crops': 'ట్రెండింగ్ పంటలు',
      'latest_news': 'తాజా వార్తలు',
      'price_alerts': 'ధర అలర్ట్స్',
      'market_analysis': 'మార్కెట్ విశ్లేషణ',
      'speak': 'మాట్లాడు',
      'current_price': 'ప్రస్తుత ధర',
      'days_ago': 'రోజుల క్రితం',
      'alert': 'అలర్ట్',
      'market_news': 'మార్కెట్ వార్తలు',
      'news_info': 'ఈ వార్త పంటల ధరలు మరియు మార్కెట్ ట్రెండ్స్‌పై ప్రభావం చూపవచ్చు. మరిన్ని వివరాల కోసం అప్‌డేట్‌గా ఉండండి.',
      'save': 'సేవ్ చేయండి',
      'news_saved_favorites': 'వార్తలు ఫేవరిట్స్‌లో సేవ్ చేయబడ్డాయి!',

      // Create Order / Sell Crop
      'voice_sell_mode': 'వాయిస్ సేల్ మోడ్',
      'start_voice_sell': 'వాయిస్ సేల్ ప్రారంభించండి',
      'required': 'అవసరం',
      'enter_valid_number': 'సరైన సంఖ్యను నమోదు చేయండి',
      'unit': 'యూనిట్',
      'price_per_unit': 'యూనిట్‌కు ధర',
      'enter_valid_amount': 'సరైన మొత్తాన్ని నమోదు చేయండి',
      'available_date': 'అందుబాటులో తేదీ',
      'select_date': 'తేదీని ఎంచుకోండి',
      'notes': 'గమనికలు',
      'submitting': 'సమర్పిస్తున్నాం...',
      'order_created': 'ఆర్డర్ సృష్టించబడింది',
      'failed': 'విఫలమైంది',
      'no_orders_yet': 'ఇంకా ఆర్డర్లు లేవు',
      'my_orders': 'నా ఆర్డర్లు',
      'create_order_to_start': 'ప్రారంభించడానికి ఆర్డర్ సృష్టించండి',
      'please_login_again': 'దయచేసి మళ్లీ లాగిన్ చేయండి',
      'created_at': 'సృష్టించబడింది',
      'accepted': 'అంగీకరించబడింది',
      'per': 'కు',
      'status': 'స్థితి',
      'quantity': 'పరిమాణం',
      'accept': 'అంగీకరించు',
      'reject': 'తిరస్కరించు',
      // Notifications
      'notifications': 'నోటిఫికేషన్లు',
      'mark_all_read': 'అన్నీ చదివినట్లుగా గుర్తించు',
      'no_notifications': 'ఇంకా నోటిఫికేషన్లు లేవు',
      'new_order_available': 'కొత్త ఆర్డర్ అందుబాటులో ఉంది',
      'order_accepted': 'ఆర్డర్ అంగీకరించబడింది!',
      'order_rejected': 'ఆర్డర్ తిరస్కరించబడింది',
      // Inventory
      'total_items': 'మొత్తం అంశాలు',
      'total_value': 'మొత్తం విలువ',
      'add_new_item': 'కొత్త అంశాన్ని జోడించండి',
      'crop_type': 'పంట రకం',
      'please_select_crop_type': 'దయచేసి పంట రకాన్ని ఎంచుకోండి',
      'quantity_kg': 'పరిమాణం (kg)',
      'please_enter_quantity': 'దయచేసి పరిమాణాన్ని నమోదు చేయండి',
      'quantity_greater_than_zero': 'పరిమాణం 0 కంటే ఎక్కువగా ఉండాలి',
      'price_per_kg': 'కిలోకు ధర (₹)',
      'please_enter_price': 'దయచేసి ధరను నమోదు చేయండి',
      'add_to_inventory': 'ఇన్వెంటరీకి జోడించండి',
      'total': 'మొత్తం',
      'edit': 'మార్చు',
      'delete': 'తొలగించు',
      'delete_item': 'అంశాన్ని తొలగించండి',
      'delete_item_confirm': 'మీరు నిజంగా తొలగించాలనుకుంటున్నారా',
      'item_deleted': 'అంశం తొలగించబడింది!',
      'item_added_to_inventory': 'అంశం ఇన్వెంటరీకి జోడించబడింది!',
      'item_updated': 'అంశం విజయవంతంగా నవీకరించబడింది!',
      // Crop Prediction
      'voice_crop_prediction': 'వాయిస్ పంట సూచన',
      'start_voice_prediction': 'వాయిస్ సూచన ప్రారంభించండి',
      'get_crop_recommendations': 'పంట సిఫార్సులు పొందండి',
      'enter_farming_conditions': 'AI ఆధారిత పంట సూచనలకు మీ వ్యవసాయ పరిస్థితులు నమోదు చేయండి',
      'soil_type_required': 'నేల రకం *',
      'please_select_soil_type': 'దయచేసి నేల రకాన్ని ఎంచుకోండి',
      'weather_condition_required': 'వాతావరణం *',
      'please_select_weather_condition': 'దయచేసి వాతావరణాన్ని ఎంచుకోండి',
      'season_required': 'ఋతువు *',
      'please_select_season': 'దయచేసి ఋతువును ఎంచుకోండి',
      'location_optional': 'ప్రాంతం (ఐచ్చికం)',
      'location_hint': 'ఉదా., ఉత్తర భారతదేశం, తీర ప్రాంతం',
      'soil_ph_optional': 'మట్టి pH (ఐచ్చికం)',
      'soil_ph_hint': 'ఉదా., 6.5',
      'rainfall_optional': 'వర్షపాతం (ఐచ్చికం)',
      'rainfall_hint': 'ఉదా., 1200mm',
      'get_ai_predictions': 'AI సూచనలను పొందండి',
      'ai_crop_recommendations': 'AI పంట సిఫార్సులు',
    },
  };

  String get currentLanguage => _currentLanguage;
  
  String getLocalizedString(String key) {
    return _localizations[_currentLanguage]?[key] ?? 
           _localizations['en']?[key] ?? 
           key;
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'te') return;
    
    _currentLanguage = languageCode;
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _currentLanguage);
    
    notifyListeners();
  }

  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null && (savedLanguage == 'en' || savedLanguage == 'te')) {
        _currentLanguage = savedLanguage;
        notifyListeners();
      }
    } catch (e) {
      // Default to English if loading fails
      _currentLanguage = 'en';
    }
  }

  bool get isEnglish => _currentLanguage == 'en';
  bool get isTelugu => _currentLanguage == 'te';
}
