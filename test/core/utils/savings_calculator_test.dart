// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/core/utils/savings_calculator.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

/// Unit tests for all business-logic formulas in [SavingsCalculator].
/// Run with: flutter test test/core/utils/savings_calculator_test.dart
void main() {
  // ── Shared fixtures ──────────────────────────────────────────────────────
  final today = DateTime(2024, 6, 15);
  final createdAt = DateTime(2024, 1, 1);
  final deadline = DateTime(2024, 12, 31);

  SavingTransaction tx(double amount, DateTime date) => SavingTransaction(
        id: 'tx',
        goalId: 'g1',
        amount: amount,
        date: date,
        savedIn: 'Cash at home',
        createdAt: date,
      );

  // ── progressPercent ──────────────────────────────────────────────────────
  group('progressPercent', () {
    test('returns 0 when nothing saved', () {
      expect(
        SavingsCalculator.progressPercent(target: 10000, current: 0),
        0.0,
      );
    });

    test('returns 50 when half saved', () {
      expect(
        SavingsCalculator.progressPercent(target: 10000, current: 5000),
        50.0,
      );
    });

    test('clamps to 100 when over-saved', () {
      expect(
        SavingsCalculator.progressPercent(target: 10000, current: 12000),
        100.0,
      );
    });

    test('returns 0 when target is 0', () {
      expect(
        SavingsCalculator.progressPercent(target: 0, current: 500),
        0.0,
      );
    });
  });

  // ── requiredPerPeriod ────────────────────────────────────────────────────
  group('requiredPerPeriod', () {
    test('daily: divides remaining by days left', () {
      // Remaining = 8,000; days left = deadline - today
      final result = SavingsCalculator.requiredPerPeriod(
        target: 10000,
        current: 2000,
        deadline: deadline,
        today: today,
        frequency: AppConstants.freqDaily,
      );
      // days from Jun 15 to Dec 31 = 199
      expect(result, closeTo(8000 / 199, 0.5));
    });

    test('weekly: divides remaining by weeks left', () {
      final result = SavingsCalculator.requiredPerPeriod(
        target: 10000,
        current: 2000,
        deadline: deadline,
        today: today,
        frequency: AppConstants.freqWeekly,
      );
      // 199 days → ceil(199/7) = 29 weeks
      expect(result, closeTo(8000 / 29, 1.0));
    });

    test('returns remaining when deadline already passed', () {
      final past = DateTime(2024, 1, 1); // before today
      final result = SavingsCalculator.requiredPerPeriod(
        target: 10000,
        current: 2000,
        deadline: past,
        today: today,
        frequency: AppConstants.freqDaily,
      );
      expect(result, 8000);
    });

    test('returns 0 when already reached target', () {
      final result = SavingsCalculator.requiredPerPeriod(
        target: 10000,
        current: 10000,
        deadline: deadline,
        today: today,
        frequency: AppConstants.freqDaily,
      );
      expect(result, 0.0);
    });
  });

  // ── expectedSavedByToday ─────────────────────────────────────────────────
  group('expectedSavedByToday', () {
    test('proportional to elapsed time', () {
      // total days = Jan 1 to Dec 31 = 365
      // elapsed   = Jan 1 to Jun 15 = 166
      final result = SavingsCalculator.expectedSavedByToday(
        target: 36500,
        createdAt: createdAt,
        deadline: deadline,
        today: today,
      );
      expect(result, closeTo(36500 * (166 / 365), 1.0));
    });

    test('returns target when today >= deadline', () {
      final result = SavingsCalculator.expectedSavedByToday(
        target: 10000,
        createdAt: createdAt,
        deadline: DateTime(2024, 1, 1),
        today: today,
      );
      expect(result, 10000);
    });
  });

  // ── behindAmount ─────────────────────────────────────────────────────────
  group('behindAmount', () {
    test('zero when ahead of schedule', () {
      final result = SavingsCalculator.behindAmount(
        target: 10000,
        current: 9000, // saved a lot
        createdAt: createdAt,
        deadline: deadline,
        today: today,
      );
      expect(result, 0.0);
    });

    test('positive when behind schedule', () {
      final result = SavingsCalculator.behindAmount(
        target: 10000,
        current: 0, // saved nothing
        createdAt: createdAt,
        deadline: deadline,
        today: today,
      );
      expect(result, greaterThan(0));
    });
  });

  // ── projectedCompletionDate ──────────────────────────────────────────────
  group('projectedCompletionDate', () {
    test('returns null when no savings recorded', () {
      final result = SavingsCalculator.projectedCompletionDate(
        target: 10000,
        current: 0,
        today: today,
        recentTransactions: [],
      );
      expect(result, isNull);
    });

    test('returns today when already complete', () {
      final result = SavingsCalculator.projectedCompletionDate(
        target: 10000,
        current: 10000,
        today: today,
        recentTransactions: [],
      );
      expect(result, today);
    });

    test('projects correctly with consistent daily savings', () {
      // Save 100/day for 30 days → average = 100/day
      final transactions = List.generate(
        30,
        (i) => tx(100, today.subtract(Duration(days: 30 - i))),
      );
      // remaining = 10000 - 3000 = 7000; at 100/day → 70 more days
      final result = SavingsCalculator.projectedCompletionDate(
        target: 10000,
        current: 3000,
        today: today,
        recentTransactions: transactions,
      );
      expect(result, isNotNull);
      // Should be approximately today + 70 days.
      // Allow a few days tolerance because ceiling rounding and
      // the 30-day average window can shift the result slightly.
      final expectedDate = today.add(const Duration(days: 70));
      expect(
        result!.difference(expectedDate).inDays.abs(),
        lessThanOrEqualTo(3),
      );
    });
  });

  // ── crossedMilestones ────────────────────────────────────────────────────
  group('crossedMilestones', () {
    test('returns empty when below 25%', () {
      expect(
        SavingsCalculator.crossedMilestones(target: 1000, current: 100),
        isEmpty,
      );
    });

    test('returns [25] when between 25% and 50%', () {
      expect(
        SavingsCalculator.crossedMilestones(target: 1000, current: 300),
        [25],
      );
    });

    test('returns all milestones when complete', () {
      expect(
        SavingsCalculator.crossedMilestones(target: 1000, current: 1000),
        [25, 50, 75, 100],
      );
    });
  });

  // ── metPlanThisPeriod ────────────────────────────────────────────────────
  group('metPlanThisPeriod', () {
    test('true when saved enough today', () {
      final result = SavingsCalculator.metPlanThisPeriod(
        frequency: AppConstants.freqDaily,
        plannedAmount: 100,
        today: today,
        transactions: [tx(150, today)],
      );
      expect(result, isTrue);
    });

    test('false when saved less than plan', () {
      final result = SavingsCalculator.metPlanThisPeriod(
        frequency: AppConstants.freqDaily,
        plannedAmount: 100,
        today: today,
        transactions: [tx(50, today)],
      );
      expect(result, isFalse);
    });

    test('false when no savings this period', () {
      final result = SavingsCalculator.metPlanThisPeriod(
        frequency: AppConstants.freqDaily,
        plannedAmount: 100,
        today: today,
        transactions: [tx(200, today.subtract(const Duration(days: 1)))],
      );
      expect(result, isFalse);
    });
  });
}
