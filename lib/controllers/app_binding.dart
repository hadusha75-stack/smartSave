import 'package:get/get.dart';

import 'auth_controller.dart';
import 'goal_controller.dart';
import 'transaction_controller.dart';
import 'reminder_controller.dart';
import 'tip_controller.dart';
import 'feedback_controller.dart';
import 'settings_controller.dart';

/// Registers all controllers when the app starts.
/// Controllers are lazy-loaded (created on first use) except
/// [AuthController] and [SettingsController] which are needed immediately.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Permanent = survive route changes; created immediately.
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);

    // Lazy = created only when first accessed.
    Get.lazyPut<GoalController>(() => GoalController(), fenix: true);
    Get.lazyPut<TransactionController>(() => TransactionController(), fenix: true);
    Get.lazyPut<ReminderController>(() => ReminderController(), fenix: true);
    Get.lazyPut<TipController>(() => TipController(), fenix: true);
    Get.lazyPut<FeedbackController>(() => FeedbackController(), fenix: true);
  }
}
