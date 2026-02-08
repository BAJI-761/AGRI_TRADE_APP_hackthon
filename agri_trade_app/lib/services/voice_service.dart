import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastRecognizedText = '';
  String _lastSpokenText = '';
  String _currentLanguage = 'en'; // 'en' or 'te'
  String _currentLocaleId = 'en_US';
  
  // Enhanced voice features
  List<String> _voiceCommandHistory = [];
  bool _isTrainingMode = false;
  int _recognitionAttempts = 0;
  Timer? _listeningTimeout;
  String _currentContext = 'general'; // 'farmer', 'retailer', 'general'
  double _confidenceThreshold = 0.7;
  bool _isVoiceEnabled = true;
  
  // Voice command mappings (English + Telugu keywords)
  final Map<String, String> _voiceCommands = {
    // Farmer commands
    'crop prediction': 'crop_prediction',
    'what to plant': 'crop_prediction',
    'crop advice': 'crop_prediction',
    'planting advice': 'crop_prediction',
    // Telugu equivalents
    'పంట సూచన': 'crop_prediction',
    'ఏ పంట వేయాలి': 'crop_prediction',
    'పంట సలహా': 'crop_prediction',
    
    'find retailers': 'retailer_search',
    'nearby shops': 'retailer_search',
    'find shops': 'retailer_search',
    'retailers': 'retailer_search',
    // Telugu
    'దుకాణాలు వెతుకు': 'retailer_search',
    'దగ్గరలో దుకాణాలు': 'retailer_search',
    
    'create order': 'create_order',
    'place order': 'create_order',
    'new order': 'create_order',
    'order': 'create_order',
    'sell': 'sell_crop',
    'sell crop': 'sell_crop',
    'sell produce': 'sell_crop',
    // Telugu
    'ఆర్డర్ సృష్టించు': 'create_order',
    'ఆర్డర్ పెట్టు': 'create_order',
    'అమ్ము': 'sell_crop',
    'పంట అమ్ము': 'sell_crop',
    'ఫలితం అమ్ము': 'sell_crop',
    
    'market price': 'market_insights',
    'price': 'market_insights',
    'market': 'market_insights',
    'rates': 'market_insights',
    // Telugu
    'మార్కెట్ ధర': 'market_insights',
    'ధర': 'market_insights',
    
    // Retailer commands
    'inventory': 'inventory',
    'stock': 'inventory',
    'manage inventory': 'inventory',
    
    'orders': 'orders',
    'customer orders': 'orders',
    'pending orders': 'orders',
    // Telugu
    'ఆర్డర్లు': 'orders',
    
    // General commands
    'help': 'help',
    'main menu': 'home',
    'home': 'home',
    'back': 'back',
    'exit': 'exit',
    // Telugu
    'సహాయం': 'help',
    'హోమ్': 'home',
    'వెనక్కి': 'back',
    'బయటకు': 'exit',
  };
  
  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastRecognizedText => _lastRecognizedText;
  String get lastSpokenText => _lastSpokenText;
  List<String> get voiceCommandHistory => List.unmodifiable(_voiceCommandHistory);
  bool get isTrainingMode => _isTrainingMode;
  String get currentContext => _currentContext;
  bool get isVoiceEnabled => _isVoiceEnabled;
  
  VoiceService() {
    _initializeTts();
    _loadLanguagePreference();
    _loadVoiceSettings();
  }
  
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage(_currentLocaleId);
    await _flutterTts.setSpeechRate(0.5); // Slower speech for better understanding
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('voice_language');
    if (lang != null) {
      await setLanguage(lang);
    }
  }

  Future<void> _loadVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isVoiceEnabled = prefs.getBool('voice_enabled') ?? true;
    _confidenceThreshold = prefs.getDouble('confidence_threshold') ?? 0.7;
    _currentContext = prefs.getString('voice_context') ?? 'general';
    _voiceCommandHistory = prefs.getStringList('voice_history') ?? [];
  }

  Future<void> _saveVoiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_enabled', _isVoiceEnabled);
    await prefs.setDouble('confidence_threshold', _confidenceThreshold);
    await prefs.setString('voice_context', _currentContext);
    await prefs.setStringList('voice_history', _voiceCommandHistory);
  }

  Future<void> setLanguage(String languageCode) async {
    // Accepts 'en' or 'te'
    if (languageCode != 'en' && languageCode != 'te') return;
    _currentLanguage = languageCode;
    _currentLocaleId = languageCode == 'te' ? 'te_IN' : 'en_US';
    await _flutterTts.setLanguage(_currentLocaleId);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_language', _currentLanguage);
  }

  // Enhanced voice methods
  Future<void> setContext(String context) async {
    _currentContext = context;
    await _saveVoiceSettings();
    notifyListeners();
  }

  Future<void> toggleVoiceEnabled() async {
    _isVoiceEnabled = !_isVoiceEnabled;
    await _saveVoiceSettings();
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    _isVoiceEnabled = enabled;
    await _saveVoiceSettings();
    notifyListeners();
  }

  Future<void> setConfidenceThreshold(double threshold) async {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    await _saveVoiceSettings();
    notifyListeners();
  }

  Future<void> startTrainingMode() async {
    _isTrainingMode = true;
    await speak(_currentLanguage == 'te' 
        ? 'వాయిస్ ట్రైనింగ్ మోడ్ ప్రారంభమైంది. మీరు వివిధ ఆదేశాలను ప్రయత్నించవచ్చు.'
        : 'Voice training mode started. You can try different commands.');
    notifyListeners();
  }

  Future<void> stopTrainingMode() async {
    _isTrainingMode = false;
    await speak(_currentLanguage == 'te' 
        ? 'వాయిస్ ట్రైనింగ్ మోడ్ ముగిసింది.'
        : 'Voice training mode ended.');
    notifyListeners();
  }

  void addToHistory(String command) {
    _voiceCommandHistory.insert(0, command);
    if (_voiceCommandHistory.length > 20) {
      _voiceCommandHistory.removeLast();
    }
    _saveVoiceSettings();
  }

  Future<void> clearHistory() async {
    _voiceCommandHistory.clear();
    await _saveVoiceSettings();
    notifyListeners();
  }

  String get currentLanguage => _currentLanguage;
  String get currentLocaleId => _currentLocaleId;
  
  Future<bool> initializeSpeech() async {
    if (!_isVoiceEnabled) {
      await speak(_currentLanguage == 'te' 
          ? 'వాయిస్ సౌలభ్యాలు నిలిపివేయబడ్డాయి.'
          : 'Voice features are disabled.');
      return false;
    }

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        await speak(_currentLanguage == 'te' 
            ? 'వాయిస్ ఆదేశాలకు మైక్రోఫోన్ అనుమతి అవసరం'
            : "Microphone permission is required for voice commands");
        return false;
      }
    
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          if (status == 'listening') {
            _listeningTimeout?.cancel();
            _listeningTimeout = Timer(const Duration(seconds: 15), () {
              if (_isListening) {
                stopListening();
                speak(_currentLanguage == 'te' 
                    ? 'వినికిడి సమయం ముగిసింది. మళ్లీ ప్రయత్నించండి.'
                    : 'Listening timeout. Please try again.');
              }
            });
          }
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _isListening = false;
          _recognitionAttempts++;
          notifyListeners();
          
          // Enhanced error handling
          if (error.errorMsg.contains('not supported') || error.errorMsg.contains('permission')) {
            speak(_currentLanguage == 'te' 
                ? 'ఈ ప్లాట్‌ఫారమ్‌లో వాయిస్ గుర్తింపు మద్దతు లేదు'
                : 'Voice recognition not supported on this platform');
          } else if (_recognitionAttempts < 3) {
            speak(_currentLanguage == 'te' 
                ? 'మళ్లీ ప్రయత్నించండి'
                : 'Please try again');
          } else {
            speak(_currentLanguage == 'te' 
                ? 'వాయిస్ గుర్తింపులో సమస్య. దయచేసి మళ్లీ ప్రయత్నించండి'
                : 'Voice recognition issue. Please try again later');
            _recognitionAttempts = 0;
          }
        },
      );
      
      return available;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      await speak(_currentLanguage == 'te' 
          ? 'వాయిస్ సౌలభ్యాలు ఈ ప్లాట్‌ఫారమ్‌లో అందుబాటులో లేవు'
          : "Voice features are not available on this platform");
      return false;
    }
  }
  
  Future<void> startListening() async {
    if (!_isListening && _isVoiceEnabled) {
      _recognitionAttempts = 0; // Reset attempts for new session
      await _speechToText.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords.toLowerCase();
          
          // Check confidence level if available
          if (result.confidence > 0 && result.confidence < _confidenceThreshold) {
            if (_isTrainingMode) {
              speak(_currentLanguage == 'te' 
                  ? 'ఆత్మవిశ్వాసం తక్కువ. మళ్లీ ప్రయత్నించండి.'
                  : 'Low confidence. Please try again.');
            }
            return;
          }
          
          notifyListeners();
          
          // Add to history if it's a final result
          if (result.finalResult) {
            addToHistory(_lastRecognizedText);
            _recognitionAttempts = 0; // Reset on successful recognition
          }
          
          // Process the recognized command
          _processVoiceCommand(_lastRecognizedText);
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: _currentLocaleId,
        onSoundLevelChange: (level) {
          // Optional: Show visual feedback for sound level
        },
      );
    } else if (!_isVoiceEnabled) {
      await speak(_currentLanguage == 'te' 
          ? 'వాయిస్ సౌలభ్యాలు నిలిపివేయబడ్డాయి'
          : 'Voice features are disabled');
    }
  }
  
  Future<void> stopListening() async {
    if (_isListening) {
      _listeningTimeout?.cancel();
      await _speechToText.stop();
    }
  }
  
  Future<void> speak(String text) async {
    if (text.isNotEmpty && !_isSpeaking) {
      _lastSpokenText = text;
      _isSpeaking = true;
      notifyListeners();
      
      await _flutterTts.speak(text);
    }
  }

  // Listen once and return the final recognized text
  Future<String> listenOnce({int seconds = 15}) async {
    final available = await initializeSpeech();
    if (!available) return '';
    
    String captured = '';
    bool isCompleted = false;
    int silenceCount = 0;
    const int maxSilenceCount = 30; // 3 seconds of silence before stopping
    
    try {
      await _speechToText.listen(
        onResult: (result) {
          debugPrint('Voice result: ${result.recognizedWords} (confidence: ${result.confidence})');
          
          if (result.recognizedWords.isNotEmpty) {
            captured = result.recognizedWords.trim();
            silenceCount = 0; // Reset silence counter when we get speech
          } else {
            silenceCount++; // Increment silence counter
          }
          
          if (result.finalResult && captured.isNotEmpty) {
            isCompleted = true;
            debugPrint('Final voice result: $captured');
          }
        },
        listenFor: Duration(seconds: seconds),
        pauseFor: const Duration(seconds: 5), // Increased pause time
        localeId: _currentLocaleId,
      );
      
      // Wait for completion, timeout, or extended silence
      int elapsed = 0;
      while (elapsed < seconds * 1000 && !isCompleted && silenceCount < maxSilenceCount) {
        await Future.delayed(const Duration(milliseconds: 100));
        elapsed += 100;
      }
      
      // Stop listening
      await _speechToText.stop();
      
    } catch (e) {
      debugPrint('Error in listenOnce: $e');
    }
    
    _lastRecognizedText = captured.toLowerCase();
    notifyListeners();
    return captured;
  }

  // Ask a prompt via TTS then capture user's response
  Future<String> askAndListen({required String promptEn, required String promptTe, int seconds = 8}) async {
    final prompt = _currentLanguage == 'te' ? promptTe : promptEn;
    await speak(prompt);
    // give a small delay before listening
    await Future.delayed(const Duration(milliseconds: 600));
    return await listenOnce(seconds: seconds);
  }

  // Detect language from a spoken phrase and set preference
  Future<String> detectAndSetLanguageFromUtterance(String utterance) async {
    final lower = utterance.toLowerCase();
    if (lower.contains('telugu') || lower.contains('తెలుగు')) {
      await setLanguage('te');
    } else {
      await setLanguage('en');
    }
    return _currentLanguage;
  }

  // Voice-guided sell flow methods
  Future<Map<String, dynamic>> voiceSellFlow() async {
    final result = <String, dynamic>{};
    
    try {
      // Ask for crop name
      const cropPromptEn = 'What crop do you want to sell?';
      const cropPromptTe = 'మీరు ఏ పంట అమ్మాలనుకుంటున్నారు?';
      final cropSpoken = await askAndListen(promptEn: cropPromptEn, promptTe: cropPromptTe, seconds: 6);
      if (cropSpoken.isEmpty) {
        await speak(_currentLanguage == 'te' ? 'పంట పేరు వినలేకపోయాను.' : 'Could not hear crop name.');
        return result;
      }
      result['crop'] = cropSpoken.trim();

      // Ask for quantity
      const qtyPromptEn = 'How much quantity? Say the number and unit, like 50 kg or 100 bags';
      const qtyPromptTe = 'ఎంత పరిమాణం? సంఖ్య మరియు యూనిట్ చెప్పండి, ఉదాహరణకు 50 కిలో లేదా 100 సంచులు';
      final qtySpoken = await askAndListen(promptEn: qtyPromptEn, promptTe: qtyPromptTe, seconds: 8);
      if (qtySpoken.isEmpty) {
        await speak(_currentLanguage == 'te' ? 'పరిమాణం వినలేకపోయాను.' : 'Could not hear quantity.');
        return result;
      }
      
      // Extract quantity and unit from speech
      final qtyData = _extractQuantityAndUnit(qtySpoken);
      result['quantity'] = qtyData['quantity'];
      result['unit'] = qtyData['unit'];

      // Ask for price
      const pricePromptEn = 'What price per unit? Say the amount, like 30 rupees or 25 rupees per kg';
      const pricePromptTe = 'యూనిట్‌కు ఎంత ధర? మొత్తం చెప్పండి, ఉదాహరణకు 30 రూపాయలు లేదా 25 రూపాయలు కిలోకు';
      final priceSpoken = await askAndListen(promptEn: pricePromptEn, promptTe: pricePromptTe, seconds: 8);
      if (priceSpoken.isEmpty) {
        await speak(_currentLanguage == 'te' ? 'ధర వినలేకపోయాను.' : 'Could not hear price.');
        return result;
      }
      
      final price = _extractPrice(priceSpoken);
      result['price'] = price;

      // Ask for location
      const locPromptEn = 'Where is your location?';
      const locPromptTe = 'మీ స్థానం ఎక్కడ?';
      final locSpoken = await askAndListen(promptEn: locPromptEn, promptTe: locPromptTe, seconds: 6);
      result['location'] = locSpoken.trim();

      // Confirmation
      final confirmText = _currentLanguage == 'te' 
          ? 'మీరు ${result['crop']} ${result['quantity']} ${result['unit']} ${result['price']} రూపాయలకు అమ్మాలనుకుంటున్నారా?'
          : 'Do you want to sell ${result['crop']} ${result['quantity']} ${result['unit']} for ${result['price']} rupees?';
      
      await speak(confirmText);
      final confirmSpoken = await askAndListen(
        promptEn: 'Say yes to confirm or no to cancel',
        promptTe: 'అవును చెప్పి నిర్ధారించండి లేదా కాదు చెప్పి రద్దు చేయండి',
        seconds: 4
      );
      
      result['confirmed'] = _isConfirmation(confirmSpoken);
      
    } catch (e) {
      await speak(_currentLanguage == 'te' ? 'ధ్వని అమ్మడం విఫలమైంది.' : 'Voice selling failed.');
    }
    
    return result;
  }

  Map<String, dynamic> _extractQuantityAndUnit(String speech) {
    final text = speech.toLowerCase().trim();
    final numbers = RegExp(r'(\d+(?:\.\d+)?)').allMatches(text);
    final quantity = numbers.isNotEmpty ? double.tryParse(numbers.first.group(1)!) ?? 0.0 : 0.0;
    
    String unit = 'kg'; // default
    if (text.contains('kg') || text.contains('kilo') || text.contains('కిలో')) {
      unit = 'kg';
    } else if (text.contains('bag') || text.contains('sack') || text.contains('సంచి')) {
      unit = 'bag';
    } else if (text.contains('ton') || text.contains('tonne') || text.contains('టన్')) {
      unit = 'ton';
    } else if (text.contains('quintal') || text.contains('క్వింటల్')) {
      unit = 'quintal';
    }
    
    return {'quantity': quantity, 'unit': unit};
  }

  double _extractPrice(String speech) {
    final text = speech.toLowerCase().trim();
    final numbers = RegExp(r'(\d+(?:\.\d+)?)').allMatches(text);
    return numbers.isNotEmpty ? double.tryParse(numbers.first.group(1)!) ?? 0.0 : 0.0;
  }

  bool _isConfirmation(String speech) {
    final text = speech.toLowerCase().trim();
    return text.contains('yes') || text.contains('yeah') || text.contains('ok') || 
           text.contains('confirm') || text.contains('అవును') || text.contains('సరే');
  }
  
  void _processVoiceCommand(String command) {
    // Find matching command with context awareness
    String? matchedCommand;
    for (String key in _voiceCommands.keys) {
      if (command.contains(key)) {
        matchedCommand = _voiceCommands[key];
        break;
      }
    }
    
    if (matchedCommand != null) {
      // Notify listeners about the command
      notifyListeners();
      
      // Context-aware audio feedback
      String feedback = _getContextualFeedback(matchedCommand);
      speak(feedback);
      
      // Add to history
      addToHistory('$matchedCommand: $command');
    } else {
      // Enhanced error handling with suggestions
      String suggestions = _getContextualSuggestions();
      speak(_currentLanguage == 'te' 
          ? "నాకు అర్థం కాలేదు. $suggestions"
          : "I didn't understand. $suggestions");
    }
  }

  String _getContextualFeedback(String command) {
    String baseFeedback = '';
    String contextPrefix = _currentLanguage == 'te' ? 'సరే, ' : 'Okay, ';
    
    switch (command) {
      case 'crop_prediction':
        baseFeedback = _currentLanguage == 'te' 
            ? "పంట సూచన తెరుస్తున్నాను. వేచి ఉండండి." 
            : "Opening crop prediction. Please wait.";
        break;
      case 'retailer_search':
        baseFeedback = _currentLanguage == 'te' 
            ? "దగ్గరలోని దుకాణాలను వెతుకుతున్నాను." 
            : "Finding nearby retailers for you.";
        break;
      case 'create_order':
        baseFeedback = _currentLanguage == 'te' 
            ? "ఆర్డర్ సృష్టిస్తున్నాను. వేచి ఉండండి." 
            : "Opening order creation. Please wait.";
        break;
      case 'sell_crop':
        baseFeedback = _currentLanguage == 'te' 
            ? "పంట అమ్మడం ప్రారంభిస్తున్నాను. వేచి ఉండండి." 
            : "Starting crop selling process. Please wait.";
        break;
      case 'market_insights':
        baseFeedback = _currentLanguage == 'te' 
            ? "మార్కెట్ ధరలు మరియు వివరాలు లోడ్ చేస్తున్నాను." 
            : "Loading market prices and insights.";
        break;
      case 'inventory':
        baseFeedback = _currentLanguage == 'te' 
            ? "ఇన్వెంటరీ నిర్వహణ తెరుస్తున్నాను." 
            : "Opening inventory management.";
        break;
      case 'orders':
        baseFeedback = _currentLanguage == 'te' 
            ? "మీ ఆర్డర్లను లోడ్ చేస్తున్నాను." 
            : "Loading your orders.";
        break;
      case 'help':
        baseFeedback = _getContextualHelp();
        break;
      case 'home':
        baseFeedback = _currentLanguage == 'te' 
            ? "ముఖ్య మెనూకి వెలుతున్నాను." 
            : "Going to main menu.";
        break;
      case 'back':
        baseFeedback = _currentLanguage == 'te' 
            ? "వెనక్కి వెలుతున్నాను." 
            : "Going back.";
        break;
      case 'exit':
        baseFeedback = _currentLanguage == 'te' 
            ? "వీడ్కోలు!" 
            : "Goodbye!";
        break;
    }
    
    return contextPrefix + baseFeedback;
  }

  String _getContextualSuggestions() {
    if (_currentContext == 'farmer') {
      return _currentLanguage == 'te' 
          ? "మీరు ఇలా చెప్పండి: పంట సూచన, దుకాణాలు వెతుకు, మార్కెట్ ధర, లేదా సహాయం."
          : "You can say: crop prediction, find retailers, market price, or help.";
    } else if (_currentContext == 'retailer') {
      return _currentLanguage == 'te' 
          ? "మీరు ఇలా చెప్పండి: ఇన్వెంటరీ, ఆర్డర్లు, మార్కెట్ వివరాలు, లేదా సహాయం."
          : "You can say: inventory, orders, market insights, or help.";
    } else {
      return _currentLanguage == 'te' 
          ? "మీరు ఇలా చెప్పండి: పంట సూచన, దుకాణాలు వెతుకు, మార్కెట్ ధర, లేదా సహాయం."
          : "You can say: crop prediction, find retailers, market price, or help.";
    }
  }

  String _getContextualHelp() {
    if (_currentContext == 'farmer') {
      return _currentLanguage == 'te' 
          ? "రైతుగా, మీరు ఇలా చెప్పండి: ఏ పంట వేయాలి, దుకాణాలు వెతుకు, మార్కెట్ ధర, ఆర్డర్ సృష్టించు, లేదా సహాయం."
          : "As a farmer, you can say: what to plant, find retailers, market price, create order, or help.";
    } else if (_currentContext == 'retailer') {
      return _currentLanguage == 'te' 
          ? "రిటైలర్‌గా, మీరు ఇలా చెప్పండి: ఇన్వెంటరీ, ఆర్డర్లు, మార్కెట్ వివరాలు, లేదా సహాయం."
          : "As a retailer, you can say: inventory, orders, market insights, or help.";
    } else {
      return _currentLanguage == 'te' 
          ? "మీరు ఇలా చెప్పండి: పంట సూచన, దుకాణాలు వెతుకు, మార్కెట్ ధర, లేదా సహాయం."
          : "You can say: crop prediction, find retailers, market price, or help.";
    }
  }
  
  // Method to get the matched command for navigation
  String? getMatchedCommand(String command) {
    for (String key in _voiceCommands.keys) {
      if (command.contains(key)) {
        return _voiceCommands[key];
      }
    }
    return null;
  }
  
  // Method to provide contextual help
  Future<void> provideHelp(String userType) async {
    String helpText;
    if (userType == 'farmer') {
      helpText = "As a farmer, you can say: what to plant, find retailers, market price, create order, or help.";
    } else if (userType == 'retailer') {
      helpText = "As a retailer, you can say: inventory, orders, market insights, or help.";
    } else {
      helpText = "You can say: crop prediction, find retailers, market price, or help.";
    }
    
    await speak(helpText);
  }
  
  @override
  void dispose() {
    _listeningTimeout?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

