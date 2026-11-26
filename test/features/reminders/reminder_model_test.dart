// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/features/reminders/domain/models/reminder.dart';

Reminder makeReminder({
  String frequency = AppConstants.freqDaily,
  int hourOfDay = 8,
  int minute = 0,
  bool active = true,
  int? weekday,
  int? dayOfMonth,
}) =>
    Reminder(
      id: 'rem_01',
      goalId: 'g1',
      frequency: frequency,
      hourOfDay: hourOfDay,
      minute: minute,
      active: active,
      weekday: weekday,
      dayOfMonth: dayOfMonth,
    );

void main() {
  group('Reminder frequency helpers', () {
    test('isDaily true for daily reminder', () {
      expect(makeReminder(frequency: AppConstants.freqDaily).isDaily, isTrue);
    });

    test('isWeekly true for weekly reminder', () {
      expect(makeReminder(frequency: AppConstants.freqWeekly).isWeekly, isTrue);
    });

    test('isMonthly true for monthly reminder', () {
      expect(
          makeReminder(frequency: AppConstants.freqMonthly).isMonthly, isTrue);
    });
  });

  group('Reminder.copyWith', () {
    test('preserves unchanged fields', () {
      final r = makeReminder(hourOfDay: 9, minute: 30);
      final copy = r.copyWith(active: false);
      expect(copy.active, isFalse);
      expect(copy.hourOfDay, 9);
      expect(copy.minute, 30);
      expect(copy.id, r.id);
    });

    test('updates weekday', () {
      final r = makeReminder(
          frequency: AppConstants.freqWeekly, weekday: DateTime.monday);
      final copy = r.copyWith(weekday: DateTime.friday);
      expect(copy.weekday, DateTime.friday);
    });
  });
}
