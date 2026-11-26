import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savesmart/core/constants/app_constants.dart';

/// A savings goal stored at users/{uid}/goals/{goalId}.
class Goal {
  final String id;
  final String userId;
  final String title;
  final String category; // matches GoalCategory.id
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String status; // active, completed, archived
  final DateTime createdAt;
  final int streak; // consecutive periods where plan was met
  final DateTime? lastSavedAt;
  final String? colorHex; // optional user-chosen color, e.g. '#4CAF50'
  final String? iconName; // optional icon identifier
  // Tracks which milestones (25,50,75,100) have already been celebrated
  final List<int> achievedMilestones;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.streak,
    this.lastSavedAt,
    this.colorHex,
    this.iconName,
    this.achievedMilestones = const [],
  });

  bool get isActive => status == AppConstants.goalStatusActive;
  bool get isCompleted => status == AppConstants.goalStatusCompleted;
  bool get isArchived => status == AppConstants.goalStatusArchived;

  /// Progress as a value between 0.0 and 1.0.
  double get progressFraction =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Progress as a percentage 0–100.
  double get progressPercent => progressFraction * 100;

  // ── Firestore serialization ───────────────────────────────────────────────

  factory Goal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Goal(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0,
      deadline: (data['deadline'] as Timestamp).toDate(),
      status: data['status'] as String? ?? AppConstants.goalStatusActive,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      lastSavedAt: (data['lastSavedAt'] as Timestamp?)?.toDate(),
      colorHex: data['colorHex'] as String?,
      iconName: data['iconName'] as String?,
      achievedMilestones: List<int>.from(data['achievedMilestones'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'streak': streak,
      if (lastSavedAt != null) 'lastSavedAt': Timestamp.fromDate(lastSavedAt!),
      if (colorHex != null) 'colorHex': colorHex,
      if (iconName != null) 'iconName': iconName,
      'achievedMilestones': achievedMilestones,
    };
  }

  Goal copyWith({
    String? title,
    String? category,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? status,
    int? streak,
    DateTime? lastSavedAt,
    String? colorHex,
    String? iconName,
    List<int>? achievedMilestones,
  }) {
    return Goal(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt,
      streak: streak ?? this.streak,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Goal && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
