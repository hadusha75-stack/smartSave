import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:savesmart_admin/services/admin_providers.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(adminFirestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Inbox')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: svc.streamFeedback(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No feedback yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _FeedbackCard(doc: docs[i], svc: svc),
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final dynamic svc;

  const _FeedbackCard({required this.doc, required this.svc});

  @override
  Widget build(BuildContext context) {
    final data      = doc.data();
    final message   = data['message'] as String? ?? '';
    final status    = data['status'] as String? ?? 'open';
    final reply     = data['reply'] as String?;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;
    final isOpen      = status == 'open';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  isOpen
                      ? Icons.mark_email_unread_rounded
                      : Icons.mark_email_read_rounded,
                  color: isOpen
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    createdAt != null
                        ? DateFormat('d MMM yyyy – HH:mm')
                            .format(createdAt)
                        : 'Unknown date',
                    style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant),
                  ),
                ),
                _StatusChip(isOpen: isOpen),
              ],
            ),
            const SizedBox(height: 10),

            // Message
            Text(message, style: textTheme.bodyMedium),

            // Admin reply (if any)
            if (reply != null && reply.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(reply,
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOpen)
                  TextButton.icon(
                    icon: const Icon(Icons.reply_rounded, size: 16),
                    label: const Text('Reply'),
                    onPressed: () =>
                        _showReplyDialog(context, doc.id),
                  ),
                if (isOpen) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark Resolved'),
                    onPressed: () => svc.markResolved(doc.id),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReplyDialog(
      BuildContext context, String feedbackId) async {
    final ctrl    = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to Feedback'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 4,
            maxLength: 500,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Write your reply…'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Reply cannot be empty.' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Send Reply')),
        ],
      ),
    );

    if (confirmed == true) {
      await svc.replyToFeedback(
          feedbackId: feedbackId, reply: ctrl.text);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final bool isOpen;
  const _StatusChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen
        ? Theme.of(context).colorScheme.primary
        : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        isOpen ? 'Open' : 'Resolved',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
