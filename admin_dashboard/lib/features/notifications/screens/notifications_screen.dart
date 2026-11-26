import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savesmart_admin/services/admin_providers.dart';

/// Sends a system-wide notification by writing to Firestore.
/// A Cloud Function (not in scope of this project) would read this
/// document and call the FCM Admin SDK to fan out the notification.
/// We write the payload to Firestore so it is auditable and can be
/// picked up by a Cloud Function trigger.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _sending = false;
  bool _sent    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);

    try {
      final db      = FirebaseFirestore.instance;
      final authUid = ref.read(authStreamProvider).valueOrNull?.uid ?? '';

      // Write a document that a Cloud Function can listen to.
      await db.collection('system_notifications').add({
        'title':     _titleCtrl.text.trim(),
        'body':      _bodyCtrl.text.trim(),
        'sentBy':    authUid,
        'sentAt':    FieldValue.serverTimestamp(),
        'processed': false,
      });

      setState(() => _sent = true);
      _titleCtrl.clear();
      _bodyCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('System Notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: colorScheme.primary.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This writes a notification request to Firestore. '
                        'A Cloud Function picks it up and sends the push to '
                        'all users via the FCM Admin SDK.',
                        style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (_sent) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.green.withAlpha(80)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green),
                      SizedBox(width: 10),
                      Text('Notification request sent!',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notification Title',
                        style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      maxLength: 65,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Time to save this week!'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required.'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    Text('Message Body',
                        style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bodyCtrl,
                      maxLines: 4,
                      maxLength: 200,
                      decoration: const InputDecoration(
                          hintText:
                              'e.g. Saving a little every week adds up. Keep going!'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Message body is required.'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5))
                            : const Icon(Icons.send_rounded),
                        label: const Text('Send to All Users'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
