// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SaveSmart';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Create Account';

  @override
  String get logout => 'Log Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get name => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get invalidEmail => 'Please enter a valid email address.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String minLength(int count) {
    return 'Must be at least $count characters.';
  }

  @override
  String get home => 'Home';

  @override
  String get goals => 'Goals';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get myGoals => 'My Goals';

  @override
  String get addGoal => 'New Goal';

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get deleteGoal => 'Delete Goal';

  @override
  String get archiveGoal => 'Archive Goal';

  @override
  String get goalTitle => 'Goal Title';

  @override
  String get targetAmount => 'Target Amount';

  @override
  String get currentAmount => 'Current Savings';

  @override
  String get deadline => 'Deadline';

  @override
  String get category => 'Category';

  @override
  String get goalDeleted => 'Goal deleted.';

  @override
  String get goalArchived => 'Goal archived.';

  @override
  String get goalCompleted => 'Goal completed! 🎉';

  @override
  String get noGoals =>
      'No savings goals yet.\nTap + to create your first goal!';

  @override
  String get cat_school_fees => 'School Fees';

  @override
  String get cat_phone => 'Phone';

  @override
  String get cat_laptop => 'Laptop';

  @override
  String get cat_emergency_fund => 'Emergency Fund';

  @override
  String get cat_business => 'Business';

  @override
  String get cat_wedding => 'Wedding';

  @override
  String get cat_other => 'Other';

  @override
  String get addSaving => 'Record Saving';

  @override
  String get editSaving => 'Edit Saving';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note (optional)';

  @override
  String get savedIn => 'Saved In';

  @override
  String get savingAdded => 'Saving recorded.';

  @override
  String get savingUpdated => 'Saving updated.';

  @override
  String get savingDeleted => 'Saving deleted.';

  @override
  String get progress => 'Progress';

  @override
  String get streak => 'Streak';

  @override
  String streakDays(int count) {
    return '$count periods';
  }

  @override
  String get badge25 => '25% Milestone 🌱';

  @override
  String get badge50 => 'Halfway There 🌿';

  @override
  String get badge75 => 'Almost Done 🌳';

  @override
  String get badge100 => 'Goal Achieved 🏆';

  @override
  String get noBadges => 'Keep saving to earn your first badge!';

  @override
  String get planDaily => 'Daily plan';

  @override
  String get planWeekly => 'Weekly plan';

  @override
  String get planMonthly => 'Monthly plan';

  @override
  String behindSchedule(String amount, String suggestion) {
    return 'You are $amount behind plan. Saving $suggestion a week puts you back on track.';
  }

  @override
  String get onTrack => 'You are on track! Keep it up.';

  @override
  String projectedCompletion(String date) {
    return 'Projected completion: $date';
  }

  @override
  String get reminders => 'Reminders';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get reminderFrequency => 'Frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get reminderWeekday => 'Day of Week';

  @override
  String get reminderSaved => 'Reminder saved.';

  @override
  String get reminderDeleted => 'Reminder deleted.';

  @override
  String get tips => 'Saving Tips';

  @override
  String get noTips => 'No tips yet.';

  @override
  String get latestTip => 'Tip of the Day';

  @override
  String get feedback => 'Send Feedback';

  @override
  String get feedbackMessage => 'Your message';

  @override
  String get feedbackSent => 'Thank you! Your feedback was sent.';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get notificationSettings => 'Notifications';

  @override
  String get onboarding1Title => 'Track Your Savings';

  @override
  String get onboarding1Body =>
      'Set a goal and record every birr you save — in your bank, wallet, or at home.';

  @override
  String get onboarding2Title => 'Stay on Plan';

  @override
  String get onboarding2Body =>
      'See exactly how much to save each day, week, or month to reach your goal on time.';

  @override
  String get onboarding3Title => 'Celebrate Progress';

  @override
  String get onboarding3Body =>
      'Earn badges, build streaks, and celebrate every milestone on the way to your goal.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorOffline =>
      'You are offline. Changes will sync when you reconnect.';

  @override
  String get errorPermission => 'You do not have permission to do this.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading…';

  @override
  String get noData => 'No data yet.';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';
}
