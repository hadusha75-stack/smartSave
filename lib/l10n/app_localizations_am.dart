// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appName => 'SaveSmart';

  @override
  String get login => 'ግባ';

  @override
  String get register => 'መለያ ፍጠር';

  @override
  String get logout => 'ውጣ';

  @override
  String get email => 'ኢሜይል';

  @override
  String get password => 'የይለፍ ቃል';

  @override
  String get forgotPassword => 'የይለፍ ቃልዎን ረሱ?';

  @override
  String get resetPassword => 'የይለፍ ቃል ዳግም አስጀምር';

  @override
  String get resetPasswordSent => 'የዳግም ማስጀመሪያ ኢሜይል ተልኳል። ሳጥኑን ያረጋግጡ።';

  @override
  String get name => 'ሙሉ ስም';

  @override
  String get confirmPassword => 'የይለፍ ቃልን አረጋግጥ';

  @override
  String get passwordMismatch => 'የይለፍ ቃሎቹ አይዛመዱም።';

  @override
  String get invalidEmail => 'እባክዎ ትክክለኛ ኢሜይል አድራሻ ያስገቡ።';

  @override
  String get fieldRequired => 'ይህ ሜዳ ያስፈልጋል።';

  @override
  String minLength(int count) {
    return 'ቢያንስ $count ቁምፊዎች መሆን አለበት።';
  }

  @override
  String get home => 'መነሻ';

  @override
  String get goals => 'ግቦች';

  @override
  String get history => 'ታሪክ';

  @override
  String get settings => 'ቅንብሮች';

  @override
  String get profile => 'መገለጫ';

  @override
  String get myGoals => 'ግቦቼ';

  @override
  String get addGoal => 'አዲስ ግብ';

  @override
  String get editGoal => 'ግብ አርትዕ';

  @override
  String get deleteGoal => 'ግብ ሰርዝ';

  @override
  String get archiveGoal => 'ግብ ማህደር አስቀምጥ';

  @override
  String get goalTitle => 'የግብ ስም';

  @override
  String get targetAmount => 'የዒላማ መጠን';

  @override
  String get currentAmount => 'አሁን የተቀዳጀው';

  @override
  String get deadline => 'የማጠናቀቂያ ቀን';

  @override
  String get category => 'ምድብ';

  @override
  String get goalDeleted => 'ግቡ ተሰርዟል።';

  @override
  String get goalArchived => 'ግቡ ወደ ማህደር ተዛውሯል።';

  @override
  String get goalCompleted => 'ግቡ ተሳካ! 🎉';

  @override
  String get noGoals => 'እስካሁን ምንም የቁጠባ ግብ የለም።\nፕላስ ተጫነው የመጀመሪያ ግብዎን ፍጠሩ!';

  @override
  String get cat_school_fees => 'የትምህርት ክፍያ';

  @override
  String get cat_phone => 'ስልክ';

  @override
  String get cat_laptop => 'ላፕቶፕ';

  @override
  String get cat_emergency_fund => 'አደጋ ፈንድ';

  @override
  String get cat_business => 'ንግድ';

  @override
  String get cat_wedding => 'ሠርግ';

  @override
  String get cat_other => 'ሌላ';

  @override
  String get addSaving => 'ቁጠባ ያስገቡ';

  @override
  String get editSaving => 'ቁጠባ አርትዕ';

  @override
  String get amount => 'መጠን';

  @override
  String get date => 'ቀን';

  @override
  String get note => 'ማስታወሻ (አማራጭ)';

  @override
  String get savedIn => 'የተቀዳጀበት';

  @override
  String get savingAdded => 'ቁጠባ ተመዝግቧል።';

  @override
  String get savingUpdated => 'ቁጠባ ተዘምኗል።';

  @override
  String get savingDeleted => 'ቁጠባ ተሰርዟል።';

  @override
  String get progress => 'ሂደት';

  @override
  String get streak => 'ተከታታይ';

  @override
  String streakDays(int count) {
    return '$count ወቅቶች';
  }

  @override
  String get badge25 => '25% ደረሰ 🌱';

  @override
  String get badge50 => 'ወደ ግማሽ 🌿';

  @override
  String get badge75 => 'ምሁር ቅርብ 🌳';

  @override
  String get badge100 => 'ግብ ተሳካ 🏆';

  @override
  String get noBadges => 'ቁጠባ ቀጥሉ የመጀመሪያ ሽልማቱን ለማግኘት!';

  @override
  String get planDaily => 'ዕለታዊ ዕቅድ';

  @override
  String get planWeekly => 'ሳምንታዊ ዕቅድ';

  @override
  String get planMonthly => 'ወርሃዊ ዕቅድ';

  @override
  String behindSchedule(String amount, String suggestion) {
    return 'ከዕቅድ $amount ወደ ኋላ ቀርተዋል። በሳምንት $suggestion ቢቆጥቡ ወደ ትክክለኛው ሂደት ይመለሳሉ።';
  }

  @override
  String get onTrack => 'ወደ ትክክለኛው ሂደት ነዎት! ቀጥሉ።';

  @override
  String projectedCompletion(String date) {
    return 'የተተነበየ ማጠናቀቂያ: $date';
  }

  @override
  String get reminders => 'አስታዋሾች';

  @override
  String get addReminder => 'አስታዋሽ ጨምር';

  @override
  String get reminderFrequency => 'ድግግሞሽ';

  @override
  String get daily => 'ዕለታዊ';

  @override
  String get weekly => 'ሳምንታዊ';

  @override
  String get monthly => 'ወርሃዊ';

  @override
  String get reminderTime => 'የማስጠንቀቂያ ሰዓት';

  @override
  String get reminderWeekday => 'የሳምንቱ ቀን';

  @override
  String get reminderSaved => 'አስታዋሹ ተቀምጧል።';

  @override
  String get reminderDeleted => 'አስታዋሹ ተሰርዟል።';

  @override
  String get tips => 'የቁጠባ ምክሮች';

  @override
  String get noTips => 'እስካሁን ምክሮች የሉም።';

  @override
  String get latestTip => 'የቀኑ ምክር';

  @override
  String get feedback => 'አስተያየት ላክ';

  @override
  String get feedbackMessage => 'መልእክትዎ';

  @override
  String get feedbackSent => 'አመሰግናለሁ! አስተያየቱ ተልኳል።';

  @override
  String get language => 'ቋንቋ';

  @override
  String get currency => 'ምንዛሬ';

  @override
  String get theme => 'ገጽ ቅንብር';

  @override
  String get lightTheme => 'ብርሃን';

  @override
  String get darkTheme => 'ጨለማ';

  @override
  String get systemTheme => 'ሲስተም';

  @override
  String get notificationSettings => 'ማሳወቂያዎች';

  @override
  String get onboarding1Title => 'ቁጠባዎን ይከታተሉ';

  @override
  String get onboarding1Body =>
      'ግብ ያስቀምጡ እና እያንዳንዱን ብር ይቆጥቡ — ባንክ፣ ዋሌት ወይም ቤት።';

  @override
  String get onboarding2Title => 'ዕቅዱን ይጠብቁ';

  @override
  String get onboarding2Body =>
      'ዕቅዱን ለማሳካት በቀን፣ ሳምንት ወይም ወር ምን ያህል ማስቀመጥ እንዳለቦት ያውቁ።';

  @override
  String get onboarding3Title => 'ሂደቱን ያክብሩ';

  @override
  String get onboarding3Body =>
      'ሽልማቶችን ያግኙ፣ ተከታታይ ዘመን ይገንቡ፣ እና ወደ ግቡ በሚያደርሱ እያንዳንዱ ምዕራፍ ይደሰቱ።';

  @override
  String get getStarted => 'ጀምር';

  @override
  String get next => 'ቀጣይ';

  @override
  String get skip => 'ዝለል';

  @override
  String get errorGeneric => 'ስህተት ተከስቷል። እባክዎ ደግም ይሞክሩ።';

  @override
  String get errorOffline => 'ከኢንተርኔት ተቋርጠዋል። ሲገናኙ ይዳረጋሉ።';

  @override
  String get errorPermission => 'ለዚህ ፈቃድ የለዎትም።';

  @override
  String get tryAgain => 'ደግም ሞክር';

  @override
  String get cancel => 'ሰርዝ';

  @override
  String get save => 'አስቀምጥ';

  @override
  String get delete => 'ሰርዝ';

  @override
  String get edit => 'አርትዕ';

  @override
  String get confirm => 'አረጋግጥ';

  @override
  String get yes => 'አዎ';

  @override
  String get no => 'አይ';

  @override
  String get close => 'ዝጋ';

  @override
  String get loading => 'በመጫን ላይ…';

  @override
  String get noData => 'እስካሁን ምንም ውሂብ የለም።';

  @override
  String get selectDate => 'ቀን ምረጥ';

  @override
  String get selectTime => 'ሰዓት ምረጥ';
}
