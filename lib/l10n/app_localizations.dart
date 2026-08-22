import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'MapBanai'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'MapBanai'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline field data collection'**
  String get homeSubtitle;

  /// No description provided for @surveyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Survey Mode'**
  String get surveyModeTitle;

  /// No description provided for @surveyModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple form-based field capture'**
  String get surveyModeSubtitle;

  /// No description provided for @gisModeTitle.
  ///
  /// In en, this message translates to:
  /// **'GIS Mode'**
  String get gisModeTitle;

  /// No description provided for @gisModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map-based spatial editing and layers'**
  String get gisModeSubtitle;

  /// No description provided for @gpsModeTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS Mode'**
  String get gpsModeTitle;

  /// No description provided for @gpsModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live GPS readings and coordinate logging'**
  String get gpsModeSubtitle;

  /// No description provided for @studyAreaModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Area Mode'**
  String get studyAreaModeTitle;

  /// No description provided for @studyAreaModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Site visits with status tracking & navigation'**
  String get studyAreaModeSubtitle;

  /// No description provided for @gpsCsvViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS CSV Viewer'**
  String get gpsCsvViewerTitle;

  /// No description provided for @gpsCsvViewerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View logs & project tracks on WebMap'**
  String get gpsCsvViewerSubtitle;

  /// No description provided for @syncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload responses & photos to cloud'**
  String get syncSubtitle;

  /// No description provided for @syncSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up cloud sync'**
  String get syncSetupTitle;

  /// No description provided for @syncSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure sync for \"{project}\"'**
  String syncSetupSubtitle(String project);

  /// No description provided for @syncLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {date}'**
  String syncLastSynced(String date);

  /// No description provided for @syncNever.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncNever;

  /// No description provided for @syncNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get syncNoInternet;

  /// No description provided for @webMapTitle.
  ///
  /// In en, this message translates to:
  /// **'WebMap'**
  String get webMapTitle;

  /// No description provided for @webMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline HTML map with filters and popups'**
  String get webMapSubtitle;

  /// No description provided for @projectSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Current project: {project}'**
  String projectSelectorTitle(String project);

  /// No description provided for @noProjectSelected.
  ///
  /// In en, this message translates to:
  /// **'No project selected — tap to choose one'**
  String get noProjectSelected;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get selectProject;

  /// No description provided for @collectedDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Collected data — {project}'**
  String collectedDataTitle(String project);

  /// No description provided for @collectedDataHint.
  ///
  /// In en, this message translates to:
  /// **'Select a project above to see its collected data.'**
  String get collectedDataHint;

  /// No description provided for @surveyResponses.
  ///
  /// In en, this message translates to:
  /// **'Survey Responses'**
  String get surveyResponses;

  /// No description provided for @gisFeatures.
  ///
  /// In en, this message translates to:
  /// **'GIS Features'**
  String get gisFeatures;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @importProject.
  ///
  /// In en, this message translates to:
  /// **'Import Project'**
  String get importProject;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsUserTitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get settingsUserTitle;

  /// No description provided for @settingsUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name is attached to every survey response, GPS log entry and export produced by the app.'**
  String get settingsUserSubtitle;

  /// No description provided for @userNameLabel.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get userNameLabel;

  /// No description provided for @userNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., John Doe'**
  String get userNameHint;

  /// No description provided for @userNameLeaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to clear.'**
  String get userNameLeaveEmpty;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language. System default follows the device language.'**
  String get languageSubtitle;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get bangla;

  /// No description provided for @themeSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeSection;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or follow the system theme.'**
  String get themeSubtitle;

  /// No description provided for @preferredTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get preferredTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @measurementSection.
  ///
  /// In en, this message translates to:
  /// **'Measurement units'**
  String get measurementSection;

  /// No description provided for @measurementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used by the GIS distance and area tools. Automatic picks metres/kilometres and square metres or hectares.'**
  String get measurementSubtitle;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @dataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all locally stored survey data.'**
  String get dataSubtitle;

  /// No description provided for @resetData.
  ///
  /// In en, this message translates to:
  /// **'Reset data'**
  String get resetData;

  /// No description provided for @resetDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Final confirmation'**
  String get resetDataConfirmTitle;

  /// No description provided for @updatesSection.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesSection;

  /// No description provided for @updatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checks the GitHub releases feed for a newer version.'**
  String get updatesSubtitle;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkForUpdatesWithVersion.
  ///
  /// In en, this message translates to:
  /// **'Check for updates — v{version} installed'**
  String checkForUpdatesWithVersion(String version);

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Offline field data collection GIS'**
  String get aboutTagline;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @saveResponses.
  ///
  /// In en, this message translates to:
  /// **'Save responses'**
  String get saveResponses;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get saveAsDraft;

  /// No description provided for @gpsRecordingActive.
  ///
  /// In en, this message translates to:
  /// **'GPS recording active — \"{name}\"'**
  String gpsRecordingActive(String name);

  /// No description provided for @gpsRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Logging continues with the screen off. Leave GPS Mode any time; come back here to stop.'**
  String get gpsRecordingHint;

  /// No description provided for @openGpsMode.
  ///
  /// In en, this message translates to:
  /// **'Open GPS Mode'**
  String get openGpsMode;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @surveyMode.
  ///
  /// In en, this message translates to:
  /// **'Survey Mode'**
  String get surveyMode;

  /// No description provided for @selectSurveyForm.
  ///
  /// In en, this message translates to:
  /// **'Select a survey form'**
  String get selectSurveyForm;

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project: {project}'**
  String projectLabel(String project);

  /// No description provided for @myForms.
  ///
  /// In en, this message translates to:
  /// **'My forms'**
  String get myForms;

  /// No description provided for @noFormsHint.
  ///
  /// In en, this message translates to:
  /// **'No forms yet for this project. Tap to build or import your first survey form.'**
  String get noFormsHint;

  /// No description provided for @startBuildingForm.
  ///
  /// In en, this message translates to:
  /// **'Start building survey form'**
  String get startBuildingForm;

  /// No description provided for @formQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String formQuestionsCount(String count);

  /// No description provided for @buildOrImportForm.
  ///
  /// In en, this message translates to:
  /// **'Build or import a survey form'**
  String get buildOrImportForm;

  /// No description provided for @formLanguage.
  ///
  /// In en, this message translates to:
  /// **'Form language'**
  String get formLanguage;

  /// No description provided for @formLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Switch between languages defined in the XLSForm'**
  String get formLanguageHint;

  /// No description provided for @captureGps.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureGps;

  /// No description provided for @measureAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measureAccuracy;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attachPhoto;

  /// No description provided for @replacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replacePhoto;

  /// No description provided for @tapToCaptureGps.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture GPS location'**
  String get tapToCaptureGps;

  /// No description provided for @tapToMeasureAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Tap to measure accuracy'**
  String get tapToMeasureAccuracy;

  /// No description provided for @photoAttached.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get photoAttached;

  /// No description provided for @geotaggedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Geotagged photo attached'**
  String get geotaggedPhoto;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String requiredField(String label);

  /// No description provided for @constraintError.
  ///
  /// In en, this message translates to:
  /// **'{label}: {error}'**
  String constraintError(String label, String error);

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// No description provided for @enterLongText.
  ///
  /// In en, this message translates to:
  /// **'Enter long text'**
  String get enterLongText;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get enterNumber;

  /// No description provided for @enterDecimal.
  ///
  /// In en, this message translates to:
  /// **'Enter decimal number'**
  String get enterDecimal;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get selectOption;

  /// No description provided for @chooseOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get chooseOption;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select date and time'**
  String get selectDateTime;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @studyAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Area'**
  String get studyAreaTitle;

  /// No description provided for @projectTitle.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectTitle;

  /// No description provided for @projectSettings.
  ///
  /// In en, this message translates to:
  /// **'Project settings'**
  String get projectSettings;

  /// No description provided for @renameProject.
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get renameProject;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @shareProject.
  ///
  /// In en, this message translates to:
  /// **'Share project'**
  String get shareProject;

  /// No description provided for @lightThemeApplied.
  ///
  /// In en, this message translates to:
  /// **'Light theme applied'**
  String get lightThemeApplied;

  /// No description provided for @darkThemeApplied.
  ///
  /// In en, this message translates to:
  /// **'Dark theme applied'**
  String get darkThemeApplied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
