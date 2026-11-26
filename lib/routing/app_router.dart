import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/features/auth/presentation/screens/login_screen.dart';
import 'package:savesmart/features/auth/presentation/screens/register_screen.dart';
import 'package:savesmart/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:savesmart/features/home/presentation/screens/home_screen.dart';
import 'package:savesmart/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:savesmart/features/goals/presentation/screens/create_edit_goal_screen.dart';
import 'package:savesmart/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:savesmart/features/transactions/presentation/screens/add_edit_saving_screen.dart';
import 'package:savesmart/features/transactions/presentation/screens/all_history_screen.dart';
import 'package:savesmart/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:savesmart/features/progress/presentation/screens/progress_screen.dart';
import 'package:savesmart/features/settings/presentation/screens/settings_screen.dart';
import 'package:savesmart/features/feedback/presentation/screens/feedback_screen.dart';

/// Named route strings.
class AppRoutes {
  AppRoutes._();
  static const splash       = '/';
  static const onboarding   = '/onboarding';
  static const login        = '/login';
  static const register     = '/register';
  static const forgotPass   = '/forgot-password';
  static const home         = '/home';
  static const createGoal   = '/goals/new';
  static const editGoal     = '/goals/edit';    // pass goalId as argument
  static const goalDetail   = '/goals/detail';  // pass goalId as argument
  static const addSaving    = '/savings/new';   // pass goalId as argument
  static const editSaving   = '/savings/edit';  // pass goalId + txId as args
  static const allHistory   = '/history';
  static const reminders    = '/reminders';     // pass goalId as argument
  static const progress     = '/progress';      // pass goalId as argument
  static const settings     = '/settings';
  static const feedback     = '/feedback';
}

/// Middleware that blocks logged-out users from protected routes.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (auth.firebaseUser.value == null) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

class AppRouter {
  AppRouter._();

  static final pages = <GetPage>[
    // ── Splash ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),

    // ── Auth screens (no middleware) ──────────────────────────────────────
    GetPage(name: AppRoutes.onboarding,  page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.login,       page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register,    page: () => const RegisterScreen()),
    GetPage(name: AppRoutes.forgotPass,  page: () => const ForgotPasswordScreen()),

    // ── Protected screens (require login) ─────────────────────────────────
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createGoal,
      page: () => const CreateEditGoalScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editGoal,
      page: () => CreateEditGoalScreen(goalId: Get.arguments as String?),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.goalDetail,
      page: () => GoalDetailScreen(goalId: Get.arguments as String),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.addSaving,
      page: () => AddEditSavingScreen(goalId: Get.arguments as String),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editSaving,
      page: () {
        final args = Get.arguments as Map<String, String>;
        return AddEditSavingScreen(
          goalId: args['goalId']!,
          transactionId: args['txId'],
        );
      },
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.allHistory,
      page: () => const AllHistoryScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.reminders,
      page: () => RemindersScreen(goalId: Get.arguments as String),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.progress,
      page: () => ProgressScreen(goalId: Get.arguments as String),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.feedback,
      page: () => const FeedbackScreen(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}

// ── Splash page ───────────────────────────────────────────────────────────────
/// Decides where to go on startup.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final auth = Get.find<AuthController>();

    // Wait one frame for auth to settle
    await Future.delayed(const Duration(milliseconds: 100));

    if (auth.firebaseUser.value != null) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    final seen = await hasSeenOnboarding();
    Get.offAllNamed(seen ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withAlpha(26),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.savings_rounded,
                  size: 56, color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              'SaveSmart',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your savings, your goals',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary.withAlpha(204),
                  ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.onPrimary.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
