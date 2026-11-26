// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tigrinya (`ti`).
class AppLocalizationsTi extends AppLocalizations {
  AppLocalizationsTi([String locale = 'ti']) : super(locale);

  @override
  String get appName => 'SaveSmart';

  @override
  String get login => 'እቶ';

  @override
  String get register => 'ሕሳብ ፍጠር';

  @override
  String get logout => 'ውጽእ';

  @override
  String get email => 'ኢሜይል';

  @override
  String get password => 'ሕቡእ ቃል';

  @override
  String get forgotPassword => 'ሕቡእ ቃልካ ረሲዕካ?';

  @override
  String get resetPassword => 'ሕቡእ ቃል ዳግም ጀምር';

  @override
  String get resetPasswordSent => 'ኢሜይል ተሰዲዱ። ሳጥንካ ርአ።';

  @override
  String get name => 'ምሉእ ስም';

  @override
  String get confirmPassword => 'ሕቡእ ቃል ኣረጋግጽ';

  @override
  String get passwordMismatch => 'ሕቡኣት ቃላት ኣይሰማምዑን።';

  @override
  String get invalidEmail => 'ቅኑዕ ኢሜይል ኣድራሻ ኣእቱ።';

  @override
  String get fieldRequired => 'እዚ መስኮት ግድን እዩ።';

  @override
  String minLength(int count) {
    return 'ቢውሕዱ $count ፊደላት ክህሉ ኣለዎ።';
  }

  @override
  String get home => 'ቤት';

  @override
  String get goals => 'ሸቶታት';

  @override
  String get history => 'ታሪኽ';

  @override
  String get settings => 'ቅምጥት';

  @override
  String get profile => 'ፕሮፋይል';

  @override
  String get myGoals => 'ሸቶታተይ';

  @override
  String get addGoal => 'ሓድሽ ሸቶ';

  @override
  String get editGoal => 'ሸቶ ኣርትዕ';

  @override
  String get deleteGoal => 'ሸቶ ሰርዝ';

  @override
  String get archiveGoal => 'ሸቶ ኣሪካይቭ';

  @override
  String get goalTitle => 'ስም ሸቶ';

  @override
  String get targetAmount => 'ዕላማ መጠን';

  @override
  String get currentAmount => 'ሕጂ ዝተቐደሰ';

  @override
  String get deadline => 'ናይ መወዳእታ ዕለት';

  @override
  String get category => 'ዓይነት';

  @override
  String get goalDeleted => 'ሸቶ ተሰሪዙ።';

  @override
  String get goalArchived => 'ሸቶ ናብ ማህደር ተዛዊሩ።';

  @override
  String get goalCompleted => 'ሸቶ ተሳኺዑ! 🎉';

  @override
  String get noGoals => 'ሸቶታት ቁጠባ ሕጂ የለን።\nፕሉስ ጠቕሊልካ መጀመሪያ ሸቶኻ ፍጠር!';

  @override
  String get cat_school_fees => 'ናይ ትምህርቲ ክፍሊት';

  @override
  String get cat_phone => 'ስልኪ';

  @override
  String get cat_laptop => 'ላፕቶፕ';

  @override
  String get cat_emergency_fund => 'ህጹጽ ፈንድ';

  @override
  String get cat_business => 'ንግዲ';

  @override
  String get cat_wedding => 'ሰርግ';

  @override
  String get cat_other => 'ካልእ';

  @override
  String get addSaving => 'ቁጠባ ኣእቱ';

  @override
  String get editSaving => 'ቁጠባ ኣርትዕ';

  @override
  String get amount => 'መጠን';

  @override
  String get date => 'ዕለት';

  @override
  String get note => 'ሓሳብ (ምርጫ)';

  @override
  String get savedIn => 'ዝተቐደሰሉ';

  @override
  String get savingAdded => 'ቁጠባ ተመዝጊቡ።';

  @override
  String get savingUpdated => 'ቁጠባ ተሓዲሱ።';

  @override
  String get savingDeleted => 'ቁጠባ ተሰሪዙ።';

  @override
  String get progress => 'ምምሕዳር';

  @override
  String get streak => 'ተኸታታሊ';

  @override
  String streakDays(int count) {
    return '$count ወቅቲ';
  }

  @override
  String get badge25 => '25% ተወቒዑ 🌱';

  @override
  String get badge50 => 'ፍርቂ ብጽሒቱ 🌿';

  @override
  String get badge75 => 'ቀረባ ወዲኡ 🌳';

  @override
  String get badge100 => 'ሸቶ ተሳኺዑ 🏆';

  @override
  String get noBadges => 'ቀጽል ቁጠባ ናይ መጀመሪያ ሽልማት ንምርካብ!';

