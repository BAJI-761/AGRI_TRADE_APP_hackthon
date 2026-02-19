import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/navigation_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/app_gradient_scaffold.dart';
import '../widgets/primary_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'message': _messageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback sent. Thank you!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.2,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'Feedback',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'We value your feedback!',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please let us know your thoughts, suggestions, or any issues you faced.',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 6,
                    decoration: AppTheme.inputDecoration.copyWith(
                      labelText: 'Your feedback',
                      alignLabelWithHint: true,
                      hintText: 'Type your message here...',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter feedback' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Submit Feedback',
                    onPressed: _submit,
                    isLoading: _sending,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


