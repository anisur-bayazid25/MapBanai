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
  String get homeSubtitle => 'সহজ ভূস্থানিক তথ্য সংগ্রহ';

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
  String get aboutTagline => 'সহজ ভূস্থানিক তথ্য সংগ্রহ';

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

  @override
  String ui146d90ab8a12(String v0) {
    return '“$v0” তৈরি হয়েছে';
  }

  @override
  String uidb9502050d6e(String v0) {
    return '১. $v0 যাচাই করুন';
  }

  @override
  String get uica8002883856 => '২. তথ্য সংগ্রহ করুন';

  @override
  String get uie2d42900f048 => '৩. অবস্থানসহ প্রমাণের ছবি';

  @override
  String get uia71b74276db0 => 'শেষ করার আগে একটি ছবি তুলুন।';

  @override
  String ui6eb4c6ceec88(String v0) {
    return '“$v0” নামে একটি প্রজেক্ট ইতিমধ্যে আছে';
  }

  @override
  String get uicf678cab87dc => 'API কী';

  @override
  String get ui6b21fb791ac0 => 'সম্পর্কে';

  @override
  String get uifa7cafd4738a => 'নির্ভুলতা (মি.)';

  @override
  String get uiece911f43765 => 'নির্ভুলতা গ্রহণ করুন';

  @override
  String get uid110ce480b6b =>
      'নির্ভুলতা গ্রহণ করা হয়েছে। তথ্য ও ছবি সংরক্ষিত আছে।';

  @override
  String uiee4a56b9d330(String v0) {
    return 'নির্ভুলতা: $v0 (সর্বোচ্চ ২০ মি.)';
  }

  @override
  String get ui5d9540ff93a7 => 'কৃতজ্ঞতা';

  @override
  String get ui61cc55aa0453 => 'যোগ করুন';

  @override
  String get ui05448f4011e4 => 'বিকল্প যোগ করুন';

  @override
  String get uif353ad702eca => 'বিন্দু যোগ করুন';

  @override
  String get uib86c7f055ded => 'প্রশ্ন যোগ করুন';

  @override
  String get uia5f99b5076d1 => 'প্রজেক্টে প্রশ্নপত্র যোগ করুন';

  @override
  String get ui912d424ade4e => 'ভিজিট শেষ করার আগে প্রজেক্টে XLSForm যোগ করুন।';

  @override
  String ui512ece25554d(String v0) {
    return 'অন্তত $v0টি ভিন্ন বিন্দু যোগ করুন।';
  }

  @override
  String ui92c3d4711cb2(String v0) {
    return 'অন্তত $v0টি বিন্দু যোগ করুন।';
  }

  @override
  String get ui6632e5c07446 => 'ফর্ম যোগ করুন';

  @override
  String get ui6f689eeab092 => 'তথ্য যোগ করুন';

  @override
  String get uifaac648b07cd => 'প্রজেক্টে লেয়ার যোগ করুন';

  @override
  String get ui259983d5b67d => 'রেখা যোগ করুন (বিন্দুতে ট্যাপ করুন)';

  @override
  String get ui69ba1bebc021 => 'নতুন লেয়ার যোগ করুন';

  @override
  String get uic4c2f28a653e => 'পর্যবেক্ষণ যোগ / ভিজিট শুরু';

  @override
  String get uia20144055a2c => 'বিকল্প যোগ করুন';

  @override
  String get uid14349309573 => 'ছবি যোগ করুন';

  @override
  String get uia6e0524cd9f4 => 'বহুভুজ যোগ করুন (বিন্দুতে ট্যাপ করুন)';

  @override
  String get uidfa9ad191cbb =>
      'স্টাডি এরিয়া, স্থাপনা ও সড়কের লেয়ার যোগ করুন। প্রজেক্ট এক্সপোর্টে মূল ফাইলও থাকবে।';

  @override
  String get uif51add823fef =>
      'স্টাডি এরিয়া, স্থাপনা বা সড়কের লেয়ার যোগ করুন। সমর্থিত ফাইল: shapefile বা ZIP, CSV, Excel, GeoJSON ও GeoPackage। সড়কের লেয়ার দিয়ে স্টাডি এরিয়া মোডে সংক্ষিপ্ততম পথ দেখা যায়। WGS84 (EPSG:4326) ব্যবহার করুন।';

  @override
  String get ui29924533fad1 => 'ভেক্টর লেয়ার যোগ করুন';

  @override
  String get ui79ba5e1b3f99 => 'পরে';

  @override
  String get ui6a72085653e4 => 'সব';

  @override
  String get uib4f794cdbb77 => 'সব দিন';

  @override
  String get ui152d422f80e6 => 'সব লেয়ার';

  @override
  String uic622d843608e(String v0) {
    return 'সব পর্যবেক্ষণ ($v0)';
  }

  @override
  String get ui755046a16371 => 'সব ধরনের রেকর্ড';

  @override
  String get ui524a33d9c5f7 => 'সব সাইট';

  @override
  String get uidd402a4a59f8 => 'সিঙ্কের সব অবস্থা';

  @override
  String get ui3ad0e3698278 => 'অনুমতি দিন';

  @override
  String get ui209e0391343c => 'ইনস্টলের অনুমতি দিন';

  @override
  String get uia0354233e8e7 => 'জিপিএস ব্যবহারের জন্য অবস্থানের অনুমতি দিন।';

  @override
  String get ui483ff5e64f97 => 'ইতিমধ্যে সিঙ্ক হয়েছে';

  @override
  String get ui12e0f83d72ab => 'সার্ভের ইতিহাস ও সিঙ্কের সারিও মুছুন';

  @override
  String get ui6742711abf37 => 'সংযুক্ত স্টাডি এরিয়ার বিন্দুও সরান';

  @override
  String get ui789bda938348 => 'উচ্চতা (মি.)';

  @override
  String get uib2482df07055 => 'উত্তর হালনাগাদ হয়েছে — সিঙ্কের জন্য প্রস্তুত';

  @override
  String get ui41def7a0febe => 'থিম';

  @override
  String get uicfea419c3b4e => 'প্রয়োগ করুন';

  @override
  String get uie4e3653eb728 => 'ইমপোর্ট প্রয়োগ করুন';

  @override
  String get uic64add5b7c88 => 'প্রশ্নপত্রের হালনাগাদ প্রয়োগ করুন';

  @override
  String get ui036a2c32985f => 'পর্যালোচিত ভিজিট প্রয়োগ করুন';

  @override
  String get uif7110953e0c1 => 'Apps Script ওয়েব অ্যাপের URL';

  @override
  String get ui6baacf7ea93e => 'প্রজেক্ট আর্কাইভ করুন';

  @override
  String get uieddc813f35b1 => 'আর্কাইভ করা';

  @override
  String get ui371c4c745268 => 'আর্কাইভ করা প্রজেক্ট';

  @override
  String get ui2745debaa64a => 'ক্ষেত্রফল';

  @override
  String get ui5de953ada8ae => 'আগের অনির্ধারিত সাইটগুলো যুক্ত করুন';

  @override
  String get uibc9e681ab30c => 'নির্বাচিতগুলো যুক্ত করুন';

  @override
  String ui775f4f08081b(String v0) {
    return 'অন্তত ৩টি বিন্দু প্রয়োজন ($v0/৩)';
  }

  @override
  String get ui1afff0157ce3 => 'যুক্ত করুন';

  @override
  String get ui29d7b5c69a0f => 'অবস্থানসহ ছবি যুক্ত করুন';

  @override
  String get ui48b5d713528c => 'প্রতিটি নতুন জমার সঙ্গে যুক্ত হবে।';

  @override
  String ui0e89f1ba582f(String v0) {
    return '“$v0” বৈশিষ্ট্যটি ইতিমধ্যে আছে';
  }

  @override
  String get uia6652617f2c7 => 'বৈশিষ্ট্য';

  @override
  String get ui541903fcabc1 => 'ব্যাকআপ পুনরুদ্ধার হয়নি। তথ্য অপরিবর্তিত আছে।';

  @override
  String get ui557ebe872d79 => 'ব্যাকআপ সফলভাবে পুনরুদ্ধার হয়েছে।';

  @override
  String get ui68ea04ad6c84 => 'বাংলা';

  @override
  String get uicc0720785428 => 'ভিত্তি মানচিত্র';

  @override
  String get ui74f39697ac32 => 'আগে';

  @override
  String get ui6cd36c7dc22c => 'ফর্মের সংক্ষিপ্ত বিবরণ';

  @override
  String get ui4dcbe4e8a47b => 'সার্ভে ফর্ম তৈরি বা ইমপোর্ট করুন';

  @override
  String get ui3281188351b8 => 'CSV';

  @override
  String get ui757d86654eda => 'গণনাকৃত';

  @override
  String get uidc6751bd6532 => 'গণনা';

  @override
  String get ui77dfd2135f4d => 'বাতিল';

  @override
  String get ui67bb11d08df2 => 'ডাউনলোড বাতিল করুন';

  @override
  String ui57d7674a7613(String v0) {
    return 'বাতিল করা যায়নি: $v0';
  }

  @override
  String get uifda8429a704c => 'রেকর্ডিং বাতিল করুন';

  @override
  String ui6ca1964345a5(String v0) {
    return 'আইকন লোড হয়নি: $v0';
  }

  @override
  String ui34ebd759c2a4(String v0) {
    return 'প্রজেক্ট লোড হয়নি: $v0';
  }

  @override
  String uied3764fb600f(String v0) {
    return 'স্টাডি এরিয়া লোড হয়নি: $v0। সংরক্ষিত তথ্য অক্ষত আছে।';
  }

  @override
  String ui4b101071fd57(String v0) {
    return 'মানচিত্রের ধরন খোলা যায়নি: $v0';
  }

  @override
  String ui81c619629565(String v0) {
    return 'প্রজেক্টের মানচিত্র খোলা যায়নি: $v0';
  }

  @override
  String uiaeb0cf0b59f1(String v0) {
    return 'লেয়ার আবার লোড হয়নি: $v0';
  }

  @override
  String uiad5108d1542b(String v0) {
    return 'নির্ভুলতা পর্যালোচনা করা যায়নি: $v0';
  }

  @override
  String get ui772a4bcb6564 => 'ক্যাপচার';

  @override
  String get ui70dd605f2b73 => 'ছবি তুলুন';

  @override
  String get ui31c77e404ec9 => 'ছবি তুলুন';

  @override
  String ui72d06195a7a3(String v0) {
    return 'তোলার সময়: $v0';
  }

  @override
  String get ui721731bb86ab => 'বিভাগ ও রং';

  @override
  String get ui8af155f38c5a => 'বিভাগের রং';

  @override
  String get uib55970d156d0 => 'জিপিএস অবস্থান কেন্দ্রে আনুন';

  @override
  String get ui7624e54f7a04 => 'সাইট কেন্দ্রে আনুন';

  @override
  String get uid9789c629cfe => 'আগের তুলনায় পরিবর্তন';

  @override
  String get uia76e5f7556db => 'পরিবর্তন বা পর্যালোচনার নোট';

  @override
  String get ui46b25978ee0b => 'শুধু পরিবর্তিত ফিচার (GeoJSON)';

  @override
  String get ui1728436a320d => 'Google Sheet দেখুন';

  @override
  String get ui736b9062b336 => 'আপডেট পরীক্ষা করুন';

  @override
  String get uie08b2e193e7a => 'ইমপোর্ট করা ফাইল দেখুন';

  @override
  String get ui66a60b5d2de0 => 'অবস্থান যাচাই ও আগের ফিচার হালনাগাদ করুন।';

  @override
  String get uia357678fa469 => 'রেকর্ড করা জিপিএস নির্ভুলতা যাচাই হচ্ছে…';

  @override
  String get ui398872e1510b => 'গিটহাব রিলিজ থেকে নতুন সংস্করণ পরীক্ষা করে।';

  @override
  String get uib8c6c4d83ff6 => '.mbproj ফাইল বাছুন';

  @override
  String get ui410406660ffe =>
      'যাচাই, হালনাগাদ ও নথিভুক্ত করতে একটি মূল ফিচার বাছুন।';

  @override
  String get ui94e9ca725723 =>
      'প্রজেক্ট বাছুন, তারপর লেয়ার বা সংগ্রহের দিন অনুযায়ী রেকর্ড খুঁজুন। ইতিহাস মুছলে সংশ্লিষ্ট রেকর্ড সিঙ্কের সারি থেকেও মুছে যাবে।';

  @override
  String get uiec39521dd3d0 => 'রেজোলিউশন বাছুন';

  @override
  String get uie6e18a5753f1 => 'সাইট বাছুন';

  @override
  String get ui45b9ce6e2d69 => 'একটি বিকল্প বেছে নিন';

  @override
  String get ui5910acf0395e => 'ফাইল বাছুন';

  @override
  String get ui1838a4158f39 => 'ফোল্ডার বাছুন';

  @override
  String get ui3caef71ba23a => 'আলো, অন্ধকার বা সিস্টেম থিম অনুসরণ করুন।';

  @override
  String get ui05047674386b =>
      'মানচিত্রটি কোন প্রজেক্টে থাকবে বাছুন। ইমপোর্ট করলে এর ফিচার যাচাই ও হালনাগাদ করতে পারবেন।';

  @override
  String get ui470bd9b52bf6 =>
      'আপনার পছন্দের ভাষা নির্বাচন করুন। সিস্টেম ডিফল্ট ডিভাইসের ভাষা অনুসরণ করে।';

  @override
  String get ui518b074e92aa => 'ইতিহাস পরিষ্কার করুন';

  @override
  String get ui0c8b3d42e61a => 'সার্ভের ইতিহাস পরিষ্কার করুন';

  @override
  String get ui719ea396ad92 => 'পরিষ্কার করুন';

  @override
  String get ui105f261a16bf => 'সব সাইট মুছুন';

  @override
  String get ui526b4d80fe1b => 'স্টাডি লেয়ার পরিষ্কার করুন';

  @override
  String get uibbfa773e5a63 => 'বন্ধ';

  @override
  String get uiaf5d06a7b201 => 'ফিচার বন্ধ করুন';

  @override
  String get uid997d8d3a964 => 'ক্লাউড সিঙ্ক';

  @override
  String get ui0bd870fd34a8 => 'Code.gs';

  @override
  String get ui68188254a969 => 'এলাকা সংগ্রহ করুন';

  @override
  String get ui42688f506949 => 'রেখা সংগ্রহ করুন';

  @override
  String get ui5e9981b89e91 => 'প্রতি পর্বে একই সাইটে পরিমাপ সংগ্রহ করুন।';

  @override
  String get uiada29d015b1d => 'বিন্দু সংগ্রহ করুন';

  @override
  String get ui5b0f7590d06f => 'সংগৃহীত';

  @override
  String get ui6f83084a2ae4 => 'সংগ্রহ পর্ব';

  @override
  String get ui309ecfafed02 => 'কলাম অনুযায়ী রং';

  @override
  String get uif28563a477a9 => 'রং';

  @override
  String get uid401aac0a65d => 'দুই সংস্করণ তুলনা করুন';

  @override
  String get ui17ccc7b6d715 => 'মানচিত্র ও সংরক্ষিত ভিজিট তুলনা করুন';

  @override
  String get ui9d5c8e519d85 => 'কম্পাস';

  @override
  String get ui5b96e7e9c657 =>
      'কম্পাস ঠিক করতে ধাতব বস্তু থেকে দূরে ফোনটি আটের মতো ঘোরান।';

  @override
  String uicac0b9c25835(String v0) {
    return 'শর্তযুক্ত: $v0';
  }

  @override
  String get ui04a212215ef9 => 'নিশ্চিত করুন';

  @override
  String ui8b1bf24a6905(String v0) {
    return 'বিরোধ মেটানো যায়নি: $v0';
  }

  @override
  String get ui222f2eac34b3 => 'যাচাইয়ের শর্ত (ঐচ্ছিক)';

  @override
  String get ui70404424ca5b => 'যাচাইয়ের বার্তা (ঐচ্ছিক)';

  @override
  String get ui2e02623966f9 => 'চালিয়ে যান';

  @override
  String get ui9201f5c65f25 => 'স্থানাঙ্ক ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String get ui1a19a2434337 => 'স্থানাঙ্ক সীমার বাইরে';

  @override
  String get ui0e7383487387 => 'ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String get ui9959dcff1e40 => 'স্থানাঙ্ক কপি করুন';

  @override
  String get ui9b6827cfc0c2 => 'প্রজেক্ট আইডি কপি করুন';

  @override
  String uifa1b57908cec(String v0) {
    return '$v0 কপি করুন';
  }

  @override
  String ui975a22c89e46(String v0) {
    return 'সড়কপথ নির্ণয় করা যায়নি: $v0';
  }

  @override
  String ui22545c204602(String v0) {
    return 'সাইট মোছা যায়নি: $v0';
  }

  @override
  String uifc746e880c1f(String v0) {
    return 'প্যাকেজ মোছা যায়নি: $v0';
  }

  @override
  String ui0334890fbaf4(String v0) {
    return 'নির্ভুলতা পাওয়া যায়নি: $v0';
  }

  @override
  String ui9a95131ae123(String v0) {
    return 'অবস্থান পাওয়া যায়নি: $v0';
  }

  @override
  String get uie4ee1b598563 => 'কোড লোড হয়নি। সহায়তা আবার খুলুন।';

  @override
  String get uic305018ed35e => 'Google Maps খোলা যায়নি।';

  @override
  String uif515a67aeb4d(String v0) {
    return 'Google Maps খোলা যায়নি: $v0';
  }

  @override
  String get uiff2ce6da5800 => 'লিংক খোলা যায়নি';

  @override
  String ui50a313090b94(String v0) {
    return 'মানচিত্র খোলা যায়নি: $v0';
  }

  @override
  String get ui17cb282d8d29 => 'ফাইল বাছাইকারী খোলা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get uibe443a8c429f => 'নির্বাচিত ফাইল পড়া যায়নি';

  @override
  String get uid77db0286a5e => 'খসড়াটি পড়া যায়নি';

  @override
  String uif3267458c32e(String v0) {
    return 'গ্রহণের তথ্য সংরক্ষিত হয়নি: $v0';
  }

  @override
  String uia8114024834a(String v0) {
    return 'খসড়া সংরক্ষিত হয়নি: $v0। উত্তরগুলো এখানেই আছে।';
  }

  @override
  String ui5d7ba60622b7(String v0) {
    return 'ফিচার সংরক্ষিত হয়নি: $v0';
  }

  @override
  String ui8607427fbc53(String v0) {
    return 'ফর্ম সংরক্ষিত হয়নি: $v0। ফর্মটি এখানেই আছে।';
  }

  @override
  String ui6e35c572c083(String v0) {
    return 'উত্তর সংরক্ষিত হয়নি: $v0। উত্তরগুলো এখানেই আছে।';
  }

  @override
  String ui269629dbe7bf(String v0) {
    return 'ফিচারটি সংরক্ষিত হয়নি: $v0';
  }

  @override
  String ui31eee97bbcb3(String v0) {
    return 'লগ শেয়ার করা যায়নি: $v0';
  }

  @override
  String get ui6e157c5da441 => 'তৈরি করুন';

  @override
  String get ui81199e796010 => 'আগে হোম থেকে প্রজেক্ট তৈরি করুন।';

  @override
  String get ui4040d68479ef => 'নিজস্ব সার্ভে ফর্ম তৈরি করুন';

  @override
  String get uib6fff06b1ea9 => 'উত্তর থেকে লেয়ার তৈরি করুন';

  @override
  String get uieb8f1b5942ac => 'পরিমাপের লেয়ার তৈরি করুন';

  @override
  String get uid147959adb0d => 'শুরু করতে প্রজেক্ট তৈরি বা ইমপোর্ট করুন।';

  @override
  String get ui79ed912d242b => 'প্রজেক্ট তৈরি বা খুলুন';

  @override
  String get uie41bffcbf8fd => 'ফর্ম তৈরির আগে প্রজেক্ট তৈরি বা বাছুন';

  @override
  String get uia8d8ff51e4c8 => 'প্রজেক্ট তৈরি করুন';

  @override
  String get uid7fd23efd3fb => 'পুনরাবৃত্ত সংগ্রহের লেয়ার তৈরি করুন';

  @override
  String get ui5fa4376dd93d => 'প্রথম সংগ্রহ পর্ব তৈরি করুন';

  @override
  String get ui1e95852771e8 => 'বর্তমান নির্ভুলতা';

  @override
  String ui5ba408a14004(String v0, String v1, String v2) {
    return 'বর্তমান মানচিত্র (সংস্করণ $v0):\n$v1\n\nসংরক্ষিত ভিজিটের প্রস্তাব:\n$v2\n\nসংরক্ষিত ভিজিট প্রয়োগ করলে বর্তমান বৈশিষ্ট্য ও জ্যামিতি বদলাবে। দুই সংস্করণই সংশোধনের ইতিহাসে থাকবে।';
  }

  @override
  String get uid1f86d5227e9 => 'নিজস্ব তথ্যের ঘর';

  @override
  String get ui2bc69d616e9c => 'লেয়ারের নিজস্ব রং';

  @override
  String get uiae1ef0143294 => 'অন্ধকার';

  @override
  String get uidd144a4c66ee => 'অন্ধকার থিম প্রয়োগ করা হয়েছে';

  @override
  String get uie5e429bcc9c2 => 'ডেটা';

  @override
  String get uieb9a4bc1c0c1 => 'তারিখ';

  @override
  String get ui7eb29d356518 => 'তারিখ ও সময়';

  @override
  String get uie4c3a2d0cc24 => 'দশমিক';

  @override
  String get uic9a6edbbca9b => 'প্রাথমিক মান (ঐচ্ছিক)';

  @override
  String get uif6fdbe48dc54 => 'মুছুন';

  @override
  String ui322a3ca0f18f(String v0) {
    return '“$v0” ও এর CSV ফাইল মুছবেন?';
  }

  @override
  String uia761ad78efaa(String v0) {
    return '“$v0” মুছবেন?';
  }

  @override
  String ui97f85ee5e056(String v0) {
    return '“$v0” মুছবেন? এটি ফেরানো যাবে না।';
  }

  @override
  String get ui163dbcf2cb0b => 'স্থানীয়ভাবে সংরক্ষিত সমস্ত সার্ভে ডেটা মুছুন।';

  @override
  String get uib6ea094ee1dd => 'খসড়া মুছুন';

  @override
  String get uie51f1f6721d0 => 'ফর্ম মুছুন';

  @override
  String get uicee51ffefd08 => 'প্যাকেজ মুছুন';

  @override
  String get uifc700472e1c8 => 'ছবি মুছুন';

  @override
  String get uiaf1456f256eb => 'প্রজেক্ট মুছুন';

  @override
  String get uib81097a6dff1 => 'উত্তর মুছুন';

  @override
  String get ui8516a714a234 => 'নির্বাচিতগুলো মুছুন';

  @override
  String get uia154a9f139a0 => 'নির্বাচিত ইতিহাস মুছবেন?';

  @override
  String get uidead9e2fceca => 'সাইট মুছুন';

  @override
  String get uibbb829eb5d99 => 'এই খসড়া মুছবেন? অসম্পূর্ণ তথ্য হারিয়ে যাবে।';

  @override
  String get ui0ddb0f574d68 => 'অনির্ধারিত সাইট মুছবেন?';

  @override
  String ui2823144885b8(String v0) {
    return '$v0টি রেকর্ড মুছুন';
  }

  @override
  String uic140eb8d4089(String v0) {
    return '$v0 মুছবেন?';
  }

  @override
  String ui417f5c09f20f(String v0, String v1) {
    return 'ইতিহাসের $v0টি রেকর্ড মোছা হয়েছে$v1।';
  }

  @override
  String get ui55f8ebc805e6 => 'বিবরণ';

  @override
  String get ui85cce1e14782 => 'সব নির্বাচন বাতিল করুন';

  @override
  String get ui36fff63ccbcd => 'বাদ দিন';

  @override
  String get ui423208095dd7 => 'দূরত্ব';

  @override
  String get uie9b450d14bc2 => 'সম্পন্ন';

  @override
  String get uia479c9c34e87 => 'ডাউনলোড';

  @override
  String get uiff0c13412b0c => 'ডাউনলোড ও ইনস্টল';

  @override
  String get ui0ff9a69a76f5 => 'মানচিত্র ডাউনলোড';

  @override
  String get ui0800a145edde =>
      'ইন্টারনেটের বাইরে যাওয়ার আগে মাঠের নির্দিষ্ট এলাকার মানচিত্র ডাউনলোড করুন। সম্পূর্ণ প্যাকেজগুলো প্রতিটি সংগ্রহ মানচিত্রের ভিত্তি মানচিত্র বাছাইয়ে দেখা যাবে।';

  @override
  String uib5da8ffe86ea(String v0) {
    return 'ডাউনলোড হয়নি। $v0';
  }

  @override
  String get uia2853733787f => 'মাঠের এলাকা ডাউনলোড করুন';

  @override
  String uib5491539e2b3(String v0) {
    return 'ডাউনলোড হচ্ছে... $v0%';
  }

  @override
  String get uic584016080ca =>
      'খসড়া রাখা যাচ্ছে না: পুনরাবৃত্ত রেকর্ড সমর্থিত নয়। প্রতি ফিচারে একটি জমা থাকে এমন ফর্ম ইমপোর্ট করুন।';

  @override
  String get ui263f1461e992 =>
      'খসড়া ফিরে এসেছে — চালিয়ে যান, শেষ করুন বা আবার সংরক্ষণ করুন';

  @override
  String get uia706abd0fea1 => 'খসড়া সংরক্ষিত';

  @override
  String get uibdb71d0f6f36 => 'খসড়া সংরক্ষিত — পরে ইতিহাস থেকে চালিয়ে যান';

  @override
  String get uife6f67656743 => 'খসড়া হালনাগাদ হয়েছে';

  @override
  String ui319e1cedce84(String v0) {
    return 'খসড়া ভিজিট $v0। এই পর্দা ছাড়লে ফিচারের সম্পাদনা সংরক্ষিত হবে।';
  }

  @override
  String get ui24673e67421a => 'সরাতে মানচিত্রের বিন্দুটি টেনে নিন।';

  @override
  String get uibb2708352747 => 'রেখা আঁকুন';

  @override
  String get ui779c76ee322b => 'বহুভুজ আঁকুন';

  @override
  String get ui0f873fbc3146 => 'মানচিত্রে আঁকুন';

  @override
  String get uifc2d12b944ac => 'ড্রপডাউন';

  @override
  String get ui35ec8f11252e =>
      'প্রতিটি সম্পূর্ণ ভিজিট আলাদা পর্যবেক্ষণ। আগের পরিমাপ সময়রেখায় থাকবে। একই প্রশ্নপত্র ও প্রশ্নের নাম দিয়ে তুলনা হয়; সংস্করণ বদলালেও পরিমাপের একক একই রাখুন।';

  @override
  String get ui4c0f7e66bf0e => 'সহজ ভূস্থানিক তথ্য সংগ্রহ';

  @override
  String get ui5301648dcf6b => 'সম্পাদনা';

  @override
  String get ui8ad0e04ead5b => 'বিকল্প সম্পাদনা';

  @override
  String get ui7ff2c7ac7f1d => 'উত্তর সম্পাদনা';

  @override
  String get uid630d038b3ad => 'ফিচার সম্পাদনা';

  @override
  String get uif1d8720160a4 => 'ফর্ম সম্পাদনা';

  @override
  String get ui28134edb87d4 => 'মানচিত্রে সম্পাদনা';

  @override
  String get ui6091ce867967 => 'স্টাডি এরিয়া মোডে সাইটটি সম্পাদনা বা সরান';

  @override
  String get ui7f9c8e468af6 => 'প্রজেক্টের নাম সম্পাদনা';

  @override
  String uiedf5a9152284(String v0) {
    return 'সাইট $v0 সম্পাদনা';
  }

  @override
  String ui12faa0f2ccff(String v0) {
    return 'সম্পাদনা — $v0';
  }

  @override
  String get ui84add5b29527 => 'ইমেইল';

  @override
  String get ui649df08a448e => 'ইংরেজি';

  @override
  String get ui7f84073ce3b4 => 'দশমিক সংখ্যা লিখুন';

  @override
  String get ui02b5062f9c93 => 'বড় টেক্সট লিখুন';

  @override
  String get uib616e9721b5f => 'সংখ্যা লিখুন';

  @override
  String get ui9c05f58f3dcc => 'টেক্সট লিখুন';

  @override
  String get ui0bd3df97dc75 => 'জমায় পরিচয় রাখতে আপনার নাম লিখুন।';

  @override
  String get ui0e2d6a433d92 => 'Excel (XLSX)';

  @override
  String get ui00db23ce33b1 => 'Excel-উপযোগী CSV';

  @override
  String get uif3e4fadb9e37 => 'এক্সপোর্ট';

  @override
  String ui919004e0521f(String v0, String v1) {
    return '“$v0” এক্সপোর্ট (v$v1)';
  }

  @override
  String get ui59e9d9bc60d6 => 'প্রজেক্ট এক্সপোর্ট / শেয়ার';

  @override
  String get ui882b3940804a => 'CSV এক্সপোর্ট / শেয়ার';

  @override
  String get uif601e90879bd => 'তথ্য এক্সপোর্ট';

  @override
  String get ui98228e8633b0 => 'জিআইএস তথ্যের এক্সপোর্ট ধরন';

  @override
  String get uid2ee1c2ac834 => 'সব পর্যবেক্ষণ CSV হিসেবে এক্সপোর্ট';

  @override
  String get ui8016ab2ed7ba => 'এক্সপোর্ট বাতিল হয়েছে।';

  @override
  String get ui6b65ee8c6ffb => 'এক্সপোর্ট হয়নি। আবার চেষ্টা করুন।';

  @override
  String ui0026e4743f02(String v0) {
    return 'এক্সপোর্ট হয়নি: $v0';
  }

  @override
  String ui0fc874762a39(String v0) {
    return 'এক্সপোর্ট প্রস্তুত: $v0';
  }

  @override
  String get uia463fe0ed8cd => 'সাইট এক্সপোর্ট';

  @override
  String get ui9d0a833e883c => 'স্থাপনা';

  @override
  String ui01387ee23eea(String v0) {
    return 'ওয়েবম্যাপ তৈরি হয়নি: $v0';
  }

  @override
  String uicd17064d090a(String v0) {
    return 'লোড হয়নি: $v0';
  }

  @override
  String get uief523b46ad00 => 'তথ্য রিসেট হয়নি';

  @override
  String uie7926fb16618(String v0) {
    return 'রেখা সংরক্ষিত হয়নি: $v0';
  }

  @override
  String ui3a80d1d372c5(String v0) {
    return 'বিন্দু সংরক্ষিত হয়নি: $v0';
  }

  @override
  String uif7f1a2f5375b(String v0) {
    return 'বহুভুজ সংরক্ষিত হয়নি: $v0';
  }

  @override
  String get uidf0ddc77356e => 'ফিচারের তথ্য';

  @override
  String get ui4bd0951a03e8 => 'ফিচার মোছা হয়েছে';

  @override
  String get ui255785f96e54 => 'ফিচার সংরক্ষিত';

  @override
  String get ui8723967a8e50 => 'ফিচার হালনাগাদ হয়েছে — সিঙ্কের জন্য প্রস্তুত';

  @override
  String get ui897fa3cadce1 =>
      'প্রজেক্টের Apps Script সংযোগ দিয়ে Google Sheet থেকে সর্বশেষ XLSForm আনুন।';

  @override
  String get ui4c0d84107ddc => 'মাঠে যাচাই';

  @override
  String get uif08ab394a08f => 'তথ্যের ঘরের নাম';

  @override
  String get uie59928316474 => 'তথ্যের ঘরের নাম (ফাঁক ছাড়া)';

  @override
  String get uifd507b95760d =>
      'আগের উত্তর ও ফর্মের নিয়ম যুক্ত রাখতে তথ্যের ঘরের নাম অপরিবর্তিত থাকে।';

  @override
  String get ui9a5b8203dea6 => 'মাঠের তথ্য যাচাই';

  @override
  String ui04da12f4ecb1(String v0) {
    return 'মাঠের তথ্য যাচাই$v0';
  }

  @override
  String get ui3f996677147b => 'মাঠকর্মীর নাম';

  @override
  String ui5e39bef6ecec(String v0) {
    return 'মাঠকর্মী: $v0';
  }

  @override
  String get uib2a03b9b7a06 => 'প্রশ্নপত্র পূরণ';

  @override
  String get ui28620a15f945 => 'প্রশ্নপত্র পূরণ (ঐচ্ছিক)';

  @override
  String get ui61b933ebc0cf => 'অবস্থা অনুযায়ী বাছুন';

  @override
  String get uic3c626512bc9 => 'চূড়ান্ত নিশ্চিতকরণ';

  @override
  String get uib74bdee9c34f => 'শেষ করুন';

  @override
  String get ui26b73a211708 => 'ভিজিট শেষ করে মানচিত্র হালনাগাদ করুন';

  @override
  String uia72abb53ded4(String v0, String v1, String v2) {
    return 'প্রথম: $v0 • সর্বশেষ: $v1 • পরিবর্তন: $v2';
  }

  @override
  String get ui6671587fff89 => 'সব সাইট দেখান';

  @override
  String get uib64b0d0a894d => 'আমার অবস্থান অনুসরণ করুন';

  @override
  String get ui736e35f71fc4 =>
      'নতুন প্রজেক্টে Code.gs-এ পেস্ট করে শুধু projectId বদলান। অন্য চারটি স্থানধারক অপরিবর্তিত রাখুন; setupMapBanai আপনার API কী, ছবির ফোল্ডার ও তথ্যের ট্যাব তৈরি করবে।';

  @override
  String ui8e0113e9ab9a(String v0) {
    return '“$v0” ফর্ম সংরক্ষিত';
  }

  @override
  String ui6b40badab021(String v0, String v1) {
    return '“$v0” ফর্ম $v1-এ সংরক্ষিত';
  }

  @override
  String ui6c07b56f89a1(String v0) {
    return '“$v0” ফর্ম হালনাগাদ হয়েছে';
  }

  @override
  String get uic3de47ae9bd2 => 'ফর্মের বিবরণ';

  @override
  String get uib6ab025c2d78 => 'ফর্ম মোছা হয়েছে';

  @override
  String get ui16dd86a84b5d => 'ফর্মের বিবরণ';

  @override
  String get ui9fd01570e232 => 'ফর্মের ভাষা';

  @override
  String get uib93262f4bc3e => 'ফর্মের নাম';

  @override
  String ui16d3ca31f7bc(String v0, String v1) {
    return 'ডিভাইসের খালি জায়গা: $v0 · মানচিত্রের ক্যাশ: $v1';
  }

  @override
  String get ui0eace7f71b6c =>
      'সম্পূর্ণ জ্যামিতি, বৈশিষ্ট্য ও সংশোধনের মূল অবস্থা';

  @override
  String get uiaa77c8a72989 =>
      'সম্পূর্ণ রেখা/বহুভুজের জ্যামিতি রাখা হয়। স্থানাঙ্কে এর নির্দেশক বিন্দু দেখানো হচ্ছে।';

  @override
  String get uid78c401e571e => 'জিআইএস ফিচার';

  @override
  String get uidca76b4d8ff0 => 'জিআইএস মোড';

  @override
  String ui43688d96e197(String v0) {
    return 'জিআইএস মোড - $v0';
  }

  @override
  String get uib6cadf4fa6c5 => 'জিআইএস তথ্য';

  @override
  String get ui350358829580 => 'জিআইএস ফিচার';

  @override
  String get uieeddcc3bc1da => 'জিআইএস ফিচার';

  @override
  String get ui2159e983c6a6 => 'জিপিএস CSV ভিউয়ার';

  @override
  String ui816774591672(String v0) {
    return 'জিপিএস লগ ($v0)';
  }

  @override
  String get uied430db463ff => 'জিপিএস মোড';

  @override
  String get uiefc3f88b78d7 => 'জিপিএস বিন্দু';

  @override
  String get uida3c038f839c => 'জিপিএস নির্ভুলতা';

  @override
  String get ui881050d044a5 => 'জিপিএস নির্ভুলতা পর্যালোচনার সীমা';

  @override
  String ui5af8da29a579(String v0) {
    return 'জিপিএস নির্ভুলতার সীমা $v0 মি. করা হয়েছে';
  }

  @override
  String get ui68d8c2dfacb1 => 'জিপিএস নির্ভুলতা: পাওয়া যায়নি';

  @override
  String ui17dd2295e5dc(String v0) {
    return 'জিপিএস নির্ভুলতা: $v0 মি.';
  }

  @override
  String ui17ff8208bb50(String v0) {
    return 'জিপিএস নির্ভুলতা: ±$v0 মি.';
  }

  @override
  String uib412d9b03d31(String v0, String v1) {
    return 'জিপিএস নির্ভুলতা: ±$v0 মি. · সীমা: $v1 মি.';
  }

  @override
  String get uie8b468b0e65c =>
      'জিপিএস চলার দিক; স্থির ফোন কোন দিকে মুখ করে আছে তা দেখায় না।';

  @override
  String get ui1139289ac231 => 'জিপিএস সেটিংস';

  @override
  String ui70ae5325e6b1(String v0) {
    return 'জিপিএস পাওয়া যাচ্ছে না: $v0';
  }

  @override
  String get ui436b10d50cf3 => 'জিপিএস বিন্দু';

  @override
  String get uid79fea5a85f4 => 'জিপিএস: খোঁজা হচ্ছে...';

  @override
  String uiefa204b85e3c(String v0, String v1) {
    return 'জিপিএস: $v0, $v1';
  }

  @override
  String get ui9c30a3485a58 => 'গ্যালারি';

  @override
  String ui8f5281dddc73(String v0) {
    return '$v0টি ফিচারের ওয়েবম্যাপ তৈরি হচ্ছে — কিছুক্ষণ লাগতে পারে...';
  }

  @override
  String get ui7bd3c4506e38 => 'শুধু জ্যামিতি';

  @override
  String get uief385e8b9394 => 'অবস্থান যুক্ত';

  @override
  String get ui127e22e72c01 => 'জিওট্যাগযুক্ত ছবি যুক্ত হয়েছে';

  @override
  String get uic6651994b242 => 'GitHub রিপোজিটরি';

  @override
  String uie8adeb7a2680(String v0) {
    return 'নির্দেশিত ভিজিট$v0';
  }

  @override
  String ui1bfc2126eb38(String v0) {
    return 'আপনার নির্দেশক উচ্চতা থেকে পরিবর্তন: $v0';
  }

  @override
  String get uib7b664830ea7 => 'সহায়তা ও ম্যানেজার সেটআপ';

  @override
  String get uidaafa6d492ee => 'হেক্স রং';

  @override
  String get uid4c2792a7245 => 'লুকানো';

  @override
  String get ui088c4ac92ba8 => 'সব লুকান';

  @override
  String get uia0419d944de6 => 'প্রজেক্ট সেটআপে লুকান; তথ্য থাকবে';

  @override
  String get ui2daccedccf3f => 'সহায়ক লেখা (ঐচ্ছিক)';

  @override
  String get ui90ccd6497400 => 'ইতিহাস';

  @override
  String ui4b923abc4390(String v0) {
    return 'ইতিহাস: $v0';
  }

  @override
  String get ui4f57a1ce99e6 => 'অনুভূমিক নির্ভুলতা';

  @override
  String get uid3cddd6b7a18 =>
      'এই উৎসের তথ্য অফলাইনে ব্যবহারের জন্য ডাউনলোডের অনুমতি আমার আছে।';

  @override
  String get ui89f89c02cf47 => 'আইডি';

  @override
  String ui37983e6e11cc(String v0) {
    return 'আইডি  $v0';
  }

  @override
  String ui4f710ef77383(String v0, String v1, String v2) {
    return 'আইডি: $v0\n$v1$v2';
  }

  @override
  String get ui50e19fda0d5b => 'ছবি';

  @override
  String get uid6fbc9d2bdd5 => 'ইমপোর্ট';

  @override
  String get ui62d55664db41 => 'প্রজেক্ট ইমপোর্ট';

  @override
  String get ui05b32fd31a55 => 'XLSForm ইমপোর্ট';

  @override
  String get ui8e37624a8c4f => 'ফর্ম ইমপোর্ট করুন';

  @override
  String get ui9c5252af721c => 'নতুন কপি হিসেবে ইমপোর্ট';

  @override
  String get uifbae892997d9 => 'ইমপোর্ট হয়নি';

  @override
  String ui5f2e5f60d176(String v0) {
    return 'ইমপোর্ট হয়নি: $v0';
  }

  @override
  String get ui31fb23cfff40 => 'ফর্ম ইমপোর্ট';

  @override
  String get uib5d0a38444e6 => 'XLSForm (.xlsx) থেকে ইমপোর্ট';

  @override
  String get ui831d2e664b77 => 'আগে প্রজেক্ট ইমপোর্ট বা বাছুন';

  @override
  String get ui447a25af708e => 'প্রজেক্ট ইমপোর্ট';

  @override
  String get ui3901be0cffb1 => 'সাইট ইমপোর্ট';

  @override
  String get uia0256e6f7c6a =>
      'নির্দেশিত ভিজিট শুরুর আগে স্টাডি এরিয়ার ফিচার ইমপোর্ট করুন।';

  @override
  String ui18e5cf926e50(String v0, String v1) {
    return '“$v0” ইমপোর্ট হয়েছে, প্রশ্ন $v1টি';
  }

  @override
  String uicd9469193dca(String v0, String v1, String v2) {
    return '$v0টি নতুন ফিচার ইমপোর্ট, $v1টি হালনাগাদ ও $v2টি স্থানীয় সংস্করণ রাখা হয়েছে।';
  }

  @override
  String uic1cb782ca0df(String v0) {
    return 'Apps Script-এ $v0 নামে HTML ফাইল যোগ করে এই কোড পেস্ট করুন।';
  }

  @override
  String get ui9e7815322ba3 => 'সংগৃহীত উত্তর ও ছবি অন্তর্ভুক্ত করুন';

  @override
  String get uidf228157de13 => 'সিঙ্ক সংযোগ অন্তর্ভুক্ত করুন';

  @override
  String get uic075b040daff =>
      'বিশ্বস্ত তথ্যসংগ্রাহকদের জন্য Apps Script URL ও API কী রাখুন। প্রাপকরা কী পড়তে পারবেন।';

  @override
  String get uieb897be763fc => 'অসম্পূর্ণ খসড়া অন্তর্ভুক্ত করুন';

  @override
  String get ui2147c24042cf =>
      'এই বিন্দুগুলোর সঙ্গে যুক্ত অন্যান্য ইতিহাসও অন্তর্ভুক্ত। ইমপোর্টের মূল ফাইল ও প্রজেক্টের সেটিংস থাকবে।';

  @override
  String get ui95949d0c4089 =>
      'সার্ভের ইতিহাস, খসড়া ও বর্তমান স্টাডি এরিয়ার বিন্দু অন্তর্ভুক্ত।';

  @override
  String get ui80cf9d54825e => 'আসা ফাইল';

  @override
  String ui233771f44a3f(String v0, String v1) {
    return 'আসা তথ্য: $v0, $v1';
  }

  @override
  String get ui370b7d97d11f =>
      'ঘরের ভেতরের পাঠ, ঋণাত্মক মানসহ, অবিশ্বস্ত হতে পারে। ভূমির নির্দেশক উচ্চতা নির্ধারণের আগে বাইরে পরীক্ষা করুন।';

  @override
  String get ui9edcffff4461 => 'পূর্ণসংখ্যা';

  @override
  String get uia2f0dfadaaeb => 'অবৈধ স্থানাঙ্ক';

  @override
  String get uicdc2fc2b9596 => 'দুটিকে আলাদা ফিচার হিসেবে রাখুন';

  @override
  String get uib1617f6d12ea => 'বর্তমান মানচিত্র রাখুন';

  @override
  String get ui7b0d52c5669d => 'স্থানীয় সংস্করণ রাখুন';

  @override
  String get ui74341e3c271d => 'লেবেল';

  @override
  String get uid95033fb8177 => 'লেবেল ও নাম প্রয়োজন';

  @override
  String get ui89b86ab0e66f => 'ভাষা';

  @override
  String uid44a265f1b26(String v0) {
    return 'শেষ সিঙ্ক: $v0';
  }

  @override
  String get uiced3905ec822 => 'অক্ষাংশ';

  @override
  String get ui4343635cf237 => 'লেয়ার';

  @override
  String ui78f4d55f17c1(String v0) {
    return 'লেয়ার  $v0';
  }

  @override
  String get ui66f2d76aa42a => 'লেয়ারের নাম';

  @override
  String get ui7d86eb32993a => 'লেয়ারের বিন্দু মুছে ইতিহাস রাখা হয়েছে';

  @override
  String get ui3a809dffc14e =>
      'লেয়ারের বিন্দু, ইতিহাস ও সিঙ্কের সারি মোছা হয়েছে';

  @override
  String get ui28d177aa2889 => 'লেয়ার সরানো হয়েছে।';

  @override
  String get ui8a398db6aeb3 => 'লেয়ারের ধরন';

  @override
  String get uif055f18aeadc => 'লেয়ার';

  @override
  String get ui92b53dd55ccd => 'লেয়ার ও প্রশ্নপত্র যোগ হয়েছে';

  @override
  String get ui50fe884f3bed => 'মুছতে খালি রাখুন।';

  @override
  String get uia36ef8aba229 => 'আলো';

  @override
  String get ui566016d4e5ce => 'আলো থিম প্রয়োগ করা হয়েছে';

  @override
  String get uiea9676003762 => 'রেখা';

  @override
  String get ui762185bb9c08 => 'রেখা সংরক্ষিত';

  @override
  String get ui0c803e02a46e => 'লাইভ জিপিএস রিডিং ও কোঅর্ডিনেট লগিং';

  @override
  String ui2f494babf600(String v0, String v1) {
    return 'স্থানীয় সংশোধন $v0; আসা সংশোধন $v1';
  }

  @override
  String get ui55a6907830e4 => 'অবস্থান দেখান';

  @override
  String get uid219c68101f5 => 'অবস্থান';

  @override
  String uid745ebd37fd5(String v0) {
    return 'অবস্থান  $v0';
  }

  @override
  String get uie6eb0764038f => 'অবস্থান সরানো হয়েছে';

  @override
  String get ui2276b254455d => 'অবস্থান বদলেছে';

  @override
  String ui6965945ee3f4(String v0) {
    return 'অবস্থানের সমস্যা: $v0';
  }

  @override
  String get uid98b3dea33e0 => 'অবস্থানের অনুমতি দেওয়া হয়নি';

  @override
  String get uic9b51a096e5c => 'অবস্থানের অনুমতি প্রয়োজন';

  @override
  String get uib47a40701451 => 'অবস্থান সরানো হয়েছে';

  @override
  String get ui3a171968d250 =>
      'স্ক্রিন বন্ধ থাকলেও লগিং চলতে থাকে। যেকোনো সময় জিপিএস মোড ছেড়ে যেতে পারেন; থামাতে এখানে ফিরে আসুন।';

  @override
  String get ui862b905c967b => 'দীর্ঘ লেখা';

  @override
  String get ui6f9f011c5d36 => 'দ্রাঘিমাংশ';

  @override
  String get ui624beb5cfdac => 'মূল স্টাডি এরিয়া';

  @override
  String get uie3dda04d8ad4 => 'প্রজেক্টের ফাইল ও লেয়ার পরিচালনা';

  @override
  String get uie5dae44b774f => 'প্রজেক্টের ফাইল ও সড়ক লেয়ার পরিচালনা';

  @override
  String get uie29679599257 => 'মানচিত্রের লেয়ার';

  @override
  String ui06cd4e58b2d2(String v0) {
    return 'মানচিত্র এক্সপোর্ট হয়নি: $v0';
  }

  @override
  String get ui55592984d7c8 => 'মানচিত্রের ছবি সংরক্ষিত';

  @override
  String ui61e2ca3a278c(String v0) {
    return 'মানচিত্রের প্রিভিউ হালনাগাদ হয়নি। জ্যামিতি রাখা আছে: $v0';
  }

  @override
  String ui997f080ca254(String v0) {
    return 'মানচিত্রের প্রিভিউ হয়নি: $v0। সংরক্ষিত ফিচার অক্ষত আছে।';
  }

  @override
  String ui2997787343d9(String v0) {
    return 'মানচিত্রে এখনও পর্যালোচনা প্রয়োজন: $v0';
  }

  @override
  String get uif001c704b2c4 =>
      'মানচিত্রের টাইলের জন্য ইন্টারনেট প্রয়োজন। সংরক্ষিত জ্যামিতি এই ডিভাইসেই থাকবে।';

  @override
  String uia81b9bf05314(String v0) {
    return 'মানচিত্র হালনাগাদে এখনও পর্যালোচনা প্রয়োজন: $v0';
  }

  @override
  String get ui6e34e5bb76d4 => 'মানচিত্র-ভিত্তিক স্থানিক সম্পাদনা ও লেয়ার';

  @override
  String get uib5b7b220e6fc => 'ম্যাপবানাই';

  @override
  String get uibfd3beb1d90d =>
      'MapBanai তৈরিতে CARE প্রজেক্ট ও ব্র্যাক বিশ্ববিদ্যালয়ের ব্র্যাক জেমস পি গ্রান্ট স্কুল অব পাবলিক হেলথের অবদান কৃতজ্ঞতার সঙ্গে স্বীকার করা হচ্ছে।';

  @override
  String get ui0911cce79bf0 => 'সম্পন্ন চিহ্নিত করুন';

  @override
  String get ui67c691a7034c => 'সংগ্রহ হয়নি চিহ্নিত করুন';

  @override
  String get uibd37e4010390 => 'অসম্পন্ন চিহ্নিত করুন';

  @override
  String get ui6d9883bf2564 =>
      'একই ফোল্ডারে মিলযুক্ত DBF পাওয়া যায়নি। SHP ও সঙ্গী ফাইল একসঙ্গে বাছুন বা তাদের ZIP ইমপোর্ট করুন।';

  @override
  String get uidf64ffd50ab4 => 'গ্রহণযোগ্য নির্ভুলতার সর্বোচ্চ সীমা';

  @override
  String get uic4af0cbf2c57 => 'ডাউনলোডের সর্বোচ্চ আকার';

  @override
  String get uid4fd0a232ee5 => 'পরিমাপ';

  @override
  String get uiff3c5f95f7ed => 'ক্ষেত্রফল মাপুন';

  @override
  String get ui44d5eb4c451a => 'দূরত্ব মাপুন';

  @override
  String get uiacca68cf2978 => 'ক্ষেত্রফল মাপতে মানচিত্রে বিন্দু যোগ করুন';

  @override
  String get uif9387f539eef => 'দূরত্ব মাপতে মানচিত্রে বিন্দু যোগ করুন';

  @override
  String get uide10edfac7e7 => 'পরিমাপ';

  @override
  String get ui31d24b69ea44 => 'পরিমাপ (যেমন লবণাক্ততা)';

  @override
  String get ui7f4511910c62 => 'পরিমাপ একক';

  @override
  String get ui57f5f5efbc59 => 'মেনু';

  @override
  String get uif729a52d65af => 'সাইটের আরও তথ্য';

  @override
  String get uib5b2f93a6b40 =>
      'শুধু বিন্দু সরানো যায়। রেখা ও এলাকার জন্য জ্যামিতি আবার আঁকুন।';

  @override
  String get uica80cd791254 => 'চলার দিক পেতে জিপিএস চালু রেখে চলুন';

  @override
  String get uif0948991d684 => 'বহু অংশের জ্যামিতি';

  @override
  String get ui51a144b4a026 => 'আমার তথ্যসংগ্রাহকের নাম';

  @override
  String get ui53f1631a0c9a => 'আমার ফর্ম';

  @override
  String get uia8f40df7087b => 'আমার নাম';

  @override
  String get ui3e2d598760ca => 'আমার উত্তর';

  @override
  String get ui709a23220f2c => 'নাম';

  @override
  String ui1dc947fc26a5(String v0) {
    return 'নাম  $v0';
  }

  @override
  String get ui9c9f03a83941 => 'নাম (ঐচ্ছিক)';

  @override
  String get uie997727f66e0 => 'পরিবর্তনের ইতিহাসে ব্যবহৃত নাম';

  @override
  String get ui3158214aeaa5 => 'মূল Excel ওয়ার্কবুক';

  @override
  String get ui33a506cf6ec5 => 'পর্যালোচনা প্রয়োজন';

  @override
  String get ui8d5addc5f483 => 'কখনো সিঙ্ক হয়নি';

  @override
  String get ui19770feca231 =>
      'নতুন ও হালনাগাদ ফিচারে প্রশ্নপত্র প্রয়োজন। আগে সার্ভে ফর্ম বাছুন।';

  @override
  String get ui5dcfe56ae106 => 'নতুন সংগ্রহ পর্ব';

  @override
  String get ui26445874a106 => 'নতুন কী';

  @override
  String get uia9cbc7c7f1b8 => 'নতুন লগ (নতুন CSV)…';

  @override
  String get uie5bcbe241fab => 'নতুন প্রজেক্ট';

  @override
  String get ui2769be10eb54 => 'নতুন স্টাডি লেয়ার';

  @override
  String ui7a022d6fe436(String v0) {
    return 'নতুন সংস্করণ: $v0';
  }

  @override
  String get ui816c52fd2bdd => 'না';

  @override
  String get ui392acae55a83 => 'নির্বাচিত প্রজেক্টে জিআইএস ফিচার পাওয়া যায়নি';

  @override
  String get ui433fd35b58a5 => 'এখনও জিপিএস লগ নেই';

  @override
  String get uif617dbefda4a =>
      'সীমার বেশি ত্রুটির কোনো জিপিএস পাঠ পর্যালোচনার বাকি নেই।';

  @override
  String get uie4dc9d32f051 => 'কোনো উত্তর রেকর্ড হয়নি।';

  @override
  String get ui43572a512bc0 => 'কোনো বৈশিষ্ট্য নেই';

  @override
  String get ui87d822a81929 =>
      'এখনও সম্পূর্ণ পর্যবেক্ষণ নেই। প্রথম ভিজিট যোগ করুন।';

  @override
  String get ui5c8ea1c2ed1a =>
      'কোনো বিরোধ নেই। ইমপোর্টের সংশোধনে মূল তথ্য ও পরিবর্তনের ইতিহাস আছে।';

  @override
  String get uied30d59a8d6d =>
      'সংযুক্ত সড়কপথ পাওয়া যায়নি। প্রজেক্ট সেটিংসে সড়কের লেয়ার যোগ করুন।';

  @override
  String get ui853fb4fdd27f => 'স্থানাঙ্ক পাওয়া যায়নি';

  @override
  String get uie2dbdc3a52a2 => 'ছবি তোলার সময় স্থানাঙ্ক পাওয়া যায়নি';

  @override
  String get uif354c94fcf63 => 'বিবরণ নেই';

  @override
  String get ui904b785a37ab =>
      'এই প্রজেক্টের জন্য এখনো কোনো ফর্ম নেই। আপনার প্রথম সার্ভে ফর্ম তৈরি বা ইমপোর্ট করতে ট্যাপ করুন।';

  @override
  String get ui92d5dd12f567 =>
      'এখনও ফর্ম নেই। ফর্ম যোগ বা XLSForm ইমপোর্ট করুন।';

  @override
  String get ui2f5bb047a0f6 => 'জ্যামিতি সংগ্রহ করা হয়নি';

  @override
  String get ui036703da6a32 => 'এখনও দিক পাওয়া যায়নি';

  @override
  String get ui836f41ede479 => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get ui6087965952b8 => 'লেয়ার রেকর্ড হয়নি';

  @override
  String get uiae6b04b93c15 => 'মিলযুক্ত সাইট নেই';

  @override
  String get uidfa7f347627b => 'নতুন কোনো সংস্করণ নেই।';

  @override
  String get uiae25632243b8 => 'এখনও অফলাইন প্যাকেজ ডাউনলোড করা হয়নি।';

  @override
  String get ui382cac49e35d => 'বিকল্প নেই। অন্তত একটি যোগ করুন।';

  @override
  String get ui48c8c8d3aa3b =>
      'এখনও ছবি নেই।\nএখানে দেখতে সার্ভে ফর্ম থেকে ছবি তুলুন।';

  @override
  String get uie92a1f7c42cf => 'প্রজেক্ট বাছা হয়নি';

  @override
  String get uie5fafd1c8ebb =>
      'কোনো প্রজেক্ট নির্বাচিত নয় — বেছে নিতে ট্যাপ করুন';

  @override
  String get ui6665189f3494 => 'কোনো প্রজেক্ট নেই।';

  @override
  String get uicac330d7f9c7 => 'এখনও প্রজেক্ট নেই';

  @override
  String get ui8f998ef5b30b =>
      'এখনও প্রজেক্ট নেই। তথ্য সংগ্রহের জন্য একটি তৈরি করুন।';

  @override
  String get uib463f7374d70 => 'এখনও প্রশ্ন নেই। শুরু করতে প্রশ্ন যোগ করুন।';

  @override
  String uie9ee6096e679(String v0) {
    return 'মানচিত্রে দেখানোর জন্য “$v0”-এ কোনো পাঠ নেই';
  }

  @override
  String get ui151474224c7d => 'নির্বাচিত লগে পাঠ নেই';

  @override
  String get ui7640fd2eb8bb => 'মানচিত্রে দেখানোর পাঠ নেই';

  @override
  String get ui9b6d98a4e333 => 'এখনও পাঠ নেই';

  @override
  String get uife1834e75700 =>
      'এখনও পরিবর্তন রেকর্ড হয়নি। প্রথম সম্পাদনা সংরক্ষণের সময় ইমপোর্টের মূল অবস্থা রাখা হবে।';

  @override
  String get ui87becd98de59 => 'প্রজেক্টে এখনও সহায়ক লেয়ার নেই।';

  @override
  String get ui8899a85385a5 => 'সংস্করণের বিবরণ দেওয়া হয়নি।';

  @override
  String get ui8b43f54f33b8 =>
      'নির্বাচিত প্রজেক্টে সংরক্ষিত মানচিত্রের তথ্য নেই';

  @override
  String get ui8c878a00b717 => 'এখনও সংরক্ষিত উত্তর বা খসড়া নেই';

  @override
  String get ui19979c176042 => 'এক্সপোর্টের জন্য সংরক্ষিত উত্তর নেই';

  @override
  String get uiaf682dd08f05 => 'এখনও সংরক্ষিত উত্তর নেই';

  @override
  String get ui58128e2f84a1 =>
      'টেমপ্লেট সংরক্ষিত নেই। প্রস্তুত প্রজেক্ট খুলে পুনর্ব্যবহারযোগ্য টেমপ্লেট থেকে একটি সংরক্ষণ করুন।';

  @override
  String get uif30931fdc702 =>
      'ফাইলে সাইট পাওয়া যায়নি। ফরম্যাট ও অক্ষাংশ/দ্রাঘিমাংশের কলাম দেখুন।';

  @override
  String get uic548672fb2d6 => 'এক্সপোর্টের সাইট নেই';

  @override
  String get ui7e2d4edf8815 => 'এখনও সাইট নেই';

  @override
  String get uif26623d21a06 =>
      'নির্বাচিত প্রজেক্টে সার্ভের উত্তর পাওয়া যায়নি';

  @override
  String get uiac6625252c3f => 'অনির্ধারিত সাইট নেই';

  @override
  String get ui2a5fc945373b => 'সংগ্রহ হয়নি';

  @override
  String get ui7bf902055995 => 'এখনও গণনা হয়নি';

  @override
  String get ui9f7b8e910f33 => 'অবস্থান যুক্ত নেই';

  @override
  String get uie45714907316 => 'এখন নয়';

  @override
  String get ui2c924e308820 => 'নোট';

  @override
  String get ui4e39567064b6 => 'নোট (ঐচ্ছিক)';

  @override
  String get ui70440046a3dc => 'নোট';

  @override
  String get ui4d56ca9be0c8 => 'নোট (ঐচ্ছিক)';

  @override
  String get ui9ce3bd4224c8 => 'ঠিক আছে';

  @override
  String get ui998c59e3a961 => 'ফিল্টার ও পপআপ সহ অফলাইন HTML মানচিত্র';

  @override
  String get ui119fc20f71cb => 'অফলাইন মানচিত্র';

  @override
  String ui954017dab827(String v0, String v1, String v2) {
    return 'অফলাইন · জুম $v0–$v1\n$v2';
  }

  @override
  String ui952291e4cc99(String v0, String v1, String v2, String v3) {
    return 'অফলাইন: $v0 · জুম $v1–$v2\n$v3';
  }

  @override
  String get uia7f9620cca32 => 'এই ডিভাইসে';

  @override
  String get ui439fd7184b90 =>
      'এক প্রজেক্টেই প্রশ্ন, মানচিত্র ও মাঠের কাজ যুক্ত থাকে।';

  @override
  String ui2e563e00b757(String v0) {
    return 'অনলাইন · $v0';
  }

  @override
  String get uia8076ae6d925 =>
      'শুধু এই সীমার চেয়ে বেশি ত্রুটির পাঠ দেখানো হয়। গৃহীত পাঠ লুকানো থাকে; ছবি ও রেকর্ড সংরক্ষিত থাকে।';

  @override
  String get uif0fa69f38b14 => 'অস্বচ্ছতা';

  @override
  String get uicf9b77061f7b => 'খুলুন';

  @override
  String get ui805e12a18145 => 'জিপিএস মোড খুলুন';

  @override
  String get uif8063877dde0 => 'অ্যাপের অনুমতির সেটিংস খুলুন';

  @override
  String get ui672b0208a0f6 => 'ক্যামেরা খুলুন';

  @override
  String get ui2150bfbc8020 => 'ডিভাইসের অবস্থান সেটিংস খুলুন';

  @override
  String get ui5ebdd4c27529 => 'Google Maps-এ খুলুন';

  @override
  String get ui052269b2c823 => 'ব্রাউজারে খুলুন';

  @override
  String get uie56f29da2af3 => 'মানচিত্র খুলুন';

  @override
  String get uicb29cc08fc8f => 'স্টাডি এরিয়ার মানচিত্র খুলুন';

  @override
  String get ui7a5cbb59b55f => 'সার্ভে খুলুন';

  @override
  String get ui3f7389db6ed3 => 'বিকল্পের নাম ও লেবেল প্রয়োজন';

  @override
  String ui7ef766113146(String v0) {
    return 'বিকল্প ($v0)';
  }

  @override
  String get uia6aab53912af => 'ইমপোর্ট করা মূল তথ্য';

  @override
  String get ui5651e882f4a9 => 'উত্তরের অন্যান্য ফরম্যাট';

  @override
  String get ui781961bc81c2 => 'বিরতি';

  @override
  String get uie1f973e6e1a9 => 'জিপিএস প্রবাহে বিরতি দিন';

  @override
  String get uif0ac0a5c9beb => 'যাচাই বাকি';

  @override
  String get ui8bc8ef67bedc => 'সময়কাল / ঋতু (ঐচ্ছিক)';

  @override
  String get ui5f602ed63d66 =>
      'ফোনের দিক · চৌম্বক উত্তর। ফোন মোটামুটি সমতল রাখুন।';

  @override
  String get uia6685fdd7078 => 'ছবি যুক্ত হয়েছে';

  @override
  String get ui568e6f033820 => 'জিপিএস অবস্থানসহ ছবি যুক্ত হয়েছে।';

  @override
  String get ui782facfeed05 => 'ছবির গ্যালারি';

  @override
  String ui431dc8d2e072(String v0) {
    return 'ছবি: $v0';
  }

  @override
  String get uic8b2e864eccb => 'ছবি';

  @override
  String get uid3a2a512adb0 => 'ডিভাইস থেকে প্রজেক্ট প্যাকেজ বাছুন';

  @override
  String get uia41391d44a4e => 'অন্তত একটি প্রশ্ন যোগ করুন';

  @override
  String get ui0e992c42efc9 => 'ফর্মের নাম লিখুন';

  @override
  String get uic9bcbcdab335 => 'প্রজেক্টের নাম লিখুন';

  @override
  String get uif79a28423ed1 => 'বিন্দু';

  @override
  String get uic958a23eb380 => 'বিন্দু সরানো হয়েছে';

  @override
  String get ui5be4bcfb8831 => 'বিন্দু সংরক্ষিত';

  @override
  String ui27c764375b49(String v0) {
    return 'বিন্দুর আকার: $v0';
  }

  @override
  String get ui85066b2ca9c0 => 'বহুভুজ';

  @override
  String get uidd91219a18cb => 'বহুভুজ সংরক্ষিত';

  @override
  String get uic2519dfe070d => 'বহুভুজের বিন্দুগুলোকে একটি এলাকা ঘিরতে হবে।';

  @override
  String get ui70f0551a5274 => 'বহনযোগ্য HTML মানচিত্র';

  @override
  String get uifc0196129453 => 'অবস্থান নির্ণয় হচ্ছে…';

  @override
  String get ui1c7b0d771fbc => 'পছন্দের ভাষা';

  @override
  String get ui90aee2f30cc4 => 'মিলযুক্ত সাইটের প্রিভিউ';

  @override
  String get uib08dc534b1c0 => 'আগের তথ্যের ব্যাকআপ পাওয়া গেছে';

  @override
  String get uif6f4da8d93e8 => 'প্রজেক্ট';

  @override
  String ui1e7149806327(String v0) {
    return '“$v0” প্রজেক্ট মোছা হয়েছে';
  }

  @override
  String get uibd3091d453d7 => 'প্রজেক্ট অ্যাটলাস';

  @override
  String get ui431c23dde814 => 'প্রজেক্ট ইতিমধ্যে আছে';

  @override
  String get ui225209bf7dec => 'প্রজেক্ট আর্কাইভ হয়েছে';

  @override
  String get uib23910158f74 => 'প্রজেক্ট কোড';

  @override
  String uib56eb4f4a3ed(String v0) {
    return 'প্রজেক্ট তৈরি হয়েছে: $v0';
  }

  @override
  String get ui15626cd209c8 => 'প্রজেক্ট সফলভাবে এক্সপোর্ট হয়েছে।';

  @override
  String get ui966c4d7db1ab => 'প্রজেক্টের ফাইল ও মানচিত্রের লেয়ার';

  @override
  String get ui5276d025220f => 'প্রজেক্ট সফলভাবে ইমপোর্ট হয়েছে।';

  @override
  String get ui9c8bf2326c83 => 'প্রজেক্টের লেয়ার';

  @override
  String get ui0a71e1dcd500 => 'একাধিক লগ ওয়েবম্যাপে দেখান';

  @override
  String get uib046dc8ee258 => 'একাধিক লগ ওয়েবম্যাপে দেখান';

  @override
  String get uiab9773fcf6b2 => 'প্রজেক্টের নাম';

  @override
  String get uiaf9d308f03d7 => 'এই খসড়ার প্রজেক্ট পাওয়া যায়নি';

  @override
  String uicdaab9257a39(String v0) {
    return 'প্রজেক্ট পাওয়া যায়নি: $v0';
  }

  @override
  String get ui62d5732e064a => 'ওয়েবম্যাপে দেখান';

  @override
  String get uibf395c9c1cc0 => 'প্রজেক্টের বিকল্প';

  @override
  String ui8f59a4be38fd(String v0) {
    return 'প্রজেক্টের নাম “$v0” করা হয়েছে';
  }

  @override
  String get uicd1b8386c131 => 'প্রজেক্ট ফিরিয়ে আনা হয়েছে';

  @override
  String get ui95590645e1aa => 'প্রজেক্ট সেটিংস';

  @override
  String get uia0e72cd3d2e8 => 'প্রজেক্ট সেটআপ';

  @override
  String get ui2e5be53bba6a => 'প্রজেক্টের সার্ভে ফর্ম';

  @override
  String get uibd1dec2f2c71 => 'প্রজেক্টের ভেক্টর লেয়ার';

  @override
  String get ui36043cc2443b => 'উত্তরসহ প্রজেক্ট (.mbproj)';

  @override
  String get uia476649af65d => 'উত্তর ছাড়া প্রজেক্ট (.mbproj)';

  @override
  String ui343f53c678de(String v0) {
    return '$v0টি লগ মানচিত্রে দেখান';
  }

  @override
  String ui29bccf013ea5(String v0) {
    return 'প্রজেক্ট: $v0';
  }

  @override
  String get uif4c26c16fcc1 => 'প্রশ্নের লেবেল';

  @override
  String ui16b39146c10b(String v0) {
    return 'প্রশ্নের নাম বৈধ ও অনন্য হতে হবে: $v0';
  }

  @override
  String get uia60d848de552 => 'প্রশ্নের ধরন';

  @override
  String get ui42d2c2bca9d8 => 'প্রশ্নপত্র';

  @override
  String get ui4be7ca321825 =>
      'নতুন বা হালনাগাদ ফিচারের জন্য প্রশ্নপত্র প্রয়োজন।';

  @override
  String get ui8ff5b8ed3fbd => 'তুলনার প্রশ্নপত্র';

  @override
  String get ui9a1fc1731f62 => 'প্রশ্ন';

  @override
  String ui1e9664cb649f(String v0) {
    return 'প্রশ্ন ($v0)';
  }

  @override
  String get uicfee98bac20a =>
      'জিপিএস মোডে ট্র্যাক রেকর্ড করুন। দেখা ও ওয়েবম্যাপে যোগ করার জন্য এখানে পাওয়া যাবে।';

  @override
  String get ui607b32a9959b => 'রেখা রেকর্ড';

  @override
  String get uiaec89b24cf54 => 'বিন্দু রেকর্ড';

  @override
  String get uid8bada38f2f6 => 'বহুভুজ রেকর্ড';

  @override
  String get ui2a0da2391fbd => 'ট্র্যাক রেকর্ড';

  @override
  String get uid5237368f5b8 => 'জিপিএস অবস্থানে সার্ভে রেকর্ড করুন';

  @override
  String get uic28f100b78f1 => 'এই লগে রেকর্ড করুন';

  @override
  String get uidb83f96c32b4 => 'রেকর্ডের ধরন';

  @override
  String get ui0161dce2f8e3 => 'রেকর্ডের দিন (স্থানীয় সময়)';

  @override
  String get ui460b7c299f9e => 'রেকর্ডিং বন্ধ হয়েছে';

  @override
  String uidea4c38150d8(String v0) {
    return '“$v0”-এ রেকর্ড হচ্ছে';
  }

  @override
  String get uif67cf3727042 => 'পুনরাবৃত্ত তথ্য সংগ্রহ';

  @override
  String get uic5d2acf8e03c => 'জ্যামিতি আবার আঁকুন';

  @override
  String get ui07e6773d4d9c => 'সহায়ক লেয়ার';

  @override
  String get ui56e3badc4e6c => 'রিফ্রেশ';

  @override
  String get uif2fe9f375cdd => 'জিপিএস রিফ্রেশ';

  @override
  String get uia06a8c2c4e63 => 'নির্ভুলতা পর্যালোচনা রিফ্রেশ';

  @override
  String get ui78b1a724f71d => 'প্যাকেজ রিফ্রেশ';

  @override
  String get ui43f7ea278bf5 => 'সড়কপথ রিফ্রেশ';

  @override
  String get ui526e453413f1 => 'প্রাসঙ্গিকতার শর্ত (ঐচ্ছিক)';

  @override
  String get uie963907dac5c => 'সরান';

  @override
  String get uif08d9c42d5af => 'জ্যামিতি সরান';

  @override
  String get uia1cc8f73a0c8 => 'ইমপোর্টের ফাইল ও এর বিন্দু সরান';

  @override
  String get ui307eeae7c0c0 => 'ইমপোর্টের ফাইল সরাবেন?';

  @override
  String get uif8ed171e210e => 'লেয়ার সরান';

  @override
  String get ui2bd3912b6424 => 'লেয়ার সরাবেন?';

  @override
  String get uic8f5eda8ace9 => 'ছবি সরান';

  @override
  String get ui12605ebbc10b => 'টেমপ্লেট সরান';

  @override
  String get ui67d95d8bf8e4 => 'ডিভাইস থেকে এই ছবি সরাবেন? এটি ফেরানো যাবে না।';

  @override
  String uid6db25dad8ea(String v0) {
    return 'নির্বাচিত $v0টি সাইট ও তাদের স্থানীয় ইতিহাস মুছবেন? এটি ফেরানো যাবে না।';
  }

  @override
  String ui3122a19db20f(String v0) {
    return 'ইমপোর্টের $v0টি বিন্দু ও তাদের ইতিহাস সরানো হয়েছে।';
  }

  @override
  String get uid3f4cb898fbe => 'নাম বদলান';

  @override
  String get ui633018f5a717 => 'প্রজেক্টের নাম পরিবর্তন';

  @override
  String get uia7cf7b25a703 => 'প্রতিস্থাপন';

  @override
  String get uif16ae4a6851b => 'আগের প্রজেক্ট প্রতিস্থাপন করুন';

  @override
  String get uia89003cf0f13 => 'ছবি বদলান';

  @override
  String get uieed6bfb41051 => 'আবশ্যক';

  @override
  String get uif83e688e4165 => 'ডেটা রিসেট';

  @override
  String get ui6e617e4fc9da => 'উত্তর';

  @override
  String ui224ce158da54(String v0) {
    return 'উত্তরের সংশোধন $v0';
  }

  @override
  String get ui69618bf63a73 => 'শুধু উত্তর (JSON)';

  @override
  String get ui3cbe6d6b9a8d => 'ফিরিয়ে আনুন';

  @override
  String uid2dd4647b6a1(String v0) {
    return '“$v0” ফিরিয়ে আনবেন? এটি আবার প্রজেক্ট সেটআপে দেখা যাবে।';
  }

  @override
  String ui04d55c7638dc(String v0) {
    return 'ফিরিয়ে আনা যায়নি: $v0';
  }

  @override
  String get uib3bd0b5a7049 => 'আবার চালু করুন';

  @override
  String get ui7e5b0347808e => 'জিপিএস প্রবাহ আবার চালু করুন';

  @override
  String get ui21b653c8009c => 'সংরক্ষিত খসড়া চালিয়ে যান';

  @override
  String get uibd0551d8ee60 => 'সার্ভের খসড়া চালিয়ে যান';

  @override
  String get ui16457335a763 => 'আবার তুলুন';

  @override
  String get ui9f5cd8a2e880 => 'আবার চেষ্টা করুন';

  @override
  String get uifce3486f03c9 => 'নির্বাচিত ছবির জিপিএস আবার চেষ্টা করুন';

  @override
  String get ui6514e3faf04e => 'মানচিত্র হালনাগাদ আবার চেষ্টা করুন';

  @override
  String get ui29ae74246d4f => 'পুনর্ব্যবহারযোগ্য টেমপ্লেট';

  @override
  String get ui42468c5b8e1a =>
      'নতুন অভিযানে প্রশ্নপত্র ও নামযুক্ত লেয়ার পুনর্ব্যবহার করুন। টেমপ্লেটে শুধু সেটআপ থাকে; প্রতিটি নতুন প্রজেক্টের নতুন পরিচয় ও নিজস্ব ক্লাউড সংযোগ প্রয়োজন। আগের ভিজিট ও ছবি মূল প্রজেক্টেই থাকে।';

  @override
  String get ui5d4f7bae5f1d =>
      'আপনার সীমার চেয়ে বেশি ত্রুটির জিপিএস পাঠ পর্যালোচনা করুন। মাঠের কাজের উপযোগী হলে পাঠটি গ্রহণ করুন।';

  @override
  String get ui4554e09dd77d =>
      'ইন্টারনেটে যুক্ত হলে পরিবর্তন দেখে প্রয়োগ করুন। নতুন সার্ভেতে নতুন সংস্করণ ব্যবহার হবে; সংরক্ষিত রেকর্ড ও খসড়ায় আগের প্রশ্নই থাকবে।';

  @override
  String get ui617ceeb41a65 => 'মোছার আগে দেখুন';

  @override
  String get ui98bd92828e31 => 'ফর্ম ইমপোর্ট পর্যালোচনা';

  @override
  String get ui0f667a68b0fb => 'মানচিত্রের বিরোধ পর্যালোচনা';

  @override
  String get ui6fc4758d8c5b => 'জ্যামিতি দেখুন বা সম্পাদনা করুন';

  @override
  String get uif960c9515a5b => 'সংরক্ষিত সার্ভে দেখুন';

  @override
  String get uicaacc870d2ec => 'দলের ইমপোর্ট পর্যালোচনা';

  @override
  String get uib5bb91f5eb74 => 'ভিজিট দেখুন / মানচিত্র হালনাগাদ আবার চেষ্টা';

  @override
  String ui39b253e1a983(String v0) {
    return 'সংশোধনের ইতিহাস ($v0)';
  }

  @override
  String get uia4c9e7ac0818 => 'সড়ক নেটওয়ার্ক';

  @override
  String get ui1e975193e087 => 'সার্ভে চালু করুন';

  @override
  String get uid0d3749eff6d => 'প্রজেক্ট ফাইল সংরক্ষণ';

  @override
  String get uif5c9eb0215b6 => 'প্রজেক্ট শেয়ার';

  @override
  String get uiefc007a393f6 => 'সংরক্ষণ';

  @override
  String get uid69b9213e0b9 => 'বিন্দু সংরক্ষণ';

  @override
  String get ui80f3d11ef8a0 => 'তবুও সংরক্ষণ…';

  @override
  String get ui77d9d7593ba8 => 'খসড়া হিসেবে সংরক্ষণ';

  @override
  String get ui4f25637a5b7e => 'খসড়া সংরক্ষণ';

  @override
  String uie89b75ddfae2(String v0) {
    return 'সংরক্ষিত হয়নি: $v0। সম্পাদনাগুলো রাখা আছে।';
  }

  @override
  String get uia8a28cda227e => 'ফিচার সংরক্ষণ';

  @override
  String get ui1194006347b8 => 'জ্যামিতি সংরক্ষণ';

  @override
  String get ui48b133194fc7 => 'রেখা সংরক্ষণ';

  @override
  String get uie5c47400711a => 'অবস্থান সংরক্ষণ';

  @override
  String get uib38557160b3a => 'বিন্দু সংরক্ষণ';

  @override
  String get uidb6b0a422ee8 => 'বিন্দু সংরক্ষণের স্থান…';

  @override
  String get uieba0e7af2b62 => 'বহুভুজ সংরক্ষণ';

  @override
  String get uif8132b134652 => 'উত্তর সংরক্ষণ';

  @override
  String get uiae8411a6278d => 'নির্বাচিত লেয়ার ও প্রশ্নপত্র সংরক্ষণ';

  @override
  String get uiaefec51925dd =>
      'শেষ করতে প্রশ্নপত্র সংরক্ষণ ও ছবি যুক্ত করুন। যেকোনো সময় খসড়া সংরক্ষণ করতে পারেন।';

  @override
  String get ui9797b0b4a5c1 => 'প্রজেক্টটি টেমপ্লেট হিসেবে সংরক্ষণ';

  @override
  String get uie30f8f020ce6 => 'সংরক্ষিত উত্তর';

  @override
  String get ui57dd6e65063e => 'এই ফোনে সংরক্ষিত · সিঙ্কের অপেক্ষায়';

  @override
  String get ui2391ec16d44b => 'সংরক্ষিত প্রজেক্ট';

  @override
  String uic1b9736fedd0(String v0) {
    return '$v0-এর সংরক্ষিত উত্তর';
  }

  @override
  String get ui28bb6965aeec =>
      'সংরক্ষিত উত্তর এখানে দেখা যায়; অসম্পূর্ণ কাজ খসড়ায় থাকে';

  @override
  String get uibf4522143a41 => 'সংরক্ষিত ভিজিট';

  @override
  String get uiae7e887517b0 => 'সংরক্ষণ হচ্ছে...';

  @override
  String get ui555b8b1249e2 => 'নাম বা অবস্থান দিয়ে খুঁজুন';

  @override
  String get ui5c562a19562f =>
      'GeoJSON, GeoPackage, SHP/ZIP, CSV, Excel বা KML/KMZ বাছুন।';

  @override
  String get uif19de55e63d0 =>
      'সংগৃহীত ডেটা দেখতে উপরে একটি প্রজেক্ট নির্বাচন করুন।';

  @override
  String get uif386a8052a3a => 'আগে প্রজেক্ট ও সার্ভে ফর্ম বাছুন।';

  @override
  String get ui410ffc9a264e => 'ফর্ম তৈরির আগে প্রজেক্ট বাছুন';

  @override
  String get ui4405857e86b5 => 'আঁকার আগে প্রজেক্ট বাছুন';

  @override
  String get ui65c52d24239c => 'আগে প্রজেক্ট বাছুন';

  @override
  String get uia1444962ecdb => 'আগে প্রজেক্টের প্রশ্নপত্র বাছুন।';

  @override
  String get ui7e607015bb18 => 'প্রজেক্ট বেছে সাইটের লেয়ার ইমপোর্ট করুন।';

  @override
  String get ui74d7e0804c5c => 'আগে প্রশ্নপত্র ও সংগ্রহ পর্ব বাছুন।';

  @override
  String get ui3b1a1262ef90 => 'একটি সার্ভে ফর্ম নির্বাচন করুন';

  @override
  String get ui913afff1faf7 => 'সব নির্বাচন করুন';

  @override
  String uifdc38dcd3912(String v0) {
    return 'সব নির্বাচন করুন ($v0টি নির্বাচিত)';
  }

  @override
  String get uiebaab4e02ce5 => 'আগে সক্রিয় প্রজেক্ট বাছুন';

  @override
  String get ui08d7aa35da9a => 'একটি বিকল্প নির্বাচন করুন';

  @override
  String get ui648c09b587f6 => 'অন্তত একটি প্রজেক্ট বাছুন';

  @override
  String get ui3e009481cb29 => 'ভিত্তি মানচিত্র বাছুন';

  @override
  String get uib84a6ecbc04c => 'তারিখ নির্বাচন করুন';

  @override
  String get ui94c7b6109333 => 'তারিখ ও সময় নির্বাচন করুন';

  @override
  String get ui7e8fcd733d84 => 'মানচিত্রে দেখাতে লগ বাছুন';

  @override
  String get ui1181e5025b41 => 'একাধিক বাছুন';

  @override
  String get ui4998e80cffcd => 'একটি বাছুন';

  @override
  String get uib4b37dd6ce6d => 'প্রজেক্ট নির্বাচন করুন';

  @override
  String get ui4978072af3ac => 'এক্সপোর্টের প্রজেক্ট বাছুন';

  @override
  String get uia7cf335d4076 =>
      'আলাদা করতে প্রশ্নপত্র ও পরিমাপ বাছুন, যেমন লবণাক্ততা। শুধু ওই পরিমাপ ও বিন্দুর অবস্থানসহ সংরক্ষিত উত্তর থেকে সাইট হবে। মূল উত্তর অক্ষত থাকবে।';

  @override
  String get ui3d7f91e8e71b => 'সময় নির্বাচন করুন';

  @override
  String get uic72ef626fe86 => 'এখানে আপেক্ষিক উচ্চতার নির্দেশক নির্ধারণ করুন';

  @override
  String get ui74a6ff25d6dd => 'ক্লাউড সিঙ্ক সেটআপ করুন';

  @override
  String get uicc1544692441 => 'আগে প্রজেক্টের ক্লাউড সিঙ্ক সেটআপ করুন';

  @override
  String get uic7f73bb54d92 => 'সেটিংস';

  @override
  String get uiaef97bb06af4 => 'সেটিংস সংরক্ষিত হয়েছে';

  @override
  String get uica90d5bc4a0e => 'Shapefile-এর সঙ্গী ফাইল';

  @override
  String get ui348cf86fa1bc => 'Shapefile, CSV, Excel, GeoJSON ও GeoPackage';

  @override
  String get ui09ca55ca52d2 => 'শেয়ার';

  @override
  String get ui142e4a88490f => 'CSV শেয়ার';

  @override
  String get ui25dac6eacbc4 => 'HTML ফাইল শেয়ার';

  @override
  String uifdf43a7041a5(String v0) {
    return 'শেয়ার হয়নি: $v0';
  }

  @override
  String get uic282b0009d54 => 'প্রজেক্ট শেয়ার';

  @override
  String get uib5f97af82c42 => 'URL ও API কী শুধু বিশ্বস্ত তথ্যসংগ্রাহককে দিন।';

  @override
  String get uidf6284851e35 => 'যৌথ গোপন টোকেন';

  @override
  String uid94a0488d308(String v0) {
    return 'শেয়ার হয়নি: $v0';
  }

  @override
  String get ui9a7f5c9f9c01 => 'এখন শেয়ার করা যাচ্ছে না।';

  @override
  String get uidd2e0b7ceac6 => 'প্রজেক্ট শেয়ার হচ্ছে…';

  @override
  String uia137ead9a9c9(String v0) {
    return 'সংক্ষিপ্ততম সড়কপথ  $v0';
  }

  @override
  String get ui50a279de829f => 'সব দেখান';

  @override
  String get uib666c5857d85 => 'সড়কপথ দেখান';

  @override
  String get ui6b97e76a48a2 => 'যাচাইয়ের শর্ত না মানলে দেখানো হবে';

  @override
  String get ui2ff741423601 => 'সহজ ফর্ম-ভিত্তিক ফিল্ড ডেটা সংগ্রহ';

  @override
  String get ui51b35f60ed25 => 'এক রং';

  @override
  String get uif8115c6458d3 => 'সাইট মোছা হয়েছে';

  @override
  String get ui03611ed63fe3 => 'সাইটের লেয়ার';

  @override
  String get ui70648b5ca5bb => 'সাইটের পর্যবেক্ষণ';

  @override
  String get ui72a6527e5742 => 'সাইটের সময়রেখা';

  @override
  String get ui73c4785414b8 => 'সাইটের সময়রেখা / পর্যবেক্ষণ যোগ';

  @override
  String get uif08625843372 => 'সাইটের সময়রেখা / পর্যবেক্ষণ তুলনা';

  @override
  String get uidc61591e7417 => 'সাইট ভিজিট';

  @override
  String get ui046c5d454e0a => 'স্ট্যাটাস ট্র্যাকিং ও নেভিগেশন সহ সাইট ভিজিট';

  @override
  String get ui3da474537ac3 => 'এড়িয়ে যান';

  @override
  String get ui952f375412e8 => 'শুরু করুন';

  @override
  String get ui2932e9a9f29d => 'আরেকটি ভিজিট শুরু করুন';

  @override
  String get ui02c86d972b56 => 'সার্ভে ফর্ম তৈরি শুরু করুন';

  @override
  String get uie92d02d3d165 => 'রেকর্ডিং শুরু';

  @override
  String get ui814036be3ced => 'ভিজিট শুরু';

  @override
  String get uibae7d5be7082 => 'অবস্থা';

  @override
  String get ui9e253470c876 => 'থামান';

  @override
  String get ui72d339ddaa22 => 'অনুসরণ বন্ধ করুন';

  @override
  String get uiee0d9dc8eb5e => 'রেকর্ডিং বন্ধ';

  @override
  String get ui794e05ff6f15 => 'স্টাডি এরিয়া';

  @override
  String get ui7454029d069c => 'স্টাডি এরিয়া মোড';

  @override
  String get ui792ac04306e0 => 'স্টাডি এরিয়া ভিজিট';

  @override
  String get uiafa82e671a4d => 'স্টাডি এরিয়ার বিন্দু / ইমপোর্ট';

  @override
  String get ui140781d627c5 => 'স্টাডি এরিয়া — শুধু দেখা';

  @override
  String get ui2e09116ca6c8 => 'স্টাডি এরিয়া';

  @override
  String get uiaec7160f7d63 => 'স্টাডি লেয়ার';

  @override
  String get ui3d5101991a4b => 'স্টাডি কর্মক্ষেত্র';

  @override
  String get uibae35f4f69ef => 'সার্ভে ফর্ম তৈরি';

  @override
  String get uifd8eb8a44d22 => 'সার্ভের ইতিহাস';

  @override
  String get ui6a0244a36b78 => 'সার্ভে মোড';

  @override
  String get ui15b4700cfe17 => 'সার্ভের উত্তর';

  @override
  String get ui56eaf8c1a78e => 'সার্ভে রেসপন্স';

  @override
  String get ui27429641f3a8 => 'সার্ভে ও জিআইএস মানচিত্র (GeoJSON)';

  @override
  String get ui1cdf92b9422d => 'সার্ভের ফিচার সংরক্ষিত';

  @override
  String get ui0f50e6cd5d73 => 'সার্ভে ফর্ম';

  @override
  String get ui61cd448fd742 => 'এই খসড়ার সার্ভে ফর্ম পাওয়া যায়নি';

  @override
  String get ui26ae75d9a213 => 'সার্ভে ফর্ম';

  @override
  String ui1bbe80df74aa(String v0) {
    return 'সার্ভের উত্তর: $v0';
  }

  @override
  String get uidb7d0e51a156 => 'সার্ভের উত্তর';

  @override
  String get uia7d7ae64cf27 => 'সার্ভের উত্তর (CSV)';

  @override
  String get uibd39220a2d4d =>
      'সার্ভে সংরক্ষিত; মানচিত্র হালনাগাদে নজর প্রয়োজন';

  @override
  String get uia515beba342a =>
      'XLSForm-এ সংজ্ঞায়িত ভাষাগুলোর মধ্যে পরিবর্তন করুন';

  @override
  String get ui905f63092ff2 => 'সিঙ্ক';

  @override
  String get uia625528186cb => 'সিঙ্ক সম্পূর্ণ';

  @override
  String get ui39040109b600 => 'সিঙ্ক হয়নি';

  @override
  String get uiecbe8bb3855d => 'সিঙ্ক শেষ';

  @override
  String get ui3e2b9221a8fb => 'প্রশ্নপত্র সিঙ্ক';

  @override
  String get ui12df0ea3611e => 'সিঙ্কের অবস্থা';

  @override
  String get ui9f462978795c =>
      'সিঙ্ক হয়েছে · নতুন সংশোধন পাঠাতে সম্পাদনা করুন';

  @override
  String get uie5c7727a106e => 'সিঙ্ক হচ্ছে...';

  @override
  String get ui9d8d3808063b => 'সিস্টেম ডিফল্ট';

  @override
  String get ui02de1f69347b => 'বিস্তারিত দেখতে মানচিত্রের ফিচারে ট্যাপ করুন';

  @override
  String get ui434e87b69d53 => 'বিস্তারিত দেখতে মানচিত্রের ফিচারে ট্যাপ করুন';

  @override
  String get uic12b336a09df => 'প্রথম বিন্দু যোগ করতে মানচিত্রে ট্যাপ করুন';

  @override
  String get uic11008251fcb =>
      'নতুন অবস্থানে ফিচারটি রাখতে মানচিত্রে ট্যাপ করুন।';

  @override
  String get ui3033c8b8aac7 => 'জিপিএস অবস্থান ক্যাপচার করতে ট্যাপ করুন';

  @override
  String get ui38d2049ea91a => 'নির্ভুলতা পরিমাপ করতে ট্যাপ করুন';

  @override
  String get ui580f6ab716ab => 'সংযোগ পরীক্ষা';

  @override
  String get ui15ccc83272b1 => 'পরীক্ষা হচ্ছে...';

  @override
  String get uic3328c39b0e2 => 'লেখা';

  @override
  String get ui8a9c91641630 =>
      '.mbproj প্যাকেজে ফর্ম, জিআইএস মূল ফাইল, মানচিত্রের লেয়ার, সেটিংস ও ক্লাউড সেটআপ স্ক্রিপ্ট থাকে। সংগৃহীত উত্তর ও ছবি রাখবেন কি না বাছুন।';

  @override
  String get ui1341db575a04 => 'সংগৃহীত বিন্দুগুলো বাদ যাবে।';

  @override
  String get ui0f6a7c9875c9 =>
      'খসড়ার প্রজেক্টটি নেই। চালিয়ে যাওয়ার আগে প্রজেক্ট ফিরিয়ে আনুন।';

  @override
  String get uia797e30923ac => 'থিম';

  @override
  String get ui2a2618391b6d =>
      'এই সংরক্ষিত সাইটগুলো কোনো প্রজেক্টে যুক্ত নেই। যুক্ত করা বা মোছার আগে বিস্তারিত দেখুন। এগুলো সার্ভের উত্তর থেকে আলাদা।';

  @override
  String ui8a91047b84cc(String v0) {
    return 'সম্পূর্ণ জ্যামিতি রাখা আছে। অংশগুলো জিআইএস সফটওয়্যারে সম্পাদনা করে সংশোধিত GeoJSON মার্জ করুন।\n\n$v0';
  }

  @override
  String get ui1644de68ca1f => 'এই খসড়ার সাইট বা প্রশ্নপত্রটি আর নেই।';

  @override
  String get ui5163769c6478 =>
      'ফিচারটি অন্যত্র বদলেছে। আবার খুলে সর্বশেষ সংস্করণ দেখুন।';

  @override
  String get ui845d01d70891 =>
      'এই তথ্যের ঘরটি ইতিমধ্যে আছে। উপরে এর মান সম্পাদনা করুন।';

  @override
  String get ui7aae0b62872a => 'ফর্মে এখনও প্রশ্ন নেই।';

  @override
  String get ui4991b992a518 =>
      'এই লেয়ারে মোছার মতো বিন্দু বা সার্ভের ইতিহাস নেই।';

  @override
  String get ui7e8c2ede22e2 =>
      'পুরোনো ফর্মের পুনরাবৃত্ত অংশ সমর্থিত নয়। আরও তথ্য সংগ্রহের আগে প্রতি ফিচারে একটি জমা থাকে এমন ফর্ম ইমপোর্ট করুন।';

  @override
  String get ui7fa6ed0dde94 => 'এই প্রশ্নের ধরনে অন্তত একটি বিকল্প প্রয়োজন';

  @override
  String get uid8245487967c =>
      'এর অফলাইন উপকরণ সরানো হবে। আপনার সংগৃহীত ফিচার ও ছবি ডিভাইসেই থাকবে।';

  @override
  String ui0178bef432ea(String v0) {
    return 'এতে প্রজেক্ট থেকে “$v0” সরানো হবে।';
  }

  @override
  String uia87ef6452c2d(String v0, String v1) {
    return 'এতে “$v0”, এর মানচিত্রের লেয়ার, ইমপোর্টের $v1টি বিন্দু ও তাদের স্থানীয় ইতিহাস সরানো হবে।';
  }

  @override
  String get ui6c82e6dd8680 => 'সময়';

  @override
  String get ui19eabc961735 => 'সময়চিহ্ন';

  @override
  String get uid79eb0a68863 => 'ট্র্যাকের নাম (ঐচ্ছিক)';

  @override
  String get uib41665a86980 => 'অবস্থান সেবা চালু করুন।';

  @override
  String ui4f1b0f8aa40a(String v0) {
    return 'ধরন: $v0';
  }

  @override
  String get ui51ed65113221 => 'অপরিবর্তিত';

  @override
  String get ui39fc72124884 => 'ফিরিয়ে নিন';

  @override
  String get uib528b0fe2e94 => 'অসম্পন্ন';

  @override
  String ui47091b4936c3(String v0) {
    return 'v$v0 হালনাগাদ এসেছে';
  }

  @override
  String uifc3b7a12bc25(String v0) {
    return 'XLSForm থেকে “$v0” হালনাগাদ হয়েছে';
  }

  @override
  String get uif33de2a5a459 => 'হালনাগাদ মানচিত্র (GeoJSON)';

  @override
  String get uic76d18079a07 => 'আপডেট';

  @override
  String get ui3f90215b1701 => 'রেসপন্স ও ছবি ক্লাউডে আপলোড করুন';

  @override
  String get ui5874b63bbc58 => 'আমার জিপিএস অবস্থানের আশেপাশের এলাকা নিন';

  @override
  String get uiab731c818a80 => 'ভিন্ন বিন্দু ব্যবহার করুন।';

  @override
  String get uif3d5a30b0ad2 => 'আসা সংস্করণ ব্যবহার করুন';

  @override
  String get ui3f546b7d94c3 => 'লেয়ার ব্যবহারের মোড';

  @override
  String get uia75e1e286eed => 'এই ছবি ব্যবহার করুন';

  @override
  String get ui2dec1c905e5d =>
      'GeoJSON, GeoPackage, zipped shapefile, CSV, Excel বা KML/KMZ আনতে উপরের ইমপোর্ট বোতাম ব্যবহার করুন।';

  @override
  String get ui890fcb6fc818 =>
      'নিজস্ব সার্ভার বা অফলাইন ডাউনলোডের অনুমতি দেয় এমন উৎস ব্যবহার করুন। অ্যাপের OSM, CARTO ও Esri ভিত্তি মানচিত্র শুধু অনলাইনে চলে। ডাউনলোডের সময় অ্যাপ খোলা রাখুন। প্যাকেজ সার্ভের ব্যাকআপে থাকে না; পুনরায় ইনস্টলের পর আবার ডাউনলোড করুন।';

  @override
  String get uib9d2e508d3e7 =>
      'জিআইএস দূরত্ব ও ক্ষেত্রফল টুলে ব্যবহৃত। স্বয়ংক্রিয়ভাবে মিটার/কিলোমিটার ও বর্গমিটার/হেক্টর নির্বাচন করে।';

  @override
  String get ui9f8a2389a20c => 'ব্যবহারকারী';

  @override
  String get ui542fc71480de => 'ব্যবহারকারীর নাম';

  @override
  String get ui8dce170de238 => 'মান';

  @override
  String get uibe37e18e12ab => 'মান (ফাঁক ছাড়া)';

  @override
  String get uibc23d6952888 => 'যাচাই / পরিবর্তনের নোট';

  @override
  String get ui062e095d2e00 => 'যাচাই সম্পূর্ণ';

  @override
  String get ui760fa1d0a21b => 'যাচাইয়ের অবস্থা';

  @override
  String get ui08f9848508a4 => 'প্রশ্নপত্র দিয়ে যাচাই';

  @override
  String ui93af16ef7e20(String v0) {
    return 'সংস্করণ $v0';
  }

  @override
  String ui6b6212f516b9(String v0) {
    return 'সংস্করণ $v0 এসেছে';
  }

  @override
  String get uie21d16e2187b =>
      'উল্লম্ব নির্ভুলতা পাওয়া যাচ্ছে না। ঘরের ভেতর জিএনএসএস উচ্চতা দিয়ে তলার উচ্চতা নির্ভরযোগ্যভাবে মাপা যায় না।';

  @override
  String ui670ea96a1459(String v0) {
    return 'উল্লম্ব অনিশ্চয়তা ±$v0 মি. · WGS84 উপবৃত্তাকার পৃষ্ঠ থেকে; সমুদ্র বা ভূমি থেকে উচ্চতা নয়।';
  }

  @override
  String get ui9db62a629ff2 => 'তথ্য দেখুন / সম্পাদনা করুন';

  @override
  String get ui70144df223fc => 'CSV দেখুন';

  @override
  String get ui32105310ab3b => 'ব্রাউজারে ফিচার দেখুন ও বাছাই করুন';

  @override
  String get uia08f63479914 => 'ওয়েবম্যাপে লগ ও প্রজেক্ট ট্র্যাক দেখুন';

  @override
  String get ui78caa7422cf5 => 'শুধু দেখুন — ইমপোর্ট নয়';

  @override
  String get ui5ceea82d3743 => 'রেকর্ড দেখুন';

  @override
  String get uidbad9f126b33 => 'দর্শক';

  @override
  String get uiae28ae06cab2 => 'স্টাডি সাইট ভিজিট করুন';

  @override
  String get ui2f33af1452b9 =>
      'ভিজিট ও ছবি সংরক্ষিত। স্টাডি মানচিত্র হালনাগাদ বাকি।';

  @override
  String get ui13db299e703f => 'অন্য ফিচারে ভিজিট করুন';

  @override
  String get uifcb7f8e18aa1 => 'ভিজিটের তারিখ';

  @override
  String get ui18a8706ac9c3 =>
      'ভিজিটের খসড়া সংরক্ষিত। পরে চালিয়ে যেতে পারবেন।';

  @override
  String get uibacabffc7265 =>
      'স্থাপনা ভিজিট করে সম্পন্ন, বাকি বা পর্যালোচনার অবস্থা রাখুন।';

  @override
  String get uid983c98256a6 => 'ভিজিটের ফলাফল';

  @override
  String get ui06547aa978e8 =>
      'ভিজিট সংরক্ষিত ও স্টাডি মানচিত্র হালনাগাদ হয়েছে।';

  @override
  String ui8d3b6ce77936(String v0) {
    return 'ভিজিট সংরক্ষিত; মানচিত্র হালনাগাদে পর্যালোচনা প্রয়োজন: $v0';
  }

  @override
  String get uiaea1d8c3ba27 =>
      'সাইট রেকর্ডের আগে নতুন জিপিএস অবস্থানের অপেক্ষা করুন।';

  @override
  String get uidbeb4f38e866 =>
      'সাম্প্রতিক নির্ভুল জিপিএস অবস্থানের অপেক্ষা করুন (২৫ মি. ও ৩০ সেকেন্ডের মধ্যে), অথবা নিজে মানচিত্রে ট্যাপ করুন।';

  @override
  String get ui1599512dd4fa => 'জিপিএস অবস্থানের অপেক্ষায়';

  @override
  String get ui69d5b3e27393 => 'জিপিএস অবস্থানের অপেক্ষায়';

  @override
  String get ui0f1b5fa21d3e =>
      'বিন্দু সংরক্ষণের আগে জিপিএস অবস্থানের অপেক্ষায়';

  @override
  String get uib933ed0f85ce => 'খসড়া সংরক্ষণের আগে জিপিএস অবস্থানের অপেক্ষায়';

  @override
  String get ui46d1bd7a4fe5 =>
      'বিন্দু স্থাপনের জন্য জিপিএস অবস্থানের অপেক্ষায়';

  @override
  String get ui403fb7e4a07b => 'অবস্থানের অপেক্ষায়…';

  @override
  String get uie8f3a099b17e => 'সিঙ্কের অপেক্ষায়';

  @override
  String get ui3650b57a63bc => 'অপেক্ষা করুন…';

  @override
  String get ui203aa501a2cf => 'রেকর্ডিং চালু রেখে সীমানা ধরে হাঁটুন';

  @override
  String get ui112c28094e9c => 'ওয়েবম্যাপ';

  @override
  String ui8524c9daa511(String v0) {
    return 'ওয়েবম্যাপ হয়নি: $v0';
  }

  @override
  String get ui83476ddef06c => 'MapBanai-এ স্বাগতম';

  @override
  String get uib16023bdc345 => 'XLSForm ইমপোর্টের সীমাবদ্ধতা';

  @override
  String get ui5397e0583f14 => 'হ্যাঁ';

  @override
  String get ui9f628b61ae0f => 'হ্যাঁ/না';

  @override
  String get ui5fc15792a3b6 => 'সর্বশেষ সংস্করণ ব্যবহার করছেন';

  @override
  String get uiab42293e29e1 => 'আপনার নাম';

  @override
  String get ui91dd05f1187c =>
      'আপনার নাম প্রতিটি সার্ভে রেসপন্স, জিপিএস লগ ও এক্সপোর্টের সাথে যুক্ত থাকবে।';

  @override
  String get ui50ee0028c989 =>
      'সর্বোচ্চ জুম ১৮ ও টাইল ৬,০০০টি। শুধু নির্ধারিত সীমানা ও জুম ডাউনলোড হবে। বড় এলাকার জন্য কম জুম বা আলাদা প্যাকেজ নিন।';

  @override
  String get uic0b885fe691b => 'প্রয়োগ হয়েছে';

  @override
  String get ui0e7766b460fd => 'খসড়া';

  @override
  String get ui2f232eece4a3 => 'যেমন নদীতীরের সার্ভে';

  @override
  String get ui7e6a1fc501ab => 'যেমন লবণাক্ততা — অক্টোবর';

  @override
  String get ui3f29e0058e85 => 'যেমন \${field_name} = \"value\"';

  @override
  String get uie5aad6660c17 => 'যেমন \${width} * \${length}';

  @override
  String get uic4425e81a34d => 'যেমন . > 0 and . < 150';

  @override
  String get uidef3966f9daf => 'যেমন, জন ডো';

  @override
  String get ui89a91669c66b => 'যেমন মৃদু';

  @override
  String get ui4486060d3535 => 'যেমন নদীতীরের সার্ভে';

  @override
  String get ui92d4bd903a26 => 'যেমন সাইট ক-এর সীমানা ধরে হাঁটা';

  @override
  String get ui3aedaef1c98d => 'যেমন ফুটব্রিজে জমে থাকা পানি';

  @override
  String get uidac85c4db8ef => 'যেমন mild';

  @override
  String get uif4bce9423af7 => 'যেমন site_name';

  @override
  String get ui3744336ac6a4 => 'ফর্ম যাচাইকৃত';

  @override
  String get uif408daa3bbc7 => 'ইমপোর্ট ব্যাচ আইডি';

  @override
  String get ui8745cffb3401 => 'চৌম্বক উত্তর';

  @override
  String get ui6ae999552a0d => 'নাম';

  @override
  String get ui71f8e7976e4c => 'কোনোটিই নয়';

  @override
  String get ui3032bf2db789 => 'সমন্বয়ের সমস্যা';

  @override
  String get ui1a77d416224c => 'আবশ্যক';

  @override
  String get uiac82a1d4da3f => 'সাইটের সিঙ্ক';

  @override
  String get ui519742fe8995 => 'চলার দিক';

  @override
  String get ui383fd7bf84aa => 'সতর্কতা';

  @override
  String ui16ae235ff3fa(String v0, String v1) {
    return '$v0 • সেশন #$v1';
  }

  @override
  String ui3047ae0d6f0b(String v0, String v1) {
    return '$v0 • $v1 • খসড়া';
  }

  @override
  String ui74286a1f17a8(String v0, String v1) {
    return '$v0 / $v1 ফিচার';
  }

  @override
  String uib31c43e0e100(String v0, String v1, String v2) {
    return '$v0 / $v1 উপকরণ · $v2';
  }

  @override
  String ui856ae446a4d6(String v0) {
    return '$v0 মেগাবাইট';
  }

  @override
  String uid2ec3044ad26(String v0) {
    return '$v0টি সংগ্রহ হয়েছে';
  }

  @override
  String uid4e292ed91bd(String v0) {
    return '$v0টি ফিচার';
  }

  @override
  String ui56d31f5a5e0f(String v0) {
    return '$v0টি ফিচার, দলীয় মার্জের সম্পূর্ণ ইতিহাসসহ';
  }

  @override
  String ui12126260f1ba(String v0, String v1) {
    return '$v0টি মিলযুক্ত রেকর্ড\n$v1টি সিঙ্কের অপেক্ষায়';
  }

  @override
  String uia98956288877(String v0) {
    return '$v0টি মিলযুক্ত সাইট';
  }

  @override
  String ui775784f1b2ec(String v0, String v1, String v2) {
    return '$v0টি নতুন ফিচার, $v1টি আসা সংশোধন, $v2টি অপরিবর্তিত বা পুরোনো সংস্করণ।';
  }

  @override
  String ui572d0978e0f5(String v0) {
    return '$v0টি প্রশ্ন';
  }

  @override
  String ui8f1a22d54d2c(String v0) {
    return '$v0টি পাঠ';
  }

  @override
  String ui21c0f7d95d18(String v0, String v1) {
    return '$v0টি রেকর্ড, যার $v1টি সিঙ্কের অপেক্ষায়। ক্লাউডের কপি অপরিবর্তিত থাকবে।';
  }

  @override
  String uib66d8dcb4ef4(String v0) {
    return '$v0টি সংরক্ষিত';
  }

  @override
  String ui41dbbb7c36bc(String v0) {
    return 'প্রজেক্ট প্যাকেজে $v0টি মূল ফাইল আছে';
  }

  @override
  String ui763b3b758174(String v0) {
    return '$v0টি অনির্ধারিত সাইট';
  }

  @override
  String uibbb4b809c6ba(String v0) {
    return '$v0টি বিন্দু • যোগ করতে মানচিত্রে ট্যাপ করুন';
  }

  @override
  String uiaa45b4005be5(String v0) {
    return '$v0 — সম্পূর্ণ কোড কপি করুন';
  }

  @override
  String ui2255f673779e(String v0, String v1) {
    return '$v0 • সার্ভে রেকর্ড $v1';
  }

  @override
  String ui1c1707c84f0d(String v0, String v1) {
    return '$v0 • সংস্করণ $v1';
  }

  @override
  String uie09431d672e4(String v0, String v1) {
    return '$v0 • $v1টি প্রশ্নপত্র';
  }

  @override
  String ui89f846bf7eed(String v0) {
    return '$v0। সর্বশেষ সংরক্ষিত খসড়া অক্ষত আছে।';
  }

  @override
  String ui13d9100a93a2(String v0, String v1) {
    return '$v0/$v1টি ছবি';
  }

  @override
  String uic7c34d515c8f(String v0, String v1) {
    return '$v0: বৈধ $v1 লিখুন';
  }

  @override
  String uib0b6457093f6(String v0, String v1) {
    return '$v0: $v1টি বিন্দু। যোগ করতে মানচিত্রে ট্যাপ করুন।';
  }

  @override
  String ui55cedac6145e(String v0, String v1) {
    return '“$v0” (সংস্করণ $v1) এই ডিভাইসে ইতিমধ্যে আছে।';
  }

  @override
  String get ui0c158c664316 =>
      'MapBanai-এর আগের ইনস্টলের ব্যাকআপ পাওয়া গেছে। সেটিংস ও সার্ভের উত্তর ফিরিয়ে আনবেন?';

  @override
  String ui14aec94c06c0(String v0) {
    return '“$v0” আর্কাইভ করবেন? প্রজেক্ট সেটআপে লুকানো হবে। তথ্য থাকবে এবং পরে ফিরিয়ে আনতে পারবেন।';
  }

  @override
  String get uid11a9f1a48ea =>
      'উপরে এক্সপোর্টের ধরন বাছুন — ফাইলটি আপনার পছন্দের স্থানে সংরক্ষণ বা শেয়ার হবে।';

  @override
  String get ui460b96b24627 =>
      'পটভূমিতে সিঙ্কের জন্য প্রজেক্টকে Google Apps Script ওয়েব অ্যাপে যুক্ত করুন।';

  @override
  String ui745bc847aafd(String v0, String v1) {
    return 'বর্তমান নির্ভুলতা ($v0) নির্ধারিত সীমার ($v1) চেয়ে খারাপ। তবুও সংরক্ষণ করবেন?';
  }

  @override
  String get uic3651ce80dea =>
      'এই প্রজেক্টে বিন্দু রেকর্ডের সময় ব্যবহৃত গ্রহণযোগ্য নির্ভুলতার প্রাথমিক সীমা।';

  @override
  String ui6e54655f0424(String v0) {
    return '“$v0” ও এর সব সার্ভের উত্তর এবং জিআইএস ফিচার মুছবেন? এটি ফেরানো যাবে না।';
  }

  @override
  String ui576e9079ff22(String v0, String v1) {
    return '“$v0” মুছবেন? এটি ফেরানো যাবে না।$v1';
  }

  @override
  String get ui4babe44dc2a9 => 'ডাউনলোড হয়নি। সংযোগ দেখে আবার চেষ্টা করুন।';

  @override
  String get uie99acc1c25e6 =>
      'আপনার নাম লিখুন — প্রতিটি সার্ভের উত্তর, জিপিএস লগ ও এক্সপোর্টে এটি থাকবে। পরে তিন দাগের মেনু থেকে আমার নাম-এ বদলাতে পারবেন।';

  @override
  String get ui4d6aba3a7042 =>
      'প্রতিটি ছবিতে জিপিএস স্থানাঙ্ক থাকতে হবে। জিপিএস নিশ্চিত হওয়া পর্যন্ত ছবি তোলার স্থানে থাকুন। গ্যালারির ছবির বৈধ জিপিএস থাকলে তা রাখা হয়।';

  @override
  String ui5413a24d990a(String v0) {
    return 'জিপিএস অবস্থান প্রস্তুত · ±$v0 মি. — ছবিতে অবস্থান যুক্ত হবে';
  }

  @override
  String ui60064654441d(String v0, String v1) {
    return 'রেখা • $v0টি বিন্দু • $v1';
  }

  @override
  String ui4e046e2d5e0a(String v0, String v1) {
    return 'শেষ করতে অন্তত $v0টি বিন্দু প্রয়োজন ($v1টি সংগ্রহ হয়েছে)';
  }

  @override
  String get ui8150b88a8de7 =>
      'এখনও লগ নেই। স্থানাঙ্ক, সময়, উচ্চতা ও নির্ভুলতা CSV ফাইলে রেকর্ড করতে লগ তৈরি করুন।';

  @override
  String get ui2b0631b176cd =>
      'এখনও প্রজেক্ট নেই — হোমের প্রজেক্ট সেটিংস থেকে তৈরি করুন বা প্রজেক্ট ইমপোর্ট দিয়ে .mbproj ফাইল আনুন';

  @override
  String get uib9f28dea1644 =>
      'এখনও প্রজেক্ট নেই — প্রজেক্ট সেটিংস থেকে তৈরি করুন বা প্রজেক্ট ইমপোর্ট দিয়ে .mbproj ফাইল আনুন';

  @override
  String get ui21e3b0114215 =>
      'একই প্রশ্নপত্র সার্ভে, জিআইএস ও স্টাডি এরিয়ার প্রশ্ন দেয়। ফর্ম তৈরি, সম্পাদনা বা XLSForm (.xlsx) ইমপোর্ট করতে পারেন।';

  @override
  String get ui771de57db095 =>
      'ডিভাইস সেটিংসে “এই উৎস থেকে অনুমতি দিন” চালু করে আবার ডাউনলোড ও ইনস্টল চাপুন।';

  @override
  String uia490dc30efac(String v0, String v1, String v2) {
    return 'বিন্দু\n$v0, $v1$v2';
  }

  @override
  String get uib3b06ed785b2 =>
      'বিন্দু একটি নোটসহ বর্তমান অবস্থান একবার সংরক্ষণ করে; নিচের ধারাবাহিক রেকর্ডিং দিয়ে রেখা/ট্র্যাক লগ হয়।';

  @override
  String ui2181a49983f5(String v0, String v1, String v2) {
    return 'বহুভুজ • $v0টি বিন্দু\nক্ষেত্রফল: $v1 • পরিসীমা: $v2';
  }

  @override
  String get ui793e65ec7509 =>
      'প্রজেক্টের আমন্ত্রণ এসেছে। ইমপোর্ট করতে MapBanai-এ .mbproj ফাইল খুলুন।';

  @override
  String get uie4fce3e26420 =>
      'আগে সেটিংসে ব্যবহারকারীর নাম দিন — তথ্য রিসেট নিশ্চিত করতে এটি প্রয়োজন।';

  @override
  String get ui2e3341bacb66 =>
      'উত্তরসহ সম্পূর্ণ প্রজেক্ট, উত্তর ছাড়া সেটআপ বা শুধু সংরক্ষিত উত্তর শেয়ার করুন। প্রজেক্ট প্যাকেজে সাধারণত জিআইএস ফাইল, ফর্ম, সেটিংস, ওয়েব URL ও API কী থাকে।';

  @override
  String get ui33a5e91c7ff1 =>
      'মোবাইল ডেটায় ধীর? ফোনের ব্রাউজারে ডাউনলোড করতে ব্রাউজারে খুলুন চাপুন, তারপর APK খুলে ইনস্টল করুন।';

  @override
  String get ui71529ccaf336 =>
      'মিলযুক্ত DBF বৈশিষ্ট্যের ফাইল পড়া যাচ্ছে না। SHP, DBF, SHX, PRJ ও CPG ফাইলের ফোল্ডার বাছুন বা শুধু জ্যামিতি ইমপোর্ট করুন। ফাইলগুলো একসঙ্গেও বাছতে পারেন।';

  @override
  String get ui7e91262eef11 =>
      'সব প্রজেক্ট, সার্ভের উত্তর, সংরক্ষিত ফর্ম ও জিপিএস লগ স্থায়ীভাবে মোছা হবে। নিশ্চিত করতে দেখানো ব্যবহারকারীর নাম হুবহু লিখুন:';

  @override
  String get ui2ebc6f4e9cc1 =>
      'নতুন কপি যোগ বা আগের প্রজেক্ট প্রতিস্থাপন করতে পারেন। প্রতিস্থাপন করলে বর্তমান প্রজেক্ট ও এতে সংগৃহীত সব তথ্য মুছে যাবে।';

  @override
  String uic2f438460953(String v0, String v1, String v2, String v3, String v4) {
    return '$v0\n\nইতিহাসের $v1টি রেকর্ড মোছা হবে, যার $v2টি সিঙ্কের অপেক্ষায়।\n$v3$v4\nএটি ফেরানো যাবে না। ক্লাউডে আপলোড করা কপি সেখানেই থাকবে।';
  }

  @override
  String ui1881010a6775(String v0, String v1, String v2) {
    return '$v0 / $v1\n\nমানচিত্রের সব $v2টি বিন্দু মুছবেন? এটি ফেরানো যাবে না।';
  }

  @override
  String ui6090069a7609(String v0, String v1, String v2) {
    return '$v0টি পাঠ$v1$v2';
  }

  @override
  String ui42346e017b40(String v0, String v1, String v2, String v3, String v4) {
    return '$v0 · $v1\nজুম $v2–$v3\n$v4';
  }

  @override
  String ui8bba0bdb8c5f(String v0, String v1) {
    return '$v0$v1-এর বিবরণ';
  }

  @override
  String ui7b693d8137e8(String v0) {
    return '\nএকই সরানো বিন্দুর সঙ্গে যুক্ত আরও $v0টি রেকর্ড অন্তর্ভুক্ত।\n';
  }

  @override
  String uid8c8c3da6665(String v0) {
    return ' এবং মানচিত্রের $v0টি বিন্দু';
  }

  @override
  String get ui54c0efcf9fc5 =>
      '১. MapBanai-এ নতুন প্রজেক্ট তৈরি করে প্রজেক্টের বিবরণ বা সহায়তা থেকে দীর্ঘ UUID প্রজেক্ট আইডি কপি করুন।\n২. নতুন Google স্প্রেডশিট তৈরি করুন বা XLSForm .xlsx-টি Google Sheets-এ খুলুন। প্রশ্নপত্রের ট্যাবের নাম হুবহু survey, choices, settings রাখুন।\n৩. XLSForm-এর শিরোনামের সারি রাখুন। survey-এর প্রচলিত কলাম: type, name, label, required, relevant, constraint, constraint_message, calculation। choices: list_name, name, label। settings: form_title, form_id, version।\n৪. তথ্যের ট্যাব বা ছবির ফোল্ডার নিজে তৈরি করতে হবে না। সেটআপ স্ক্রিপ্ট responses, features, photos, revisions ও ব্যক্তিগত Drive ছবির ফোল্ডার তৈরি করে।\n৫. প্রতিটি নতুন প্রজেক্টে নতুন স্প্রেডশিট ও স্ক্রিপ্ট নিন। একটি স্প্রেডশিটের সাধারণ সেটআপে spreadsheet ID কপি করতে হয় না।';

  @override
  String get ui0d72badb9fca =>
      '১. নতুন Google স্প্রেডশিট থেকে Extensions → Apps Script খুলুন। এতে স্ক্রিপ্ট ওই স্প্রেডশিটে যুক্ত হয়; এটিই bound workbook।\n২. নিচের সম্পূর্ণ Code.gs এডিটরে পেস্ট করুন। Map ও Charts নামে দুটি HTML ফাইল যোগ করে নিচের মিলযুক্ত HTML পেস্ট করুন।\n৩. Code.gs-এর উপরে শুধু PASTE_PROJECT_ID_FROM_MAPBANAI-এর জায়গায় কপি করা প্রজেক্ট আইডি দিন; উদ্ধৃতিচিহ্ন রাখুন। questionnaireSheetId, dataSheetId, apiKey ও photoFolderId-এর স্থানধারক বদলাবেন না।\n৪. সংরক্ষণ করে ফাংশনের ড্রপডাউন থেকে setupMapBanai চালান। ম্যানেজার অ্যাকাউন্ট দিয়ে spreadsheet ও Drive-এর অনুমতি দিন। স্ক্রিপ্ট এই স্প্রেডশিটে প্রশ্ন ও সংগৃহীত তথ্য রাখবে, ব্যক্তিগত API কী, ছবির ফোল্ডার ও তথ্যের ট্যাব তৈরি করবে।\n৫. স্প্রেডশিট আবার খুলে MapBanai → Connection and setup guide থেকে API কী কপি করুন। Apps Script → Project Settings → Script properties-এ MAPBANAI_API_KEY-ও আছে। এটি MapBanai-এর পাসওয়ার্ড; Google Cloud API পরিচয়পত্র লাগে না।\n৬. Apps Script-এ Deploy → New deployment → Web app বাছুন। Execute as: Me এবং Who has access: Anyone দিন। Deploy চাপুন, প্রয়োজনে অনুমতি দিয়ে /exec-এ শেষ হওয়া সম্পূর্ণ Web app URL কপি করুন; এডিটরের ঠিকানা নয়। Anyone না থাকলে Google Workspace প্রশাসককে বলুন।\n৭. MapBanai-এ প্রজেক্টের বিবরণ → ক্লাউড সিঙ্ক-এ URL ও API কী পেস্ট করুন। সংরক্ষণ করে সংযোগ পরীক্ষা চাপুন। রেকর্ড না পাঠিয়েই প্রজেক্ট আইডি, কী ও তথ্যের শিটে প্রবেশাধিকার যাচাই হয়।\n৮. সার্ভে মোড → প্রশ্নপত্র সিঙ্ক → Google Sheet দেখুন → পর্যালোচনা → হালনাগাদ প্রয়োগ করুন। একটি পরীক্ষামূলক উত্তর নিয়ে হোম থেকে সিঙ্ক করে শিট দেখুন। উত্তর সম্পাদনা করে আবার সিঙ্ক দিয়ে সংশোধনের ইতিহাস যাচাই করুন।\n৯. বিশ্বস্ত মাঠদলের জন্য সিঙ্ক সংযোগসহ প্রজেক্ট এক্সপোর্ট করুন। তথ্যসংগ্রাহক ইমপোর্ট করে হোমের তিন দাগের মেনুতে নিজের নাম দেবেন। নতুন প্রজেক্টে নতুন করে এই সেটআপ করুন।';

  @override
  String get ui0daa4f380987 => 'একর (ac)';

  @override
  String get uid3d9949c92a8 =>
      'অ্যাটলাস Connecting-এ আটকে থাকলে এটি শুরু/লোড হওয়ার সমস্যা; সাইটের সংখ্যার বিষয় নয়। মিলযুক্ত সম্পূর্ণ Map.html ও Code.gs বদলে সংরক্ষণ করে স্প্রেডশিটের মেনু থেকে অ্যাটলাস আবার খুলুন। দেখানো অবস্থা/ত্রুটি পড়ুন; ৪৫ সেকেন্ডের বেশি হলে Apps Script → Executions দেখুন। ম্যানেজারের মানচিত্র HTTPS দিয়ে নির্দিষ্ট Leaflet লোড করে; ইন্টারনেট লাগে।\n\nInvalid JSON/405 হলে ডিপ্লয় করা /exec URL নিন, এডিটর বা /dev নয়। doPost আছে কি না দেখে নতুন স্ক্রিপ্ট সংস্করণ ডিপ্লয় করুন।\n\nভুল প্রজেক্ট/কী হলে Code.gs ও প্রজেক্টের বিবরণের আইডি-কী মিলিয়ে অ্যাপে সংরক্ষণ করুন।\n\nঅনুমতি/সেটআপে সমস্যা হলে মালিক হিসেবে setupMapBanai চালিয়ে spreadsheet/folder ID ও সংরক্ষিত ফলাফলের কলামের নাম যাচাই করুন। ব্যক্তিগতভাবে Executions-এর বিবরণ দেখুন।\n\nপ্রশ্নপত্রে সমস্যা হলে ট্যাব ও কলামের হুবহু নাম, স্থায়ী form_id এবং বৈধ XLSForm নিয়ম দেখুন। উদ্দেশ্যকৃত XLSForm লেখা থেকে ভিন্ন ফল দেয় এমন সূত্র এড়িয়ে অভিব্যক্তি সাধারণ লেখা হিসেবে রাখুন।\n\nধীর/ব্যস্ত আপলোডে সম্পূর্ণ ব্যাচ অক্ষত থাকে। বাকি রেকর্ডের জন্য আবার সিঙ্ক করুন। সার্ভারের সময়সীমা শেষ হওয়া ও ইন্টারনেট হারানো আলাদা করে দেখানো হয়। Google সেবার সীমা প্রযোজ্য; খুব বড় কাজে নিজস্ব সার্ভার লাগে। সরবরাহকৃত ব্যাকএন্ডে প্রতি রেকর্ডে সর্বোচ্চ ১,৬০,০০০ JSON অক্ষর থাকে।\n\nসরকারি তথ্যসূত্র: developers.google.com/apps-script/guides/web এবং developers.google.com/apps-script/reference/spreadsheet/range।';

  @override
  String get uiac9041e76816 => 'স্বয়ংক্রিয়';

  @override
  String get uie1fb894bb078 =>
      'প্রজেক্ট ও প্রশ্নপত্র বেছে প্রশ্নের উত্তর দিন, আবশ্যিক ঘর ও যাচাইয়ের বার্তা মেনে সংরক্ষণ করুন। শর্তযুক্ত প্রশ্ন ইমপোর্টারে সমর্থিত XLSForm নিয়ম মেনে চলে। মাঠকাজের আগে ইমপোর্টের সতর্কতা দেখুন। তারিখের প্রশ্নে তারিখ বাছাইকারী ব্যবহার হয়। মাঠের তথ্য যাচাইয়ে শুধু নির্ধারিত নির্ভুলতার সীমা ছাড়ানো সংরক্ষিত জিপিএস/ছবির পাঠ দেখা যায়। উপযোগী পাঠ গ্রহণ করে এই ডিভাইসে তালিকা থেকে লুকান বা রেকর্ড খুলে দেখুন। সীমা ও গ্রহণের সিদ্ধান্ত প্রজেক্ট অনুযায়ী থাকে; ফিরিয়ে নিন দিয়ে সদ্য গৃহীত পাঠ ফেরে। এতে ছবি আটকে যায় না বা তথ্য বদলায় না। অসম্পূর্ণ সাক্ষাৎকার চালিয়ে যেতে খসড়া সংরক্ষণ করুন।';

  @override
  String get ui58167ff8f947 =>
      'Google Sheets-এর survey, choices ও settings ঘর সম্পাদনা করুন। অ্যাপে প্রজেক্ট → সার্ভে মোড → প্রশ্নপত্র সিঙ্ক → Google Sheet দেখুন → পর্যালোচনা → হালনাগাদ প্রয়োগ করুন। নতুন সাক্ষাৎকার ও বৈশিষ্ট্যের এডিটরে নতুন প্রশ্ন ব্যবহার হবে। আগে সংরক্ষিত রেকর্ড ও খসড়ায় মূল ফর্মের সংস্করণ থাকবে। হালনাগাদে ইন্টারনেট লাগে; তথ্য সংগ্রহ অফলাইনে করা যায়। প্রশ্নের name অপরিবর্তিত রাখুন, সরাসরি সক্রিয় সাক্ষাৎকারের মধ্যে সংস্করণ বদলাবেন না এবং মাঠে দেওয়ার আগে নতুন প্রশ্ন পরীক্ষা করুন।';

  @override
  String get ui7514aeee4771 => 'তথ্যসংগ্রাহক: সংগ্রহ, সংশোধন ও সিঙ্ক';

  @override
  String get ui7d5c63dab944 => 'ফুট (ft)';

  @override
  String get ui9a35340e0499 => 'জিআইএস মোড: আঁকা ও বৈশিষ্ট্য লেখা';

  @override
  String get uid21c6a5da671 => 'জিপিএস মোড ও অবস্থানসহ ছবি';

  @override
  String get uibf3148392176 =>
      'জিপিএস মোড প্রজেক্ট থেকে স্বাধীন। এতে অবস্থানের পরীক্ষা ও রেকর্ডিং আছে। কম্পাস চৌম্বক উত্তর অনুযায়ী সেন্সর ব্যবহার করে; বিকল্প হিসেবে জিপিএস চলার দিক আলাদাভাবে চিহ্নিত থাকে। ফোন সমতল রাখুন, প্রয়োজনে ধাতব বস্তু থেকে দূরে কম্পাস ঠিক করুন। জিএনএসএস উচ্চতা উপগ্রহের আনুমানিক উচ্চতা, ভবনের ভূমিতল থেকে উচ্চতা নয়; ঘরের ভেতর ভুল হতে পারে। বাইরে অবস্থান ও উল্লম্ব নির্ভুলতা যাচাই করুন।\n\nছবিতে অবস্থান যুক্ত করতে বৈধ অবস্থান প্রয়োজন। নির্ভুলতা পরে পর্যালোচনার জন্য থাকে; কঠোর সীমা দিয়ে ছবি তোলা আটকানো হয় না। অবস্থান ও ক্যামেরার অনুমতি দিন এবং অবস্থান পেতে সময় দিন।';

  @override
  String get ui65e00a1aa4fc => 'হেক্টর (ha)';

  @override
  String get ui2e2fa0ad4e93 =>
      'সংযোগ ছাড়ার আগে ফর্ম, প্রজেক্ট প্যাকেজ ও স্টাডি মানচিত্র ইমপোর্ট করুন। সমর্থিত ক্ষেত্রে অফলাইন ভিত্তি মানচিত্র প্রস্তুত করুন; অনলাইন টাইলের জন্য ইন্টারনেট লাগে। মাঠের রেকর্ড স্থানীয়ভাবে রেখে সংযোগে নির্বাচিত প্রজেক্ট সিঙ্ক করুন। উত্তর, জিআইএস/স্টাডি ফিচার ও ছবি একবারে সর্বোচ্চ ২০টি রেকর্ডের ধারাবাহিক ব্যাচে যায়। ব্যস্ত সার্ভারে স্বয়ংক্রিয়ভাবে আবার চেষ্টা হয়; পাঠানো ব্যাচ অক্ষত থাকে। আবার সিঙ্ক দিলে শুধু বাকি রেকর্ড যায়। ব্যাকএন্ড স্থায়ী রেকর্ড ও ছবির আইডি পুনর্ব্যবহার করে। সংরক্ষিত সম্পাদনায় response_revision বাড়ে ও আপলোডের সারিতে ফেরে। revisions ট্যাবে আপলোডের সংস্করণ থাকে; সিঙ্কের আগে একাধিক সম্পাদনা হলে শুধু শেষটি যায়। সংশোধন সিঙ্কে নতুন Code.gs ডিপ্লয় করুন। বিরোধ ম্যানেজারের পর্যালোচনার জন্য ফোনে থাকে।\n\nম্যানেজার: Google স্প্রেডশিট আবার খুলে MapBanai → Map workspace বা Charts workspace বাছুন। মানচিত্রে ভিত্তি মানচিত্র, নকশা, আলাদা ফন্ট, বিভাগের রং/চিহ্ন, লেজেন্ড সম্পাদনা ও PNG/JPEG আছে। একাধিক GeoJSON বা shapefile ZIP লেয়ার যোগ করা যায়। উভয় কর্মক্ষেত্রে পূর্ণপর্দা আছে; ব্রাউজারে বাধা থাকলে বড় Sheets ডায়ালগ ব্যবহৃত হয়। চার্টে সমষ্টি, থিম ও PNG/JPEG/SVG আছে। অনুমোদিত ম্যানেজার প্রয়োজন; এগুলো প্রকাশ্য লিংক নয়।\n\nসম্পূর্ণ রেকর্ডের JSON (জ্যামিতি ও উত্তরসহ) json_1 থেকে json_4 কলামে থাকে; যুক্ত করলে মূল রেকর্ড পাওয়া যায়। photos ট্যাবে তথ্য, ছোট প্রিভিউ ও Drive লিংক থাকে। নতুন আপলোডে প্রিভিউ নিজে তৈরি হয়। পুরোনো ছবির জন্য শিট আবার খুলে MapBanai → Refresh photo previews চালান (একবারে সর্বোচ্চ ৫০টি অনুপস্থিত প্রিভিউ)। ফাইল ব্যক্তিগত থাকে; শিটের দর্শক ছোট ছবি দেখতে পান। প্রিভিউ না হলে Drive লিংক ব্যবহার করুন। এই ব্যাকএন্ড আপলোডের গন্তব্য; অন্য তথ্যসংগ্রাহকের রেকর্ড নিজে আপনার ফোনে আসে না।';

  @override
  String get ui6d3be8e36078 => 'কিলোমিটার (km)';

  @override
  String get uif836181704ed => 'ম্যানেজার সেটআপ: একটি ওয়ার্কবুক নাকি দুটি?';

  @override
  String get uie1ca88d502bf => 'ম্যানেজার সেটআপ: স্ক্রিপ্ট পেস্ট ও ডিপ্লয়';

  @override
  String get uia120af7937ca => 'ম্যানেজার সেটআপ: Google Sheets প্রস্তুত করা';

  @override
  String get ui8762dae21dde =>
      'ম্যানেজার: প্রজেক্ট তৈরি করুন, XLSForm ইমপোর্ট করে প্রশ্নপত্র বাছুন এবং স্টাডি এরিয়ার মানচিত্র যোগ করুন। প্রয়োজনে ক্লাউড সংযোগ দিন। বিশ্বস্ত মাঠকর্মীদের জন্য সিঙ্ক সংযোগসহ প্রজেক্ট প্যাকেজ এক্সপোর্ট বা শেয়ার করুন।\n\nতথ্যসংগ্রাহক: হোম → তিন দাগের মেনু → আমার নাম-এ নাম দিন। প্রজেক্ট প্যাকেজ ইমপোর্ট করে বাছুন। সার্ভে মোড → প্রশ্নপত্র সিঙ্ক দিয়ে নতুন প্রশ্ন দেখুন। সার্ভে, জিআইএস বা স্টাডি সাইট ভিজিটে অফলাইনে তথ্য নিন। আমার উত্তর থেকে সংরক্ষিত উত্তর দেখুন ও সংশোধন করুন। ইন্টারনেটে হোম → ক্লাউড সিঙ্ক দিয়ে নতুন রেকর্ড ও সংশোধন পাঠান। সংশোধনে মূল সংগ্রাহক ও স্থায়ী আইডি থাকে, সম্পাদকের পরিচয় যুক্ত হয় এবং উত্তরের সংশোধন নম্বর বাড়ে; এটি প্রশ্নপত্রের সংস্করণ থেকে আলাদা। একই প্রজেক্ট ও প্রশ্ন জিআইএস ও স্টাডি এরিয়ায় ব্যবহার হয়। জিপিএস মোড স্বাধীনভাবে চলে।';

  @override
  String get uiaf34806a7287 => 'মিটার (m)';

  @override
  String get uib0b04ac9caed => 'মাইল (mi)';

  @override
  String get ui682761a623ce => 'অফলাইন কাজ, ক্লাউড সিঙ্ক ও ছবি';

  @override
  String get uia71aaef663f0 =>
      'প্রজেক্টের বিবরণ → পুনর্ব্যবহারযোগ্য টেমপ্লেট খুলুন। পুরো প্রজেক্ট বা নির্বাচিত লেয়ার ও প্রশ্নপত্র সংরক্ষণ করুন। প্রজেক্ট সেটআপ → পুনর্ব্যবহারযোগ্য টেমপ্লেট থেকে নতুন প্রজেক্ট তৈরি করুন। প্রজেক্টের বিবরণ থেকে বর্তমান প্রজেক্টেও টেমপ্লেটের লেয়ার যোগ করা যায়। টেমপ্লেটে ফর্ম, লেয়ারের নাম ও সেটআপ থাকে; সাইটের জ্যামিতি, ভিজিট, ছবি ও ক্লাউড কী থাকে না। নতুন প্রজেক্ট ও লেয়ার নতুন পরিচয় পায়। নতুন প্রজেক্টের ক্লাউড সংযোগ আলাদা করে দিন। টেমপ্লেট স্থানীয়ভাবে থাকে ও ডেটাবেসের ব্যাকআপে অন্তর্ভুক্ত হয়। অন্য ফোনে দিতে টেমপ্লেট থেকে প্রজেক্ট তৈরি করে তার প্যাকেজ এক্সপোর্ট করুন।';

  @override
  String get ui78f2a306509a =>
      'নির্বাচিত প্রজেক্টের ওয়েবম্যাপ খুলুন। Explore → Colours & categories থেকে লেখা/সংখ্যার কলাম বাছুন। Categories দিয়ে প্রতিটি মানের রং ও দৃশ্যমানতা, Graduated দিয়ে সংখ্যাভিত্তিক রং দিন। প্রথমে জ্যামিতির ধরন অনুযায়ী একরঙা থাকে। Download Map-এ বিভাগের নাম, রং ও চিহ্ন সম্পাদনা করুন। ফিচার বাছাই ও তথ্য দেখা, থিম, লেবেল চালু/বন্ধ এবং শিরোনাম-উপশিরোনামসহ পোস্টার বা শুধু মানচিত্রের ছবি তৈরি করা যায়। পরিষ্কার চিত্রের জন্য PNG, ছোট ফাইলের জন্য JPEG নিন। আলাদা Download Map বোতামে ১২টি নকশা, নিজস্ব রং, লম্বা/আড়াআড়ি, অনুপাত ও HD/Full HD/QHD/4K/নিজস্ব রেজোলিউশন আছে। Download ফোনের ফাইল বাছাইকারী এবং Share শেয়ারের তালিকা খোলে। ভিত্তি টাইল লোড ও এক্সপোর্টযোগ্য হতে হবে; অফলাইন/শুধু তথ্যের ছবিতে পটভূমি নাও থাকতে পারে। লেজেন্ডের নাম বদলান, বিন্দুর চিহ্ন/রেখার ধরন/বহুভুজের সীমা বাছুন বা PNG/স্বয়ংসম্পূর্ণ SVG আইকন দিন (সর্বোচ্চ ৫১২ কিলোবাইট ও প্রতি পাশে ২০৪৮ পিক্সেল)। শিরোনাম, উপশিরোনাম ও লেজেন্ডে আলাদা ফন্ট এবং চারটি অন্তর্ভুক্ত অফলাইন ফন্ট আছে। লেখা, চিহ্ন ও উত্তর তীর রেজোলিউশনের সঙ্গে বড় হয়; পড়তে সাধারণ/বড়/অতিরিক্ত বড় বাছুন। পোস্টারের ৮০ শতাংশের বেশি মানচিত্র, নিচে ছোট শিরোনাম ও লেজেন্ড থাকে। প্রথমে দৃশ্যমান সব তথ্য মাপসই হয়; নিজের ফ্রেম রাখতে Current map view বাছুন। শিরোনামের নিচে স্থানাঙ্ক থাকে না। শুধু অন্তর্ভুক্ত ভিত্তি মানচিত্রের কৃতিত্ব থাকে; রেকর্ডের সংখ্যা ও পটভূমিহীনতার বার্তা থাকে না।';

  @override
  String get ui0f3c63f41614 =>
      'স্টাডি এরিয়ার ফিচার খুলে সাইটের সময়রেখা / পর্যবেক্ষণ যোগ বাছুন, অথবা নির্দেশিত ভিজিটে ফিচার বেছে সময়রেখা খুলুন। আরেকটি পরিমাপের জন্য পর্যবেক্ষণ যোগ / ভিজিট শুরু চাপুন। প্রতিটি ভিজিট আলাদাভাবে শেষ করুন; আগের উত্তর একই স্থায়ী feature UUID-তে যুক্ত থাকবে। তুলনার জন্য প্রশ্নপত্র ও সংখ্যাভিত্তিক প্রশ্ন (যেমন লবণাক্ততা) বাছুন। প্রশ্নের নাম ও একক একই রাখুন। সব পর্যবেক্ষণ CSV হিসেবে এক্সপোর্ট করা যায়; feature_uuid দিয়ে স্টাডি মানচিত্রের GeoJSON-এর সঙ্গে যুক্ত করুন। ইমপোর্টের ভিজিট ইতিহাস স্থানীয় সাক্ষাৎকারের সঙ্গে যুক্ত হয় এবং একই রেকর্ড দুবার রাখা হয় না। সময়রেখায় শুধু এই ডিভাইসে থাকা ইতিহাস দেখা যায়; ক্লাউড সিঙ্ক অন্য ফোনের ভিজিট নামায় না।';

  @override
  String get ui4452be7b875c =>
      'প্রজেক্ট প্যাকেজে প্রজেক্টের সংজ্ঞা, ফর্ম ও স্টাডি লেয়ারের সেটআপ থাকে। সংগৃহীত উত্তর ও ছবি রাখতে এক্সপোর্টের সংশ্লিষ্ট বিকল্প বাছুন; শুধু সেটআপের প্যাকেজ তথ্যের ব্যাকআপ নয়। ঐচ্ছিক সিঙ্ক সংযোগে URL ও কী থাকে। দলের মধ্যে একই প্রজেক্ট পরিচয় রাখুন; প্রজেক্ট নকল করলে নতুন পরিচয় হয় এবং নিজস্ব ব্যাকএন্ড সেটআপ লাগে।\n\nসংগৃহীত তথ্যের জন্য ব্যাকআপ/এক্সপোর্ট ব্যবহার করে ফোনের বাইরেও কপি রাখুন। একই স্বাক্ষরের অ্যাপের উপর হালনাগাদ ইনস্টল করলে স্থানীয় তথ্য থাকে; আনইনস্টল বা অ্যাপের সংরক্ষণ মুছলে স্থানীয় তথ্য হারায়। প্যাকেজ এক্সপোর্টের আগে ক্লাউড সেটিংস সংরক্ষণ করুন।';

  @override
  String get ui48f8d1dd5266 =>
      'প্রতি প্রজেক্টে একটি Google ওয়ার্কবুক, একটি Apps Script ওয়েব অ্যাপ ও একটি ব্যক্তিগত API কী ব্যবহার করা সুবিধাজনক। একই ওয়ার্কবুকে প্রশ্নপত্রের survey, choices, settings এবং ফলাফলের responses, features, photos, revisions ট্যাব রাখুন। দ্বিতীয় URL বা কী লাগে না।\n\nআলাদা সংরক্ষণের জন্য দুটি ওয়ার্কবুক নিন: questionnaireSheetId-তে XLSForm ওয়ার্কবুক এবং dataSheetId-তে সংগৃহীত তথ্যের ওয়ার্কবুক দিন। একই স্ক্রিপ্ট দুটো পরিচালনা করে, তাই অ্যাপে একটি URL ও কী-ই লাগবে। এই সংস্করণে দুটি স্বাধীন ডিপ্লয়মেন্ট/কী সেটআপ নেই।\n\nপ্রতি প্রজেক্টের সেটআপ আলাদা রাখুন। প্রশ্নপত্র ম্যানেজার সম্পাদনা করবেন; তথ্যসংগ্রাহকের শুধু MapBanai প্যাকেজ লাগবে। API কী দিয়ে প্রজেক্টের সংযোগে প্রবেশ করা যায়, তাই কীসহ প্যাকেজ শুধু নিজের মাঠদলকে দিন।';

  @override
  String get uifd76b27cda7d => 'সহায়ক ভেক্টর লেয়ার ও পটভূমি';

  @override
  String get ui12432a3ccda1 => 'পুনরাবৃত্ত পর্যবেক্ষণ ও সাইটের সময়রেখা';

  @override
  String get ui6cb726ab7ebc => 'প্রজেক্ট ও লেয়ারের পুনর্ব্যবহারযোগ্য টেমপ্লেট';

  @override
  String get ui1a25286391c7 =>
      'প্রজেক্ট ও স্টাডি এরিয়ার মানচিত্র বাছুন। উপরের টুলবার থেকে ইমপোর্ট করুন; Android-এর MIME বাছাই নির্বিশেষে GeoJSON ও GeoPackage নেওয়া যায়। বৈশিষ্ট্য রাখতে shapefile-এর সঙ্গী ফাইল একসঙ্গে ZIP করুন। বাইরের ফাইল খুললে বর্তমান বা নতুন প্রজেক্ট, অথবা শুধু প্রিভিউ বাছা যায়। স্টাডি লেয়ার বাছাইয়ে নতুন লেয়ার যোগ করুন; প্লাস বোতাম নতুন জিপিএস অবস্থানে প্রশ্নপত্র খোলে। নতুন বা হালনাগাদ ফিচারে প্রশ্নপত্র প্রয়োজন; অন্য অবস্থায় ঐচ্ছিকভাবে প্রশ্নপত্র পূরণ করা যায়। এড়িয়ে গেলে আগের উত্তর থাকবে। বিভাগ ও রং থেকে যাচাইয়ের অবস্থা বা কলাম অনুযায়ী রং, বিভাগ দেখানো এবং বিন্দুর আকার বাছুন। নির্বাচিত এলাকায় ভিজিট শুরু বা খসড়া চালিয়ে যান; সাইট যাচাই, নতুন তথ্য ও বৈশিষ্ট্য হালনাগাদ করুন। ইতিহাসে পর্যালোচনার ধাপ থাকে। পুরোনো অনির্ধারিত সাইট নিজে প্রজেক্টে যুক্ত করুন। মাঠকাজ শেষে হালনাগাদ এলাকা এক্সপোর্ট করুন।';

  @override
  String get ui3ba9b97177d2 =>
      'প্রজেক্ট, লেয়ার ও সার্ভে বাছুন। বিন্দু, রেখা বা বহুভুজ যোগ করে নির্বাচিত প্রশ্নপত্র দিয়ে তথ্য লিখুন। আগের জ্যামিতি ও বৈশিষ্ট্য সম্পাদনা করা যায়। প্রশ্ন নির্বাচিত সার্ভে ফর্মেই নির্ধারণ করুন; আলাদা প্রজেক্ট সেটিংসের তথ্যের ঘর এডিটর সরানো হয়েছে, তবে পুরোনো মান সংরক্ষিত আছে। ফিচারকে সাইট বা পুনরায় ভিজিটের সঙ্গে যুক্ত করতে একই পরিচায়ক রাখুন। জিআইএস সফটওয়্যারে বিশ্লেষণের জন্য স্থানিক তথ্য এক্সপোর্ট করুন।';

  @override
  String get uicba2a97abd4c => 'শেয়ার, ব্যাকআপ ও অ্যাপ হালনাগাদ';

  @override
  String get ui1cc6418b3dc4 => 'বর্গফুট (ft²)';

  @override
  String get ui397fb00a21fd => 'বর্গকিলোমিটার (km²)';

  @override
  String get ui65e207ca8636 => 'বর্গমিটার (m²)';

  @override
  String get ui35e941e250ac => 'স্টাডি এরিয়া: ভিজিট ও পুনরাবৃত্ত সংগ্রহ';

  @override
  String get uicf8de9900977 => 'স্টাডি এরিয়ার বিন্দু মানচিত্রে থাকবে।\n';

  @override
  String get ui1cfa4ca96cef => 'সার্ভে মোড ও মাঠের তথ্য যাচাই';

  @override
  String get ui55cabd86f046 => 'অবস্থান বাছতে মানচিত্রে ট্যাপ করুন';

  @override
  String get ui38a1e2db198c => 'বিন্দুটি সরাতে মানচিত্রে ট্যাপ করুন';

  @override
  String ui9fd1493c60ac(String v0) {
    return 'এই প্রজেক্টের আইডি: $v0';
  }

  @override
  String get uia3ce2bacb32e => 'ক্লাউড সেটআপের সমস্যা সমাধান';

  @override
  String get ui693379c73728 => 'অনলাইনে প্রশ্নপত্র হালনাগাদ';

  @override
  String get ui0a045ba7552d => 'জিপিএস অবস্থান নিন';

  @override
  String get uif202ba19ecbc =>
      'ওয়েবম্যাপ → লেয়ার → ভেক্টর লেয়ার যোগ করুন। একাধিক shapefile ZIP, অথবা .shp-এর সঙ্গে .dbf/.shx/.prj/.cpg বাছুন। GeoJSON FeatureCollection সমর্থিত। আগে WGS84 (EPSG:4326)-এ রূপান্তর করুন; .prj না থাকলে WGS84 ধরা হয়। প্রতি লেয়ারে দৃশ্যমানতা, রং ও অস্বচ্ছতা দিন। সহায়ক লেয়ার সংগৃহীত পর্যবেক্ষণ থেকে আলাদা, স্থানীয়ভাবে থাকে এবং প্রজেক্ট প্যাকেজ ও শেয়ার করা HTML মানচিত্রে যায়। Explore → Background map থেকে সড়ক, উপগ্রহচিত্র, ভূপ্রকৃতি, মানবিক সহায়তা, সাইক্লিং বা পটভূমিহীন মানচিত্র বাছুন। দৃশ্যমান ভেক্টর লেয়ার ছবির এক্সপোর্টে থাকে। প্রতি প্রজেক্টে সর্বোচ্চ ৬৪ মেগাবাইট ও ৫০,০০০ সহায়ক ফিচার ইমপোর্ট সমর্থিত।';

  @override
  String get ui18f2b9281b8e => 'ওয়েবম্যাপ, মানচিত্রের নকশা ও ছবি';

  @override
  String get ui231e564db4cd => 'সম্পন্ন';

  @override
  String get uif0f6ea94f6ad => 'পর্যালোচনা প্রয়োজন';

  @override
  String get ui7e3cbb17832c => 'নতুন ফিচার';

  @override
  String get uib18d1e57ecc0 => 'পাওয়া যায়নি';

  @override
  String get uie22586930a5b => 'বাকি';

  @override
  String get ui13a1891af75c => 'হালনাগাদ';

  @override
  String get uiec734b651574 => 'যাচাইকৃত';

  @override
  String ui1a9356ff587e(String v0) {
    return 'সংযুক্ত $v0টি স্টাডি এরিয়ার বিন্দুও সরানো হবে।\n';
  }

  @override
  String get ui12a3a4f498b2 => 'নির্ভুলতা';

  @override
  String get ui89ee1223f2e1 => 'নির্ভুলতা যাচাই';

  @override
  String get uib375acb22bce => 'রেকর্ডিং বাতিল করবেন?';

  @override
  String get ui744d0bab1b52 => 'ফিচার মুছুন';

  @override
  String get uidff896de7cef => 'লগ মুছুন';

  @override
  String get uia84949c694a9 => 'ঢাকার সময় (GMT+6)';

  @override
  String uiec4dd3969fea(String v0) {
    return 'সার্ভের খসড়া — $v0';
  }

  @override
  String get ui22a31d86e018 => 'খসড়া';

  @override
  String get ui5fc97790c6a8 => 'অতিবাহিত';

  @override
  String ui88bbbbe65742(String v0) {
    return 'ফিচার $v0';
  }

  @override
  String get uif5c66da8133d => 'জিএনএসএস উচ্চতা';

  @override
  String ui93db01b4b539(String v0) {
    return 'জিপিএস লগ $v0';
  }

  @override
  String get ui97eeda258d4d => 'GeoJSON';

  @override
  String get ui04b47027708e => 'GeoPackage';

  @override
  String get uib1ddccafa588 => 'Google Earth / GIS';

  @override
  String get uic5bd90689147 => 'KML';

  @override
  String get uid2521a9d2adb => 'MapBanai স্টাডি এরিয়া এক্সপোর্ট';

  @override
  String get ui0c409607d527 => 'MapBanai ওয়েবম্যাপ';

  @override
  String get ui7dbb0cc1dc12 => 'পরিমাপের সাইট';

  @override
  String get ui695385e41e56 => 'নতুন বিন্দুর লগ';

  @override
  String get ui329d3a41479d => 'পরিসীমা';

  @override
  String get uif9e31cfd1b72 => 'প্রজেক্টের বিবরণ';

  @override
  String get uiaecc2a7055a2 => 'ট্র্যাক রেকর্ড';

  @override
  String get uic1ea3d0bd91c => 'লগের নাম বদলান';

  @override
  String uidc4de6540089(String v0) {
    return 'পর্ব $v0';
  }

  @override
  String get ui29053fbf93da => 'SQLite + WKB জ্যামিতি';

  @override
  String get ui5205fe16c422 => 'উপগ্রহ (ব্যবহৃত / দৃশ্যমান)';

  @override
  String get ui2d2cb022bc3d => 'গতি';

  @override
  String get uiaa45b267e05e => 'সার্ভে ও মানচিত্রের ইতিহাস';

  @override
  String get uifbea242d37f8 => 'WKT জ্যামিতিসহ সারণির তথ্য';

  @override
  String get ui998249c59a6e => 'UTC সময় (জিপিএস)';

  @override
  String get uib3a015034320 => 'বিন্দু';

  @override
  String get ui69bd4ef9fbd0 => 'দেখুন';

  @override
  String get ui7f85f35d7ca2 => 'Web / QGIS';

  @override
  String ui824755f37e73(String v0) {
    return '$v0 — পর্যবেক্ষণ';
  }

  @override
  String get ui0bcc30904efc => 'এই নামে সংগ্রহ পর্ব ইতিমধ্যে আছে।';

  @override
  String get ui88896e6489d6 => 'খসড়ার সংযুক্ত ফিচার বদলানো যাবে না।';

  @override
  String get ui89c343833e83 =>
      'এই ফলাফলের জন্য পরিবর্তন বা পর্যালোচনার নোট লিখুন।';

  @override
  String get ui7da0faaccb67 => 'এই লেয়ারের সংগ্রহ পর্ব বাছুন।';

  @override
  String get ui462afc2c8051 => 'এই প্রজেক্টের ফর্ম বাছুন।';

  @override
  String get ui117493d4eef6 =>
      'এই প্রজেক্টের পুনরাবৃত্ত সংগ্রহের লেয়ার বাছুন।';

  @override
  String get ui361f7065ffe8 => 'এই প্রজেক্ট ও কাজের মোডের সাইট বাছুন।';

  @override
  String get ui36e876a95151 =>
      'ভিজিটের ফলাফল বাছুন: যাচাইকৃত, হালনাগাদ, পাওয়া যায়নি বা পর্যালোচনা প্রয়োজন।';

  @override
  String get uic502d96e61cd =>
      'আগে নির্বাচিত সার্ভে সম্পূর্ণ করে সংরক্ষণ করুন।';

  @override
  String get ui2c4d8c966796 => 'বর্তমান ফিচার অন্য প্রজেক্টের।';

  @override
  String get ui1103b1a10bbd => 'শেষ করার সময় খসড়া বদলেছে। আবার খুলুন।';

  @override
  String get ui03b6c1a0b4ac => 'খসড়াটি বদলেছে। শেষ করার আগে আবার খুলুন।';

  @override
  String get uibe390c0ef7b4 => 'সংগ্রহ পর্বের নাম লিখুন।';

  @override
  String get uif7299773137e => 'লেয়ারের নাম লিখুন';

  @override
  String get ui4a355a1939ef => 'লেয়ারের নাম লিখুন।';

  @override
  String get uiebf870d13fa8 => 'ফিচারের জ্যামিতি নেই বা সঠিক নয়।';

  @override
  String get ui8bc3895df8c2 =>
      'ফিচার সরানো হয়েছে। ভিজিট প্রয়োগের আগে স্টাডি মানচিত্র ফিরিয়ে আনুন বা দেখুন।';

  @override
  String get ui1761acebd70a => 'ফর্ম এই প্রজেক্টের নয়';

  @override
  String get uiba63f7620f2b => 'সংগ্রহের অবস্থা সঠিক নয়।';

  @override
  String get ui86fa10d3afc9 =>
      'পর্যালোচনার সময় মানচিত্র আবার বদলেছে। আবার খুলে সংস্করণ তুলনা করুন।';

  @override
  String get ui5877c7c71c31 =>
      'এই বাছাইয়ে বিন্দুর অবস্থানসহ কোনো সংরক্ষিত পরিমাপ নেই।';

  @override
  String get ui1bd927bf4b76 =>
      'শুধু সংরক্ষিত ও প্রয়োগ বাকি ভিজিট নতুন মূল অবস্থার সঙ্গে মেলানো যায়।';

  @override
  String get ui5076a1f7ffb8 =>
      'শুধু সংরক্ষিত ভিজিট দিয়ে মানচিত্র সমন্বয় করা যায়।';

  @override
  String get uice44f8239f96 =>
      'হোম থেকে স্টাডি এরিয়া খুলে মাঠে যাচাই, পুনরাবৃত্ত তথ্য সংগ্রহ বা স্টাডি এরিয়া ভিজিট বাছুন। প্রজেক্ট, সাইটের লেয়ার ও প্রশ্নপত্র দিন। প্রজেক্টের লেয়ার থেকে প্রতিটি আপলোডের ব্যবহারযোগ্য মোড বাছুন। মাঠে যাচাই মূল ফিচার হালনাগাদ করে; সাইট বেছে প্রশ্নপত্রের বোতামে ভিজিট শুরু বা পুরোনো খসড়া চালিয়ে যান। পুনরাবৃত্ত তথ্য সংগ্রহে নাম, ঐচ্ছিক সময়কাল/ঋতু ও তারিখসহ সংগ্রহ পর্ব বাছুন। প্রতি পর্বে সংগৃহীত, সংগ্রহ হয়নি ও পর্যালোচনার অবস্থা আলাদা থাকে। প্রথম পরিমাপ থেকে সাইট বানাতে উত্তর থেকে লেয়ার তৈরি বেছে মূল প্রশ্নপত্র ও সংখ্যাভিত্তিক পরিমাপ দিন। মূল উত্তর অক্ষত থাকে। স্টাডি এরিয়া ভিজিটে দ্রুত সম্পন্ন, অসম্পন্ন বা পর্যালোচনার অবস্থা এবং ঐচ্ছিক প্রশ্নপত্র আছে। নির্বাচিত সাইট থেকে Google Maps-এ বাইরের নেভিগেশন খুলুন। সময়রেখায় আগের পর্যবেক্ষণ থাকে। আপলোডের সাইটের নাম ও বৈশিষ্ট্য অপরিবর্তিত থাকে; প্রশ্নের বাংলা লেবেলের জন্য দ্বিভাষিক XLSForm ব্যবহার করুন।';

  @override
  String get uicbcd0cfd27d2 => 'প্রজেক্টটি আর নেই';

  @override
  String get ui325826737355 => 'প্রজেক্টটি আর নেই।';

  @override
  String get uib71084f5010f =>
      'প্রজেক্ট প্যাকেজে প্রজেক্টের সংজ্ঞা, প্রশ্নপত্র, লেয়ার ও সেটআপ থাকে। সংগৃহীত রেকর্ডও নিতে উত্তর ও ছবি অন্তর্ভুক্ত করার বিকল্প বাছুন; শুধু সেটআপের প্যাকেজ সংগৃহীত তথ্যের ব্যাকআপ নয়। সিঙ্ক সংযোগ অন্তর্ভুক্ত করলে বিশ্বস্ত মাঠদলের জন্য URL ও API কী থাকে। দলের একই প্রজেক্ট পরিচয় রাখুন। নতুন কপি করলে আলাদা পরিচয় ও ব্যাকএন্ড সেটআপ প্রয়োজন।\n\nফোনের বাইরেও ব্যাকআপ রাখুন। একই স্বাক্ষরের অ্যাপের উপর হালনাগাদ করলে স্থানীয় তথ্য থাকে; আনইনস্টল বা অ্যাপের সংরক্ষণ মুছলে তথ্য হারায়। এক্সপোর্টের আগে ক্লাউড সংযোগ সংরক্ষণ করুন।';

  @override
  String get uie6e161cc9336 =>
      'এই সংগ্রহ সম্পূর্ণ করতে নির্বাচিত প্রশ্নপত্র সংরক্ষণ করুন।';

  @override
  String get ui3dc7df584218 => 'এই প্রশ্নপত্রের সংখ্যাভিত্তিক পরিমাপ বাছুন।';

  @override
  String get ui36e792741f9f => 'প্রশ্নপত্র ও পরিমাপ বাছুন।';

  @override
  String get ui0808b5a3481d => 'এই প্রজেক্টের প্রশ্নপত্র বাছুন।';

  @override
  String get ui24607fcc859f => 'স্টাডি লেয়ার এই প্রজেক্টের নয়';

  @override
  String get ui01f762c7c32b => 'সংগ্রহ পর্বটি অন্য লেয়ারের।';

  @override
  String get uib7287c8bc71b =>
      'খসড়াটি অন্য পর্দায় বদলেছে। সংরক্ষণের আগে আবার খুলুন।';

  @override
  String get ui937151b52477 => 'খসড়াটি বদলেছে। সংরক্ষণের আগে আবার খুলুন।';

  @override
  String get ui2c9f263743c4 => 'ফিচারটি অন্য প্রজেক্টের।';

  @override
  String get ui547bca6d008d =>
      'ভিজিটটি ইতিমধ্যে শেষ হয়েছে। সংরক্ষিত রেকর্ড আবার খুলুন।';

  @override
  String get ui5f30a4c4489e => 'পর্যালোচনার সময় ভিজিট বদলেছে। আবার খুলুন।';

  @override
  String get ui85f5c6c2edf4 => 'ভিজিটটি নেই।';

  @override
  String get uieda6aa29be81 => 'ভিজিটের খসড়াটি আর নেই।';

  @override
  String get ui0aabe5893a27 => 'ভিজিট মোছা হয়েছে।';

  @override
  String get ui6ecd86a8f125 => '১৬:১০ · ল্যাপটপ';

  @override
  String get uif05d6690fa2d => '১৬:৯ · ওয়ালপেপার';

  @override
  String get uia57dc941dcd3 => '১:১ · বর্গাকার';

  @override
  String get uib4381bea81cf => '২১:৯ · অতিরিক্ত চওড়া';

  @override
  String get ui2823d71dd313 => '৩:২ · ছবি';

  @override
  String get ui4bfeadd27478 => '৪:৩ · ধ্রুপদি';

  @override
  String get uidd24b455a6e9 => 'সব ফর্ম / ধরন';

  @override
  String get ui6405179d241b => 'সব অবস্থা';

  @override
  String get ui14ce09a8dd4e => 'এলাকা';

  @override
  String get ui4e077cf8bf92 => 'দৈর্ঘ্য-প্রস্থের অনুপাত';

  @override
  String get ui9bffcb9f06c2 => 'বৈশিষ্ট্যের সারণি';

  @override
  String get ui64dd60fe1a04 => 'পটভূমি';

  @override
  String get uid0d92ae1cf5e => 'পটভূমির মানচিত্র';

  @override
  String get ui601cd5a75b27 => 'ভিত্তি মানচিত্রের রঙের ধরন';

  @override
  String get ui019728575b52 => 'সাদাকালো';

  @override
  String get ui06992d2c6a4f => 'ব্লুপ্রিন্ট';

  @override
  String get ui76d1fadb362e => 'ক্যাপশনের বিন্যাস';

  @override
  String get uia1e4a4404fb7 => 'বিভাগ · কলামের মান';

  @override
  String get ui16e5447a8046 => 'মাঝে';

  @override
  String get ui253444ab88a5 =>
      'নকশা ও ছবির আকার বাছুন। ডাউনলোডের আগে মানচিত্র সরিয়ে বা জুম করে নিন।';

  @override
  String get ui219c06043a26 => 'ধ্রুপদি সেরিফ';

  @override
  String get ui0f8dabf7dc77 => 'মানচিত্র ডাউনলোড বন্ধ করুন';

  @override
  String get ui0c4b831492a5 => 'উপকূলের নীল';

  @override
  String get ui4bbb632f02fd => 'সংগ্রহ';

  @override
  String get uie3199d24849e => 'তথ্যসংগ্রাহক';

  @override
  String get ui653bfaa2a80f => 'রঙের ভিত্তি';

  @override
  String get ui02dabdeefe20 => 'রং সাইটের অবস্থা দেখায়';

  @override
  String get ui8d30cc74f67e => 'রং ও বিভাগ';

  @override
  String get ui8b8025fc854d => 'বর্তমান ভিত্তি মানচিত্র';

  @override
  String get uie11f3a510f6a => 'বর্তমান মানচিত্রের দৃশ্য';

  @override
  String get ui134d207372fc => 'নিজস্ব রং';

  @override
  String get ui915add28af82 => 'নিজস্ব মাপ';

  @override
  String get uic646cf24f147 => 'শুধু তথ্য';

  @override
  String get ui160e0e54c6f5 => 'মরুর বালি';

  @override
  String get uiaa30393c7650 => 'JPEG ডাউনলোড';

  @override
  String get ui0c8309d1f4d0 => 'PNG ডাউনলোড';

  @override
  String get ui6dc7d6db796a => 'ডাউনলোড প্রস্তুত';

  @override
  String get uic756f6af1f03 => 'সবাই';

  @override
  String get uib965ae66fcc4 => 'অনুসন্ধান';

  @override
  String get uie1a3f6c998b3 => 'মাঠের তথ্য দেখুন';

  @override
  String get ui583cccdcd165 => 'এক্সপোর্ট হচ্ছে…';

  @override
  String get ui05128f46d8c8 => 'অতিরিক্ত বড়';

  @override
  String get uicbb7a61052e1 => 'ফিচারের লেবেল';

  @override
  String get ui45b8b762d80d => 'মাঠের অ্যাটলাস';

  @override
  String get uid509f832e48f => 'সাইট বা উত্তর খুঁজুন';

  @override
  String get uib20486dfffd5 => 'ফলাফল মাপসই করুন';

  @override
  String get uic7c22ccaf35b => 'দৃশ্যমান তথ্য মাপসই করুন';

  @override
  String get uif41c4e4dab0b => 'বন';

  @override
  String get ui3f66052a107e => 'থেকে';

  @override
  String get ui839e01b3dcb2 => 'Full HD · ১৯২০';

  @override
  String get uic5a6470c3d70 => 'জ্যামিতির ধরন';

  @override
  String get ui53b0911438aa => 'স্তরভিত্তিক · সংখ্যার মান';

  @override
  String get uib1ef9dd05873 => 'HD · ১২৮০';

  @override
  String get uif81c3e5ae1c6 => 'উচ্চতা (পিক্সেল)';

  @override
  String get uif2468877acc4 => 'সারণি লুকান';

  @override
  String get ui9bcbf7e9ceb7 => 'কাগজে কালি';

  @override
  String get ui7dc4bea61853 => 'আড়াআড়ি';

  @override
  String get ui738fd1d2452f => 'বড়';

  @override
  String get ui75c88f3a0072 => 'ল্যাভেন্ডার';

  @override
  String get ui972ad8d8a503 => 'বিন্যাস';

  @override
  String get ui8ae1c34bd37f => 'বামে';

  @override
  String get uif40b6a07a9d0 => 'লেজেন্ডের ফন্ট';

  @override
  String get ui5b8fbe24bfd9 => 'লেজেন্ডের নাম ও চিহ্ন';

  @override
  String get uic6fd3870c86e => 'রেখা';

  @override
  String get ui36360d6d8c2a => 'Lobster · হাতে লেখা';

  @override
  String get ui6d14f8cbd660 => 'Lora · বইয়ের সেরিফ';

  @override
  String get ui304ceba28849 => 'মানচিত্রের বিস্তার';

  @override
  String get uidb1a9c33957d => 'মানচিত্রের বাছাই';

  @override
  String get uifdee43176a62 => 'মানচিত্রের লেয়ার';

  @override
  String get uidf2a2bdfd1ae => 'শুধু মানচিত্র';

  @override
  String get uia418467db07d => 'মানচিত্রের পোস্টার';

  @override
  String get ui708370785b57 =>
      'টাইলের জন্য ইন্টারনেট লাগে; আপনার তথ্য অফলাইনে চলে';

  @override
  String get ui889a7e8464fa => 'মানচিত্রের শিরোনাম';

  @override
  String get ui08a159c05728 => 'MapBanai · প্রজেক্ট অ্যাটলাস';

  @override
  String get ui09ee4407bee8 => 'নকশার সঙ্গে মেলান';

  @override
  String get uia8df2fec28d8 => 'সর্বোচ্চ';

  @override
  String get ui8b4b0b8ee2ca => 'সর্বোচ্চ পরিমাপ';

  @override
  String get ui558287ddcc35 => 'মধ্যরাত';

  @override
  String get ui5d398eef3ecc => 'সর্বনিম্ন';

  @override
  String get ui4a0c5b771fb5 => 'সর্বনিম্ন পরিমাপ';

  @override
  String get ui08b10f41c999 => 'আধুনিক স্যান্স সেরিফ';

  @override
  String get uidef80ab2391e => 'আমার অবস্থান';

  @override
  String get ui9825e8466d49 => 'নাম, আইডি, লবণাক্ততা…';

  @override
  String get ui2b7c08c3ab75 => 'নাম';

  @override
  String get uibc981983e7f5 => 'পরেরটি';

  @override
  String get ui416010b25189 => 'পটভূমি নেই';

  @override
  String get uibd4d569dbbb2 => 'Nunito · গোলাকার';

  @override
  String get uie3de5ab0ca4c => 'বন্ধ';

  @override
  String get ui86e4e3875420 => 'অভিমুখ';

  @override
  String get uic0a8060f3b11 => 'মূল';

  @override
  String get ui7a297fcb17e0 => 'Oswald · সরু';

  @override
  String get ui22d507f2ba74 => 'কাগজ';

  @override
  String get ui4b2a6a314956 => 'বিন্দু';

  @override
  String get ui92b6b1bf71e0 => 'লম্বালম্বি';

  @override
  String get ui1643936014d7 => 'ছবি তৈরি হচ্ছে…';

  @override
  String get ui50f94286ba30 => 'আগেরটি';

  @override
  String get uif842de4b00d7 => 'প্রজেক্টের মানচিত্র';

  @override
  String get ui30891032b07f => 'এক রঙের ছায়া';

  @override
  String get ui6f43b588ef53 => 'QHD · ২৫৬০';

  @override
  String get ui44c57abd888a => 'রিসেট';

  @override
  String get ui516aae52959d => 'রেজোলিউশন';

  @override
  String get ui954daa8b0033 => 'ডানে';

  @override
  String get ui4c7311ae72a1 => 'গোলাপি কোয়ার্টজ';

  @override
  String get ui3e2479c4685a => 'সেজ ও ক্রিম';

  @override
  String get uieb61da0ddb23 => 'JPEG শেয়ার';

  @override
  String get ui69b2ba27ee1a => 'PNG শেয়ার';

  @override
  String get uid97d1ee339e4 => 'দেখান';

  @override
  String get ui445d12dec2a5 => 'সারণি দেখান';

  @override
  String get ui17480c963f26 => 'সাইটের অবস্থা';

  @override
  String get ui8684c3cda710 => 'সাইট ও সংগ্রহ';

  @override
  String get ui25e0ca14c327 => 'হালকা ম্লান';

  @override
  String get ui564186be1ef2 => 'সাধারণ · রেজোলিউশন অনুযায়ী মাপ';

  @override
  String get ui1f214e692623 => 'স্টাডি সাইট';

  @override
  String get ui99a0efc6cfd8 => 'ধরন';

  @override
  String get uie159d05a124c => 'উপশিরোনাম';

  @override
  String get ui68731e7bff79 => 'উপশিরোনামের ফন্ট';

  @override
  String get ui54041909beab => 'সার্ভে ফর্ম / ধরন';

  @override
  String get ui5c55024681cc => 'প্রতীকায়ন';

  @override
  String get ui0424f6e7026f => 'সারণি';

  @override
  String get uida6453b3fe00 => 'কারিগরি মনো';

  @override
  String get ui8be6e64eb5c3 => 'পোড়ামাটি';

  @override
  String get ui5da8b6d504e5 => 'লেখা ও চিহ্নের আকার';

  @override
  String get uiae79ea1e9c63 => 'পর্যন্ত';

  @override
  String get uif4beb9af58f7 => 'লেখার বিন্যাস';

  @override
  String get ui6c3b0475960a => 'দৃশ্যমান ফিচার';

  @override
  String get ui3b2f5b0cf572 => 'উজ্জ্বল';

  @override
  String get ui26606552151f => 'উষ্ণ পুরোনো ধরন';

  @override
  String get uie73a0adf49ce => 'প্রস্থ (পিক্সেল)';

  @override
  String get ui046786ec74e0 => 'আপনার প্রজেক্টের নাম';

  @override
  String get uid74015d4e00f => 'যেমন লবণাক্ততা · অক্টোবরের মাঠ ভিজিট';

  @override
  String ui6313520ac1e1(String v0) {
    return 'ফিচারের UUID: $v0';
  }

  @override
  String uia68e9ddcf3b8(String v0) {
    return 'পর্যবেক্ষণের UUID: $v0';
  }

  @override
  String get uia1e34f91579d => 'আরও কাজ';

  @override
  String get uie93c7af975cb => 'কাজের ধরন বাছুন';

  @override
  String get uibce757708457 => 'কর্মপ্রবাহের আবশ্যক ধাপ';

  @override
  String get ui339529eee4c0 =>
      'মাঠদলের সঙ্গে প্রকল্প ভাগ করার আগে আবশ্যক ধাপ নির্ধারণ করুন। এই সেটিংস পরিবর্তনের পর হালনাগাদ প্রকল্প প্যাকেজ ভাগ করুন।';

  @override
  String get uicd39c5d4c2d2 => 'প্রশ্নমালা আবশ্যক';

  @override
  String get uic184e2bde3f6 => 'অবস্থানযুক্ত ছবি আবশ্যক';

  @override
  String get ui8caa0a53724d => 'আবশ্যক ধাপ সংরক্ষণ করুন';

  @override
  String get ui551b1994e409 => 'ছবি ঐচ্ছিক।';

  @override
  String get ui0b0a3f8c430f =>
      'শেষ করতে আবশ্যক ধাপগুলো সম্পন্ন করুন। যেকোনো সময় খসড়া সংরক্ষণ করতে পারবেন।';

  @override
  String get ui6e4c1e3c8ad1 => 'নিকটবর্তী অপরিদর্শিত স্থান';

  @override
  String get ui66fc75da8df4 => 'আপনার জিপিএস অবস্থান থেকে সরলরেখায় দূরত্ব।';

  @override
  String get ui701b8859c071 =>
      'সাম্প্রতিক জিপিএস অবস্থান নেই। স্থানগুলো নাম অনুযায়ী সাজানো হয়েছে।';

  @override
  String get uic9704e072a21 => 'অবস্থান হালনাগাদ করুন';

  @override
  String get ui3362f0a776a1 => 'এই লেয়ারে অপরিদর্শিত স্থান নেই।';

  @override
  String get ui51848b274f3e => 'অবস্থান ব্যবহারের অনুমতি প্রয়োজন।';

  @override
  String get ui45f4f4818756 => 'অবস্থানযুক্ত ছবি প্রয়োজন।';

  @override
  String get ui0ded61d14817 =>
      'স্থানটি সম্পন্ন হিসেবে চিহ্নিত করার আগে আবশ্যক প্রশ্নমালা ও ছবির ধাপ শেষ করুন।';

  @override
  String get uif8e4834eedd0 => 'কর্মপ্রবাহের আবশ্যক ধাপের সেটিংস সঠিক নয়।';

  @override
  String get ui39854cbe2f78 =>
      'প্রতিটি কর্মপ্রবাহের জন্য আবশ্যক প্রশ্নমালা ও ছবি';

  @override
  String get ui1c8464e927ab => 'সেটিংস লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String ui57d8a0369581(String v0, String v1) {
    return '$v0টি জরিপ · $v1টি মানচিত্র রেকর্ড';
  }

  @override
  String get ui96f608c16cef => 'বাকি';

  @override
  String get uid1ecc7f909ab => 'অপরিবর্তিত / সম্পন্ন';

  @override
  String get ui9f94eae70b22 =>
      'অনলাইন প্রজেক্ট লিংক এখনও সমর্থিত নয়। প্রেরকের কাছে প্রজেক্ট ফাইল (.mbproj) চান।';

  @override
  String uidc28bfa36b03(String v0) {
    return 'স্থানটি মুছতে পারেনি: $v0';
  }

  @override
  String get ui72dee98881cc => 'বর্তমান জিপিএস অবস্থানে পয়েন্ট যোগ করুন';

  @override
  String get ui28edaf4de42d =>
      'এই কাজ ফিরিয়ে নেওয়া যাবে না। চালিয়ে যাওয়ার আগে ব্যাকআপ এক্সপোর্ট করুন।';

  @override
  String ui11753d7c0e00(String v0) {
    return 'আমি বুঝেছি যে সিঙ্ক না হওয়া $v0টি রেকর্ড হারিয়ে যাবে।';
  }

  @override
  String ui290774591872(String v0) {
    return 'নিশ্চিত করতে প্রজেক্টের নাম লিখুন: $v0';
  }

  @override
  String get uiaaaaecf77fe9 => 'ডিভাইস থেকে মুছুন';

  @override
  String ui44b817558a93(String v0, String v1, String v2) {
    return '$v0: এই ডিভাইস থেকে $v1টি ম্যাপ পয়েন্ট ও $v2টি ইতিহাসের রেকর্ড মুছে যাবে। ক্লাউডের কপি অপরিবর্তিত থাকবে।';
  }

  @override
  String ui3f3efb1d5de2(String v0, String v1) {
    return 'এই ডিভাইস থেকে $v0টি ইতিহাসের রেকর্ড ও সংযুক্ত $v1টি ম্যাপ পয়েন্ট মুছে যাবে। ক্লাউডের কপি অপরিবর্তিত থাকবে।';
  }
}
