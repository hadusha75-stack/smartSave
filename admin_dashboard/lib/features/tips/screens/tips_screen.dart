import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:savesmart_admin/services/admin_providers.dart';

class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(adminFirestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saving Tips')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTipDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Tip'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: svc.streamTips(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No tips yet. Add one with the + button.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TipCard(
              doc: docs[i],
              onEdit: () => _showTipDialog(context, ref, doc: docs[i]),
              onDelete: () => _deleteTip(context, svc, docs[i].id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTipDialog(
    BuildContext context,
    WidgetRef ref, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final ctrl = TextEditingController(
        text: doc != null ? doc.data()['message'] as String? ?? '' : '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? 'New Tip' : 'Edit Tip'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 4,
            maxLength: 300,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter a saving tip…',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Tip cannot be empty.'
                : null,
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
              child: const Text('Save')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final svc    = ref.read(adminFirestoreServiceProvider);
    final authUid = ref.read(authStreamProvider).valueOrNull?.uid ?? '';

    if (doc == null) {
      await svc.createTip(message: ctrl.text, adminUid: authUid);
    } else {
      await svc.updateTip(doc.id, ctrl.text);
    }
  }

  Future<void> _deleteTip(
    BuildContext context,
    dynamic svc,
    String tipId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tip'),
        content:
            const Text('Remove this tip? It will no longer appear in the app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await svc.deleteTip(tipId);
  }
}

class _TipCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TipCard({
    required this.doc,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data      = doc.data();
    final message   = data['message'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_rounded,
                color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('d MMM yyyy').format(createdAt),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit),
                IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: colorScheme.error),
                    onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
