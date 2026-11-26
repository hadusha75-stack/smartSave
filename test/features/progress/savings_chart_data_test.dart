// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/core/utils/savings_calculator.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

/// Helper: build a SavingTransaction for testing
SavingTransaction tx(double amount, DateTime date) => SavingTransaction(
      id: 'tx_${date.millisecondsSinceEpoch}',
      goalId: 'g1',
      amount: amount,
      date: date,
      savedIn: 'Bank',
      createdAt: date,
    );

/// Simulates the chart data-building used in _SavingsChart:
/// sorts transactions oldest-first and builds a cumulative total per day.
Map<DateTime, double> buildCumulativeByDay(
    List<SavingTransaction> transactions) {
  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
  final Map<DateTime, double> result = {};
  double running = 0;
  for (final t in sorted) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    running += t.amount;
    result[day] = running;
  }
  return result;
}

void main() {
  final base = DateTime(2024, 6, 1);

  group('Chart cumulative data', () {
    test('empty transactions produce empty map', () {
      expect(buildCumulativeByDay([]), isEmpty);
    });

    test('single transaction produces one entry', () {
      final result = buildCumulativeByDay([tx(500, base)]);
      expect(result.length, 1);
      expect(result.values.first, 500);
    });

    test('multiple days accumulate correctly', () {
      final transactions = [
        tx(1000, base),
        tx(500, base.add(const Duration(days: 1))),
        tx(200, base.add(const Duration(days: 3))),
      ];
      final result = buildCumulativeByDay(transactions);
      final days = result.keys.toList()..sort();

      expect(result[days[0]], 1000);
      expect(result[days[1]], 1500);
      expect(result[days[2]], 1700);
    });

    test('two transactions on same day accumulate into one entry', () {
      final transactions = [
        tx(300, base),
        tx(700, base), // same day
      ];
      final result = buildCumulativeByDay(transactions);
      expect(result.length, 1);
      expect(result.values.first, 1000);
    });

    test('transactions given out of order are sorted before accumulating', () {
      final transactions = [
        tx(200, base.add(const Duration(days: 2))), // later
        tx(1000, base),                              // earlier
      ];
      final result = buildCumulativeByDay(transactions);
      final days = result.keys.toList()..sort();
      // First cumulative point should be 1000 (from day 0)
      expect(result[days[0]], 1000);
      // Second should be 1200 (cumulative)
      expect(result[days[1]], 1200);
    });
  });

  group('Projected completion with real transactions', () {
    test('projects correctly when saving steadily', () {
      final today = DateTime(2024, 7, 1);
      final transactions = List.generate(
        30,
        (i) => tx(200, today.subtract(Duration(days: 30 - i))),
      );
      final result = SavingsCalculator.projectedCompletionDate(
        target: 10000,
        current: 6000,
        today: today,
        recentTransactions: transactions,
      );
      // remaining = 4000, avg = 200/day → 20 more days
      expect(result, isNotNull);
      expect(result!.difference(today).inDays, closeTo(20, 1));
    });

    test('returns null when no recent transactions', () {
      expect(
        SavingsCalculator.projectedCompletionDate(
          target: 10000,
          current: 2000,
          today: DateTime.now(),
          recentTransactions: [],
        ),
        isNull,
      );
    });

    test('returns today when goal already complete', () {
      final today = DateTime(2024, 7, 1);
      final result = SavingsCalculator.projectedCompletionDate(
        target: 5000,
        current: 5000,
        today: today,
        recentTransactions: [],
      );
      expect(result, today);
    });
  });
}
