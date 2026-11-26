import 'package:cloud_firestore/cloud_firestore.dart';

/// A single saving record stored at
/// users/{uid}/goals/{goalId}/transactions/{txId}.
class SavingTransaction {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;
  final String savedIn; // Bank, Mobile wallet, Cash at home, Savings group, Other
  final DateTime createdAt;

  const SavingTransaction({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    required this.savedIn,
    required this.createdAt,
  });

  // ── Firestore serialization ───────────────────────────────────────────────

  factory SavingTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SavingTransaction(
      id: doc.id,
      goalId: data['goalId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
      savedIn: data['savedIn'] as String? ?? 'Other',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'goalId': goalId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      if (note != null && note!.isNotEmpty) 'note': note,
      'savedIn': savedIn,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SavingTransaction copyWith({
    double? amount,
    DateTime? date,
    String? note,
    String? savedIn,
  }) {
    return SavingTransaction(
      id: id,
      goalId: goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      savedIn: savedIn ?? this.savedIn,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingTransaction && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
