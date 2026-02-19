import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card_wrapper.dart';
import '../widgets/primary_button.dart';
import 'user_type_selection_screen.dart';

class RegistrationProfileScreen extends StatefulWidget {
  final String? phoneNumber;
  const RegistrationProfileScreen({super.key, this.phoneNumber});

  @override
  State<RegistrationProfileScreen> createState() =>
      _RegistrationProfileScreenState();
}

class _RegistrationProfileScreenState extends State<RegistrationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _userType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Voice guidance
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       _speakGuidance();
    });
  }

  Future<void> _loadInitialData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.name != null && auth.name!.isNotEmpty) {
      _nameController.text = auth.name!;
    }
    if (auth.address != null && auth.address!.isNotEmpty) {
      _addressController.text = auth.address!;
    }
    _userType = auth.userType;
    
    if ((widget.phoneNumber ?? '').isNotEmpty) {
      _phoneController.text = widget.phoneNumber!;
    }
    
    await _loadDraft();
  }

  Future<void> _speakGuidance() async {
      final voice = Provider.of<VoiceService>(context, listen: false);
      final ls = Provider.of<LanguageService>(context, listen: false);
      await voice.speak(ls.isTelugu
          ? 'దయచేసి మీ పేరు మరియు చిరునామాను నమోదు చేయండి.'
          : 'Please enter your name and address details.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
      final voice = Provider.of<VoiceService>(context, listen: false);
      
      // Save profile
      await auth.createOrUpdateUserProfile(
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        userType: _userType ?? 'farmer', 
      );
      
      await voice.speak(
        lang == 'te' ? 'ప్రొఫైల్ సేవ్ అయింది.' : 'Profile saved successfully.',
      );
      
      // Clear draft
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey());
      
      if (!mounted) return;

      // Navigate based on user type or missing type
      // If user selected type here (via dropdown), we assume flow is complete -> Home
      // But if we want to enforce distinct selection screen, we could skip dropdown here.
      // Current design: includes dropdown.
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _draftKey() => 'profile_draft_${widget.phoneNumber}';
  String _draftPhoneKey() => 'profile_phone_draft';

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = prefs.getStringList(_draftKey());
      if (draft != null && draft.length >= 2) {
        if (_nameController.text.isEmpty) _nameController.text = draft[0];
        if (_addressController.text.isEmpty) _addressController.text = draft[1];
        if (_userType == null && draft.length > 2 && draft[2].isNotEmpty) {
           _userType = draft[2];
        }
        if(mounted) setState(() {});
      }
      if (_phoneController.text.isEmpty) {
        final d = prefs.getString(_draftPhoneKey());
        if (d != null) _phoneController.text = d;
      }
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_draftKey(), [
        _nameController.text,
        _addressController.text,
        _userType ?? '',
      ]);
      await prefs.setString(_draftPhoneKey(), _phoneController.text);
    } catch (_) {}
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.textSecondary),
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isTe = languageService.isTelugu;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.premiumGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: GlassCardWrapper(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isTe ? 'ప్రొఫైల్' : 'Complete Profile',
                        style: AppTheme.displayMedium.copyWith(
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTe
                            ? 'దయచేసి మీ వివరాలను నమోదు చేయండి'
                            : 'Please enter your details below',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      
                      // Phone Field (ReadOnly if passed)
                      if ((widget.phoneNumber ?? '').isEmpty)
                        Padding(
                           padding: const EdgeInsets.only(bottom: 16),
                           child: TextFormField(
                             controller: _phoneController,
                             decoration: _buildInputDecoration(isTe ? 'ఫోన్ నంబర్' : 'Phone Number'),
                             keyboardType: TextInputType.phone,
                             onChanged: (_) => _saveDraft(),
                             validator: (v) {
                               final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                               return digits.length < 10
                                   ? (isTe ? 'చెల్లని నంబర్' : 'Invalid phone number')
                                   : null;
                             },
                           ),
                        ),
                        
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(isTe ? 'పూర్తి పేరు' : 'Full Name'),
                        onChanged: (_) => _saveDraft(),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? (isTe ? 'పేరు అవసరం' : 'Name is required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _addressController,
                        decoration: _buildInputDecoration(isTe ? 'చిరునామా' : 'Address'),
                        onChanged: (_) => _saveDraft(),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? (isTe ? 'చిరునామా అవసరం' : 'Address is required')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _userType,
                        decoration: _buildInputDecoration(isTe ? 'వినియోగదారు రకం' : 'User Type'),
                        items: [
                          DropdownMenuItem(
                            value: 'farmer',
                            child: Text(isTe ? 'రైతు' : 'Farmer'),
                          ),
                          DropdownMenuItem(
                            value: 'retailer',
                            child: Text(isTe ? 'వ్యాపారి' : 'Retailer'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _userType = v);
                          _saveDraft();
                        },
                        validator: (v) => v == null
                            ? (isTe ? 'రకం ఎంచుకోండి' : 'Select a type')
                            : null,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      PrimaryButton(
                        label: isTe ? 'సేవ్ చేయండి' : 'Save Profile',
                        onPressed: _saving ? null : _save,
                        isLoading: _saving,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



