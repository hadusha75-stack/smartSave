// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/features/goals/domain/models/goal.dart';

Goal makeGoal({
  double target = 10000,
  double current = 0,
  String status = AppConstants.goalStatusActive,
  int streak = 0,
  List<int> milestones = const [],
}) =>
    Goal(
      id: 'g1',
      userId: 'u1',
      title: 'Test',
      category: 'other',
      targetAmount: target,
      currentAmount: current,
      deadline: DateTime(2025, 12, 31),
      status: status,
      createdAt: DateTime(2025, 1, 1),
      streak: streak,
      achievedMilestones: milestones,
    );

void main() {
  group('Goal.progressFraction', () {
    test('0 when nothing saved', () {
      expect(makeGoal(current: 0).progressFraction, 0.0);
    });

    test('0.5 when half saved', () {
      expect(makeGoal(current: 5000).progressFraction, 0.5);
    });

    test('clamps to 1.0 when over target', () {
      expect(makeGoal(current: 15000).progressFraction, 1.0);
    });
  });

  group('Goal.progressPercent', () {
    test('returns 75 when 75% saved', () {
      expect(makeGoal(current: 7500).progressPercent, 75.0);
    });
  });

  group('Goal status helpers', () {
    test('isActive true for active goal', () {
      expect(makeGoal(status: AppConstants.goalStatusActive).isActive, true);
    });

    test('isCompleted true for completed goal', () {
      expect(
          makeGoal(status: AppConstants.goalStatusCompleted).isCompleted, true);
    });

    test('isArchived true for archived goal', () {
      expect(
          makeGoal(status: AppConstants.goalStatusArchived).isArchived, true);
    });
  });

  group('Goal.copyWith', () {
    test('preserves unchanged fields', () {
      final g = makeGoal(target: 5000, streak: 3);
      final copy = g.copyWith(title: 'New name');
      expect(copy.title, 'New name');
      expect(copy.targetAmount, 5000);
      expect(copy.streak, 3);
      expect(copy.id, g.id);
    });
  });
}
