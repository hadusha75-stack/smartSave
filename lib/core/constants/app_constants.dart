/// App-wide constants used across all features.
library;

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'SaveSmart';
  static const String appVersion = '1.0.0';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String goalsCollection = 'goals';
  static const String transactionsCollection = 'transactions';
  static const String remindersCollection = 'reminders';
  static const String tipsCollection = 'tips';
  static const String feedbackCollection = 'feedback';
  static const String categoriesCollection = 'categories';

  // User roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // User status
  static const String statusActive = 'active';
  static const String statusSuspended = 'suspended';

  // Goal status
  static const String goalStatusActive = 'active';
  static const String goalStatusCompleted = 'completed';
  static const String goalStatusArchived = 'archived';

  // Feedback status
  static const String feedbackStatusOpen = 'open';
  static const String feedbackStatusResolved = 'resolved';

  // Default currency
  static const String defaultCurrency = 'ETB';

  // Supported currencies
  static const List<String> supportedCurrencies = ['ETB', 'USD', 'EUR'];

  // Reminder frequency keys
  static const String freqDaily = 'daily';
  static const String freqWeekly = 'weekly';
  static const String freqMonthly = 'monthly';

  // "Saved in" options
  static const String savedInBank = 'Bank';
  static const String savedInWallet = 'Mobile wallet';
  static const String savedInCash = 'Cash at home';
  static const String savedInGroup = 'Savings group';
  static const String savedInOther = 'Other';

  static const List<String> savedInOptions = [
    savedInBank,
    savedInWallet,
    savedInCash,
    savedInGroup,
    savedInOther,
  ];

  // Milestone percentages
  static const List<int> milestones = [25, 50, 75, 100];

  // Pagination
  static const int pageSize = 20;

  // Streak: number of days considered for projected completion
  static const int projectionDays = 30;
}
