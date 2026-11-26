import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savesmart/core/constants/app_constants.dart';

/// A per-goal reminder stored at
/// users/{uid}/goals/{goalId}/reminders/{reminderId}.
class Reminder {
  final String id;
  final String goalId;
  final String frequency; // daily, weekly, monthly
  final int? weekday; // 1=Mon … 7=Sun, only used when frequency == weekly
  final int? dayOfMonth; // 1–28, only used when frequency == monthly
  final int hourOfDay; // 0–23
  final int minute; // 0–59
  final bool active;

  const Reminder({
    required this.id,
    required this.goalId,
    required this.frequency,
    this.weekday,
    this.dayOfMonth,
    required this.hourOfDay,
    required this.minute,
    required this.active,
  });

  bool get isDaily => frequency == AppConstants.freqDaily;
  bool get isWeekly => frequency == AppConstants.freqWeekly;
  bool get isMonthly => frequency == AppConstants.freqMonthly;

  // ── Firestore serialization ───────────────────────────────────────────────

  factory Reminder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Reminder(
      id: doc.id,
      goalId: data['goalId'] as String? ?? '',
      frequency: data['frequency'] as String? ?? AppConstants.freqDaily,
      weekday: data['weekday'] as int?,
      dayOfMonth: data['dayOfMonth'] as int?,
      hourOfDay: (data['hourOfDay'] as num?)?.toInt() ?? 8,
      minute: (data['minute'] as num?)?.toInt() ?? 0,
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'goalId': goalId,
      'frequency': frequency,
      if (weekday != null) 'weekday': weekday,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      'hourOfDay': hourOfDay,
      'minute': minute,
      'active': active,
    };
  }

  Reminder copyWith({
    String? frequency,
    int? weekday,
    int? dayOfMonth,
    int? hourOfDay,
    int? minute,
    bool? active,
  }) {
    return Reminder(
      id: id,
      goalId: goalId,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      minute: minute ?? this.minute,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reminder && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
