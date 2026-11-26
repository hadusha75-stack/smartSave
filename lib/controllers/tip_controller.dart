import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:savesmart/core/constants/app_constants.dart';
import 'package:savesmart/features/tips/domain/models/tip.dart';

/// GetX controller for saving tips.
class TipController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Latest tip for the home screen banner.
  final Rxn<Tip> latestTip = Rxn<Tip>();

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _db
        .collection(AppConstants.tipsCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      latestTip.value =
          snap.docs.isEmpty ? null : Tip.fromFirestore(snap.docs.first);
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
