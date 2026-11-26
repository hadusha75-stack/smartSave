import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/errors/app_error.dart';
import 'package:savesmart/features/reminders/domain/models/reminder.dart';
import 'package:savesmart/services/notification_service.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class ReminderRepository {
  final FirebaseFirestore _db;
  final String uid;
  ReminderRepository({
    required FirebaseFirestore firestore,
    required this.uid,
  }) : _db = firestore;

  // ── Path helper ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _remRef(String goalId) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.goalsCollection)
      .doc(goalId)
      .collection(AppConstants.remindersCollection);

  // ── Watch ─────────────────────────────────────────────────────────────────

  Stream<List<Reminder>> watchReminders(String goalId) {
    if (uid.isEmpty) return Stream.value([]);
    return _remRef(goalId).snapshots().map((s) => s.docs
        .map((d) => Reminder.fromFirestore(d))
        .toList());
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Create a reminder, store it in Firestore, and schedule the local
  /// notification. Returns the new reminder id.
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
    if (uid.isEmpty) throw const AppError(message: 'Not logged in.');
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

      // 1. Write to Firestore
      await _remRef(goalId).doc(id).set(reminder.toFirestore());

      // 2. Schedule local notification
      final notifId = _notifId(id);
      final body = _buildBody(
          frequency: frequency,
          amount: weeklyPlanAmount,
          currency: currency);
      await _schedule(
        notifId: notifId,
        title: 'SaveSmart – $goalTitle',
        body: body,
        reminder: reminder,
      );

      return id;
    } catch (e) {
      throw AppError.from(e);
    }
  }

  // ── Toggle active ─────────────────────────────────────────────────────────

  /// Enable or disable a reminder. When disabled the local notification is
  /// cancelled; when re-enabled it is re-scheduled.
  Future<void> setActive({
    required String goalId,
    required String reminderId,
    required bool active,
    required String goalTitle,
    required double weeklyPlanAmount,
    required String currency,
  }) async {
    try {
      await _remRef(goalId).doc(reminderId).update({'active': active});

      final notifId = _notifId(reminderId);
      if (!active) {
        await NotificationService.cancelReminder(notifId);
      } else {
        // Re-read the reminder to re-schedule it
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
    } catch (e) {
      throw AppError.from(e);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteReminder({
    required String goalId,
    required String reminderId,
  }) async {
    try {
      await _remRef(goalId).doc(reminderId).delete();
      await NotificationService.cancelReminder(_notifId(reminderId));
    } catch (e) {
      throw AppError.from(e);
    }
  }

  // ── Reschedule all active reminders ──────────────────────────────────────
  // Called on app startup in case the device was restarted.

  Future<void> rescheduleAll({
    required String goalId,
    required String goalTitle,
    required double weeklyPlanAmount,
    required String currency,
  }) async {
    if (uid.isEmpty) return;
    try {
      final snap = await _remRef(goalId).where('active', isEqualTo: true).get();
      for (final doc in snap.docs) {
        final reminder = Reminder.fromFirestore(doc);
        final notifId = _notifId(reminder.id);
        final body = _buildBody(
            frequency: reminder.frequency,
            amount: weeklyPlanAmount,
            currency: currency);
        await _schedule(
            notifId: notifId,
            title: 'SaveSmart – $goalTitle',
            body: body,
            reminder: reminder);
      }
    } catch (_) {
      // Best-effort; don't crash the app
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Convert a UUID reminder id to a stable int notification id.
  /// We take the first 8 hex chars of the UUID and parse as int.
  int _notifId(String reminderId) {
    final hex = reminderId.replaceAll('-', '').substring(0, 8);
    return int.parse(hex, radix: 16) & 0x7FFFFFFF; // keep positive
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
        break;
      case AppConstants.freqWeekly:
        await NotificationService.scheduleWeeklyReminder(
          notificationId: notifId,
          title: title,
          body: body,
          weekday: reminder.weekday ?? DateTime.monday,
          hour: reminder.hourOfDay,
          minute: reminder.minute,
        );
        break;
      case AppConstants.freqMonthly:
        await NotificationService.scheduleMonthlyReminder(
          notificationId: notifId,
          title: title,
          body: body,
          dayOfMonth: reminder.dayOfMonth ?? 1,
          hour: reminder.hourOfDay,
          minute: reminder.minute,
        );
        break;
    }
  }

  String _buildBody({
    required String frequency,
    required double amount,
    required String currency,
  }) {
    // Format amount with commas, no decimals for ETB
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
}
