import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../services/language_service.dart';
import '../widgets/navigation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationProfileScreen extends StatefulWidget {
  final String? phoneNumber; // optional; when null/empty we show phone input
  const RegistrationProfileScreen({super.key, required this.phoneNumber});

  @override
  State<RegistrationProfileScreen> createState() => _RegistrationProfileScreenState();
}

class _RegistrationProfileScreenState extends State<RegistrationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _userType;
  bool _saving = false;
  // Voice-driven filling removed for registration; manual entry only

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing profile if available
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
    _loadDraft();
    // Speak onboarding guidance (manual entry only on this screen)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final voice = Provider.of<VoiceService>(context, listen: false);
      final ls = Provider.of<LanguageService>(context, listen: false);
      await voice.setLanguage(ls.currentLanguage);
      await voice.speak(ls.isTelugu
          ? 'దయచేసి వివరాలను చేతితో నమోదు చేయండి. ఈ పేజీలో వాయిస్ ఇన్‌పుట్ అందుబాటులో లేదు.'
          : 'Please enter your details manually. Voice input is disabled on this page.');
    });
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
      await auth.createOrUpdateUserProfile(
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        userType: _userType!,
      );
      final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
      final voice = Provider.of<VoiceService>(context, listen: false);
      await voice.speak(
        lang == 'te' ? 'ప్రొఫైల్ సేవ్ అయింది. డాష్‌బోర్డ్‌కు వెళుతున్నాము.' : 'Profile saved. Taking you to your dashboard.',
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      // Clear draft after successful save
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      if (draft != null && draft.length == 3) {
        if (_nameController.text.isEmpty) _nameController.text = draft[0];
        if (_addressController.text.isEmpty) _addressController.text = draft[1];
        _userType ??= draft[2].isEmpty ? null : draft[2];
        setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isTe = languageService.currentLanguage == 'te';
    return NavigationHelper(
      showBackButton: false,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
        appBar: NavigationAppBar(
          title: isTe ? 'ప్రొఫైల్' : 'Complete Profile',
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          showBackButton: false,
        ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Instructions
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  isTe
                      ? 'దయచేసి మీ ఫోన్ నంబర్, పూర్తి పేరు, చిరునామా మరియు వినియోగదారు రకం నమోదు చేయండి.'
                      : 'Please enter your phone number, full name, address and user type.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              // Manual-only notice
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isTe
                            ? 'ఈ పేజీలో వాయిస్ ఇన్‌పుట్ లేదు. దయచేసి వివరాలు చేతితో నమోదు చేయండి.'
                            : 'Voice input is not available on this page. Please enter details manually.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              if ((widget.phoneNumber ?? '').isEmpty) ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: isTe ? 'ఫోన్ నంబర్' : 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _saveDraft(),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length < 10 ? (isTe ? 'చెల్లని నంబర్' : 'Invalid phone number') : null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: isTe ? 'పేరు' : 'Full Name'),
                onChanged: (_) => _saveDraft(),
                validator: (v) => v == null || v.trim().isEmpty ? (isTe ? 'పేరు అవసరం' : 'Name is required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: isTe ? 'చిరునామా' : 'Address'),
                onChanged: (_) => _saveDraft(),
                validator: (v) => v == null || v.trim().isEmpty ? (isTe ? 'చిరునామా అవసరం' : 'Address is required') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _userType,
                decoration: InputDecoration(labelText: isTe ? 'వినియోగదారు రకం' : 'User Type'),
                items: const [
                  DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                  DropdownMenuItem(value: 'retailer', child: Text('Retailer')),
                ],
                onChanged: (v) {
                  setState(() => _userType = v);
                  _saveDraft();
                },
                validator: (v) => v == null ? (isTe ? 'రకం ఎంచుకోండి' : 'Select a type') : null,
              ),
              const SizedBox(height: 24),
              // Live Preview Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTe ? 'మీరు నమోదు చేసిన వివరాలు' : 'What you have entered',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _previewRow(isTe ? 'ఫోన్' : 'Phone', _phoneController.text.isEmpty ? '-' : _phoneController.text),
                      _previewRow(isTe ? 'పేరు' : 'Name', _nameController.text.isEmpty ? '-' : _nameController.text),
                      _previewRow(isTe ? 'చిరునామా' : 'Address', _addressController.text.isEmpty ? '-' : _addressController.text),
                      _previewRow(isTe ? 'రకం' : 'Type', _userType ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isTe ? 'సేవ్ చేయండి' : 'Save'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  // Voice fill and step-by-step voice guide removed to enforce manual entry

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


