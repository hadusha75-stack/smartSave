import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/feedback_controller.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _msgCtrl = TextEditingController();
  final _fbCtrl  = Get.find<FeedbackController>();

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await _fbCtrl.submitFeedback(_msgCtrl.text);
      Get.back();
      Get.snackbar('Thank you', 'Your feedback was sent.',
          backgroundColor: Theme.of(context).colorScheme.primary,
          colorText: Theme.of(context).colorScheme.onPrimary);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.feedback_outlined, size: 32,
                    color: cs.onSecondaryContainer),
              ),
              const SizedBox(height: 20),
              Text('Share your thoughts',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Report a problem, suggest a feature, or ask a question.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 28),
              TextFormField(
                controller: _msgCtrl,
                maxLines: 6, maxLength: 500, autofocus: true,
                decoration: const InputDecoration(hintText: 'Write your message here…'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please write a message.';
                  if (v.trim().length < 10) return 'Message too short (min 10 characters).';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton.icon(
                  onPressed: _fbCtrl.isLoading.value ? null : _submit,
                  icon: _fbCtrl.isLoading.value
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Icon(Icons.send_rounded),
                  label: const Text('Send Feedback'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
