import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:savesmart_admin/features/auth/screens/admin_login_screen.dart';
import 'package:savesmart_admin/features/dashboard/screens/dashboard_screen.dart';
import 'package:savesmart_admin/features/users/screens/users_screen.dart';
import 'package:savesmart_admin/features/tips/screens/tips_screen.dart';
import 'package:savesmart_admin/features/feedback/screens/feedback_screen.dart';
import 'package:savesmart_admin/features/notifications/screens/notifications_screen.dart';
import 'package:savesmart_admin/features/categories/screens/categories_screen.dart';
import 'package:savesmart_admin/services/admin_providers.dart';

class AdminRoutes {
  AdminRoutes._();
  static const login         = '/login';
  static const dashboard     = '/dashboard';
  static const users         = '/users';
  static const tips          = '/tips';
  static const notifications = '/notifications';
  static const feedback      = '/feedback';
  static const categories    = '/categories';
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authStreamProvider);

  return GoRouter(
    initialLocation: AdminRoutes.dashboard,
    redirect: (context, state) {
      if (authStream.isLoading) return null;
      final loggedIn = authStream.valueOrNull != null;
      final onLogin = state.matchedLocation == AdminRoutes.login;

      if (!loggedIn && !onLogin) return AdminRoutes.login;
      if (loggedIn && onLogin) return AdminRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AdminRoutes.login,
        builder: (_, __) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AdminShell(
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AdminRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AdminRoutes.users,
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: AdminRoutes.tips,
            builder: (_, __) => const TipsScreen(),
          ),
          GoRoute(
            path: AdminRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AdminRoutes.feedback,
            builder: (_, __) => const FeedbackScreen(),
          ),
          GoRoute(
            path: AdminRoutes.categories,
            builder: (_, __) => const CategoriesScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Shell that wraps every admin screen in the responsive scaffold.
class _AdminShell extends StatelessWidget {
  final String currentPath;
  final Widget child;
  const _AdminShell({required this.currentPath, required this.child});

  @override
  Widget build(BuildContext context) {
    // Import deferred to avoid circular dependency
    return _ShellWrapper(currentPath: currentPath, child: child);
  }
}

class _ShellWrapper extends ConsumerWidget {
  final String currentPath;
  final Widget child;
  const _ShellWrapper(
      {required this.currentPath, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inline scaffold here to avoid extra import
    final isWide = MediaQuery.of(context).size.width >= 720;
    final colorScheme = Theme.of(context).colorScheme;

    final navItems = [
      (icon: Icons.dashboard_rounded,     label: 'Dashboard',    path: AdminRoutes.dashboard),
      (icon: Icons.people_rounded,         label: 'Users',        path: AdminRoutes.users),
      (icon: Icons.lightbulb_rounded,      label: 'Tips',         path: AdminRoutes.tips),
      (icon: Icons.notifications_rounded,  label: 'Notifications',path: AdminRoutes.notifications),
      (icon: Icons.feedback_rounded,       label: 'Feedback',     path: AdminRoutes.feedback),
      (icon: Icons.category_rounded,       label: 'Categories',   path: AdminRoutes.categories),
    ];

    int selectedIdx = 0;
    for (var i = 0; i < navItems.length; i++) {
      if (currentPath.startsWith(navItems[i].path)) {
        selectedIdx = i;
        break;
      }
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 220,
              child: Container(
                color: colorScheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                              color: colorScheme.primary, size: 28),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SaveSmart',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary)),
                              Text('Admin',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          color:
                                              colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...navItems.asMap().entries.map((e) {
                      final selected = e.key == selectedIdx;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          tileColor: selected
                              ? colorScheme.primaryContainer.withAlpha(80)
                              : Colors.transparent,
                          leading: Icon(e.value.icon,
                              color: selected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              size: 20),
                          title: Text(e.value.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: selected
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant)),
                          onTap: () => context.go(e.value.path),
                        ),
                      );
                    }),
                    const Spacer(),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout_rounded,
                          color: colorScheme.error, size: 20),
                      title: Text('Log Out',
                          style:
                              TextStyle(color: colorScheme.error)),
                      onTap: () =>
                          ref.read(adminAuthProvider.notifier).logout(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIdx,
        onDestinationSelected: (i) => context.go(navItems[i].path),
        destinations: navItems
            .map((n) => NavigationDestination(
                icon: Icon(n.icon), label: n.label))
            .toList(),
      ),
    );
  }
}