  @override
  String get planDaily => 'ዕለታዊ ውጥን';

  @override
  String get planWeekly => 'ሰሙናዊ ውጥን';

  @override
  String get planMonthly => 'ወርሓዊ ውጥን';

  @override
  String behindSchedule(String amount, String suggestion) {
    return 'ካብ ውጥን $amount ድሕሪ ኢኻ። ኣብ ሰሙን $suggestion እንተቐደስካ ናብ ቅኑዕ መስመር ትምለስ።';
  }

  @override
  String get onTrack => 'ኣብ ቅኑዕ መስመር ኢኻ! ቀጽል።';

  @override
  String projectedCompletion(String date) {
    return 'ትጽቢታዊ ፍጻሜ: $date';
  }

  @override
  String get reminders => 'ዘኪርካ';

  @override
  String get addReminder => 'ዘኪርካ ወስኽ';

  @override
  String get reminderFrequency => 'ድጋፍ';

  @override
  String get daily => 'ዕለታዊ';

  @override
  String get weekly => 'ሰሙናዊ';

  @override
  String get monthly => 'ወርሓዊ';

  @override
  String get reminderTime => 'ሰዓት ዘኪርካ';

  @override
  String get reminderWeekday => 'ናይ ሰሙን ዕለት';

  @override
  String get reminderSaved => 'ዘኪርካ ተቐሚጡ።';

  @override
  String get reminderDeleted => 'ዘኪርካ ተሰሪዙ።';

  @override
  String get tips => 'ምኽሪ ቁጠባ';

  @override
  String get noTips => 'ምኽርታት ሕጂ የለን።';

  @override
  String get latestTip => 'ምኽሪ ናይ ሎሚ ዕለት';

  @override
  String get feedback => 'ርኢቶ ስደድ';

  @override
  String get feedbackMessage => 'መልእኽትካ';

  @override
  String get feedbackSent => 'የቐንየለይ! ርኢቶኻ ተሰዲዱ።';

  @override
  String get language => 'ቋንቋ';

  @override
  String get currency => 'ምንዛረ';

  @override
  String get theme => 'ጽሩይ';

  @override
  String get lightTheme => 'ብርሃን';

  @override
  String get darkTheme => 'ጸልማት';

  @override
  String get systemTheme => 'ሲስተም';

  @override
  String get notificationSettings => 'ምስክርነት';

  @override
  String get onboarding1Title => 'ቁጠባኻ ክትክታተሎ';

  @override
  String get onboarding1Body =>
      'ሸቶ ኣቐምጥ ከምኡ ድማ ኩሉ ቅርሽ ቁጠብ — ኣብ ባንኪ፣ ዋሌት ወይ ኣብ ገዛ።';

  @override
  String get onboarding2Title => 'ኣብ ውጥን ጽናሕ';

  @override
  String get onboarding2Body =>
      'ሸቶ ንምብጻሕ ሎሚ፣ ኣብ ሰሙን ወይ ወሩ ክንደይ ምቕዳስ ከም ዘሎካ ፍለጥ።';

  @override
  String get onboarding3Title => 'ምምሕዳር ኣኽብሮ';

  @override
  String get onboarding3Body =>
      'ሽልማት ርካብ፣ ተኸታታሊ ፍጠር፣ ናብ ሸቶ ኣብ ዝወስዱ ኩሉ ምዕቀባ ሕጐስ።';

  @override
  String get getStarted => 'ጀምር';

  @override
  String get next => 'ቀጽል';

  @override
  String get skip => 'ሓልፍ';

  @override
  String get errorGeneric => 'ጌጋ ተፈጢሩ። በጃኻ ደጊምካ ፈትን።';

  @override
  String get errorOffline => 'ካብ ኢንተርነት ተቐሪጽካ ኢኻ። ምስ ተወሃሃድካ ምስ ምምሕዳር ትዳረብ።';

  @override
  String get errorPermission => 'ንዚ ፍቓድ የብልካን።';

  @override
  String get tryAgain => 'ደጊምካ ፈትን';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get save => 'ቀምጥ';

  @override
  String get delete => 'ሰርዝ';

  @override
  String get edit => 'ኣርትዕ';

  @override
  String get confirm => 'ኣረጋግጽ';

  @override
  String get yes => 'እወ';

  @override
  String get no => 'ኣይፋሉ';

  @override
  String get close => 'ዕጸዎ';

  @override
  String get loading => 'ይጽዓን ኣሎ…';

  @override
  String get noData => 'ሕጂ ዳታ የለን።';

  @override
  String get selectDate => 'ዕለት ምረጽ';

  @override
  String get selectTime => 'ሰዓት ምረጽ';
}
