import 'package:flutter/material.dart';

/// Predefined goal categories with icons and colors.
class GoalCategory {
  final String id;
  final String nameKey; // localization key
  final IconData icon;
  final Color color;

  const GoalCategory({
    required this.id,
    required this.nameKey,
    required this.icon,
    required this.color,
  });
}

class GoalCategories {
  GoalCategories._();

  static const List<GoalCategory> defaults = [
    GoalCategory(
      id: 'school_fees',
      nameKey: 'cat_school_fees',
      icon: Icons.school_rounded,
      color: Color(0xFF2196F3),
    ),
    GoalCategory(
      id: 'phone',
      nameKey: 'cat_phone',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF9C27B0),
    ),
    GoalCategory(
      id: 'laptop',
      nameKey: 'cat_laptop',
      icon: Icons.laptop_rounded,
      color: Color(0xFF607D8B),
    ),
    GoalCategory(
      id: 'emergency_fund',
      nameKey: 'cat_emergency_fund',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFFF44336),
    ),
    GoalCategory(
      id: 'business',
      nameKey: 'cat_business',
      icon: Icons.storefront_rounded,
      color: Color(0xFFFF9800),
    ),
    GoalCategory(
      id: 'wedding',
      nameKey: 'cat_wedding',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE91E63),
    ),
    GoalCategory(
      id: 'other',
      nameKey: 'cat_other',
      icon: Icons.savings_rounded,
      color: Color(0xFF4CAF50),
    ),
  ];

  static GoalCategory? findById(String id) {
    try {
      return defaults.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
