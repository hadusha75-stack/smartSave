import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/features/reminders/domain/models/reminder.dart';
import 'package:savesmart/services/notification_service.dart';

/// GetX controller for per-goal reminders.
class ReminderController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _uid = '';

  /// Reminders for the currently-viewed goal.
  final RxList<Reminder> reminders = <Reminder>[].obs;

  final RxBool isLoading = false.obs;

  StreamSubscription? _sub;

  void setUid(String uid) {
    _uid = uid;
  }

  CollectionReference<Map<String, dynamic>> _remRef(String goalId) => _db
      .collection(AppConstants.usersCollection)
      .doc(_uid)
      .collection(AppConstants.goalsCollection)
      .doc(goalId)
      .collection(AppConstants.remindersCollection);

  // ── Stream ───────────────────────────────────────────────────────────────────

  void subscribeToReminders(String goalId) {
    _sub?.cancel();
    _sub = _remRef(goalId).snapshots().listen((snap) {
      reminders.value = snap.docs.map((d) => Reminder.fromFirestore(d)).toList();
    });
  }

  // ── Create ───────────────────────────────────────────────────────────────────

  Future<String> createReminder({
    required String goalId,
    required String goalTitle,
    required String frequency,
    required int hourOfDay,
    required int minute,
    int? weekday,
    int? dayOfMonth,
    required double weeklyPlanAmount,
    required String currency,
  }) async {
    isLoading.value = true;
    try {
      final id = const Uuid().v4();
      final reminder = Reminder(
        id: id,
        goalId: goalId,
        frequency: frequency,
        weekday: weekday,
        dayOfMonth: dayOfMonth,
        hourOfDay: hourOfDay,
        minute: minute,
        active: true,
      );

      await _remRef(goalId).doc(id).set(reminder.toFirestore());

      final notifId = _notifId(id);
      final body = _buildBody(
          frequency: frequency, amount: weeklyPlanAmount, currency: currency);

      await _schedule(
        notifId: notifId,
        title: 'SaveSmart – $goalTitle',
        body: body,
        reminder: reminder,
      );

      return id;
    } catch (e) {
      throw AppError.from(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Toggle active ────────────────────────────────────────────────────────────

  Future<void> setActive({
    required String goalId,
    required String reminderId,
    required bool active,
    required String goalTitle,
    required double weeklyPlanAmount,
    required String currency,
  }) async {
    await _remRef(goalId).doc(reminderId).update({'active': active});

    final notifId = _notifId(reminderId);
    if (!active) {
      await NotificationService.cancelReminder(notifId);
    } else {
      final snap = await _remRef(goalId).doc(reminderId).get();
      if (snap.exists) {
        final reminder = Reminder.fromFirestore(snap);
        final body = _buildBody(
            frequency: reminder.frequency,
            amount: weeklyPlanAmount,
            currency: currency);
        await _schedule(
          notifId: notifId,
          title: 'SaveSmart – $goalTitle',
          body: body,
          reminder: reminder,
        );
      }
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteReminder({
    required String goalId,
    required String reminderId,
  }) async {
    await _remRef(goalId).doc(reminderId).delete();
    await NotificationService.cancelReminder(_notifId(reminderId));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  int _notifId(String reminderId) {
    final hex = reminderId.replaceAll('-', '').substring(0, 8);
    return int.parse(hex, radix: 16) & 0x7FFFFFFF;
  }

  Future<void> _schedule({
    required int notifId,
    required String title,
    required String body,
    required Reminder reminder,
  }) async {
    switch (reminder.frequency) {
      case AppConstants.freqDaily:
        await NotificationService.scheduleDailyReminder(
          notificationId: notifId,
          title: title,
          body: body,
          hour: reminder.hourOfDay,
          minute: reminder.minute,
        );
      case AppConstants.freqWeekly:
        await NotificationService.scheduleWeeklyReminder(
          notificationId: notifId,
          title: title,
          body: body,
          weekday: reminder.weekday ?? DateTime.monday,
          hour: reminder.hourOfDay,
          minute: reminder.minute,
        );
      case AppConstants.freqMonthly:
        await NotificationService.scheduleMonthlyReminder(
          notificationId: notifId,
          title: title,
          body: body,
          dayOfMonth: reminder.dayOfMonth ?? 1,
          hour: reminder.hourOfDay,
          minute: reminder.minute,
        );
    }
  }

  String _buildBody({
    required String frequency,
    required double amount,
    required String currency,
  }) {
    final fmt = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    switch (frequency) {
      case AppConstants.freqDaily:
        return 'Time to save! Your daily plan is $fmt $currency.';
      case AppConstants.freqWeekly:
        return 'Time to save! Your weekly plan is $fmt $currency.';
      case AppConstants.freqMonthly:
        return 'Time to save! Your monthly plan is $fmt $currency.';
      default:
        return 'Time to save towards your goal!';
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
