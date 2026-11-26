import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/extensions/datetime_extensions.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

/// All savings-plan business logic in one place.
///
/// Every formula here matches the specification exactly:
///
///   requiredPerPeriod  = (target - current) / periodsLeft
///   expectedByToday    = target × (daysElapsed / totalDays)
///   behindAmount       = max(0, expectedByToday - current)
///   progressPercent    = (current / target) × 100
///   projectedCompletion= today + (remaining / avgPerDay30)
///
/// This class is pure (no Flutter / Firebase imports) so it can be
/// tested easily with plain Dart unit tests.
class SavingsCalculator {
  SavingsCalculator._(); // static-only utility class

  // ── Core calculations ─────────────────────────────────────────────────────

  /// How much the user needs to save per period to reach [target] by [deadline].
  ///
  /// [current]   – amount already saved
  /// [frequency] – 'daily', 'weekly', or 'monthly'
  static double requiredPerPeriod({
    required double target,
    required double current,
    required DateTime deadline,
    required DateTime today,
    required String frequency,
  }) {
    final remaining = (target - current).clamp(0, double.infinity).toDouble();
    if (remaining == 0) return 0;

    final periodsLeft = _periodsLeft(
      frequency: frequency,
      deadline: deadline,
      today: today,
    );
    if (periodsLeft <= 0) return remaining; // deadline passed → show full amount
    return remaining / periodsLeft;
  }

  /// Expected amount saved by [today] if the user were on track.
  static double expectedSavedByToday({
    required double target,
    required DateTime createdAt,
    required DateTime deadline,
    required DateTime today,
  }) {
    final totalDays = createdAt.daysUntil(deadline);
    if (totalDays <= 0) return target;
    final elapsed = createdAt.daysUntil(today).clamp(0, totalDays);
    return target * (elapsed / totalDays);
  }

  /// How far behind the user is compared to the ideal pace.
  static double behindAmount({
    required double target,
    required double current,
    required DateTime createdAt,
    required DateTime deadline,
    required DateTime today,
  }) {
    final expected = expectedSavedByToday(
      target: target,
      createdAt: createdAt,
      deadline: deadline,
      today: today,
    );
    return (expected - current).clamp(0, double.infinity).toDouble();
  }

  /// Projected completion date based on average daily savings over last 30 days.
  /// Returns null if no savings have been recorded or average is zero.
  static DateTime? projectedCompletionDate({
    required double target,
    required double current,
    required DateTime today,
    required List<SavingTransaction> recentTransactions,
  }) {
    if (current >= target) return today; // already done
    final avgPerDay = _averageDailyAmount(
      transactions: recentTransactions,
      today: today,
      days: AppConstants.projectionDays,
    );
    if (avgPerDay <= 0) return null;
    final daysNeeded = ((target - current) / avgPerDay).ceil();
    return today.add(Duration(days: daysNeeded));
  }

  /// Progress as a percentage 0–100.
  static double progressPercent({
    required double target,
    required double current,
  }) {
    if (target <= 0) return 0;
    return (current / target * 100).clamp(0, 100).toDouble();
  }

  /// Which milestones (from [AppConstants.milestones]) have been crossed.
  static List<int> crossedMilestones({required double target, required double current}) {
    final pct = progressPercent(target: target, current: current);
    return AppConstants.milestones.where((m) => pct >= m).toList();
  }

  // ── Streak logic ──────────────────────────────────────────────────────────

  /// Whether the user met the plan in the current period.
  ///
  /// We check whether the total saved since the start of the current period
  /// is at least [plannedAmount].
  static bool metPlanThisPeriod({
    required String frequency,
    required double plannedAmount,
    required DateTime today,
    required List<SavingTransaction> transactions,
  }) {
    final periodStart = _currentPeriodStart(frequency: frequency, today: today);
    final savedThisPeriod = transactions
        .where((t) => !t.date.isBefore(periodStart) && !t.date.isAfter(today))
        .fold<double>(0, (sum, t) => sum + t.amount);
    return savedThisPeriod >= plannedAmount;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static double _averageDailyAmount({
    required List<SavingTransaction> transactions,
    required DateTime today,
    required int days,
  }) {
    final cutoff = today.subtract(Duration(days: days));
    final recent = transactions.where((t) => t.date.isAfter(cutoff));
    final total = recent.fold<double>(0, (sum, t) => sum + t.amount);
    return total / days;
  }

  static double _periodsLeft({
    required String frequency,
    required DateTime deadline,
    required DateTime today,
  }) {
    final daysLeft = today.daysUntil(deadline).clamp(0, double.infinity);
    switch (frequency) {
      case AppConstants.freqDaily:
        return daysLeft.toDouble();
      case AppConstants.freqWeekly:
        return (daysLeft / 7).ceilToDouble();
      case AppConstants.freqMonthly:
        // Count remaining calendar months (at least 1 if any days left)
        if (daysLeft == 0) return 0;
        int months = (deadline.year - today.year) * 12 +
            (deadline.month - today.month);
        if (deadline.day < today.day) months--;
        return months.clamp(1, double.infinity).toDouble();
      default:
        return daysLeft.toDouble();
    }
  }

  static DateTime _currentPeriodStart({
    required String frequency,
    required DateTime today,
  }) {
    switch (frequency) {
      case AppConstants.freqDaily:
        return today.startOfDay;
      case AppConstants.freqWeekly:
        return today.startOfWeek;
      case AppConstants.freqMonthly:
        return today.startOfMonth;
      default:
        return today.startOfDay;
    }
  }
}
