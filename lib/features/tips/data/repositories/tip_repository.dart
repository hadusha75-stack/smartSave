import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/features/tips/domain/models/tip.dart';

class TipRepository {
  final FirebaseFirestore _db;
  TipRepository({required FirebaseFirestore firestore}) : _db = firestore;

  Stream<Tip?> watchLatestTip() {
    return _db
        .collection(AppConstants.tipsCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : Tip.fromFirestore(
                s.docs.first as DocumentSnapshot<Map<String, dynamic>>));
  }

  Stream<List<Tip>> watchAllTips() {
    return _db
        .collection(AppConstants.tipsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                Tip.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }
}
