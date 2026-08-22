import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'ম্যাপবানাই';

  @override
  String get homeTitle => 'ম্যাপবানাই';

  @override
  String get homeSubtitle => 'অফলাইন ফিল্ড ডেটা সংগ্রহ';

  @override
  String get surveyModeTitle => 'সার্ভে মোড';

  @override
  String get surveyModeSubtitle => 'সহজ ফর্ম-ভিত্তিক ফিল্ড ডেটা সংগ্রহ';

  @override
  String get gisModeTitle => 'জিআইএস মোড';

  @override
  String get gisModeSubtitle => 'মানচিত্র-ভিত্তিক স্থানিক সম্পাদনা ও লেয়ার';

  @override
  String get gpsModeTitle => 'জিপিএস মোড';

  @override
  String get gpsModeSubtitle => 'লাইভ জিপিএস রিডিং ও কোঅর্ডিনেট লগিং';

  @override
  String get studyAreaModeTitle => 'স্টাডি এরিয়া মোড';

  @override
  String get studyAreaModeSubtitle =>
      'স্ট্যাটাস ট্র্যাকিং ও নেভিগেশন সহ সাইট ভিজিট';

  @override
  String get gpsCsvViewerTitle => 'জিপিএস CSV ভিউয়ার';

  @override
  String get gpsCsvViewerSubtitle => 'ওয়েবম্যাপে লগ ও প্রজেক্ট ট্র্যাক দেখুন';

  @override
  String get syncTitle => 'সিঙ্ক';

  @override
  String get syncSubtitle => 'রেসপন্স ও ছবি ক্লাউডে আপলোড করুন';

  @override
  String get syncSetupTitle => 'ক্লাউড সিঙ্ক সেটআপ করুন';

  @override
  String syncSetupSubtitle(String project) {
    return '\"$project\" এর জন্য সিঙ্ক কনফিগার করুন';
  }

  @override
  String syncLastSynced(String date) {
    return 'শেষ সিঙ্ক: $date';
  }

  @override
  String get syncNever => 'কখনো সিঙ্ক হয়নি';

  @override
  String get syncNoInternet => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get webMapTitle => 'ওয়েবম্যাপ';

  @override
  String get webMapSubtitle => 'ফিল্টার ও পপআপ সহ অফলাইন HTML মানচিত্র';

  @override
  String projectSelectorTitle(String project) {
    return 'বর্তমান প্রজেক্ট: $project';
  }

  @override
  String get noProjectSelected =>
      'কোনো প্রজেক্ট নির্বাচিত নয় — বেছে নিতে ট্যাপ করুন';

  @override
  String get selectProject => 'প্রজেক্ট নির্বাচন করুন';

  @override
  String collectedDataTitle(String project) {
    return 'সংগৃহীত ডেটা — $project';
  }

  @override
  String get collectedDataHint =>
      'সংগৃহীত ডেটা দেখতে উপরে একটি প্রজেক্ট নির্বাচন করুন।';

  @override
  String get surveyResponses => 'সার্ভে রেসপন্স';

  @override
  String get gisFeatures => 'জিআইএস ফিচার';

  @override
  String get open => 'খুলুন';

  @override
  String get history => 'ইতিহাস';

  @override
  String get export => 'এক্সপোর্ট';

  @override
  String get importProject => 'প্রজেক্ট ইমপোর্ট';

  @override
  String get settings => 'সেটিংস';

  @override
  String get settingsUserTitle => 'ব্যবহারকারী';

  @override
  String get settingsUserSubtitle =>
      'আপনার নাম প্রতিটি সার্ভে রেসপন্স, জিপিএস লগ ও এক্সপোর্টের সাথে যুক্ত থাকবে।';

  @override
  String get userNameLabel => 'ব্যবহারকারীর নাম';

  @override
  String get userNameHint => 'যেমন, জন ডো';

  @override
  String get userNameLeaveEmpty => 'মুছতে খালি রাখুন।';

  @override
  String get languageSection => 'ভাষা';

  @override
  String get languageSubtitle =>
      'আপনার পছন্দের ভাষা নির্বাচন করুন। সিস্টেম ডিফল্ট ডিভাইসের ভাষা অনুসরণ করে।';

  @override
  String get preferredLanguage => 'পছন্দের ভাষা';

  @override
  String get systemDefault => 'সিস্টেম ডিফল্ট';

  @override
  String get english => 'ইংরেজি';

  @override
  String get bangla => 'বাংলা';

  @override
  String get themeSection => 'থিম';

  @override
  String get themeSubtitle => 'আলো, অন্ধকার বা সিস্টেম থিম অনুসরণ করুন।';

  @override
  String get preferredTheme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম ডিফল্ট';

  @override
  String get themeLight => 'আলো';

  @override
  String get themeDark => 'অন্ধকার';

  @override
  String get measurementSection => 'পরিমাপ একক';

  @override
  String get measurementSubtitle =>
      'জিআইএস দূরত্ব ও ক্ষেত্রফল টুলে ব্যবহৃত। স্বয়ংক্রিয়ভাবে মিটার/কিলোমিটার ও বর্গমিটার/হেক্টর নির্বাচন করে।';

  @override
  String get distance => 'দূরত্ব';

  @override
  String get area => 'ক্ষেত্রফল';

  @override
  String get dataSection => 'ডেটা';

  @override
  String get dataSubtitle => 'স্থানীয়ভাবে সংরক্ষিত সমস্ত সার্ভে ডেটা মুছুন।';

  @override
  String get resetData => 'ডেটা রিসেট';

  @override
  String get resetDataConfirmTitle => 'চূড়ান্ত নিশ্চিতকরণ';

  @override
  String get updatesSection => 'আপডেট';

  @override
  String get updatesSubtitle => 'গিটহাব রিলিজ থেকে নতুন সংস্করণ পরীক্ষা করে।';

  @override
  String get checkForUpdates => 'আপডেট পরীক্ষা করুন';

  @override
  String checkForUpdatesWithVersion(String version) {
    return 'আপডেট পরীক্ষা করুন — v$version ইনস্টল করা আছে';
  }

  @override
  String get aboutSection => 'সম্পর্কে';

  @override
  String get aboutTagline => 'অফলাইন ফিল্ড ডেটা সংগ্রহ জিআইএস';

  @override
  String versionLabel(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get settingsSaved => 'সেটিংস সংরক্ষিত হয়েছে';

  @override
  String get saveResponses => 'উত্তর সংরক্ষণ করুন';

  @override
  String get saveAsDraft => 'খসড়া হিসেবে সংরক্ষণ';

  @override
  String gpsRecordingActive(String name) {
    return 'জিপিএস রেকর্ডিং সক্রিয় — \"$name\"';
  }

  @override
  String get gpsRecordingHint =>
      'স্ক্রিন বন্ধ থাকলেও লগিং চলতে থাকে। যেকোনো সময় জিপিএস মোড ছেড়ে যেতে পারেন; থামাতে এখানে ফিরে আসুন।';

  @override
  String get openGpsMode => 'জিপিএস মোড খুলুন';

  @override
  String get stop => 'থামান';

  @override
  String get surveyMode => 'সার্ভে মোড';

  @override
  String get selectSurveyForm => 'একটি সার্ভে ফর্ম নির্বাচন করুন';

  @override
  String projectLabel(String project) {
    return 'প্রজেক্ট: $project';
  }

  @override
  String get myForms => 'আমার ফর্ম';

  @override
  String get noFormsHint =>
      'এই প্রজেক্টের জন্য এখনো কোনো ফর্ম নেই। আপনার প্রথম সার্ভে ফর্ম তৈরি বা ইমপোর্ট করতে ট্যাপ করুন।';

  @override
  String get startBuildingForm => 'সার্ভে ফর্ম তৈরি শুরু করুন';

  @override
  String formQuestionsCount(String count) {
    return '$count টি প্রশ্ন';
  }

  @override
  String get buildOrImportForm => 'সার্ভে ফর্ম তৈরি বা ইমপোর্ট করুন';

  @override
  String get formLanguage => 'ফর্মের ভাষা';

  @override
  String get formLanguageHint =>
      'XLSForm-এ সংজ্ঞায়িত ভাষাগুলোর মধ্যে পরিবর্তন করুন';

  @override
  String get captureGps => 'ক্যাপচার';

  @override
  String get measureAccuracy => 'পরিমাপ';

  @override
  String get attachPhoto => 'যুক্ত করুন';

  @override
  String get replacePhoto => 'প্রতিস্থাপন';

  @override
  String get tapToCaptureGps => 'জিপিএস অবস্থান ক্যাপচার করতে ট্যাপ করুন';

  @override
  String get tapToMeasureAccuracy => 'নির্ভুলতা পরিমাপ করতে ট্যাপ করুন';

  @override
  String get photoAttached => 'ছবি যুক্ত হয়েছে';

  @override
  String get geotaggedPhoto => 'জিওট্যাগযুক্ত ছবি যুক্ত হয়েছে';

  @override
  String requiredField(String label) {
    return '$label আবশ্যক';
  }

  @override
  String constraintError(String label, String error) {
    return '$label: $error';
  }

  @override
  String get enterText => 'টেক্সট লিখুন';

  @override
  String get enterLongText => 'বড় টেক্সট লিখুন';

  @override
  String get enterNumber => 'সংখ্যা লিখুন';

  @override
  String get enterDecimal => 'দশমিক সংখ্যা লিখুন';

  @override
  String get selectOption => 'একটি বিকল্প নির্বাচন করুন';

  @override
  String get chooseOption => 'একটি বিকল্প বেছে নিন';

  @override
  String get selectDate => 'তারিখ নির্বাচন করুন';

  @override
  String get selectTime => 'সময় নির্বাচন করুন';

  @override
  String get selectDateTime => 'তারিখ ও সময় নির্বাচন করুন';

  @override
  String get yes => 'হ্যাঁ';

  @override
  String get no => 'না';

  @override
  String get cancel => 'বাতিল';

  @override
  String get close => 'বন্ধ';

  @override
  String get delete => 'মুছুন';

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get studyAreaTitle => 'স্টাডি এরিয়া';

  @override
  String get projectTitle => 'প্রজেক্ট';

  @override
  String get projectSettings => 'প্রজেক্ট সেটিংস';

  @override
  String get renameProject => 'প্রজেক্টের নাম পরিবর্তন';

  @override
  String get deleteProject => 'প্রজেক্ট মুছুন';

  @override
  String get shareProject => 'প্রজেক্ট শেয়ার';

  @override
  String get lightThemeApplied => 'আলো থিম প্রয়োগ করা হয়েছে';

  @override
  String get darkThemeApplied => 'অন্ধকার থিম প্রয়োগ করা হয়েছে';
}
