import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:savesmart_admin/services/admin_providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.read(adminFirestoreServiceProvider);
    final stream = _search.isEmpty
        ? svc.streamUsers()
        : svc.searchUsers(_search);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(_search.isEmpty
                  ? 'No users registered yet.'
                  : 'No users matching "$_search".'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _UserTile(doc: docs[i]),
          );
        },
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _UserTile({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data        = doc.data();
    final uid         = doc.id;
    final name        = data['name'] as String? ?? 'Unknown';
    final email       = data['email'] as String? ?? '';
    final role        = data['role'] as String? ?? 'user';
    final status      = data['status'] as String? ?? 'active';
    final createdAt   = (data['createdAt'] as Timestamp?)?.toDate();
    final colorScheme = Theme.of(context).colorScheme;
    final svc         = ref.read(adminFirestoreServiceProvider);

    final isSuspended = status == 'suspended';
    final isAdmin     = role == 'admin';

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: isAdmin
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (isAdmin)
              _Chip(label: 'Admin', color: colorScheme.primary),
            if (isSuspended)
              _Chip(label: 'Suspended', color: colorScheme.error),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
            if (createdAt != null)
              Text(
                'Joined ${DateFormat('d MMM yyyy').format(createdAt)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.outlineVariant),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: isAdmin
            ? null // Never show action menu for admin accounts
            : PopupMenuButton<String>(
                onSelected: (action) =>
                    _onAction(context, action, uid, isSuspended, svc),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: isSuspended ? 'unsuspend' : 'suspend',
                    child: Text(isSuspended
                        ? 'Unsuspend Account'
                        : 'Suspend Account'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    String action,
    String uid,
    bool isSuspended,
    dynamic svc,
  ) async {
    if (action == 'suspend') {
      final ok = await _confirm(context,
          title: 'Suspend Account',
          message:
              'The user will be blocked from logging in. You can unsuspend them later.',
          confirmLabel: 'Suspend');
      if (ok) await svc.suspendUser(uid);
    } else if (action == 'unsuspend') {
      await svc.unsuspendUser(uid);
    } else if (action == 'delete') {
      final ok = await _confirm(context,
          title: 'Delete Account',
          message:
              'This deletes the user\'s Firestore document. '
              'The Firebase Auth account must be deleted separately via '
              'the Firebase console or a Cloud Function.',
          confirmLabel: 'Delete',
          destructive: true);
      if (ok) await svc.deleteUserDoc(uid);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(ctx).colorScheme.error)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}
