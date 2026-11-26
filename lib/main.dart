import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/app_binding.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routing/app_router.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'l10n/app_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseService.enableOfflinePersistence();

  // 2. Local notifications — only on mobile
  if (!kIsWeb) {
    await NotificationService.initialise();
  }

  // 3. FCM foreground handler — only on mobile, not web
  if (!kIsWeb) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.showImmediate(
          id: message.hashCode,
          title: notification.title ?? 'SaveSmart',
          body: notification.body ?? '',
        );
      }
    });
  }

  runApp(const SaveSmartApp());
}

class SaveSmartApp extends StatelessWidget {
  const SaveSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SaveSmart',
      debugShowCheckedModeBanner: false,

      // ── Themes ──────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // updated by SettingsController

      // ── Localization ─────────────────────────────────────────────────────
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en'),
      translations: AppTranslations(),
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Bindings (registers all controllers) ─────────────────────────────
      initialBinding: AppBinding(),

      // ── Routing ──────────────────────────────────────────────────────────
      initialRoute: AppRoutes.splash,
      getPages: AppRouter.pages,
    );
  }
}
