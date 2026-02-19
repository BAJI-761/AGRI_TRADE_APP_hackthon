import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/voice_service.dart';
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../models/order.dart' as model;

import '../../theme/app_theme.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../widgets/primary_button.dart';

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
  bool _isListening = false;

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

  Future<void> _handleVoiceSell() async {
    setState(() => _isListening = true);
    try {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      
      final available = await voiceService.initializeSpeech();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice not available')),
          );
        }
        setState(() => _isListening = false);
        return;
      }

      final result = await voiceService.voiceSellFlow();
      
      if (result['confirmed'] == true && result.isNotEmpty) {
        _cropController.text = result['crop'] ?? '';
        _quantityController.text = result['quantity']?.toString() ?? '';
        _unitController.text = result['unit'] ?? 'kg';
        _priceController.text = result['price']?.toString() ?? '';
        _locationController.text = result['location'] ?? '';
        _availableDate = DateTime.now().add(const Duration(days: 1));
        
        setState(() {});
        
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
    } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      String farmerId = '';
      if (auth.user != null && auth.user!.uid.isNotEmpty) {
        farmerId = auth.user!.uid;
      } else if (auth.phone != null && auth.phone!.isNotEmpty) {
        farmerId = auth.phone!;
      } else if (auth.name != null) {
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
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      service.setNotificationService(notificationService);
      
      await service.createOrder(order);
      
      if (!mounted) return;
      
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      await voiceService.speak(
        voiceService.currentLanguage == 'te' 
          ? 'ఆర్డర్ సృష్టించబడింది.' 
          : 'Order created successfully.'
      );
      
      if (mounted) {
        final ls = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ls.getLocalizedString('order_created')), backgroundColor: AppTheme.primaryGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final ls = Provider.of<LanguageService>(context, listen: false);
        String errorMessage = '${ls.getLocalizedString('failed')}: $e';
        
        if (e.toString().contains('PERMISSION_DENIED')) {
          errorMessage = ls.currentLanguage == 'te'
            ? 'అనుమతి తిరస్కరించబడింది.'
            : 'Permission denied.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ls = Provider.of<LanguageService>(context);
    
    return AppGradientScaffold(
      headerHeightFraction: 0.2, // Smaller header for detail screens
      headerChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                ls.getLocalizedString('create_order'),
                style: AppTheme.headingMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
      bodyChildren: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Voice Assistant Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic, color: AppTheme.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ls.currentLanguage == 'te' 
                              ? 'వాయిస్ ద్వారా ఆర్డర్ చేయండి'
                              : 'Create order with Voice',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ls.currentLanguage == 'te'
                        ? 'మైక్ నొక్కి చెప్పండి: "నేను 50 కిలోల బియ్యం 2000 రూపాయలకు అమ్మాలి"'
                        : 'Tap mic and say: "I want to sell 50kg rice for 2000 rupees"',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isListening ? null : _handleVoiceSell,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? AppTheme.errorRed : AppTheme.primaryGreen,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? AppTheme.errorRed : AppTheme.primaryGreen).withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.graphic_eq : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    if (_isListening) ...[
                      const SizedBox(height: 8),
                      Text(
                        ls.currentLanguage == 'te' ? 'వినబడుతోంది...' : 'Listening...',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Manual Entry Form
              TextFormField(
                controller: _cropController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('crop_label'),
                  prefixIcon: const Icon(Icons.grass, color: AppTheme.primaryGreen),
                ),
                validator: (v) => v?.trim().isEmpty == true ? ls.getLocalizedString('required') : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.getLocalizedString('quantity'),
                        prefixIcon: const Icon(Icons.scale, color: AppTheme.primaryGreen),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.getLocalizedString('unit'),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? ls.getLocalizedString('required') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('price_per_unit'),
                  prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
              ),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _availableDate = picked);
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _availableDate == null ? '' : 
                            '${_availableDate!.day}/${_availableDate!.month}/${_availableDate!.year}'
                    ),
                    decoration: AppTheme.inputDecoration.copyWith(
                      labelText: ls.getLocalizedString('available_date'),
                      prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                    ),
                    validator: (_) => _availableDate == null ? ls.getLocalizedString('select_date') : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('location'),
                  prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.getLocalizedString('notes'),
                  prefixIcon: const Icon(Icons.note, color: AppTheme.primaryGreen),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(
                label: ls.getLocalizedString('create_order'),
                isLoading: _submitting,
                onPressed: _submitOrder,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}


