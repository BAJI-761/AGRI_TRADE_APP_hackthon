import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/voice_service.dart';
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../models/order.dart' as model;
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // To handle file paths
import 'dart:convert'; // For Base64 encoding

import '../../theme/app_theme.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../widgets/primary_button.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? retailerId; // Optional: for direct trade requests

  const CreateOrderScreen({super.key, this.retailerId});

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

  // Phase B: Quality & Details State
  final _moistureController = TextEditingController();
  final _storageDurationController = TextEditingController();
  final _landAreaController = TextEditingController();
  final _varietyController = TextEditingController();
  final _pesticidesController = TextEditingController();
  final _gstController = TextEditingController();
  
  DateTime? _cultivatedDate;
  DateTime? _harvestedDate;
  
  String _storageType = 'Warehouse';
  final List<String> _storageTypes = ['Cold Storage', 'Warehouse', 'Open', 'Natural Dry'];
  
  String _packaging = 'Sack';
  final List<String> _packagingTypes = ['Loose', 'Sack', 'Box'];

  String _grade = 'B';
  final List<String> _grades = ['A', 'B', 'C'];
  
  bool _isOrganic = false;
  
  // Simulated Media (Updated for ImagePicker)
  final List<XFile> _cropImages = []; 
  final ImagePicker _picker = ImagePicker();
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.retailerId != null) {
      // Pre-fill notes or handle UI for direct request
      _notesController.text = 'Direct trade request to retailer.';
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
    
    // Phase B Dispose
    _moistureController.dispose();
    _storageDurationController.dispose();
    _landAreaController.dispose();
    _varietyController.dispose();
    _pesticidesController.dispose();
    _gstController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70, // Optimized for PDF generation
      );
      
      if (pickedFile != null) {
        setState(() {
          _cropImages.add(pickedFile);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
      }
    }
  }

  void _showImagePickerOptions() {
    final ls = Provider.of<LanguageService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(ls.currentLanguage == 'te' ? 'కెమెరా' : 'Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(ls.currentLanguage == 'te' ? 'గ్యాలరీ' : 'Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
      
      // Convert images to Base64
      List<String> base64Images = [];
      for (var img in _cropImages) {
        final bytes = await img.readAsBytes();
        base64Images.add(base64Encode(bytes));
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
        retailerId: widget.retailerId, // Set the specific retailer ID
        
        // Phase B Fields
        cropImages: base64Images, // Store Base64 strings
        videoUrl: _videoUrl,
        cultivatedDate: _cultivatedDate,
        harvestedDate: _harvestedDate,
        storageType: _storageType,
        storageDuration: int.tryParse(_storageDurationController.text) ?? 0,
        moistureContent: double.tryParse(_moistureController.text) ?? 0.0,
        isOrganic: _isOrganic,
        pesticidesUsed: _isOrganic ? 'No' : _pesticidesController.text.trim(),
        gstNumber: _gstController.text.trim(),
        packaging: _packaging,
        grade: _grade,
        landArea: double.tryParse(_landAreaController.text) ?? 0.0,
        cropVariety: _varietyController.text.trim(),
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
              
              const Divider(),
              const SizedBox(height: 16),
              
              // Quality & Details Header
              Text(
                ls.currentLanguage == 'te' ? 'నాణ్యత & వివరాలు' : 'Quality & Details',
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: 16),

              // 1. Images & Video (Simulated)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ls.currentLanguage == 'te' ? 'పంట ఫోటోలు (కనీసం 1)' : 'Crop Images (Min 1)',
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._cropImages.map((img) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(img.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _cropImages.remove(img)),
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )),
                        GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryGreen, style: BorderStyle.solid), // Fixed Dashed Border Error
                            ),
                            child: const Icon(Icons.add_a_photo, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    if (_cropImages.isEmpty && _submitting)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          ls.currentLanguage == 'te' ? 'ఫోటో అవసరం' : 'Image required',
                          style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Dates (Cultivated & Harvested)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 90)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _cultivatedDate = picked);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: _cultivatedDate == null ? '' : '${_cultivatedDate!.day}/${_cultivatedDate!.month}/${_cultivatedDate!.year}'
                          ),
                          decoration: AppTheme.inputDecoration.copyWith(
                            labelText: ls.currentLanguage == 'te' ? 'సాగు తేదీ' : 'Cultivated Date',
                            suffixIcon: const Icon(Icons.calendar_month),
                          ),
                          validator: (v) => _cultivatedDate == null ? ls.getLocalizedString('required') : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _harvestedDate = picked);
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                              text: _harvestedDate == null ? '' : '${_harvestedDate!.day}/${_harvestedDate!.month}/${_harvestedDate!.year}'
                          ),
                          decoration: AppTheme.inputDecoration.copyWith(
                            labelText: ls.currentLanguage == 'te' ? 'కోత తేదీ' : 'Harvested Date',
                            suffixIcon: const Icon(Icons.calendar_month),
                          ),
                          validator: (v) => _harvestedDate == null ? ls.getLocalizedString('required') : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Storage
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _storageType,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.currentLanguage == 'te' ? 'నిల్వ రకం' : 'Storage Type',
                      ),
                      items: _storageTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _storageType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _storageDurationController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.currentLanguage == 'te' ? 'రోజులు' : 'Days',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Moisture & Land Area
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _moistureController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.currentLanguage == 'te' ? 'తేమ (%)' : 'Moisture (%)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _landAreaController,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.currentLanguage == 'te' ? 'భూమి (ఎకరాలు)' : 'Land (Acres)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Variety & Organic
              TextFormField(
                controller: _varietyController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.currentLanguage == 'te' ? 'పంట రకం/రకం' : 'Crop Variety',
                ),
                validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(ls.currentLanguage == 'te' ? 'సేంద్రీయ?' : 'Organic?'),
                value: _isOrganic,
                onChanged: (v) => setState(() => _isOrganic = v),
                activeColor: AppTheme.primaryGreen,
              ),
              if (!_isOrganic)
                TextFormField(
                  controller: _pesticidesController,
                  decoration: AppTheme.inputDecoration.copyWith(
                    labelText: ls.currentLanguage == 'te' ? 'పురుగుమందుల పేరు' : 'Pesticide Name',
                  ),
                  validator: (v) => !_isOrganic && v?.isEmpty == true ? ls.getLocalizedString('required') : null,
                ),
              const SizedBox(height: 16),

              // 6. Packaging & Grade
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _packaging,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.currentLanguage == 'te' ? 'ప్యాకేజింగ్' : 'Packaging',
                      ),
                      items: _packagingTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _packaging = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _grade,
                      decoration: AppTheme.inputDecoration.copyWith(
                        labelText: ls.currentLanguage == 'te' ? 'గ్రేడ్' : 'Grade',
                      ),
                      items: _grades.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _grade = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7. GST
              TextFormField(
                controller: _gstController,
                decoration: AppTheme.inputDecoration.copyWith(
                  labelText: ls.currentLanguage == 'te' ? 'GST సంఖ్య' : 'GST Number',
                ),
                validator: (v) => v?.isEmpty == true ? ls.getLocalizedString('required') : null,
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


