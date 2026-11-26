import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/controllers/settings_controller.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/routing/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth     = Get.find<AuthController>();
    final settings = Get.find<SettingsController>();
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(() {
        final user = auth.currentUser.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile card
            if (user != null)
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.primaryContainer,
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: tt.headlineSmall?.copyWith(
                            color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(user.email, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ])),
                ]),
              )),
            const SizedBox(height: 16),

            const _Label('Appearance'),
            Card(child: Column(children: [
              // Theme
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                trailing: Obx(() => DropdownButton<ThemeMode>(
                  value: settings.themeMode.value,
                  underline: const SizedBox(),
                  onChanged: (m) { if (m != null) settings.setTheme(m); },
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(value: ThemeMode.light,  child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark,   child: Text('Dark')),
                  ],
                )),
              ),
              const Divider(height: 1, indent: 56),
              // Language
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                trailing: Obx(() => DropdownButton<String>(
                  value: settings.locale.value?.languageCode ?? 'en',
                  underline: const SizedBox(),
                  onChanged: (code) {
                    if (code != null) settings.setLocale(Locale(code));
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'am', child: Text('አማርኛ')),
                    DropdownMenuItem(value: 'ti', child: Text('ትግርኛ')),
                  ],
                )),
              ),
              const Divider(height: 1, indent: 56),
              // Currency
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.attach_money_rounded),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: user.currency,
                    underline: const SizedBox(),
                    onChanged: (code) async {
                      if (code != null) await auth.updateProfile(currency: code);
                    },
                    items: AppConstants.supportedCurrencies.map((c) =>
                        DropdownMenuItem(value: c, child: Text(c))).toList(),
                  ),
                ),
            ])),
            const SizedBox(height: 16),

            const _Label('Account'),
            Card(child: Column(children: [
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('Send Feedback'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Get.toNamed(AppRoutes.feedback),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: cs.error),
                title: Text('Log Out', style: TextStyle(color: cs.error)),
                onTap: () => _confirmLogout(context, auth),
              ),
            ])),
            const SizedBox(height: 24),
            Center(child: Text('SaveSmart v${AppConstants.appVersion}',
                style: tt.bodySmall?.copyWith(color: cs.outlineVariant))),
          ],
        );
      }),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthController auth) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Log Out')),
      ],
    ));
    if (ok == true) {
      await auth.logout();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700)),
  );
}
