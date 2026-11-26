// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/features/transactions/domain/models/saving_transaction.dart';

void main() {
  group('SavingTransaction', () {
    test('copyWith preserves id and goalId', () {
      final tx = SavingTransaction(
        id: 'tx1',
        goalId: 'g1',
        amount: 500,
        date: DateTime(2024, 6, 15),
        savedIn: 'Bank',
        createdAt: DateTime(2024, 6, 15),
      );

      final copy = tx.copyWith(amount: 1000, savedIn: 'Cash at home');
      expect(copy.id, 'tx1');
      expect(copy.goalId, 'g1');
      expect(copy.amount, 1000);
      expect(copy.savedIn, 'Cash at home');
    });

    test('toFirestore includes all required fields', () {
      final tx = SavingTransaction(
        id: 'tx1',
        goalId: 'g1',
        amount: 250.50,
        date: DateTime(2024, 6, 15),
        note: 'Salary',
        savedIn: 'Bank',
        createdAt: DateTime(2024, 6, 15),
      );

      final map = tx.toFirestore();
      expect(map['goalId'], 'g1');
      expect(map['amount'], 250.50);
      expect(map['savedIn'], 'Bank');
      expect(map['note'], 'Salary');
      expect(map['date'], isNotNull);
      expect(map['createdAt'], isNotNull);
    });

    test('toFirestore omits empty note', () {
      final tx = SavingTransaction(
        id: 'tx1',
        goalId: 'g1',
        amount: 100,
        date: DateTime(2024, 6, 15),
        note: '',
        savedIn: 'Cash at home',
        createdAt: DateTime(2024, 6, 15),
      );

      final map = tx.toFirestore();
      expect(map.containsKey('note'), isFalse);
    });

    test('equality is based on id', () {
      final tx1 = SavingTransaction(
        id: 'tx1', goalId: 'g1', amount: 100,
        date: DateTime(2024, 1, 1), savedIn: 'Bank',
        createdAt: DateTime(2024, 1, 1),
      );
      final tx2 = SavingTransaction(
        id: 'tx1', goalId: 'g2', amount: 200,
        date: DateTime(2024, 2, 1), savedIn: 'Cash at home',
        createdAt: DateTime(2024, 2, 1),
      );
      expect(tx1, equals(tx2));
      expect(tx1.hashCode, tx2.hashCode);
    });
  });
}
