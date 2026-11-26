import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savesmart_admin/services/admin_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(adminFirestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goal Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, svc),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: svc.streamCategories(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No custom categories yet. The app uses built-in defaults.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final doc  = docs[i];
              final name = doc.data()['name'] as String? ?? doc.id;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.category_rounded),
                  title: Text(name),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 20),
                    onPressed: () =>
                        _confirmDelete(context, svc, doc.id, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, dynamic svc) async {
    final ctrl    = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Category name'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Name is required.'
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
              child: const Text('Add')),
        ],
      ),
    );
    if (confirmed == true) await svc.createCategory(ctrl.text);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    dynamic svc,
    String id,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Remove "$name"? Goals with this category will keep it but it '
            'won\'t appear in the picker for new goals.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await svc.deleteCategory(id);
  }
}
