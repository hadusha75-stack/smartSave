import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:savesmart/routing/app_router.dart';

/// The key used in SharedPreferences to track if onboarding was completed.
const _onboardingKey = 'onboarding_complete';

/// Returns true if the user has already seen onboarding.
Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey) ?? false;
}

/// Marks onboarding as complete so it is never shown again.
Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingKey, true);
}

// ── Slide data ────────────────────────────────────────────────────────────────

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;
  final Color iconBg;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.iconBg,
  });
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.savings_rounded,
    title: 'Track Your Savings',
    body: 'Set a goal and record every birr you save — in your bank, mobile wallet, or at home. '
        'SaveSmart shows you exactly how far you have come.',
    iconBg: Color(0xFFE8F5E9),
  ),
  _OnboardingSlide(
    icon: Icons.trending_up_rounded,
    title: 'Stay on Plan',
    body: 'See exactly how much to save each day, week, or month to reach your goal on time. '
        'Get reminded when it is time to save.',
    iconBg: Color(0xFFE3F2FD),
  ),
  _OnboardingSlide(
    icon: Icons.emoji_events_rounded,
    title: 'Celebrate Progress',
    body: 'Earn milestone badges, build saving streaks, and see your progress on a chart. '
        'Your money stays in your hands — SaveSmart just keeps you motivated.',
    iconBg: Color(0xFFFFF8E1),
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingComplete();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ───────────────────────���────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),

            // ── Page view ──────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // ── Dots indicator ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // ── Action button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual slide widget ───────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: slide.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 80, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Body
          Text(
            slide.body,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

