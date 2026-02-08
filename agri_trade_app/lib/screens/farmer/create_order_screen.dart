import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/voice_service.dart';
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../models/order.dart' as model;
import '../../widgets/navigation_helper.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _availableDate;
  bool _submitting = false;
  bool _voiceMode = false;

  void _toggleVoiceMode() {
    setState(() {
      _voiceMode = !_voiceMode;
    });
  }

  Future<void> _handleVoiceSell() async {
    try {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      
      // Initialize voice service
      final available = await voiceService.initializeSpeech();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice not available')),
          );
        }
        return;
      }

      // Start voice sell flow
      final result = await voiceService.voiceSellFlow();
      
      if (result['confirmed'] == true && result.isNotEmpty) {
        // Populate form fields with voice data
        _cropController.text = result['crop'] ?? '';
        _quantityController.text = result['quantity']?.toString() ?? '';
        _unitController.text = result['unit'] ?? 'kg';
        _priceController.text = result['price']?.toString() ?? '';
        _locationController.text = result['location'] ?? '';
        _availableDate = DateTime.now().add(const Duration(days: 1)); // Default to tomorrow
        
        setState(() {});
        
        // Auto-submit if all required fields are filled
        if (_cropController.text.isNotEmpty && 
            _quantityController.text.isNotEmpty && 
            _priceController.text.isNotEmpty) {
          await _submitOrder();
        }
      } else {
        await voiceService.speak(
          voiceService.currentLanguage == 'te' 
            ? 'అమ్మడం రద్దు చేయబడింది.' 
            : 'Selling cancelled.'
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice sell error: $e')),
        );
      }
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Get farmer ID: use Firebase Auth UID if available, otherwise use phone number
      String farmerId = '';
      if (auth.user != null && auth.user!.uid.isNotEmpty) {
        farmerId = auth.user!.uid;
      } else if (auth.phone != null && auth.phone!.isNotEmpty) {
        farmerId = auth.phone!;
      } else if (auth.name != null) {
        // Last resort: use name as identifier (shouldn't happen in normal flow)
        farmerId = auth.name!;
      }
      
      if (farmerId.isEmpty) {
        final ls = Provider.of<LanguageService>(context, listen: false);
        throw Exception(ls.currentLanguage == 'te' 
          ? 'రైతును గుర్తించలేకపోయాము. దయచేసి మళ్లీ లాగిన్ చేయండి.'
          : 'Unable to identify farmer. Please log in again.');
      }
      
      final order = model.Order(
        id: '',
        farmerId: farmerId,
        crop: _cropController.text.trim(),
        quantity: double.parse(_quantityController.text),
        unit: _unitController.text.trim(),
        pricePerUnit: double.parse(_priceController.text),
        availableDate: _availableDate ?? DateTime.now().add(const Duration(days: 1)),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        status: 'pending',
      );
      
      final service = OrderService();
      // Link notification service
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      service.setNotificationService(notificationService);
      
      await service.createOrder(order);
      
      if (!mounted) return;
      
      // Voice confirmation
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.speak(
        voiceService.currentLanguage == 'te' 
          ? 'ఆర్డర్ సృష్టించబడింది.' 
          : 'Order created successfully.'
      );
      
      if (mounted) {
        final ls = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ls.getLocalizedString('order_created'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final ls = Provider.of<LanguageService>(context, listen: false);
        String errorMessage = '${ls.getLocalizedString('failed')}: $e';
        
        // Provide user-friendly error messages
        if (e.toString().contains('PERMISSION_DENIED') || e.toString().contains('permission')) {
          errorMessage = ls.currentLanguage == 'te'
            ? 'అనుమతి తిరస్కరించబడింది. దయచేసి Firebase Console లో Firestore నియమాలను తనిఖీ చేయండి.'
            : 'Permission denied. Please check Firestore rules in Firebase Console.';
        } else if (e.toString().contains('network') || e.toString().contains('internet')) {
          errorMessage = ls.currentLanguage == 'te'
            ? 'నెట్‌వర్క్ లోపం. దయచేసి ఇంటర్నెట్ కనెక్షన్‌ను తనిఖీ చేయండి.'
            : 'Network error. Please check your internet connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _cropController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('create_order'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [],
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
              children: [
              
              TextFormField(
                controller: _cropController,
                decoration: InputDecoration(
                  labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('crop_label'),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? Provider.of<LanguageService>(context, listen: false).getLocalizedString('required') : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('quantity')),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return Provider.of<LanguageService>(context, listen: false).getLocalizedString('required');
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return Provider.of<LanguageService>(context, listen: false).getLocalizedString('enter_valid_number');
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('unit')),
                      validator: (v) => v == null || v.trim().isEmpty ? Provider.of<LanguageService>(context, listen: false).getLocalizedString('required') : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('price_per_unit')),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return Provider.of<LanguageService>(context, listen: false).getLocalizedString('required');
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return Provider.of<LanguageService>(context, listen: false).getLocalizedString('enter_valid_amount');
                  return null;
                },
              ),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                  );
                  if (picked != null) {
                    setState(() => _availableDate = picked);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('available_date'),
                      hintText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('select_date'),
                    ),
                    validator: (_) => _availableDate == null ? Provider.of<LanguageService>(context, listen: false).getLocalizedString('select_date') : null,
                    controller: TextEditingController(
                      text: _availableDate == null
                          ? ''
                          : '${_availableDate!.year}-${_availableDate!.month.toString().padLeft(2, '0')}-${_availableDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _locationController,
              decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('location')),
              ),
              TextFormField(
                controller: _notesController,
              decoration: InputDecoration(labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('notes')),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Consumer<LanguageService>(
                builder: (context, ls, _) => Text(_submitting ? ls.getLocalizedString('submitting') : ls.getLocalizedString('create_order')),
              ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}


