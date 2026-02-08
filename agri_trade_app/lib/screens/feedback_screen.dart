import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/navigation_helper.dart';

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
        const SnackBar(content: Text('Feedback sent. Thank you!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: 'Feedback',
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Your feedback',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter feedback' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}


