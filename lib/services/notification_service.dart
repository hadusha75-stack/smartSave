import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_service.dart';

/// Top-level handler for background FCM messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised before this is called.
  debugPrint('FCM background message: ${message.messageId}');
}

/// Manages both Firebase Cloud Messaging (remote) and
/// flutter_local_notifications (scheduled local) notifications.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // Android notification channel
  static const _channelId = 'savesmart_reminders';
  static const _channelName = 'Savings Reminders';
  static const _channelDesc = 'Scheduled savings reminders';

  static bool _initialised = false;

  // ── Initialisation ────────────────────────────────────────────────────────

  static Future<void> initialise() async {
    if (_initialised) return;

    // Load timezone data
    tz.initializeTimeZones();
    // Default to Addis Ababa (UTC+3)
    tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));

    // Local notifications setup
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _initialised = true;
  }

  // ── Permission requests ───────────────────────────────────────────────────

  /// Request notification permissions (Android 13+, iOS).
  static Future<bool> requestPermissions() async {
    // FCM permission
    final settings = await FirebaseService.messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final fcmGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    // Android 13+ exact alarm permission is handled via AndroidManifest.xml
    // We just need to check local notification permission on Android 13+
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      return granted && fcmGranted;
    }

    if (!kIsWeb && Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted && fcmGranted;
    }

    return fcmGranted;
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  /// Get the current FCM device token.
  static Future<String?> getFcmToken() =>
      FirebaseService.messaging.getToken();

  // ── Schedule local notifications ──────────────────────────────────────────

  /// Schedule a repeating daily notification.
  static Future<void> scheduleDailyReminder({
    required int notificationId,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a weekly notification on a specific weekday (1=Mon, 7=Sun).
  static Future<void> scheduleWeeklyReminder({
    required int notificationId,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    // Find the next occurrence of the given weekday
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Advance day-by-day until we hit the right weekday
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a monthly notification on a specific day of month.
  static Future<void> scheduleMonthlyReminder({
    required int notificationId,
    required String title,
    required String body,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth.clamp(1, 28), // cap at 28 for Feb safety
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      // Advance one month
      scheduled = tz.TZDateTime(
        tz.local,
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        dayOfMonth.clamp(1, 28),
        hour,
        minute,
      );
    }

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a specific scheduled notification.
  static Future<void> cancelReminder(int notificationId) =>
      _plugin.cancel(notificationId);

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Immediate notification (for milestone etc.) ───────────────────────────

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _notificationDetails());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Navigation on tap is handled in Stage 5 (Reminders)
    debugPrint('Notification tapped: ${response.payload}');
  }
}
