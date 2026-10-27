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
  /// **'Easy Geospatial Data Collection'**
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
  /// **'Easy Geospatial Data Collection'**
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

  /// "{v0}" created
  ///
  /// In en, this message translates to:
  /// **'\"{v0}\" created'**
  String ui146d90ab8a12(String v0);

  /// 1. Verify {v0}
  ///
  /// In en, this message translates to:
  /// **'1. Verify {v0}'**
  String uidb9502050d6e(String v0);

  /// 2. Collect information
  ///
  /// In en, this message translates to:
  /// **'2. Collect information'**
  String get uica8002883856;

  /// 3. Geotagged evidence photo
  ///
  /// In en, this message translates to:
  /// **'3. Geotagged evidence photo'**
  String get uie2d42900f048;

  /// A photo is required before finishing.
  ///
  /// In en, this message translates to:
  /// **'A photo is required before finishing.'**
  String get uia71b74276db0;

  /// A project named "{v0}" already exists
  ///
  /// In en, this message translates to:
  /// **'A project named \"{v0}\" already exists'**
  String ui6eb4c6ceec88(String v0);

  /// API key
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get uicf678cab87dc;

  /// About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get ui6b21fb791ac0;

  /// Acc (m)
  ///
  /// In en, this message translates to:
  /// **'Acc (m)'**
  String get uifa7cafd4738a;

  /// Accept accuracy
  ///
  /// In en, this message translates to:
  /// **'Accept accuracy'**
  String get uiece911f43765;

  /// Accuracy accepted. Your data and photo are kept.
  ///
  /// In en, this message translates to:
  /// **'Accuracy accepted. Your data and photo are kept.'**
  String get uid110ce480b6b;

  /// Accuracy: {v0} (max 20 m)
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {v0} (max 20 m)'**
  String uiee4a56b9d330(String v0);

  /// Acknowledgments
  ///
  /// In en, this message translates to:
  /// **'Acknowledgments'**
  String get ui5d9540ff93a7;

  /// Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get ui61cc55aa0453;

  /// Add Option
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get ui05448f4011e4;

  /// Add Point
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get uif353ad702eca;

  /// Add Question
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get uib86c7f055ded;

  /// Add a project questionnaire
  ///
  /// In en, this message translates to:
  /// **'Add a project questionnaire'**
  String get uia5f99b5076d1;

  /// Add an XLSForm to this project before finishing a visit.
  ///
  /// In en, this message translates to:
  /// **'Add an XLSForm to this project before finishing a visit.'**
  String get ui912d424ade4e;

  /// Add at least {v0} distinct vertices.
  ///
  /// In en, this message translates to:
  /// **'Add at least {v0} distinct vertices.'**
  String ui512ece25554d(String v0);

  /// Add at least {v0} vertices.
  ///
  /// In en, this message translates to:
  /// **'Add at least {v0} vertices.'**
  String ui92c3d4711cb2(String v0);

  /// Add form
  ///
  /// In en, this message translates to:
  /// **'Add form'**
  String get ui6632e5c07446;

  /// Add information
  ///
  /// In en, this message translates to:
  /// **'Add information'**
  String get ui6f689eeab092;

  /// Add layers to this project
  ///
  /// In en, this message translates to:
  /// **'Add layers to this project'**
  String get uifaac648b07cd;

  /// Add line (tap vertices)
  ///
  /// In en, this message translates to:
  /// **'Add line (tap vertices)'**
  String get ui259983d5b67d;

  /// Add new Layer
  ///
  /// In en, this message translates to:
  /// **'Add new Layer'**
  String get ui69ba1bebc021;

  /// Add observation / start visit
  ///
  /// In en, this message translates to:
  /// **'Add observation / start visit'**
  String get uic4c2f28a653e;

  /// Add option
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get uia20144055a2c;

  /// Add photo
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get uid14349309573;

  /// Add polygon (tap vertices)
  ///
  /// In en, this message translates to:
  /// **'Add polygon (tap vertices)'**
  String get uia6e0524cd9f4;

  /// Add study-area, facility and road layers. Source files travel with project exports.
  ///
  /// In en, this message translates to:
  /// **'Add study-area, facility and road layers. Source files travel with project exports.'**
  String get uidfa9ad191cbb;

  /// Add study-area, facility or road layers. Supported files: shapefile or ZIP, CSV, Excel, GeoJSON and GeoPackage. Road layers can provide shortest-path directions in Study Area Mode. Use WGS84 (EPSG:4326).
  ///
  /// In en, this message translates to:
  /// **'Add study-area, facility or road layers. Supported files: shapefile or ZIP, CSV, Excel, GeoJSON and GeoPackage. Road layers can provide shortest-path directions in Study Area Mode. Use WGS84 (EPSG:4326).'**
  String get uif51add823fef;

  /// Add vector layers
  ///
  /// In en, this message translates to:
  /// **'Add vector layers'**
  String get ui29924533fad1;

  /// After
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get ui79ba5e1b3f99;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ui6a72085653e4;

  /// All days
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get uib4f794cdbb77;

  /// All layers
  ///
  /// In en, this message translates to:
  /// **'All layers'**
  String get ui152d422f80e6;

  /// All observations ({v0})
  ///
  /// In en, this message translates to:
  /// **'All observations ({v0})'**
  String uic622d843608e(String v0);

  /// All record types
  ///
  /// In en, this message translates to:
  /// **'All record types'**
  String get ui755046a16371;

  /// All sites
  ///
  /// In en, this message translates to:
  /// **'All sites'**
  String get ui524a33d9c5f7;

  /// All sync statuses
  ///
  /// In en, this message translates to:
  /// **'All sync statuses'**
  String get uidd402a4a59f8;

  /// Allow
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get ui3ad0e3698278;

  /// Allow installation
  ///
  /// In en, this message translates to:
  /// **'Allow installation'**
  String get ui209e0391343c;

  /// Allow location permission to use GPS.
  ///
  /// In en, this message translates to:
  /// **'Allow location permission to use GPS.'**
  String get uia0354233e8e7;

  /// Already synced
  ///
  /// In en, this message translates to:
  /// **'Already synced'**
  String get ui483ff5e64f97;

  /// Also clear survey history and sync queue
  ///
  /// In en, this message translates to:
  /// **'Also clear survey history and sync queue'**
  String get ui12e0f83d72ab;

  /// Also remove linked Study Area points
  ///
  /// In en, this message translates to:
  /// **'Also remove linked Study Area points'**
  String get ui6742711abf37;

  /// Alt (m)
  ///
  /// In en, this message translates to:
  /// **'Alt (m)'**
  String get ui789bda938348;

  /// Answers updated — ready to sync
  ///
  /// In en, this message translates to:
  /// **'Answers updated — ready to sync'**
  String get uib2482df07055;

  /// Appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get ui41def7a0febe;

  /// Apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get uicfea419c3b4e;

  /// Apply import
  ///
  /// In en, this message translates to:
  /// **'Apply import'**
  String get uie4e3653eb728;

  /// Apply questionnaire update
  ///
  /// In en, this message translates to:
  /// **'Apply questionnaire update'**
  String get uic64add5b7c88;

  /// Apply reviewed visit
  ///
  /// In en, this message translates to:
  /// **'Apply reviewed visit'**
  String get ui036a2c32985f;

  /// Apps Script Web App URL
  ///
  /// In en, this message translates to:
  /// **'Apps Script Web App URL'**
  String get uif7110953e0c1;

  /// Archive project
  ///
  /// In en, this message translates to:
  /// **'Archive project'**
  String get ui6baacf7ea93e;

  /// Archived
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get uieddc813f35b1;

  /// Archived project
  ///
  /// In en, this message translates to:
  /// **'Archived project'**
  String get ui371c4c745268;

  /// Area
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get ui2745debaa64a;

  /// Assign previous unassigned sites
  ///
  /// In en, this message translates to:
  /// **'Assign previous unassigned sites'**
  String get ui5de953ada8ae;

  /// Assign selected
  ///
  /// In en, this message translates to:
  /// **'Assign selected'**
  String get uibc9e681ab30c;

  /// At least 3 vertices required ({v0}/3)
  ///
  /// In en, this message translates to:
  /// **'At least 3 vertices required ({v0}/3)'**
  String ui775f4f08081b(String v0);

  /// Attach
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get ui1afff0157ce3;

  /// Attach photo (geotagged)
  ///
  /// In en, this message translates to:
  /// **'Attach photo (geotagged)'**
  String get ui29d7b5c69a0f;

  /// Attached to each new submission.
  ///
  /// In en, this message translates to:
  /// **'Attached to each new submission.'**
  String get ui48b5d713528c;

  /// Attribute "{v0}" already exists
  ///
  /// In en, this message translates to:
  /// **'Attribute \"{v0}\" already exists'**
  String ui0e89f1ba582f(String v0);

  /// Attributes
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get uia6652617f2c7;

  /// Backup restore failed. Data was not changed.
  ///
  /// In en, this message translates to:
  /// **'Backup restore failed. Data was not changed.'**
  String get ui541903fcabc1;

  /// Backup restored successfully.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get ui557ebe872d79;

  /// Bangla
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get ui68ea04ad6c84;

  /// Basemap
  ///
  /// In en, this message translates to:
  /// **'Basemap'**
  String get uicc0720785428;

  /// Before
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get ui74f39697ac32;

  /// Brief description of this form
  ///
  /// In en, this message translates to:
  /// **'Brief description of this form'**
  String get ui6cd36c7dc22c;

  /// Build or import a survey form
  ///
  /// In en, this message translates to:
  /// **'Build or import a survey form'**
  String get ui4dcbe4e8a47b;

  /// CSV
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get ui3281188351b8;

  /// Calculated
  ///
  /// In en, this message translates to:
  /// **'Calculated'**
  String get ui757d86654eda;

  /// Calculation
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get uidc6751bd6532;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ui77dfd2135f4d;

  /// Cancel download
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get ui67bb11d08df2;

  /// Cancel failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cancel failed: {v0}'**
  String ui57d7674a7613(String v0);

  /// Cancel recording
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get uifda8429a704c;

  /// Cannot load icon: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cannot load icon: {v0}'**
  String ui6ca1964345a5(String v0);

  /// Cannot load project: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cannot load project: {v0}'**
  String ui34ebd759c2a4(String v0);

  /// Cannot load study area: {v0}. Stored data was preserved.
  ///
  /// In en, this message translates to:
  /// **'Cannot load study area: {v0}. Stored data was preserved.'**
  String uied3764fb600f(String v0);

  /// Cannot open map styles: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cannot open map styles: {v0}'**
  String ui4b101071fd57(String v0);

  /// Cannot open project map: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cannot open project map: {v0}'**
  String ui81c619629565(String v0);

  /// Cannot reload layers: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cannot reload layers: {v0}'**
  String uiaeb0cf0b59f1(String v0);

  /// Cannot review accuracy: {v0}
  ///
  /// In en, this message translates to:
  /// **'Cannot review accuracy: {v0}'**
  String uiad5108d1542b(String v0);

  /// Capture
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get ui772a4bcb6564;

  /// Capture Photo
  ///
  /// In en, this message translates to:
  /// **'Capture Photo'**
  String get ui70dd605f2b73;

  /// Capture photo
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get ui31c77e404ec9;

  /// Captured {v0}
  ///
  /// In en, this message translates to:
  /// **'Captured {v0}'**
  String ui72d06195a7a3(String v0);

  /// Categories & colors
  ///
  /// In en, this message translates to:
  /// **'Categories & colors'**
  String get ui721731bb86ab;

  /// Category color
  ///
  /// In en, this message translates to:
  /// **'Category color'**
  String get ui8af155f38c5a;

  /// Center on GPS
  ///
  /// In en, this message translates to:
  /// **'Center on GPS'**
  String get uib55970d156d0;

  /// Center on site
  ///
  /// In en, this message translates to:
  /// **'Center on site'**
  String get ui7624e54f7a04;

  /// Change from previous
  ///
  /// In en, this message translates to:
  /// **'Change from previous'**
  String get uid9789c629cfe;

  /// Change or review note
  ///
  /// In en, this message translates to:
  /// **'Change or review note'**
  String get uia76e5f7556db;

  /// Changed features only (GeoJSON)
  ///
  /// In en, this message translates to:
  /// **'Changed features only (GeoJSON)'**
  String get ui46b25978ee0b;

  /// Check Google Sheet
  ///
  /// In en, this message translates to:
  /// **'Check Google Sheet'**
  String get ui1728436a320d;

  /// Check for updates
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get ui736b9062b336;

  /// Check imported files
  ///
  /// In en, this message translates to:
  /// **'Check imported files'**
  String get uie08b2e193e7a;

  /// Check locations and update existing features.
  ///
  /// In en, this message translates to:
  /// **'Check locations and update existing features.'**
  String get ui66a60b5d2de0;

  /// Checking recorded GPS accuracy…
  ///
  /// In en, this message translates to:
  /// **'Checking recorded GPS accuracy…'**
  String get uia357678fa469;

  /// Checks the GitHub releases feed for a newer version.
  ///
  /// In en, this message translates to:
  /// **'Checks the GitHub releases feed for a newer version.'**
  String get ui398872e1510b;

  /// Choose .mbproj file
  ///
  /// In en, this message translates to:
  /// **'Choose .mbproj file'**
  String get uib8c6c4d83ff6;

  /// Choose a baseline feature to verify, update and document.
  ///
  /// In en, this message translates to:
  /// **'Choose a baseline feature to verify, update and document.'**
  String get ui410406660ffe;

  /// Choose a project, then narrow the records by layer or recorded day. Deleting history also removes those records from the sync queue.
  ///
  /// In en, this message translates to:
  /// **'Choose a project, then narrow the records by layer or recorded day. Deleting history also removes those records from the sync queue.'**
  String get ui94e9ca725723;

  /// Choose a resolution
  ///
  /// In en, this message translates to:
  /// **'Choose a resolution'**
  String get uiec39521dd3d0;

  /// Choose a site
  ///
  /// In en, this message translates to:
  /// **'Choose a site'**
  String get uie6e18a5753f1;

  /// Choose an option
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get ui45b9ce6e2d69;

  /// Choose files
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get ui5910acf0395e;

  /// Choose folder
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get ui1838a4158f39;

  /// Choose light, dark, or follow the system theme.
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or follow the system theme.'**
  String get ui3caef71ba23a;

  /// Choose where this map belongs. Importing lets you verify and update its features.
  ///
  /// In en, this message translates to:
  /// **'Choose where this map belongs. Importing lets you verify and update its features.'**
  String get ui05047674386b;

  /// Choose your preferred language. System default follows the device language.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language. System default follows the device language.'**
  String get ui470bd9b52bf6;

  /// Clean up history
  ///
  /// In en, this message translates to:
  /// **'Clean up history'**
  String get ui518b074e92aa;

  /// Clean up survey history
  ///
  /// In en, this message translates to:
  /// **'Clean up survey history'**
  String get ui0c8b3d42e61a;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get ui719ea396ad92;

  /// Clear all sites
  ///
  /// In en, this message translates to:
  /// **'Clear all sites'**
  String get ui105f261a16bf;

  /// Clear study layer
  ///
  /// In en, this message translates to:
  /// **'Clear study layer'**
  String get ui526b4d80fe1b;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get uibbfa773e5a63;

  /// Close feature
  ///
  /// In en, this message translates to:
  /// **'Close feature'**
  String get uiaf5d06a7b201;

  /// Cloud Sync
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get uid997d8d3a964;

  /// Code.gs
  ///
  /// In en, this message translates to:
  /// **'Code.gs'**
  String get ui0bd870fd34a8;

  /// Collect area
  ///
  /// In en, this message translates to:
  /// **'Collect area'**
  String get ui68188254a969;

  /// Collect line
  ///
  /// In en, this message translates to:
  /// **'Collect line'**
  String get ui42688f506949;

  /// Collect measurements at the same sites each round.
  ///
  /// In en, this message translates to:
  /// **'Collect measurements at the same sites each round.'**
  String get ui5e9981b89e91;

  /// Collect point
  ///
  /// In en, this message translates to:
  /// **'Collect point'**
  String get uiada29d015b1d;

  /// Collected
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get ui5b0f7590d06f;

  /// Collection round
  ///
  /// In en, this message translates to:
  /// **'Collection round'**
  String get ui6f83084a2ae4;

  /// Color by column
  ///
  /// In en, this message translates to:
  /// **'Color by column'**
  String get ui309ecfafed02;

  /// Colour
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get uif28563a477a9;

  /// Compare both versions
  ///
  /// In en, this message translates to:
  /// **'Compare both versions'**
  String get uid401aac0a65d;

  /// Compare map and saved visit
  ///
  /// In en, this message translates to:
  /// **'Compare map and saved visit'**
  String get ui17ccc7b6d715;

  /// Compass
  ///
  /// In en, this message translates to:
  /// **'Compass'**
  String get ui9d5c8e519d85;

  /// Compass needs calibration: move the phone in a figure-eight, away from metal.
  ///
  /// In en, this message translates to:
  /// **'Compass needs calibration: move the phone in a figure-eight, away from metal.'**
  String get ui5b96e7e9c657;

  /// Conditional: {v0}
  ///
  /// In en, this message translates to:
  /// **'Conditional: {v0}'**
  String uicac0b9c25835(String v0);

  /// Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ui04a212215ef9;

  /// Conflict resolution failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Conflict resolution failed: {v0}'**
  String ui8b1bf24a6905(String v0);

  /// Constraint (optional)
  ///
  /// In en, this message translates to:
  /// **'Constraint (optional)'**
  String get ui222f2eac34b3;

  /// Constraint message (optional)
  ///
  /// In en, this message translates to:
  /// **'Constraint message (optional)'**
  String get ui70404424ca5b;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get ui2e02623966f9;

  /// Coordinates copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied to clipboard'**
  String get ui9201f5c65f25;

  /// Coordinates out of range
  ///
  /// In en, this message translates to:
  /// **'Coordinates out of range'**
  String get ui1a19a2434337;

  /// Copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get ui0e7383487387;

  /// Copy coordinates
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get ui9959dcff1e40;

  /// Copy project ID
  ///
  /// In en, this message translates to:
  /// **'Copy project ID'**
  String get ui9b6827cfc0c2;

  /// Copy {v0}
  ///
  /// In en, this message translates to:
  /// **'Copy {v0}'**
  String uifa1b57908cec(String v0);

  /// Could not calculate a road route: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not calculate a road route: {v0}'**
  String ui975a22c89e46(String v0);

  /// Could not clear sites: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not clear sites: {v0}'**
  String ui22545c204602(String v0);

  /// Could not delete package: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not delete package: {v0}'**
  String uifc746e880c1f(String v0);

  /// Could not get accuracy: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not get accuracy: {v0}'**
  String ui0334890fbaf4(String v0);

  /// Could not get location: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not get location: {v0}'**
  String ui9a95131ae123(String v0);

  /// Could not load code. Reopen Help.
  ///
  /// In en, this message translates to:
  /// **'Could not load code. Reopen Help.'**
  String get uie4ee1b598563;

  /// Could not open Google Maps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get uic305018ed35e;

  /// Could not open Google Maps: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps: {v0}'**
  String uif515a67aeb4d(String v0);

  /// Could not open link
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get uiff2ce6da5800;

  /// Could not open map: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not open map: {v0}'**
  String ui50a313090b94(String v0);

  /// Could not open the file picker. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker. Please try again.'**
  String get ui17cb282d8d29;

  /// Could not read the QR code
  ///
  /// In en, this message translates to:
  /// **'Could not read the QR code'**
  String get uie5e1f203c3e2;

  /// Could not read the selected file
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file'**
  String get uibe443a8c429f;

  /// Could not read this draft
  ///
  /// In en, this message translates to:
  /// **'Could not read this draft'**
  String get uid77db0286a5e;

  /// Could not save acceptance: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not save acceptance: {v0}'**
  String uif3267458c32e(String v0);

  /// Could not save draft: {v0}. Answers remain here.
  ///
  /// In en, this message translates to:
  /// **'Could not save draft: {v0}. Answers remain here.'**
  String uia8114024834a(String v0);

  /// Could not save feature: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not save feature: {v0}'**
  String ui5d7ba60622b7(String v0);

  /// Could not save form: {v0}. Your form is still here.
  ///
  /// In en, this message translates to:
  /// **'Could not save form: {v0}. Your form is still here.'**
  String ui8607427fbc53(String v0);

  /// Could not save responses: {v0}. Your answers are still here.
  ///
  /// In en, this message translates to:
  /// **'Could not save responses: {v0}. Your answers are still here.'**
  String ui6e35c572c083(String v0);

  /// Could not save the feature: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not save the feature: {v0}'**
  String ui269629dbe7bf(String v0);

  /// Could not share log: {v0}
  ///
  /// In en, this message translates to:
  /// **'Could not share log: {v0}'**
  String ui31eee97bbcb3(String v0);

  /// Create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get ui6e157c5da441;

  /// Create a project from Home first.
  ///
  /// In en, this message translates to:
  /// **'Create a project from Home first.'**
  String get ui81199e796010;

  /// Create custom survey form
  ///
  /// In en, this message translates to:
  /// **'Create custom survey form'**
  String get ui4040d68479ef;

  /// Create layer from responses
  ///
  /// In en, this message translates to:
  /// **'Create layer from responses'**
  String get uib6fff06b1ea9;

  /// Create measurement layer
  ///
  /// In en, this message translates to:
  /// **'Create measurement layer'**
  String get uieb8f1b5942ac;

  /// Create or import a project to start.
  ///
  /// In en, this message translates to:
  /// **'Create or import a project to start.'**
  String get uid147959adb0d;

  /// Create or open a project
  ///
  /// In en, this message translates to:
  /// **'Create or open a project'**
  String get ui79ed912d242b;

  /// Create or select a project before building a form
  ///
  /// In en, this message translates to:
  /// **'Create or select a project before building a form'**
  String get uie41bffcbf8fd;

  /// Create project
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get uia8d8ff51e4c8;

  /// Create recurring layer
  ///
  /// In en, this message translates to:
  /// **'Create recurring layer'**
  String get uid7fd23efd3fb;

  /// Create your first round
  ///
  /// In en, this message translates to:
  /// **'Create your first round'**
  String get ui5fa4376dd93d;

  /// Current accuracy
  ///
  /// In en, this message translates to:
  /// **'Current accuracy'**
  String get ui1e95852771e8;

  /// Current map (revision {v0}):
  /// {v1}
  ///
  /// Saved visit proposal:
  /// {v2}
  ///
  /// Applying the saved visit replaces current attributes and geometry. Both versions remain in revision history.
  ///
  /// In en, this message translates to:
  /// **'Current map (revision {v0}):\n{v1}\n\nSaved visit proposal:\n{v2}\n\nApplying the saved visit replaces current attributes and geometry. Both versions remain in revision history.'**
  String ui5ba408a14004(String v0, String v1, String v2);

  /// Custom fields
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get uid1f86d5227e9;

  /// Custom layer colour
  ///
  /// In en, this message translates to:
  /// **'Custom layer colour'**
  String get ui2bc69d616e9c;

  /// Dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get uiae1ef0143294;

  /// Dark theme applied
  ///
  /// In en, this message translates to:
  /// **'Dark theme applied'**
  String get uidd144a4c66ee;

  /// Data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get uie5e429bcc9c2;

  /// Date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get uieb9a4bc1c0c1;

  /// Date & time
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get ui7eb29d356518;

  /// Decimal
  ///
  /// In en, this message translates to:
  /// **'Decimal'**
  String get uie4c3a2d0cc24;

  /// Default value (optional)
  ///
  /// In en, this message translates to:
  /// **'Default value (optional)'**
  String get uic9a6edbbca9b;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get uif6fdbe48dc54;

  /// Delete "{v0}" and its CSV file?
  ///
  /// In en, this message translates to:
  /// **'Delete \"{v0}\" and its CSV file?'**
  String ui322a3ca0f18f(String v0);

  /// Delete "{v0}"?
  ///
  /// In en, this message translates to:
  /// **'Delete \"{v0}\"?'**
  String uia761ad78efaa(String v0);

  /// Delete "{v0}"? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{v0}\"? This cannot be undone.'**
  String ui97f85ee5e056(String v0);

  /// Delete all locally stored survey data.
  ///
  /// In en, this message translates to:
  /// **'Delete all locally stored survey data.'**
  String get ui163dbcf2cb0b;

  /// Delete draft
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get uib6ea094ee1dd;

  /// Delete form
  ///
  /// In en, this message translates to:
  /// **'Delete form'**
  String get uie51f1f6721d0;

  /// Delete package
  ///
  /// In en, this message translates to:
  /// **'Delete package'**
  String get uicee51ffefd08;

  /// Delete photo
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get uifc700472e1c8;

  /// Delete project
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get uiaf1456f256eb;

  /// Delete response
  ///
  /// In en, this message translates to:
  /// **'Delete response'**
  String get uib81097a6dff1;

  /// Delete selected
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get ui8516a714a234;

  /// Delete selected history?
  ///
  /// In en, this message translates to:
  /// **'Delete selected history?'**
  String get uia154a9f139a0;

  /// Delete site
  ///
  /// In en, this message translates to:
  /// **'Delete site'**
  String get uidead9e2fceca;

  /// Delete this draft? The unfinished data will be lost.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft? The unfinished data will be lost.'**
  String get uibbb829eb5d99;

  /// Delete unassigned sites?
  ///
  /// In en, this message translates to:
  /// **'Delete unassigned sites?'**
  String get ui0ddb0f574d68;

  /// Delete {v0} records
  ///
  /// In en, this message translates to:
  /// **'Delete {v0} records'**
  String ui2823144885b8(String v0);

  /// Delete {v0}?
  ///
  /// In en, this message translates to:
  /// **'Delete {v0}?'**
  String uic140eb8d4089(String v0);

  /// Deleted {v0} history records{v1}.
  ///
  /// In en, this message translates to:
  /// **'Deleted {v0} history records{v1}.'**
  String ui417f5c09f20f(String v0, String v1);

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ui55f8ebc805e6;

  /// Deselect all
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get ui85cce1e14782;

  /// Discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get ui36fff63ccbcd;

  /// Distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get ui423208095dd7;

  /// Done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get uie9b450d14bc2;

  /// Download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get uia479c9c34e87;

  /// Download & Install
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get uiff0c13412b0c;

  /// Download Map
  ///
  /// In en, this message translates to:
  /// **'Download Map'**
  String get ui0ff9a69a76f5;

  /// Download a bounded field area before leaving internet coverage. Completed packages appear in the Basemap selector on every collection map.
  ///
  /// In en, this message translates to:
  /// **'Download a bounded field area before leaving internet coverage. Completed packages appear in the Basemap selector on every collection map.'**
  String get ui0800a145edde;

  /// Download failed. {v0}
  ///
  /// In en, this message translates to:
  /// **'Download failed. {v0}'**
  String uib5da8ffe86ea(String v0);

  /// Download field area
  ///
  /// In en, this message translates to:
  /// **'Download field area'**
  String get uia2853733787f;

  /// Downloading... {v0}%
  ///
  /// In en, this message translates to:
  /// **'Downloading... {v0}%'**
  String uib5491539e2b3(String v0);

  /// Draft cannot be saved: repeated records are not supported. Import a form with one submission per feature.
  ///
  /// In en, this message translates to:
  /// **'Draft cannot be saved: repeated records are not supported. Import a form with one submission per feature.'**
  String get uic584016080ca;

  /// Draft restored — continue, finish, or save it again
  ///
  /// In en, this message translates to:
  /// **'Draft restored — continue, finish, or save it again'**
  String get ui263f1461e992;

  /// Draft saved
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get uia706abd0fea1;

  /// Draft saved — resume it from History later
  ///
  /// In en, this message translates to:
  /// **'Draft saved — resume it from History later'**
  String get uibdb71d0f6f36;

  /// Draft updated
  ///
  /// In en, this message translates to:
  /// **'Draft updated'**
  String get uife6f67656743;

  /// Draft visit {v0}. Leaving this screen saves the feature edits.
  ///
  /// In en, this message translates to:
  /// **'Draft visit {v0}. Leaving this screen saves the feature edits.'**
  String ui319e1cedce84(String v0);

  /// Drag the point on the map to move it.
  ///
  /// In en, this message translates to:
  /// **'Drag the point on the map to move it.'**
  String get ui24673e67421a;

  /// Draw Line
  ///
  /// In en, this message translates to:
  /// **'Draw Line'**
  String get uibb2708352747;

  /// Draw Polygon
  ///
  /// In en, this message translates to:
  /// **'Draw Polygon'**
  String get ui779c76ee322b;

  /// Draw on map
  ///
  /// In en, this message translates to:
  /// **'Draw on map'**
  String get ui0f873fbc3146;

  /// Dropdown
  ///
  /// In en, this message translates to:
  /// **'Dropdown'**
  String get uifc2d12b944ac;

  /// Each completed visit is a separate observation. Earlier measurements stay in the timeline. Comparisons use the same questionnaire and question name; keep measurement units consistent across versions.
  ///
  /// In en, this message translates to:
  /// **'Each completed visit is a separate observation. Earlier measurements stay in the timeline. Comparisons use the same questionnaire and question name; keep measurement units consistent across versions.'**
  String get ui35ec8f11252e;

  /// Easy Geospatial Data Collection
  ///
  /// In en, this message translates to:
  /// **'Easy Geospatial Data Collection'**
  String get ui4c0f7e66bf0e;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get ui5301648dcf6b;

  /// Edit Option
  ///
  /// In en, this message translates to:
  /// **'Edit Option'**
  String get ui8ad0e04ead5b;

  /// Edit answers
  ///
  /// In en, this message translates to:
  /// **'Edit answers'**
  String get ui7ff2c7ac7f1d;

  /// Edit feature
  ///
  /// In en, this message translates to:
  /// **'Edit feature'**
  String get uid630d038b3ad;

  /// Edit form
  ///
  /// In en, this message translates to:
  /// **'Edit form'**
  String get uif1d8720160a4;

  /// Edit on map
  ///
  /// In en, this message translates to:
  /// **'Edit on map'**
  String get ui28134edb87d4;

  /// Edit or remove this site in Study Area mode
  ///
  /// In en, this message translates to:
  /// **'Edit or remove this site in Study Area mode'**
  String get ui6091ce867967;

  /// Edit project name
  ///
  /// In en, this message translates to:
  /// **'Edit project name'**
  String get ui7f9c8e468af6;

  /// Edit site {v0}
  ///
  /// In en, this message translates to:
  /// **'Edit site {v0}'**
  String uiedf5a9152284(String v0);

  /// Edit — {v0}
  ///
  /// In en, this message translates to:
  /// **'Edit — {v0}'**
  String ui12faa0f2ccff(String v0);

  /// Email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ui84add5b29527;

  /// English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get ui649df08a448e;

  /// Enter a MapBanai QR code or link
  ///
  /// In en, this message translates to:
  /// **'Enter a MapBanai QR code or link'**
  String get ui75320322f7f3;

  /// Enter decimal number
  ///
  /// In en, this message translates to:
  /// **'Enter decimal number'**
  String get ui7f84073ce3b4;

  /// Enter long text
  ///
  /// In en, this message translates to:
  /// **'Enter long text'**
  String get ui02b5062f9c93;

  /// Enter number
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get uib616e9721b5f;

  /// Enter text
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get ui9c05f58f3dcc;

  /// Enter your name so submissions identify you.
  ///
  /// In en, this message translates to:
  /// **'Enter your name so submissions identify you.'**
  String get ui0bd3df97dc75;

  /// Excel (XLSX)
  ///
  /// In en, this message translates to:
  /// **'Excel (XLSX)'**
  String get ui0e2d6a433d92;

  /// Excel-compatible CSV
  ///
  /// In en, this message translates to:
  /// **'Excel-compatible CSV'**
  String get ui00db23ce33b1;

  /// Export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get uif3e4fadb9e37;

  /// Export "{v0}" (v{v1})
  ///
  /// In en, this message translates to:
  /// **'Export \"{v0}\" (v{v1})'**
  String ui919004e0521f(String v0, String v1);

  /// Export / Share project
  ///
  /// In en, this message translates to:
  /// **'Export / Share project'**
  String get ui59e9d9bc60d6;

  /// Export / share CSV
  ///
  /// In en, this message translates to:
  /// **'Export / share CSV'**
  String get ui882b3940804a;

  /// Export Data
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get uif601e90879bd;

  /// Export GIS data as
  ///
  /// In en, this message translates to:
  /// **'Export GIS data as'**
  String get ui98228e8633b0;

  /// Export all observations as CSV
  ///
  /// In en, this message translates to:
  /// **'Export all observations as CSV'**
  String get uid2ee1c2ac834;

  /// Export cancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get ui8016ab2ed7ba;

  /// Export failed. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get ui6b65ee8c6ffb;

  /// Export failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Export failed: {v0}'**
  String ui0026e4743f02(String v0);

  /// Export ready: {v0}
  ///
  /// In en, this message translates to:
  /// **'Export ready: {v0}'**
  String ui0fc874762a39(String v0);

  /// Export sites
  ///
  /// In en, this message translates to:
  /// **'Export sites'**
  String get uia463fe0ed8cd;

  /// Facilities
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get ui9d0a833e883c;

  /// Failed to generate webmap: {v0}
  ///
  /// In en, this message translates to:
  /// **'Failed to generate webmap: {v0}'**
  String ui01387ee23eea(String v0);

  /// Failed to load: {v0}
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {v0}'**
  String uicd17064d090a(String v0);

  /// Failed to reset data
  ///
  /// In en, this message translates to:
  /// **'Failed to reset data'**
  String get uief523b46ad00;

  /// Failed to save line: {v0}
  ///
  /// In en, this message translates to:
  /// **'Failed to save line: {v0}'**
  String uie7926fb16618(String v0);

  /// Failed to save point: {v0}
  ///
  /// In en, this message translates to:
  /// **'Failed to save point: {v0}'**
  String ui3a80d1d372c5(String v0);

  /// Failed to save polygon: {v0}
  ///
  /// In en, this message translates to:
  /// **'Failed to save polygon: {v0}'**
  String uif7f1a2f5375b(String v0);

  /// Feature Info
  ///
  /// In en, this message translates to:
  /// **'Feature Info'**
  String get uidf0ddc77356e;

  /// Feature deleted
  ///
  /// In en, this message translates to:
  /// **'Feature deleted'**
  String get ui4bd0951a03e8;

  /// Feature saved
  ///
  /// In en, this message translates to:
  /// **'Feature saved'**
  String get ui255785f96e54;

  /// Feature updated — ready to sync
  ///
  /// In en, this message translates to:
  /// **'Feature updated — ready to sync'**
  String get ui8723967a8e50;

  /// Fetch the latest XLSForm from your project’s Google Sheet using its Apps Script connection.
  ///
  /// In en, this message translates to:
  /// **'Fetch the latest XLSForm from your project’s Google Sheet using its Apps Script connection.'**
  String get ui897fa3cadce1;

  /// Field Verification
  ///
  /// In en, this message translates to:
  /// **'Field Verification'**
  String get ui4c0d84107ddc;

  /// Field name
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get uif08ab394a08f;

  /// Field name (no spaces)
  ///
  /// In en, this message translates to:
  /// **'Field name (no spaces)'**
  String get uie59928316474;

  /// Field names stay fixed so existing answers and form rules remain linked.
  ///
  /// In en, this message translates to:
  /// **'Field names stay fixed so existing answers and form rules remain linked.'**
  String get uifd507b95760d;

  /// Field quality checks
  ///
  /// In en, this message translates to:
  /// **'Field quality checks'**
  String get ui9a5b8203dea6;

  /// Field quality{v0}
  ///
  /// In en, this message translates to:
  /// **'Field quality{v0}'**
  String ui04da12f4ecb1(String v0);

  /// Fieldworker name
  ///
  /// In en, this message translates to:
  /// **'Fieldworker name'**
  String get ui3f996677147b;

  /// Fieldworker: {v0}
  ///
  /// In en, this message translates to:
  /// **'Fieldworker: {v0}'**
  String ui5e39bef6ecec(String v0);

  /// Fill questionnaire
  ///
  /// In en, this message translates to:
  /// **'Fill questionnaire'**
  String get uib2a03b9b7a06;

  /// Fill questionnaire (optional)
  ///
  /// In en, this message translates to:
  /// **'Fill questionnaire (optional)'**
  String get ui28620a15f945;

  /// Filter status
  ///
  /// In en, this message translates to:
  /// **'Filter status'**
  String get ui61b933ebc0cf;

  /// Final confirmation
  ///
  /// In en, this message translates to:
  /// **'Final confirmation'**
  String get uic3c626512bc9;

  /// Finish
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get uib74bdee9c34f;

  /// Finish visit and update map
  ///
  /// In en, this message translates to:
  /// **'Finish visit and update map'**
  String get ui26b73a211708;

  /// First: {v0} • Latest: {v1} • Change: {v2}
  ///
  /// In en, this message translates to:
  /// **'First: {v0} • Latest: {v1} • Change: {v2}'**
  String uia72abb53ded4(String v0, String v1, String v2);

  /// Fit all sites
  ///
  /// In en, this message translates to:
  /// **'Fit all sites'**
  String get ui6671587fff89;

  /// Follow me
  ///
  /// In en, this message translates to:
  /// **'Follow me'**
  String get uib64b0d0a894d;

  /// For a new project, paste into Code.gs and replace only projectId. Leave the other four placeholders unchanged; setupMapBanai creates your API key, photo folder and data tabs.
  ///
  /// In en, this message translates to:
  /// **'For a new project, paste into Code.gs and replace only projectId. Leave the other four placeholders unchanged; setupMapBanai creates your API key, photo folder and data tabs.'**
  String get ui736e35f71fc4;

  /// Form "{v0}" saved
  ///
  /// In en, this message translates to:
  /// **'Form \"{v0}\" saved'**
  String ui8e0113e9ab9a(String v0);

  /// Form "{v0}" saved in {v1}
  ///
  /// In en, this message translates to:
  /// **'Form \"{v0}\" saved in {v1}'**
  String ui6b40badab021(String v0, String v1);

  /// Form "{v0}" updated
  ///
  /// In en, this message translates to:
  /// **'Form \"{v0}\" updated'**
  String ui6c07b56f89a1(String v0);

  /// Form Details
  ///
  /// In en, this message translates to:
  /// **'Form Details'**
  String get uic3de47ae9bd2;

  /// Form deleted
  ///
  /// In en, this message translates to:
  /// **'Form deleted'**
  String get uib6ab025c2d78;

  /// Form details
  ///
  /// In en, this message translates to:
  /// **'Form details'**
  String get ui16dd86a84b5d;

  /// Form language
  ///
  /// In en, this message translates to:
  /// **'Form language'**
  String get ui9fd01570e232;

  /// Form name
  ///
  /// In en, this message translates to:
  /// **'Form name'**
  String get uib93262f4bc3e;

  /// Free device storage: {v0} · Map cache: {v1}
  ///
  /// In en, this message translates to:
  /// **'Free device storage: {v0} · Map cache: {v1}'**
  String ui16d3ca31f7bc(String v0, String v1);

  /// Full geometry, attributes and revision baseline
  ///
  /// In en, this message translates to:
  /// **'Full geometry, attributes and revision baseline'**
  String get ui0eace7f71b6c;

  /// Full line/polygon geometry is retained. Coordinates show its reference vertex.
  ///
  /// In en, this message translates to:
  /// **'Full line/polygon geometry is retained. Coordinates show its reference vertex.'**
  String get uiaa77c8a72989;

  /// GIS Features
  ///
  /// In en, this message translates to:
  /// **'GIS Features'**
  String get uid78c401e571e;

  /// GIS Mode
  ///
  /// In en, this message translates to:
  /// **'GIS Mode'**
  String get uidca76b4d8ff0;

  /// GIS Mode - {v0}
  ///
  /// In en, this message translates to:
  /// **'GIS Mode - {v0}'**
  String ui43688d96e197(String v0);

  /// GIS data
  ///
  /// In en, this message translates to:
  /// **'GIS data'**
  String get uib6cadf4fa6c5;

  /// GIS feature
  ///
  /// In en, this message translates to:
  /// **'GIS feature'**
  String get ui350358829580;

  /// GIS features
  ///
  /// In en, this message translates to:
  /// **'GIS features'**
  String get uieeddcc3bc1da;

  /// GPS CSV Viewer
  ///
  /// In en, this message translates to:
  /// **'GPS CSV Viewer'**
  String get ui2159e983c6a6;

  /// GPS Logs ({v0})
  ///
  /// In en, this message translates to:
  /// **'GPS Logs ({v0})'**
  String ui816774591672(String v0);

  /// GPS Mode
  ///
  /// In en, this message translates to:
  /// **'GPS Mode'**
  String get uied430db463ff;

  /// GPS Point
  ///
  /// In en, this message translates to:
  /// **'GPS Point'**
  String get uiefc3f88b78d7;

  /// GPS accuracy
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy'**
  String get uida3c038f839c;

  /// GPS accuracy review limit
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy review limit'**
  String get ui881050d044a5;

  /// GPS accuracy threshold set to {v0} m
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy threshold set to {v0} m'**
  String ui5af8da29a579(String v0);

  /// GPS accuracy: unavailable
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy: unavailable'**
  String get ui68d8c2dfacb1;

  /// GPS accuracy: {v0} m
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy: {v0} m'**
  String ui17dd2295e5dc(String v0);

  /// GPS accuracy: ±{v0} m
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy: ±{v0} m'**
  String ui17ff8208bb50(String v0);

  /// GPS accuracy: ±{v0} m · Limit: {v1} m
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy: ±{v0} m · Limit: {v1} m'**
  String uib412d9b03d31(String v0, String v1);

  /// GPS direction of travel; this does not show where a stationary phone faces.
  ///
  /// In en, this message translates to:
  /// **'GPS direction of travel; this does not show where a stationary phone faces.'**
  String get uie8b468b0e65c;

  /// GPS settings
  ///
  /// In en, this message translates to:
  /// **'GPS settings'**
  String get ui1139289ac231;

  /// GPS unavailable: {v0}
  ///
  /// In en, this message translates to:
  /// **'GPS unavailable: {v0}'**
  String ui70ae5325e6b1(String v0);

  /// GPS vertex
  ///
  /// In en, this message translates to:
  /// **'GPS vertex'**
  String get ui436b10d50cf3;

  /// GPS: Searching...
  ///
  /// In en, this message translates to:
  /// **'GPS: Searching...'**
  String get uid79fea5a85f4;

  /// GPS: {v0}, {v1}
  ///
  /// In en, this message translates to:
  /// **'GPS: {v0}, {v1}'**
  String uiefa204b85e3c(String v0, String v1);

  /// Gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get ui9c30a3485a58;

  /// Generating webmap for {v0} features — this may take a moment...
  ///
  /// In en, this message translates to:
  /// **'Generating webmap for {v0} features — this may take a moment...'**
  String ui8f5281dddc73(String v0);

  /// Geometry only
  ///
  /// In en, this message translates to:
  /// **'Geometry only'**
  String get ui7bd3c4506e38;

  /// Geotagged
  ///
  /// In en, this message translates to:
  /// **'Geotagged'**
  String get uief385e8b9394;

  /// Geotagged photo attached
  ///
  /// In en, this message translates to:
  /// **'Geotagged photo attached'**
  String get ui127e22e72c01;

  /// GitHub repository
  ///
  /// In en, this message translates to:
  /// **'GitHub repository'**
  String get uic6651994b242;

  /// Guided visit{v0}
  ///
  /// In en, this message translates to:
  /// **'Guided visit{v0}'**
  String uie8adeb7a2680(String v0);

  /// Height change from your reference: {v0}
  ///
  /// In en, this message translates to:
  /// **'Height change from your reference: {v0}'**
  String ui1bfc2126eb38(String v0);

  /// Help & manager setup
  ///
  /// In en, this message translates to:
  /// **'Help & manager setup'**
  String get uib7b664830ea7;

  /// Hex colour
  ///
  /// In en, this message translates to:
  /// **'Hex colour'**
  String get uidaafa6d492ee;

  /// Hidden
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get uid4c2792a7245;

  /// Hide all
  ///
  /// In en, this message translates to:
  /// **'Hide all'**
  String get ui088c4ac92ba8;

  /// Hide from project setup; data is kept
  ///
  /// In en, this message translates to:
  /// **'Hide from project setup; data is kept'**
  String get uia0419d944de6;

  /// Hint text (optional)
  ///
  /// In en, this message translates to:
  /// **'Hint text (optional)'**
  String get ui2daccedccf3f;

  /// History
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get ui90ccd6497400;

  /// History: {v0}
  ///
  /// In en, this message translates to:
  /// **'History: {v0}'**
  String ui4b923abc4390(String v0);

  /// Horizontal
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get ui4f57a1ce99e6;

  /// I have permission to download this source for offline use.
  ///
  /// In en, this message translates to:
  /// **'I have permission to download this source for offline use.'**
  String get uid3cddd6b7a18;

  /// ID
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get ui89f89c02cf47;

  /// ID  {v0}
  ///
  /// In en, this message translates to:
  /// **'ID  {v0}'**
  String ui37983e6e11cc(String v0);

  /// ID: {v0}
  /// {v1}{v2}
  ///
  /// In en, this message translates to:
  /// **'ID: {v0}\n{v1}{v2}'**
  String ui4f710ef77383(String v0, String v1, String v2);

  /// Image
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get ui50e19fda0d5b;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get uid6fbc9d2bdd5;

  /// Import Project
  ///
  /// In en, this message translates to:
  /// **'Import Project'**
  String get ui62d55664db41;

  /// Import XLSForm
  ///
  /// In en, this message translates to:
  /// **'Import XLSForm'**
  String get ui05b32fd31a55;

  /// Import a form
  ///
  /// In en, this message translates to:
  /// **'Import a form'**
  String get ui8e37624a8c4f;

  /// Import as new copy
  ///
  /// In en, this message translates to:
  /// **'Import as new copy'**
  String get ui9c5252af721c;

  /// Import failed
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get uifbae892997d9;

  /// Import failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Import failed: {v0}'**
  String ui5f2e5f60d176(String v0);

  /// Import form
  ///
  /// In en, this message translates to:
  /// **'Import form'**
  String get ui31fb23cfff40;

  /// Import from XLSForm (.xlsx)
  ///
  /// In en, this message translates to:
  /// **'Import from XLSForm (.xlsx)'**
  String get uib5d0a38444e6;

  /// Import or select a project first
  ///
  /// In en, this message translates to:
  /// **'Import or select a project first'**
  String get ui831d2e664b77;

  /// Import project
  ///
  /// In en, this message translates to:
  /// **'Import project'**
  String get ui447a25af708e;

  /// Import sites
  ///
  /// In en, this message translates to:
  /// **'Import sites'**
  String get ui3901be0cffb1;

  /// Import study-area features first to begin a guided baseline visit.
  ///
  /// In en, this message translates to:
  /// **'Import study-area features first to begin a guided baseline visit.'**
  String get uia0256e6f7c6a;

  /// Imported "{v0}" with {v1} questions
  ///
  /// In en, this message translates to:
  /// **'Imported \"{v0}\" with {v1} questions'**
  String ui18e5cf926e50(String v0, String v1);

  /// Imported {v0} new features, updated {v1}, kept {v2} local versions.
  ///
  /// In en, this message translates to:
  /// **'Imported {v0} new features, updated {v1}, kept {v2} local versions.'**
  String uicd9469193dca(String v0, String v1, String v2);

  /// In Apps Script, add an HTML file named {v0}, then paste this code.
  ///
  /// In en, this message translates to:
  /// **'In Apps Script, add an HTML file named {v0}, then paste this code.'**
  String uic1cb782ca0df(String v0);

  /// Include collected responses and photos
  ///
  /// In en, this message translates to:
  /// **'Include collected responses and photos'**
  String get ui9e7815322ba3;

  /// Include sync connection
  ///
  /// In en, this message translates to:
  /// **'Include sync connection'**
  String get uidf228157de13;

  /// Include the Apps Script URL and API key for trusted enumerators. Recipients can read the key.
  ///
  /// In en, this message translates to:
  /// **'Include the Apps Script URL and API key for trusted enumerators. Recipients can read the key.'**
  String get uic075b040daff;

  /// Include unfinished drafts
  ///
  /// In en, this message translates to:
  /// **'Include unfinished drafts'**
  String get uieb897be763fc;

  /// Includes other history records linked to those points. Imported source files and project settings are kept.
  ///
  /// In en, this message translates to:
  /// **'Includes other history records linked to those points. Imported source files and project settings are kept.'**
  String get ui2147c24042cf;

  /// Includes survey history, drafts and current Study Area points.
  ///
  /// In en, this message translates to:
  /// **'Includes survey history, drafts and current Study Area points.'**
  String get ui95949d0c4089;

  /// Incoming file
  ///
  /// In en, this message translates to:
  /// **'Incoming file'**
  String get ui80cf9d54825e;

  /// Incoming: {v0}, {v1}
  ///
  /// In en, this message translates to:
  /// **'Incoming: {v0}, {v1}'**
  String ui233771f44a3f(String v0, String v1);

  /// Indoor readings, including negative values, may be unreliable. Test outdoors before setting a ground reference.
  ///
  /// In en, this message translates to:
  /// **'Indoor readings, including negative values, may be unreliable. Test outdoors before setting a ground reference.'**
  String get ui370b7d97d11f;

  /// Integer
  ///
  /// In en, this message translates to:
  /// **'Integer'**
  String get ui9edcffff4461;

  /// Invalid coordinates
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates'**
  String get uia2f0dfadaaeb;

  /// Keep both as separate features
  ///
  /// In en, this message translates to:
  /// **'Keep both as separate features'**
  String get uicdc2fc2b9596;

  /// Keep current map
  ///
  /// In en, this message translates to:
  /// **'Keep current map'**
  String get uib1617f6d12ea;

  /// Keep local version
  ///
  /// In en, this message translates to:
  /// **'Keep local version'**
  String get ui7b0d52c5669d;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get ui74341e3c271d;

  /// Label and name are required
  ///
  /// In en, this message translates to:
  /// **'Label and name are required'**
  String get uid95033fb8177;

  /// Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get ui89b86ab0e66f;

  /// Last synced: {v0}
  ///
  /// In en, this message translates to:
  /// **'Last synced: {v0}'**
  String uid44a265f1b26(String v0);

  /// Latitude
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get uiced3905ec822;

  /// Layer
  ///
  /// In en, this message translates to:
  /// **'Layer'**
  String get ui4343635cf237;

  /// Layer  {v0}
  ///
  /// In en, this message translates to:
  /// **'Layer  {v0}'**
  String ui78f4d55f17c1(String v0);

  /// Layer name
  ///
  /// In en, this message translates to:
  /// **'Layer name'**
  String get ui66f2d76aa42a;

  /// Layer points cleared; history kept
  ///
  /// In en, this message translates to:
  /// **'Layer points cleared; history kept'**
  String get ui7d86eb32993a;

  /// Layer points, history and sync queue cleared
  ///
  /// In en, this message translates to:
  /// **'Layer points, history and sync queue cleared'**
  String get ui3a809dffc14e;

  /// Layer removed.
  ///
  /// In en, this message translates to:
  /// **'Layer removed.'**
  String get ui28d177aa2889;

  /// Layer type
  ///
  /// In en, this message translates to:
  /// **'Layer type'**
  String get ui8a398db6aeb3;

  /// Layers
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get uif055f18aeadc;

  /// Layers and questionnaires added
  ///
  /// In en, this message translates to:
  /// **'Layers and questionnaires added'**
  String get ui92b53dd55ccd;

  /// Leave empty to clear.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to clear.'**
  String get ui50fe884f3bed;

  /// Light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get uia36ef8aba229;

  /// Light theme applied
  ///
  /// In en, this message translates to:
  /// **'Light theme applied'**
  String get ui566016d4e5ce;

  /// Line
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get uiea9676003762;

  /// Line saved
  ///
  /// In en, this message translates to:
  /// **'Line saved'**
  String get ui762185bb9c08;

  /// Live GPS readings and coordinate logging
  ///
  /// In en, this message translates to:
  /// **'Live GPS readings and coordinate logging'**
  String get ui0c803e02a46e;

  /// Local revision {v0}; incoming revision {v1}
  ///
  /// In en, this message translates to:
  /// **'Local revision {v0}; incoming revision {v1}'**
  String ui2f494babf600(String v0, String v1);

  /// Locate
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get ui55a6907830e4;

  /// Location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get uid219c68101f5;

  /// Location  {v0}
  ///
  /// In en, this message translates to:
  /// **'Location  {v0}'**
  String uid745ebd37fd5(String v0);

  /// Location Removed
  ///
  /// In en, this message translates to:
  /// **'Location Removed'**
  String get uie6eb0764038f;

  /// Location changed
  ///
  /// In en, this message translates to:
  /// **'Location changed'**
  String get ui2276b254455d;

  /// Location error: {v0}
  ///
  /// In en, this message translates to:
  /// **'Location error: {v0}'**
  String ui6965945ee3f4(String v0);

  /// Location permission not granted
  ///
  /// In en, this message translates to:
  /// **'Location permission not granted'**
  String get uid98b3dea33e0;

  /// Location permission required
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get uic9b51a096e5c;

  /// Location removed
  ///
  /// In en, this message translates to:
  /// **'Location removed'**
  String get uib47a40701451;

  /// Logging continues with the screen off. Leave GPS Mode any time; come back here to stop.
  ///
  /// In en, this message translates to:
  /// **'Logging continues with the screen off. Leave GPS Mode any time; come back here to stop.'**
  String get ui3a171968d250;

  /// Long text
  ///
  /// In en, this message translates to:
  /// **'Long text'**
  String get ui862b905c967b;

  /// Longitude
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get ui6f9f011c5d36;

  /// Main study area
  ///
  /// In en, this message translates to:
  /// **'Main study area'**
  String get ui624beb5cfdac;

  /// Manage project files and layers
  ///
  /// In en, this message translates to:
  /// **'Manage project files and layers'**
  String get uie3dda04d8ad4;

  /// Manage project files and road layers
  ///
  /// In en, this message translates to:
  /// **'Manage project files and road layers'**
  String get uie5dae44b774f;

  /// Map Layers
  ///
  /// In en, this message translates to:
  /// **'Map Layers'**
  String get uie29679599257;

  /// Map export failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Map export failed: {v0}'**
  String ui06cd4e58b2d2(String v0);

  /// Map image saved
  ///
  /// In en, this message translates to:
  /// **'Map image saved'**
  String get ui55592984d7c8;

  /// Map preview could not update. Geometry is retained: {v0}
  ///
  /// In en, this message translates to:
  /// **'Map preview could not update. Geometry is retained: {v0}'**
  String ui61e2ca3a278c(String v0);

  /// Map preview failed: {v0}. Stored features are retained.
  ///
  /// In en, this message translates to:
  /// **'Map preview failed: {v0}. Stored features are retained.'**
  String ui997f080ca254(String v0);

  /// Map still needs review: {v0}
  ///
  /// In en, this message translates to:
  /// **'Map still needs review: {v0}'**
  String ui2997787343d9(String v0);

  /// Map tiles need internet. Saved geometry stays on this device.
  ///
  /// In en, this message translates to:
  /// **'Map tiles need internet. Saved geometry stays on this device.'**
  String get uif001c704b2c4;

  /// Map update still needs review: {v0}
  ///
  /// In en, this message translates to:
  /// **'Map update still needs review: {v0}'**
  String uia81b9bf05314(String v0);

  /// Map-based spatial editing and layers
  ///
  /// In en, this message translates to:
  /// **'Map-based spatial editing and layers'**
  String get ui6e34e5bb76d4;

  /// MapBanai
  ///
  /// In en, this message translates to:
  /// **'MapBanai'**
  String get uib5b7b220e6fc;

  /// MapBanai gratefully acknowledges the contributions of the CARE project and BRAC James P Grant School of Public Health, BRAC University, to its development.
  ///
  /// In en, this message translates to:
  /// **'MapBanai gratefully acknowledges the contributions of the CARE project and BRAC James P Grant School of Public Health, BRAC University, to its development.'**
  String get uibfd3beb1d90d;

  /// Mark done
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get ui0911cce79bf0;

  /// Mark not collected
  ///
  /// In en, this message translates to:
  /// **'Mark not collected'**
  String get ui67c691a7034c;

  /// Mark undone
  ///
  /// In en, this message translates to:
  /// **'Mark undone'**
  String get uibd37e4010390;

  /// Matching DBF not found in that folder. Select SHP and companions together or import their ZIP.
  ///
  /// In en, this message translates to:
  /// **'Matching DBF not found in that folder. Select SHP and companions together or import their ZIP.'**
  String get ui6d9883bf2564;

  /// Max acceptable accuracy
  ///
  /// In en, this message translates to:
  /// **'Max acceptable accuracy'**
  String get uidf64ffd50ab4;

  /// Maximum download size
  ///
  /// In en, this message translates to:
  /// **'Maximum download size'**
  String get uic4af0cbf2c57;

  /// Measure
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get uid4fd0a232ee5;

  /// Measure Area
  ///
  /// In en, this message translates to:
  /// **'Measure Area'**
  String get uiff3c5f95f7ed;

  /// Measure Distance
  ///
  /// In en, this message translates to:
  /// **'Measure Distance'**
  String get ui44d5eb4c451a;

  /// Measure area — tap points on the map
  ///
  /// In en, this message translates to:
  /// **'Measure area — tap points on the map'**
  String get uiacca68cf2978;

  /// Measure distance — tap points on the map
  ///
  /// In en, this message translates to:
  /// **'Measure distance — tap points on the map'**
  String get uif9387f539eef;

  /// Measurement
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get uide10edfac7e7;

  /// Measurement (e.g. salinity)
  ///
  /// In en, this message translates to:
  /// **'Measurement (e.g. salinity)'**
  String get ui31d24b69ea44;

  /// Measurement units
  ///
  /// In en, this message translates to:
  /// **'Measurement units'**
  String get ui7f4511910c62;

  /// Menu
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get ui57f5f5efbc59;

  /// More site details
  ///
  /// In en, this message translates to:
  /// **'More site details'**
  String get uif729a52d65af;

  /// Move is available for points. Use Redraw geometry for lines and areas.
  ///
  /// In en, this message translates to:
  /// **'Move is available for points. Use Redraw geometry for lines and areas.'**
  String get uib5b2f93a6b40;

  /// Move with GPS to get a heading fix
  ///
  /// In en, this message translates to:
  /// **'Move with GPS to get a heading fix'**
  String get uica80cd791254;

  /// Multipart geometry
  ///
  /// In en, this message translates to:
  /// **'Multipart geometry'**
  String get uif0948991d684;

  /// My enumerator name
  ///
  /// In en, this message translates to:
  /// **'My enumerator name'**
  String get ui51a144b4a026;

  /// My forms
  ///
  /// In en, this message translates to:
  /// **'My forms'**
  String get ui53f1631a0c9a;

  /// My name
  ///
  /// In en, this message translates to:
  /// **'My name'**
  String get uia8f40df7087b;

  /// My responses
  ///
  /// In en, this message translates to:
  /// **'My responses'**
  String get ui3e2d598760ca;

  /// Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ui709a23220f2c;

  /// Name  {v0}
  ///
  /// In en, this message translates to:
  /// **'Name  {v0}'**
  String ui1dc947fc26a5(String v0);

  /// Name (optional)
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get ui9c9f03a83941;

  /// Name used in change history
  ///
  /// In en, this message translates to:
  /// **'Name used in change history'**
  String get uie997727f66e0;

  /// Native Excel workbook
  ///
  /// In en, this message translates to:
  /// **'Native Excel workbook'**
  String get ui3158214aeaa5;

  /// Needs review
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get ui33a506cf6ec5;

  /// Never synced
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get ui8d5addc5f483;

  /// New and updated features require a questionnaire. Select a survey form first.
  ///
  /// In en, this message translates to:
  /// **'New and updated features require a questionnaire. Select a survey form first.'**
  String get ui19770feca231;

  /// New collection round
  ///
  /// In en, this message translates to:
  /// **'New collection round'**
  String get ui5dcfe56ae106;

  /// New key
  ///
  /// In en, this message translates to:
  /// **'New key'**
  String get ui26445874a106;

  /// New log (new CSV)…
  ///
  /// In en, this message translates to:
  /// **'New log (new CSV)…'**
  String get uia9cbc7c7f1b8;

  /// New project
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get uie5bcbe241fab;

  /// New study layer
  ///
  /// In en, this message translates to:
  /// **'New study layer'**
  String get ui2769be10eb54;

  /// New version: {v0}
  ///
  /// In en, this message translates to:
  /// **'New version: {v0}'**
  String ui7a022d6fe436(String v0);

  /// No
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get ui816c52fd2bdd;

  /// No GIS features found for the selected project(s)
  ///
  /// In en, this message translates to:
  /// **'No GIS features found for the selected project(s)'**
  String get ui392acae55a83;

  /// No GPS logs yet
  ///
  /// In en, this message translates to:
  /// **'No GPS logs yet'**
  String get ui433fd35b58a5;

  /// No GPS readings above the limit need review.
  ///
  /// In en, this message translates to:
  /// **'No GPS readings above the limit need review.'**
  String get uif617dbefda4a;

  /// No answers recorded.
  ///
  /// In en, this message translates to:
  /// **'No answers recorded.'**
  String get uie4dc9d32f051;

  /// No attributes
  ///
  /// In en, this message translates to:
  /// **'No attributes'**
  String get ui43572a512bc0;

  /// No completed observations yet. Add the first visit.
  ///
  /// In en, this message translates to:
  /// **'No completed observations yet. Add the first visit.'**
  String get ui87d822a81929;

  /// No conflicts. Imported revisions include their original data and change history.
  ///
  /// In en, this message translates to:
  /// **'No conflicts. Imported revisions include their original data and change history.'**
  String get ui5c8ea1c2ed1a;

  /// No connected road route found. Add a road layer in Project settings.
  ///
  /// In en, this message translates to:
  /// **'No connected road route found. Add a road layer in Project settings.'**
  String get uied30d59a8d6d;

  /// No coordinates available
  ///
  /// In en, this message translates to:
  /// **'No coordinates available'**
  String get ui853fb4fdd27f;

  /// No coordinates were available at capture time
  ///
  /// In en, this message translates to:
  /// **'No coordinates were available at capture time'**
  String get uie2dbdc3a52a2;

  /// No description
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get uif354c94fcf63;

  /// No forms yet for this project. Tap to build or import your first survey form.
  ///
  /// In en, this message translates to:
  /// **'No forms yet for this project. Tap to build or import your first survey form.'**
  String get ui904b785a37ab;

  /// No forms yet. Add one or import an XLSForm file.
  ///
  /// In en, this message translates to:
  /// **'No forms yet. Add one or import an XLSForm file.'**
  String get ui92d5dd12f567;

  /// No geometry captured
  ///
  /// In en, this message translates to:
  /// **'No geometry captured'**
  String get ui2f5bb047a0f6;

  /// No heading yet
  ///
  /// In en, this message translates to:
  /// **'No heading yet'**
  String get ui036703da6a32;

  /// No internet connection
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get ui836f41ede479;

  /// No layer recorded
  ///
  /// In en, this message translates to:
  /// **'No layer recorded'**
  String get ui6087965952b8;

  /// No matching sites
  ///
  /// In en, this message translates to:
  /// **'No matching sites'**
  String get uiae6b04b93c15;

  /// No newer version is available.
  ///
  /// In en, this message translates to:
  /// **'No newer version is available.'**
  String get uidfa7f347627b;

  /// No offline packages downloaded yet.
  ///
  /// In en, this message translates to:
  /// **'No offline packages downloaded yet.'**
  String get uiae25632243b8;

  /// No options yet. Add at least one.
  ///
  /// In en, this message translates to:
  /// **'No options yet. Add at least one.'**
  String get ui382cac49e35d;

  /// No photos yet.
  /// Capture photos from a survey form to see them here.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.\nCapture photos from a survey form to see them here.'**
  String get ui48c8c8d3aa3b;

  /// No project selected
  ///
  /// In en, this message translates to:
  /// **'No project selected'**
  String get uie92a1f7c42cf;

  /// No project selected — tap to choose one
  ///
  /// In en, this message translates to:
  /// **'No project selected — tap to choose one'**
  String get uie5fafd1c8ebb;

  /// No projects available.
  ///
  /// In en, this message translates to:
  /// **'No projects available.'**
  String get ui6665189f3494;

  /// No projects yet
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get uicac330d7f9c7;

  /// No projects yet. Create one to start collecting data.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Create one to start collecting data.'**
  String get ui8f998ef5b30b;

  /// No questions yet. Add one to get started.
  ///
  /// In en, this message translates to:
  /// **'No questions yet. Add one to get started.'**
  String get uib463f7374d70;

  /// No readings in "{v0}" to project
  ///
  /// In en, this message translates to:
  /// **'No readings in \"{v0}\" to project'**
  String uie9ee6096e679(String v0);

  /// No readings in selected logs
  ///
  /// In en, this message translates to:
  /// **'No readings in selected logs'**
  String get ui151474224c7d;

  /// No readings to project
  ///
  /// In en, this message translates to:
  /// **'No readings to project'**
  String get ui7640fd2eb8bb;

  /// No readings yet
  ///
  /// In en, this message translates to:
  /// **'No readings yet'**
  String get ui9b6d98a4e333;

  /// No recorded changes yet. Imported baseline is preserved when the first edit is saved.
  ///
  /// In en, this message translates to:
  /// **'No recorded changes yet. Imported baseline is preserved when the first edit is saved.'**
  String get uife1834e75700;

  /// No reference layers added to this project yet.
  ///
  /// In en, this message translates to:
  /// **'No reference layers added to this project yet.'**
  String get ui87becd98de59;

  /// No release notes were provided.
  ///
  /// In en, this message translates to:
  /// **'No release notes were provided.'**
  String get ui8899a85385a5;

  /// No saved map data in the selected projects
  ///
  /// In en, this message translates to:
  /// **'No saved map data in the selected projects'**
  String get ui8b43f54f33b8;

  /// No saved responses or drafts yet
  ///
  /// In en, this message translates to:
  /// **'No saved responses or drafts yet'**
  String get ui8c878a00b717;

  /// No saved responses to export
  ///
  /// In en, this message translates to:
  /// **'No saved responses to export'**
  String get ui19979c176042;

  /// No saved responses yet
  ///
  /// In en, this message translates to:
  /// **'No saved responses yet'**
  String get uiaf682dd08f05;

  /// No saved templates. Open a configured project → Reusable templates to save one.
  ///
  /// In en, this message translates to:
  /// **'No saved templates. Open a configured project → Reusable templates to save one.'**
  String get ui58128e2f84a1;

  /// No sites found in file. Check format and lat/lon columns.
  ///
  /// In en, this message translates to:
  /// **'No sites found in file. Check format and lat/lon columns.'**
  String get uif30931fdc702;

  /// No sites to export
  ///
  /// In en, this message translates to:
  /// **'No sites to export'**
  String get uic548672fb2d6;

  /// No sites yet
  ///
  /// In en, this message translates to:
  /// **'No sites yet'**
  String get ui7e2d4edf8815;

  /// No survey responses found for the selected project(s)
  ///
  /// In en, this message translates to:
  /// **'No survey responses found for the selected project(s)'**
  String get uif26623d21a06;

  /// No unassigned sites
  ///
  /// In en, this message translates to:
  /// **'No unassigned sites'**
  String get uiac6625252c3f;

  /// Not collected
  ///
  /// In en, this message translates to:
  /// **'Not collected'**
  String get ui2a5fc945373b;

  /// Not computed yet
  ///
  /// In en, this message translates to:
  /// **'Not computed yet'**
  String get ui7bf902055995;

  /// Not geotagged
  ///
  /// In en, this message translates to:
  /// **'Not geotagged'**
  String get ui9f7b8e910f33;

  /// Not now
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get uie45714907316;

  /// Note
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ui2c924e308820;

  /// Note (optional)
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get ui4e39567064b6;

  /// Notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ui70440046a3dc;

  /// Notes (optional)
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get ui4d56ca9be0c8;

  /// OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ui9ce3bd4224c8;

  /// Offline HTML map with filters and popups
  ///
  /// In en, this message translates to:
  /// **'Offline HTML map with filters and popups'**
  String get ui998c59e3a961;

  /// Offline maps
  ///
  /// In en, this message translates to:
  /// **'Offline maps'**
  String get ui119fc20f71cb;

  /// Offline · zoom {v0}–{v1}
  /// {v2}
  ///
  /// In en, this message translates to:
  /// **'Offline · zoom {v0}–{v1}\n{v2}'**
  String ui954017dab827(String v0, String v1, String v2);

  /// Offline: {v0} · zoom {v1}–{v2}
  /// {v3}
  ///
  /// In en, this message translates to:
  /// **'Offline: {v0} · zoom {v1}–{v2}\n{v3}'**
  String ui952291e4cc99(String v0, String v1, String v2, String v3);

  /// On this device
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get uia7f9620cca32;

  /// One project connects your questions, maps and fieldwork.
  ///
  /// In en, this message translates to:
  /// **'One project connects your questions, maps and fieldwork.'**
  String get ui439fd7184b90;

  /// Online · {v0}
  ///
  /// In en, this message translates to:
  /// **'Online · {v0}'**
  String ui2e563e00b757(String v0);

  /// Only readings above this limit appear. Accepted readings stay hidden; photos and records remain saved.
  ///
  /// In en, this message translates to:
  /// **'Only readings above this limit appear. Accepted readings stay hidden; photos and records remain saved.'**
  String get uia8076ae6d925;

  /// Opacity
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get uif0fa69f38b14;

  /// Open
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uicf9b77061f7b;

  /// Open GPS Mode
  ///
  /// In en, this message translates to:
  /// **'Open GPS Mode'**
  String get ui805e12a18145;

  /// Open app permission settings
  ///
  /// In en, this message translates to:
  /// **'Open app permission settings'**
  String get uif8063877dde0;

  /// Open camera
  ///
  /// In en, this message translates to:
  /// **'Open camera'**
  String get ui672b0208a0f6;

  /// Open device location settings
  ///
  /// In en, this message translates to:
  /// **'Open device location settings'**
  String get ui2150bfbc8020;

  /// Open in Google Maps
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get ui5ebdd4c27529;

  /// Open in browser
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get ui052269b2c823;

  /// Open map
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get uie56f29da2af3;

  /// Open study-area map
  ///
  /// In en, this message translates to:
  /// **'Open study-area map'**
  String get uicb29cc08fc8f;

  /// Open survey
  ///
  /// In en, this message translates to:
  /// **'Open survey'**
  String get ui7a5cbb59b55f;

  /// Open the camera to scan a project code
  ///
  /// In en, this message translates to:
  /// **'Open the camera to scan a project code'**
  String get ui942b4ee5ed69;

  /// Option name and label are required
  ///
  /// In en, this message translates to:
  /// **'Option name and label are required'**
  String get ui3f7389db6ed3;

  /// Options ({v0})
  ///
  /// In en, this message translates to:
  /// **'Options ({v0})'**
  String ui7ef766113146(String v0);

  /// Original imported data
  ///
  /// In en, this message translates to:
  /// **'Original imported data'**
  String get uia6aab53912af;

  /// Other response formats
  ///
  /// In en, this message translates to:
  /// **'Other response formats'**
  String get ui5651e882f4a9;

  /// Paste instead
  ///
  /// In en, this message translates to:
  /// **'Paste instead'**
  String get ui55007921901d;

  /// Paste project code
  ///
  /// In en, this message translates to:
  /// **'Paste project code'**
  String get uie5dc642cc6a3;

  /// Paste the MapBanai code here
  ///
  /// In en, this message translates to:
  /// **'Paste the MapBanai code here'**
  String get ui5c5260ab99c7;

  /// Pause
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get ui781961bc81c2;

  /// Pause GPS stream
  ///
  /// In en, this message translates to:
  /// **'Pause GPS stream'**
  String get uie1f973e6e1a9;

  /// Pending verification
  ///
  /// In en, this message translates to:
  /// **'Pending verification'**
  String get uif0ac0a5c9beb;

  /// Period / season (optional)
  ///
  /// In en, this message translates to:
  /// **'Period / season (optional)'**
  String get ui8bc8ef67bedc;

  /// Phone direction · magnetic north. Keep the phone reasonably flat.
  ///
  /// In en, this message translates to:
  /// **'Phone direction · magnetic north. Keep the phone reasonably flat.'**
  String get ui5f602ed63d66;

  /// Photo attached
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get uia6685fdd7078;

  /// Photo attached with embedded GPS.
  ///
  /// In en, this message translates to:
  /// **'Photo attached with embedded GPS.'**
  String get ui568e6f033820;

  /// Photo gallery
  ///
  /// In en, this message translates to:
  /// **'Photo gallery'**
  String get ui782facfeed05;

  /// Photo: {v0}
  ///
  /// In en, this message translates to:
  /// **'Photo: {v0}'**
  String ui431dc8d2e072(String v0);

  /// Photos
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get uic8b2e864eccb;

  /// Pick a QR image from your gallery
  ///
  /// In en, this message translates to:
  /// **'Pick a QR image from your gallery'**
  String get ui4cec4b3d3d96;

  /// Pick a project package from your device
  ///
  /// In en, this message translates to:
  /// **'Pick a project package from your device'**
  String get uid3a2a512adb0;

  /// Please add at least one question
  ///
  /// In en, this message translates to:
  /// **'Please add at least one question'**
  String get uia41391d44a4e;

  /// Please enter a form name
  ///
  /// In en, this message translates to:
  /// **'Please enter a form name'**
  String get ui0e992c42efc9;

  /// Please enter a project name
  ///
  /// In en, this message translates to:
  /// **'Please enter a project name'**
  String get uic9bcbcdab335;

  /// Point
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get uif79a28423ed1;

  /// Point moved
  ///
  /// In en, this message translates to:
  /// **'Point moved'**
  String get uic958a23eb380;

  /// Point saved
  ///
  /// In en, this message translates to:
  /// **'Point saved'**
  String get ui5be4bcfb8831;

  /// Point size: {v0}
  ///
  /// In en, this message translates to:
  /// **'Point size: {v0}'**
  String ui27c764375b49(String v0);

  /// Polygon
  ///
  /// In en, this message translates to:
  /// **'Polygon'**
  String get ui85066b2ca9c0;

  /// Polygon saved
  ///
  /// In en, this message translates to:
  /// **'Polygon saved'**
  String get uidd91219a18cb;

  /// Polygon vertices must enclose an area.
  ///
  /// In en, this message translates to:
  /// **'Polygon vertices must enclose an area.'**
  String get uic2519dfe070d;

  /// Portable HTML map
  ///
  /// In en, this message translates to:
  /// **'Portable HTML map'**
  String get ui70f0551a5274;

  /// Positioning…
  ///
  /// In en, this message translates to:
  /// **'Positioning…'**
  String get uifc0196129453;

  /// Preferred language
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get ui1c7b0d771fbc;

  /// Preview matching sites
  ///
  /// In en, this message translates to:
  /// **'Preview matching sites'**
  String get ui90aee2f30cc4;

  /// Previous data backup found
  ///
  /// In en, this message translates to:
  /// **'Previous data backup found'**
  String get uib08dc534b1c0;

  /// Project
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get uif6f4da8d93e8;

  /// Project "{v0}" deleted
  ///
  /// In en, this message translates to:
  /// **'Project \"{v0}\" deleted'**
  String ui1e7149806327(String v0);

  /// Project Atlas
  ///
  /// In en, this message translates to:
  /// **'Project Atlas'**
  String get uibd3091d453d7;

  /// Project QR code
  ///
  /// In en, this message translates to:
  /// **'Project QR code'**
  String get uib23aff4a7cbf;

  /// Project already exists
  ///
  /// In en, this message translates to:
  /// **'Project already exists'**
  String get ui431c23dde814;

  /// Project archived
  ///
  /// In en, this message translates to:
  /// **'Project archived'**
  String get ui225209bf7dec;

  /// Project code
  ///
  /// In en, this message translates to:
  /// **'Project code'**
  String get uib23910158f74;

  /// Project created: {v0}
  ///
  /// In en, this message translates to:
  /// **'Project created: {v0}'**
  String uib56eb4f4a3ed(String v0);

  /// Project exported successfully.
  ///
  /// In en, this message translates to:
  /// **'Project exported successfully.'**
  String get ui15626cd209c8;

  /// Project files and map layers
  ///
  /// In en, this message translates to:
  /// **'Project files and map layers'**
  String get ui966c4d7db1ab;

  /// Project imported successfully.
  ///
  /// In en, this message translates to:
  /// **'Project imported successfully.'**
  String get ui5276d025220f;

  /// Project is too large for direct QR transfer.
  ///
  /// In en, this message translates to:
  /// **'Project is too large for direct QR transfer.'**
  String get ui379ec791fb77;

  /// Project layers
  ///
  /// In en, this message translates to:
  /// **'Project layers'**
  String get ui9c8bf2326c83;

  /// Project multiple logs on WebMap
  ///
  /// In en, this message translates to:
  /// **'Project multiple logs on WebMap'**
  String get ui0a71e1dcd500;

  /// Project multiple on WebMap
  ///
  /// In en, this message translates to:
  /// **'Project multiple on WebMap'**
  String get uib046dc8ee258;

  /// Project name
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get uiab9773fcf6b2;

  /// Project not found for this draft
  ///
  /// In en, this message translates to:
  /// **'Project not found for this draft'**
  String get uiaf9d308f03d7;

  /// Project not found: {v0}
  ///
  /// In en, this message translates to:
  /// **'Project not found: {v0}'**
  String uicdaab9257a39(String v0);

  /// Project on WebMap
  ///
  /// In en, this message translates to:
  /// **'Project on WebMap'**
  String get ui62d5732e064a;

  /// Project options
  ///
  /// In en, this message translates to:
  /// **'Project options'**
  String get uibf395c9c1cc0;

  /// Project renamed to "{v0}"
  ///
  /// In en, this message translates to:
  /// **'Project renamed to \"{v0}\"'**
  String ui8f59a4be38fd(String v0);

  /// Project restored
  ///
  /// In en, this message translates to:
  /// **'Project restored'**
  String get uicd1b8386c131;

  /// Project settings
  ///
  /// In en, this message translates to:
  /// **'Project settings'**
  String get ui95590645e1aa;

  /// Project setup
  ///
  /// In en, this message translates to:
  /// **'Project setup'**
  String get uia0e72cd3d2e8;

  /// Project survey form
  ///
  /// In en, this message translates to:
  /// **'Project survey form'**
  String get ui2e5be53bba6a;

  /// Project vector layers
  ///
  /// In en, this message translates to:
  /// **'Project vector layers'**
  String get uibd1dec2f2c71;

  /// Project with responses (.mbproj)
  ///
  /// In en, this message translates to:
  /// **'Project with responses (.mbproj)'**
  String get ui36043cc2443b;

  /// Project without responses (.mbproj)
  ///
  /// In en, this message translates to:
  /// **'Project without responses (.mbproj)'**
  String get uia476649af65d;

  /// Project {v0} logs
  ///
  /// In en, this message translates to:
  /// **'Project {v0} logs'**
  String ui343f53c678de(String v0);

  /// Project: {v0}
  ///
  /// In en, this message translates to:
  /// **'Project: {v0}'**
  String ui29bccf013ea5(String v0);

  /// QR code
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get uiabba02fcdd8b;

  /// Question label
  ///
  /// In en, this message translates to:
  /// **'Question label'**
  String get uif4c26c16fcc1;

  /// Question names must be valid and unique: {v0}
  ///
  /// In en, this message translates to:
  /// **'Question names must be valid and unique: {v0}'**
  String ui16b39146c10b(String v0);

  /// Question type
  ///
  /// In en, this message translates to:
  /// **'Question type'**
  String get uia60d848de552;

  /// Questionnaire
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get ui42d2c2bca9d8;

  /// Questionnaire required for new or updated features.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire required for new or updated features.'**
  String get ui4be7ca321825;

  /// Questionnaire to compare
  ///
  /// In en, this message translates to:
  /// **'Questionnaire to compare'**
  String get ui8ff5b8ed3fbd;

  /// Questions
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get ui9a1fc1731f62;

  /// Questions ({v0})
  ///
  /// In en, this message translates to:
  /// **'Questions ({v0})'**
  String ui1e9664cb649f(String v0);

  /// Record GPS tracks in GPS Mode. They will appear here for viewing and WebMap overlay.
  ///
  /// In en, this message translates to:
  /// **'Record GPS tracks in GPS Mode. They will appear here for viewing and WebMap overlay.'**
  String get uicfee98bac20a;

  /// Record Line
  ///
  /// In en, this message translates to:
  /// **'Record Line'**
  String get ui607b32a9959b;

  /// Record Point
  ///
  /// In en, this message translates to:
  /// **'Record Point'**
  String get uiaec89b24cf54;

  /// Record Polygon
  ///
  /// In en, this message translates to:
  /// **'Record Polygon'**
  String get uid8bada38f2f6;

  /// Record Track
  ///
  /// In en, this message translates to:
  /// **'Record Track'**
  String get ui2a0da2391fbd;

  /// Record survey at GPS
  ///
  /// In en, this message translates to:
  /// **'Record survey at GPS'**
  String get uid5237368f5b8;

  /// Record to this log
  ///
  /// In en, this message translates to:
  /// **'Record to this log'**
  String get uic28f100b78f1;

  /// Record type
  ///
  /// In en, this message translates to:
  /// **'Record type'**
  String get uidb83f96c32b4;

  /// Recorded day (local time)
  ///
  /// In en, this message translates to:
  /// **'Recorded day (local time)'**
  String get ui0161dce2f8e3;

  /// Recording stopped
  ///
  /// In en, this message translates to:
  /// **'Recording stopped'**
  String get ui460b7c299f9e;

  /// Recording to "{v0}"
  ///
  /// In en, this message translates to:
  /// **'Recording to \"{v0}\"'**
  String uidea4c38150d8(String v0);

  /// Recurring Collection
  ///
  /// In en, this message translates to:
  /// **'Recurring Collection'**
  String get uif67cf3727042;

  /// Redraw geometry
  ///
  /// In en, this message translates to:
  /// **'Redraw geometry'**
  String get uic5d2acf8e03c;

  /// Reference layer
  ///
  /// In en, this message translates to:
  /// **'Reference layer'**
  String get ui07e6773d4d9c;

  /// Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get ui56e3badc4e6c;

  /// Refresh GPS
  ///
  /// In en, this message translates to:
  /// **'Refresh GPS'**
  String get uif2fe9f375cdd;

  /// Refresh accuracy review
  ///
  /// In en, this message translates to:
  /// **'Refresh accuracy review'**
  String get uia06a8c2c4e63;

  /// Refresh packages
  ///
  /// In en, this message translates to:
  /// **'Refresh packages'**
  String get ui78b1a724f71d;

  /// Refresh road directions
  ///
  /// In en, this message translates to:
  /// **'Refresh road directions'**
  String get ui43f7ea278bf5;

  /// Relevance (optional)
  ///
  /// In en, this message translates to:
  /// **'Relevance (optional)'**
  String get ui526e453413f1;

  /// Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get uie963907dac5c;

  /// Remove geometry
  ///
  /// In en, this message translates to:
  /// **'Remove geometry'**
  String get uif08d9c42d5af;

  /// Remove imported file and its points
  ///
  /// In en, this message translates to:
  /// **'Remove imported file and its points'**
  String get uia1cc8f73a0c8;

  /// Remove imported file?
  ///
  /// In en, this message translates to:
  /// **'Remove imported file?'**
  String get ui307eeae7c0c0;

  /// Remove layer
  ///
  /// In en, this message translates to:
  /// **'Remove layer'**
  String get uif8ed171e210e;

  /// Remove layer?
  ///
  /// In en, this message translates to:
  /// **'Remove layer?'**
  String get ui2bd3912b6424;

  /// Remove photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get uic8f5eda8ace9;

  /// Remove template
  ///
  /// In en, this message translates to:
  /// **'Remove template'**
  String get ui12605ebbc10b;

  /// Remove this photo from the device? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo from the device? This cannot be undone.'**
  String get ui67d95d8bf8e4;

  /// Remove {v0} selected map sites and their local histories? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Remove {v0} selected map sites and their local histories? This cannot be undone.'**
  String uid6db25dad8ea(String v0);

  /// Removed {v0} imported points and their history.
  ///
  /// In en, this message translates to:
  /// **'Removed {v0} imported points and their history.'**
  String ui3122a19db20f(String v0);

  /// Rename
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get uid3f4cb898fbe;

  /// Rename project
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get ui633018f5a717;

  /// Replace
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get uia7cf7b25a703;

  /// Replace existing project
  ///
  /// In en, this message translates to:
  /// **'Replace existing project'**
  String get uif16ae4a6851b;

  /// Replace photo
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get uia89003cf0f13;

  /// Required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get uieed6bfb41051;

  /// Reset data
  ///
  /// In en, this message translates to:
  /// **'Reset data'**
  String get uif83e688e4165;

  /// Response
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get ui6e617e4fc9da;

  /// Response revision {v0}
  ///
  /// In en, this message translates to:
  /// **'Response revision {v0}'**
  String ui224ce158da54(String v0);

  /// Responses only (JSON)
  ///
  /// In en, this message translates to:
  /// **'Responses only (JSON)'**
  String get ui69618bf63a73;

  /// Restore
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get ui3cbe6d6b9a8d;

  /// Restore "{v0}"? It will appear in project setup again.
  ///
  /// In en, this message translates to:
  /// **'Restore \"{v0}\"? It will appear in project setup again.'**
  String uid2dd4647b6a1(String v0);

  /// Restore failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {v0}'**
  String ui04d55c7638dc(String v0);

  /// Resume
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get uib3bd0b5a7049;

  /// Resume GPS stream
  ///
  /// In en, this message translates to:
  /// **'Resume GPS stream'**
  String get ui7e5b0347808e;

  /// Resume saved draft
  ///
  /// In en, this message translates to:
  /// **'Resume saved draft'**
  String get ui21b653c8009c;

  /// Resume survey draft
  ///
  /// In en, this message translates to:
  /// **'Resume survey draft'**
  String get uibd0551d8ee60;

  /// Retake
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get ui16457335a763;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ui9f5cd8a2e880;

  /// Retry GPS for selected photo
  ///
  /// In en, this message translates to:
  /// **'Retry GPS for selected photo'**
  String get uifce3486f03c9;

  /// Retry map update
  ///
  /// In en, this message translates to:
  /// **'Retry map update'**
  String get ui6514e3faf04e;

  /// Reusable templates
  ///
  /// In en, this message translates to:
  /// **'Reusable templates'**
  String get ui29ae74246d4f;

  /// Reuse questionnaires and named layers for a new campaign. Templates contain setup only; each new project gets a fresh identity and needs its own cloud connection. Existing visits and photos stay in the original project.
  ///
  /// In en, this message translates to:
  /// **'Reuse questionnaires and named layers for a new campaign. Templates contain setup only; each new project gets a fresh identity and needs its own cloud connection. Existing visits and photos stay in the original project.'**
  String get ui42468c5b8e1a;

  /// Review GPS accuracy above your limit. Accept a reading if it is suitable for your fieldwork.
  ///
  /// In en, this message translates to:
  /// **'Review GPS accuracy above your limit. Accept a reading if it is suitable for your fieldwork.'**
  String get ui5d4f7bae5f1d;

  /// Review and apply changes when connected. New surveys use the new version; saved records and drafts keep their original questions.
  ///
  /// In en, this message translates to:
  /// **'Review and apply changes when connected. New surveys use the new version; saved records and drafts keep their original questions.'**
  String get ui4554e09dd77d;

  /// Review deletion
  ///
  /// In en, this message translates to:
  /// **'Review deletion'**
  String get ui617ceeb41a65;

  /// Review form import
  ///
  /// In en, this message translates to:
  /// **'Review form import'**
  String get ui98bd92828e31;

  /// Review map conflict
  ///
  /// In en, this message translates to:
  /// **'Review map conflict'**
  String get ui0f667a68b0fb;

  /// Review or edit geometry
  ///
  /// In en, this message translates to:
  /// **'Review or edit geometry'**
  String get ui6fc4758d8c5b;

  /// Review saved survey
  ///
  /// In en, this message translates to:
  /// **'Review saved survey'**
  String get uif960c9515a5b;

  /// Review team import
  ///
  /// In en, this message translates to:
  /// **'Review team import'**
  String get uicaacc870d2ec;

  /// Review visit / retry map update
  ///
  /// In en, this message translates to:
  /// **'Review visit / retry map update'**
  String get uib5bb91f5eb74;

  /// Revision history ({v0})
  ///
  /// In en, this message translates to:
  /// **'Revision history ({v0})'**
  String ui39b253e1a983(String v0);

  /// Road network
  ///
  /// In en, this message translates to:
  /// **'Road network'**
  String get uia4c9e7ac0818;

  /// Run survey
  ///
  /// In en, this message translates to:
  /// **'Run survey'**
  String get ui1e975193e087;

  /// SAVE PROJECT FILE
  ///
  /// In en, this message translates to:
  /// **'SAVE PROJECT FILE'**
  String get uid0d3749eff6d;

  /// SHARE PROJECT
  ///
  /// In en, this message translates to:
  /// **'SHARE PROJECT'**
  String get uif5c9eb0215b6;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get uiefc007a393f6;

  /// Save Point
  ///
  /// In en, this message translates to:
  /// **'Save Point'**
  String get uid69b9213e0b9;

  /// Save anyway…
  ///
  /// In en, this message translates to:
  /// **'Save anyway…'**
  String get ui80f3d11ef8a0;

  /// Save as draft
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get ui77d9d7593ba8;

  /// Save draft
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get ui4f25637a5b7e;

  /// Save failed: {v0}. Your edits are retained.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {v0}. Your edits are retained.'**
  String uie89b75ddfae2(String v0);

  /// Save feature
  ///
  /// In en, this message translates to:
  /// **'Save feature'**
  String get uia8a28cda227e;

  /// Save geometry
  ///
  /// In en, this message translates to:
  /// **'Save geometry'**
  String get ui1194006347b8;

  /// Save line
  ///
  /// In en, this message translates to:
  /// **'Save line'**
  String get ui48b133194fc7;

  /// Save location
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get uie5c47400711a;

  /// Save point
  ///
  /// In en, this message translates to:
  /// **'Save point'**
  String get uib38557160b3a;

  /// Save point to…
  ///
  /// In en, this message translates to:
  /// **'Save point to…'**
  String get uidb6b0a422ee8;

  /// Save polygon
  ///
  /// In en, this message translates to:
  /// **'Save polygon'**
  String get uieba0e7af2b62;

  /// Save responses
  ///
  /// In en, this message translates to:
  /// **'Save responses'**
  String get uif8132b134652;

  /// Save selected layer and questionnaire
  ///
  /// In en, this message translates to:
  /// **'Save selected layer and questionnaire'**
  String get uiae8411a6278d;

  /// Save the questionnaire and attach a photo to finish. You can save a draft at any time.
  ///
  /// In en, this message translates to:
  /// **'Save the questionnaire and attach a photo to finish. You can save a draft at any time.'**
  String get uiaefec51925dd;

  /// Save this project as template
  ///
  /// In en, this message translates to:
  /// **'Save this project as template'**
  String get ui9797b0b4a5c1;

  /// Saved answers
  ///
  /// In en, this message translates to:
  /// **'Saved answers'**
  String get uie30f8f020ce6;

  /// Saved on this phone · waiting to sync
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone · waiting to sync'**
  String get ui57dd6e65063e;

  /// Saved projects
  ///
  /// In en, this message translates to:
  /// **'Saved projects'**
  String get ui2391ec16d44b;

  /// Saved response for {v0}
  ///
  /// In en, this message translates to:
  /// **'Saved response for {v0}'**
  String uic1b9736fedd0(String v0);

  /// Saved responses appear here; unfinished work is kept as drafts
  ///
  /// In en, this message translates to:
  /// **'Saved responses appear here; unfinished work is kept as drafts'**
  String get ui28bb6965aeec;

  /// Saved visit
  ///
  /// In en, this message translates to:
  /// **'Saved visit'**
  String get uibf4522143a41;

  /// Saving...
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get uiae7e887517b0;

  /// Scan QR code
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get uie7d8c30678ab;

  /// Scan QR from gallery
  ///
  /// In en, this message translates to:
  /// **'Scan QR from gallery'**
  String get uif64c3fbefbf2;

  /// Search by name or location
  ///
  /// In en, this message translates to:
  /// **'Search by name or location'**
  String get ui555b8b1249e2;

  /// Select GeoJSON, GeoPackage, SHP/ZIP, CSV, Excel or KML/KMZ.
  ///
  /// In en, this message translates to:
  /// **'Select GeoJSON, GeoPackage, SHP/ZIP, CSV, Excel or KML/KMZ.'**
  String get ui5c562a19562f;

  /// Select a project above to see its collected data.
  ///
  /// In en, this message translates to:
  /// **'Select a project above to see its collected data.'**
  String get uif19de55e63d0;

  /// Select a project and survey form first.
  ///
  /// In en, this message translates to:
  /// **'Select a project and survey form first.'**
  String get uif386a8052a3a;

  /// Select a project before building a form
  ///
  /// In en, this message translates to:
  /// **'Select a project before building a form'**
  String get ui410ffc9a264e;

  /// Select a project before drawing
  ///
  /// In en, this message translates to:
  /// **'Select a project before drawing'**
  String get ui4405857e86b5;

  /// Select a project first
  ///
  /// In en, this message translates to:
  /// **'Select a project first'**
  String get ui65c52d24239c;

  /// Select a project questionnaire first.
  ///
  /// In en, this message translates to:
  /// **'Select a project questionnaire first.'**
  String get uia1444962ecdb;

  /// Select a project, then import its site layer.
  ///
  /// In en, this message translates to:
  /// **'Select a project, then import its site layer.'**
  String get ui7e607015bb18;

  /// Select a questionnaire and collection round first.
  ///
  /// In en, this message translates to:
  /// **'Select a questionnaire and collection round first.'**
  String get ui74d7e0804c5c;

  /// Select a survey form
  ///
  /// In en, this message translates to:
  /// **'Select a survey form'**
  String get ui3b1a1262ef90;

  /// Select all
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get ui913afff1faf7;

  /// Select all ({v0} selected)
  ///
  /// In en, this message translates to:
  /// **'Select all ({v0} selected)'**
  String uifdc38dcd3912(String v0);

  /// Select an active project first
  ///
  /// In en, this message translates to:
  /// **'Select an active project first'**
  String get uiebaab4e02ce5;

  /// Select an option
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get ui08d7aa35da9a;

  /// Select at least one project
  ///
  /// In en, this message translates to:
  /// **'Select at least one project'**
  String get ui648c09b587f6;

  /// Select basemap
  ///
  /// In en, this message translates to:
  /// **'Select basemap'**
  String get ui3e009481cb29;

  /// Select date
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get uib84a6ecbc04c;

  /// Select date and time
  ///
  /// In en, this message translates to:
  /// **'Select date and time'**
  String get ui94c7b6109333;

  /// Select logs to project
  ///
  /// In en, this message translates to:
  /// **'Select logs to project'**
  String get ui7e8fcd733d84;

  /// Select multiple
  ///
  /// In en, this message translates to:
  /// **'Select multiple'**
  String get ui1181e5025b41;

  /// Select one
  ///
  /// In en, this message translates to:
  /// **'Select one'**
  String get ui4998e80cffcd;

  /// Select project
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get uib4b37dd6ce6d;

  /// Select projects to export
  ///
  /// In en, this message translates to:
  /// **'Select projects to export'**
  String get ui4978072af3ac;

  /// Select the questionnaire and measurement to separate, such as salinity. Only saved responses with that measurement and a point location become sites. Original responses stay intact.
  ///
  /// In en, this message translates to:
  /// **'Select the questionnaire and measurement to separate, such as salinity. Only saved responses with that measurement and a point location become sites. Original responses stay intact.'**
  String get uia7cf335d4076;

  /// Select time
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get ui3d7f91e8e71b;

  /// Set relative height reference here
  ///
  /// In en, this message translates to:
  /// **'Set relative height reference here'**
  String get uic72ef626fe86;

  /// Set up cloud sync
  ///
  /// In en, this message translates to:
  /// **'Set up cloud sync'**
  String get ui74a6ff25d6dd;

  /// Set up cloud sync for this project first
  ///
  /// In en, this message translates to:
  /// **'Set up cloud sync for this project first'**
  String get uicc1544692441;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get uic7f73bb54d92;

  /// Settings saved
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get uiaef97bb06af4;

  /// Shapefile companion files
  ///
  /// In en, this message translates to:
  /// **'Shapefile companion files'**
  String get uica90d5bc4a0e;

  /// Shapefile, CSV, Excel, GeoJSON and GeoPackage
  ///
  /// In en, this message translates to:
  /// **'Shapefile, CSV, Excel, GeoJSON and GeoPackage'**
  String get ui348cf86fa1bc;

  /// Share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get ui09ca55ca52d2;

  /// Share CSV
  ///
  /// In en, this message translates to:
  /// **'Share CSV'**
  String get ui142e4a88490f;

  /// Share HTML file
  ///
  /// In en, this message translates to:
  /// **'Share HTML file'**
  String get ui25dac6eacbc4;

  /// Share failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Share failed: {v0}'**
  String uifdf43a7041a5(String v0);

  /// Share project
  ///
  /// In en, this message translates to:
  /// **'Share project'**
  String get uic282b0009d54;

  /// Share the URL and API key only with trusted enumerators.
  ///
  /// In en, this message translates to:
  /// **'Share the URL and API key only with trusted enumerators.'**
  String get uib5f97af82c42;

  /// Shared secret token
  ///
  /// In en, this message translates to:
  /// **'Shared secret token'**
  String get uidf6284851e35;

  /// Sharing failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'Sharing failed: {v0}'**
  String uid94a0488d308(String v0);

  /// Sharing is not available right now.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available right now.'**
  String get ui9a7f5c9f9c01;

  /// Sharing project…
  ///
  /// In en, this message translates to:
  /// **'Sharing project…'**
  String get uidd2e0b7ceac6;

  /// Shortest road route  {v0}
  ///
  /// In en, this message translates to:
  /// **'Shortest road route  {v0}'**
  String uia137ead9a9c9(String v0);

  /// Show all
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get ui50a279de829f;

  /// Show road directions
  ///
  /// In en, this message translates to:
  /// **'Show road directions'**
  String get uib666c5857d85;

  /// Shown when the constraint is violated
  ///
  /// In en, this message translates to:
  /// **'Shown when the constraint is violated'**
  String get ui6b97e76a48a2;

  /// Simple form-based field capture
  ///
  /// In en, this message translates to:
  /// **'Simple form-based field capture'**
  String get ui2ff741423601;

  /// Single color
  ///
  /// In en, this message translates to:
  /// **'Single color'**
  String get ui51b35f60ed25;

  /// Site deleted
  ///
  /// In en, this message translates to:
  /// **'Site deleted'**
  String get uif8115c6458d3;

  /// Site layer
  ///
  /// In en, this message translates to:
  /// **'Site layer'**
  String get ui03611ed63fe3;

  /// Site observation
  ///
  /// In en, this message translates to:
  /// **'Site observation'**
  String get ui70648b5ca5bb;

  /// Site timeline
  ///
  /// In en, this message translates to:
  /// **'Site timeline'**
  String get ui72a6527e5742;

  /// Site timeline / add observation
  ///
  /// In en, this message translates to:
  /// **'Site timeline / add observation'**
  String get ui73c4785414b8;

  /// Site timeline / compare observations
  ///
  /// In en, this message translates to:
  /// **'Site timeline / compare observations'**
  String get uif08625843372;

  /// Site visits
  ///
  /// In en, this message translates to:
  /// **'Site visits'**
  String get uidc61591e7417;

  /// Site visits with status tracking & navigation
  ///
  /// In en, this message translates to:
  /// **'Site visits with status tracking & navigation'**
  String get ui046c5d454e0a;

  /// Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get ui3da474537ac3;

  /// Start
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get ui952f375412e8;

  /// Start another visit
  ///
  /// In en, this message translates to:
  /// **'Start another visit'**
  String get ui2932e9a9f29d;

  /// Start building survey form
  ///
  /// In en, this message translates to:
  /// **'Start building survey form'**
  String get ui02c86d972b56;

  /// Start recording
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get uie92d02d3d165;

  /// Start visit
  ///
  /// In en, this message translates to:
  /// **'Start visit'**
  String get ui814036be3ced;

  /// Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get uibae7d5be7082;

  /// Stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get ui9e253470c876;

  /// Stop following
  ///
  /// In en, this message translates to:
  /// **'Stop following'**
  String get ui72d339ddaa22;

  /// Stop recording
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get uiee0d9dc8eb5e;

  /// Study Area
  ///
  /// In en, this message translates to:
  /// **'Study Area'**
  String get ui794e05ff6f15;

  /// Study Area Mode
  ///
  /// In en, this message translates to:
  /// **'Study Area Mode'**
  String get ui7454029d069c;

  /// Study Area Visits
  ///
  /// In en, this message translates to:
  /// **'Study Area Visits'**
  String get ui792ac04306e0;

  /// Study Area points / imports
  ///
  /// In en, this message translates to:
  /// **'Study Area points / imports'**
  String get uiafa82e671a4d;

  /// Study Area — View only
  ///
  /// In en, this message translates to:
  /// **'Study Area — View only'**
  String get ui140781d627c5;

  /// Study area
  ///
  /// In en, this message translates to:
  /// **'Study area'**
  String get ui2e09116ca6c8;

  /// Study layer
  ///
  /// In en, this message translates to:
  /// **'Study layer'**
  String get uiaec7160f7d63;

  /// Study workspace
  ///
  /// In en, this message translates to:
  /// **'Study workspace'**
  String get ui3d5101991a4b;

  /// Survey Form Builder
  ///
  /// In en, this message translates to:
  /// **'Survey Form Builder'**
  String get uibae35f4f69ef;

  /// Survey History
  ///
  /// In en, this message translates to:
  /// **'Survey History'**
  String get uifd8eb8a44d22;

  /// Survey Mode
  ///
  /// In en, this message translates to:
  /// **'Survey Mode'**
  String get ui6a0244a36b78;

  /// Survey Response
  ///
  /// In en, this message translates to:
  /// **'Survey Response'**
  String get ui15b4700cfe17;

  /// Survey Responses
  ///
  /// In en, this message translates to:
  /// **'Survey Responses'**
  String get ui56eaf8c1a78e;

  /// Survey and GIS map (GeoJSON)
  ///
  /// In en, this message translates to:
  /// **'Survey and GIS map (GeoJSON)'**
  String get ui27429641f3a8;

  /// Survey feature saved
  ///
  /// In en, this message translates to:
  /// **'Survey feature saved'**
  String get ui1cdf92b9422d;

  /// Survey form
  ///
  /// In en, this message translates to:
  /// **'Survey form'**
  String get ui0f50e6cd5d73;

  /// Survey form not found for this draft
  ///
  /// In en, this message translates to:
  /// **'Survey form not found for this draft'**
  String get ui61cd448fd742;

  /// Survey forms
  ///
  /// In en, this message translates to:
  /// **'Survey forms'**
  String get ui26ae75d9a213;

  /// Survey response: {v0}
  ///
  /// In en, this message translates to:
  /// **'Survey response: {v0}'**
  String ui1bbe80df74aa(String v0);

  /// Survey responses
  ///
  /// In en, this message translates to:
  /// **'Survey responses'**
  String get uidb7d0e51a156;

  /// Survey responses (CSV)
  ///
  /// In en, this message translates to:
  /// **'Survey responses (CSV)'**
  String get uia7d7ae64cf27;

  /// Survey saved; map update needs attention
  ///
  /// In en, this message translates to:
  /// **'Survey saved; map update needs attention'**
  String get uibd39220a2d4d;

  /// Switch between languages defined in the XLSForm
  ///
  /// In en, this message translates to:
  /// **'Switch between languages defined in the XLSForm'**
  String get uia515beba342a;

  /// Sync
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get ui905f63092ff2;

  /// Sync complete
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get uia625528186cb;

  /// Sync failed
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get ui39040109b600;

  /// Sync finished
  ///
  /// In en, this message translates to:
  /// **'Sync finished'**
  String get uiecbe8bb3855d;

  /// Sync questionnaire
  ///
  /// In en, this message translates to:
  /// **'Sync questionnaire'**
  String get ui3e2b9221a8fb;

  /// Sync status
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get ui12df0ea3611e;

  /// Synced · edit to send a new revision
  ///
  /// In en, this message translates to:
  /// **'Synced · edit to send a new revision'**
  String get ui9f462978795c;

  /// Syncing...
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get uie5c7727a106e;

  /// System default
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get ui9d8d3808063b;

  /// Tap a feature on the map to see details
  ///
  /// In en, this message translates to:
  /// **'Tap a feature on the map to see details'**
  String get ui02de1f69347b;

  /// Tap a feature on the map to see its details
  ///
  /// In en, this message translates to:
  /// **'Tap a feature on the map to see its details'**
  String get ui434e87b69d53;

  /// Tap the map to add the first point
  ///
  /// In en, this message translates to:
  /// **'Tap the map to add the first point'**
  String get uic12b336a09df;

  /// Tap the map to place this feature at its new location.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place this feature at its new location.'**
  String get uic11008251fcb;

  /// Tap to capture GPS location
  ///
  /// In en, this message translates to:
  /// **'Tap to capture GPS location'**
  String get ui3033c8b8aac7;

  /// Tap to measure accuracy
  ///
  /// In en, this message translates to:
  /// **'Tap to measure accuracy'**
  String get ui38d2049ea91a;

  /// Test Connection
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get ui580f6ab716ab;

  /// Testing...
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get ui15ccc83272b1;

  /// Text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get uic3328c39b0e2;

  /// The .mbproj package includes forms, GIS source files, map layers, settings and cloud setup scripts. Choose whether to include collected responses and their photos.
  ///
  /// In en, this message translates to:
  /// **'The .mbproj package includes forms, GIS source files, map layers, settings and cloud setup scripts. Choose whether to include collected responses and their photos.'**
  String get ui8a9c91641630;

  /// The collected vertices will be discarded.
  ///
  /// In en, this message translates to:
  /// **'The collected vertices will be discarded.'**
  String get ui1341db575a04;

  /// The draft project is unavailable. Restore the project before resuming.
  ///
  /// In en, this message translates to:
  /// **'The draft project is unavailable. Restore the project before resuming.'**
  String get ui0f6a7c9875c9;

  /// Theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get uia797e30923ac;

  /// These are stored map sites without a project assignment. Review their details before assigning or deleting them. They are separate from survey responses.
  ///
  /// In en, this message translates to:
  /// **'These are stored map sites without a project assignment. Review their details before assigning or deleting them. They are separate from survey responses.'**
  String get ui2a2618391b6d;

  /// This complete geometry is preserved. Edit its parts in GIS software and merge the revised GeoJSON to redraw it.
  ///
  /// {v0}
  ///
  /// In en, this message translates to:
  /// **'This complete geometry is preserved. Edit its parts in GIS software and merge the revised GeoJSON to redraw it.\n\n{v0}'**
  String ui8a91047b84cc(String v0);

  /// This draft’s site or questionnaire is no longer available.
  ///
  /// In en, this message translates to:
  /// **'This draft’s site or questionnaire is no longer available.'**
  String get ui1644de68ca1f;

  /// This feature changed elsewhere. Reopen it and review the latest version.
  ///
  /// In en, this message translates to:
  /// **'This feature changed elsewhere. Reopen it and review the latest version.'**
  String get ui5163769c6478;

  /// This field already exists. Edit its value above.
  ///
  /// In en, this message translates to:
  /// **'This field already exists. Edit its value above.'**
  String get ui845d01d70891;

  /// This form has no questions yet.
  ///
  /// In en, this message translates to:
  /// **'This form has no questions yet.'**
  String get ui7aae0b62872a;

  /// This layer has no points or survey history to clear.
  ///
  /// In en, this message translates to:
  /// **'This layer has no points or survey history to clear.'**
  String get ui4991b992a518;

  /// This legacy form has unsupported repeats. Import a form with one submission per feature before collecting more data.
  ///
  /// In en, this message translates to:
  /// **'This legacy form has unsupported repeats. Import a form with one submission per feature before collecting more data.'**
  String get ui7e8c2ede22e2;

  /// This question type needs at least one option
  ///
  /// In en, this message translates to:
  /// **'This question type needs at least one option'**
  String get ui7fa6ed0dde94;

  /// This removes its offline resources. Your surveyed features and photos stay on the device.
  ///
  /// In en, this message translates to:
  /// **'This removes its offline resources. Your surveyed features and photos stay on the device.'**
  String get uid8245487967c;

  /// This will remove “{v0}” from this project.
  ///
  /// In en, this message translates to:
  /// **'This will remove “{v0}” from this project.'**
  String ui0178bef432ea(String v0);

  /// This will remove “{v0}”, its map layer, {v1} imported points, and their local history.
  ///
  /// In en, this message translates to:
  /// **'This will remove “{v0}”, its map layer, {v1} imported points, and their local history.'**
  String uia87ef6452c2d(String v0, String v1);

  /// Time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get ui6c82e6dd8680;

  /// Timestamp
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get ui19eabc961735;

  /// Track name (optional)
  ///
  /// In en, this message translates to:
  /// **'Track name (optional)'**
  String get uid79eb0a68863;

  /// Turn on location services.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services.'**
  String get uib41665a86980;

  /// Type: {v0}
  ///
  /// In en, this message translates to:
  /// **'Type: {v0}'**
  String ui4f1b0f8aa40a(String v0);

  /// Unchanged
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get ui51ed65113221;

  /// Undo
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get ui39fc72124884;

  /// Undone
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get uib528b0fe2e94;

  /// Update v{v0} is available
  ///
  /// In en, this message translates to:
  /// **'Update v{v0} is available'**
  String ui47091b4936c3(String v0);

  /// Updated "{v0}" from XLSForm
  ///
  /// In en, this message translates to:
  /// **'Updated \"{v0}\" from XLSForm'**
  String uifc3b7a12bc25(String v0);

  /// Updated map (GeoJSON)
  ///
  /// In en, this message translates to:
  /// **'Updated map (GeoJSON)'**
  String get uif33de2a5a459;

  /// Updates
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get uic76d18079a07;

  /// Upload responses & photos to cloud
  ///
  /// In en, this message translates to:
  /// **'Upload responses & photos to cloud'**
  String get ui3f90215b1701;

  /// Use area around my GPS location
  ///
  /// In en, this message translates to:
  /// **'Use area around my GPS location'**
  String get ui5874b63bbc58;

  /// Use distinct vertices.
  ///
  /// In en, this message translates to:
  /// **'Use distinct vertices.'**
  String get uiab731c818a80;

  /// Use incoming version
  ///
  /// In en, this message translates to:
  /// **'Use incoming version'**
  String get uif3d5a30b0ad2;

  /// Use layers in
  ///
  /// In en, this message translates to:
  /// **'Use layers in'**
  String get ui3f546b7d94c3;

  /// Use photo
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get uia75e1e286eed;

  /// Use the top Import button for GeoJSON, GeoPackage, zipped shapefiles, CSV, Excel or KML/KMZ.
  ///
  /// In en, this message translates to:
  /// **'Use the top Import button for GeoJSON, GeoPackage, zipped shapefiles, CSV, Excel or KML/KMZ.'**
  String get ui2dec1c905e5d;

  /// Use your own server or a provider that permits offline downloads. Built-in OSM, CARTO and Esri basemaps remain online-only. Keep the app open while downloading. Packages are not part of survey backups; re-download them after reinstall.
  ///
  /// In en, this message translates to:
  /// **'Use your own server or a provider that permits offline downloads. Built-in OSM, CARTO and Esri basemaps remain online-only. Keep the app open while downloading. Packages are not part of survey backups; re-download them after reinstall.'**
  String get ui890fcb6fc818;

  /// Used by the GIS distance and area tools. Automatic picks metres/kilometres and square metres or hectares.
  ///
  /// In en, this message translates to:
  /// **'Used by the GIS distance and area tools. Automatic picks metres/kilometres and square metres or hectares.'**
  String get uib9d2e508d3e7;

  /// User
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get ui9f8a2389a20c;

  /// User name
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get ui542fc71480de;

  /// Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get ui8dce170de238;

  /// Value (no spaces)
  ///
  /// In en, this message translates to:
  /// **'Value (no spaces)'**
  String get uibe37e18e12ab;

  /// Verification / change note
  ///
  /// In en, this message translates to:
  /// **'Verification / change note'**
  String get uibc23d6952888;

  /// Verification Complete
  ///
  /// In en, this message translates to:
  /// **'Verification Complete'**
  String get ui062e095d2e00;

  /// Verification status
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get ui760fa1d0a21b;

  /// Verify with questionnaire
  ///
  /// In en, this message translates to:
  /// **'Verify with questionnaire'**
  String get ui08f9848508a4;

  /// Version {v0}
  ///
  /// In en, this message translates to:
  /// **'Version {v0}'**
  String ui93af16ef7e20(String v0);

  /// Version {v0} is available
  ///
  /// In en, this message translates to:
  /// **'Version {v0} is available'**
  String ui6b6212f516b9(String v0);

  /// Vertical accuracy unavailable. GNSS altitude is not a reliable floor-height measurement indoors.
  ///
  /// In en, this message translates to:
  /// **'Vertical accuracy unavailable. GNSS altitude is not a reliable floor-height measurement indoors.'**
  String get uie21d16e2187b;

  /// Vertical uncertainty ±{v0} m · WGS84 ellipsoid, not sea level or height above ground.
  ///
  /// In en, this message translates to:
  /// **'Vertical uncertainty ±{v0} m · WGS84 ellipsoid, not sea level or height above ground.'**
  String ui670ea96a1459(String v0);

  /// View / edit information
  ///
  /// In en, this message translates to:
  /// **'View / edit information'**
  String get ui9db62a629ff2;

  /// View CSV
  ///
  /// In en, this message translates to:
  /// **'View CSV'**
  String get ui70144df223fc;

  /// View and filter features in a browser
  ///
  /// In en, this message translates to:
  /// **'View and filter features in a browser'**
  String get ui32105310ab3b;

  /// View logs & project tracks on WebMap
  ///
  /// In en, this message translates to:
  /// **'View logs & project tracks on WebMap'**
  String get uia08f63479914;

  /// View only — do not import
  ///
  /// In en, this message translates to:
  /// **'View only — do not import'**
  String get ui78caa7422cf5;

  /// View record
  ///
  /// In en, this message translates to:
  /// **'View record'**
  String get ui5ceea82d3743;

  /// Viewer
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get uidbad9f126b33;

  /// Visit a study site
  ///
  /// In en, this message translates to:
  /// **'Visit a study site'**
  String get uiae28ae06cab2;

  /// Visit and photo are saved. Study map update is pending.
  ///
  /// In en, this message translates to:
  /// **'Visit and photo are saved. Study map update is pending.'**
  String get ui2f33af1452b9;

  /// Visit another feature
  ///
  /// In en, this message translates to:
  /// **'Visit another feature'**
  String get ui13db299e703f;

  /// Visit date
  ///
  /// In en, this message translates to:
  /// **'Visit date'**
  String get uifcb7f8e18aa1;

  /// Visit draft saved. You can resume it later.
  ///
  /// In en, this message translates to:
  /// **'Visit draft saved. You can resume it later.'**
  String get ui18a8706ac9c3;

  /// Visit facilities and track done, pending or review.
  ///
  /// In en, this message translates to:
  /// **'Visit facilities and track done, pending or review.'**
  String get uibacabffc7265;

  /// Visit outcome
  ///
  /// In en, this message translates to:
  /// **'Visit outcome'**
  String get uid983c98256a6;

  /// Visit saved and study map updated.
  ///
  /// In en, this message translates to:
  /// **'Visit saved and study map updated.'**
  String get ui06547aa978e8;

  /// Visit saved; map update needs review: {v0}
  ///
  /// In en, this message translates to:
  /// **'Visit saved; map update needs review: {v0}'**
  String ui8d3b6ce77936(String v0);

  /// Wait for a fresh GPS location before recording a site.
  ///
  /// In en, this message translates to:
  /// **'Wait for a fresh GPS location before recording a site.'**
  String get uiaea1d8c3ba27;

  /// Wait for a fresh, accurate GPS fix (within 25 m and 30 seconds), or tap the map manually.
  ///
  /// In en, this message translates to:
  /// **'Wait for a fresh, accurate GPS fix (within 25 m and 30 seconds), or tap the map manually.'**
  String get uidbeb4f38e866;

  /// Waiting for GPS fix
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS fix'**
  String get ui1599512dd4fa;

  /// Waiting for a GPS fix
  ///
  /// In en, this message translates to:
  /// **'Waiting for a GPS fix'**
  String get ui69d5b3e27393;

  /// Waiting for a GPS fix before saving a point
  ///
  /// In en, this message translates to:
  /// **'Waiting for a GPS fix before saving a point'**
  String get ui0f1b5fa21d3e;

  /// Waiting for a GPS fix before saving the draft
  ///
  /// In en, this message translates to:
  /// **'Waiting for a GPS fix before saving the draft'**
  String get uib933ed0f85ce;

  /// Waiting for a GPS fix to place the point
  ///
  /// In en, this message translates to:
  /// **'Waiting for a GPS fix to place the point'**
  String get ui46d1bd7a4fe5;

  /// Waiting for position…
  ///
  /// In en, this message translates to:
  /// **'Waiting for position…'**
  String get ui403fb7e4a07b;

  /// Waiting to sync
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get uie8f3a099b17e;

  /// Waiting…
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get ui3650b57a63bc;

  /// Walk along the boundary while recording
  ///
  /// In en, this message translates to:
  /// **'Walk along the boundary while recording'**
  String get ui203aa501a2cf;

  /// WebMap
  ///
  /// In en, this message translates to:
  /// **'WebMap'**
  String get ui112c28094e9c;

  /// WebMap failed: {v0}
  ///
  /// In en, this message translates to:
  /// **'WebMap failed: {v0}'**
  String ui8524c9daa511(String v0);

  /// Welcome to MapBanai
  ///
  /// In en, this message translates to:
  /// **'Welcome to MapBanai'**
  String get ui83476ddef06c;

  /// XLSForm import limitations
  ///
  /// In en, this message translates to:
  /// **'XLSForm import limitations'**
  String get uib16023bdc345;

  /// Yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ui5397e0583f14;

  /// Yes/No
  ///
  /// In en, this message translates to:
  /// **'Yes/No'**
  String get ui9f628b61ae0f;

  /// You're up to date
  ///
  /// In en, this message translates to:
  /// **'You\'\'re up to date'**
  String get ui5fc15792a3b6;

  /// Your name
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get uiab42293e29e1;

  /// Your name is attached to every survey response, GPS log entry and export produced by the app.
  ///
  /// In en, this message translates to:
  /// **'Your name is attached to every survey response, GPS log entry and export produced by the app.'**
  String get ui91dd05f1187c;

  /// Zoom 18 maximum; 6,000 tiles maximum. Download covers only these bounds and zooms. Larger areas need lower zoom or separate packages.
  ///
  /// In en, this message translates to:
  /// **'Zoom 18 maximum; 6,000 tiles maximum. Download covers only these bounds and zooms. Larger areas need lower zoom or separate packages.'**
  String get ui50ee0028c989;

  /// applied
  ///
  /// In en, this message translates to:
  /// **'applied'**
  String get uic0b885fe691b;

  /// draft
  ///
  /// In en, this message translates to:
  /// **'draft'**
  String get ui0e7766b460fd;

  /// e.g. Riverbank survey
  ///
  /// In en, this message translates to:
  /// **'e.g. Riverbank survey'**
  String get ui2f232eece4a3;

  /// e.g. Salinity — October
  ///
  /// In en, this message translates to:
  /// **'e.g. Salinity — October'**
  String get ui7e6a1fc501ab;

  /// e.g., ${field_name} = "value"
  ///
  /// In en, this message translates to:
  /// **'e.g., \$\'{\'field_name\'}\' = \"value\"'**
  String get ui3f29e0058e85;

  /// e.g., ${width} * ${length}
  ///
  /// In en, this message translates to:
  /// **'e.g., \$\'{\'width\'}\' * \$\'{\'length\'}\''**
  String get uie5aad6660c17;

  /// e.g., . > 0 and . < 150
  ///
  /// In en, this message translates to:
  /// **'e.g., . > 0 and . < 150'**
  String get uic4425e81a34d;

  /// e.g., John Doe
  ///
  /// In en, this message translates to:
  /// **'e.g., John Doe'**
  String get uidef3966f9daf;

  /// e.g., Mild
  ///
  /// In en, this message translates to:
  /// **'e.g., Mild'**
  String get ui89a91669c66b;

  /// e.g., Riverbank Survey
  ///
  /// In en, this message translates to:
  /// **'e.g., Riverbank Survey'**
  String get ui4486060d3535;

  /// e.g., Site A boundary walk
  ///
  /// In en, this message translates to:
  /// **'e.g., Site A boundary walk'**
  String get ui92d4bd903a26;

  /// e.g., Standing water at footbridge
  ///
  /// In en, this message translates to:
  /// **'e.g., Standing water at footbridge'**
  String get ui3aedaef1c98d;

  /// e.g., mild
  ///
  /// In en, this message translates to:
  /// **'e.g., mild'**
  String get uidac85c4db8ef;

  /// e.g., site_name
  ///
  /// In en, this message translates to:
  /// **'e.g., site_name'**
  String get uif4bce9423af7;

  /// form_validated
  ///
  /// In en, this message translates to:
  /// **'form_validated'**
  String get ui3744336ac6a4;

  /// import_batch_id
  ///
  /// In en, this message translates to:
  /// **'import_batch_id'**
  String get uif408daa3bbc7;

  /// magnetic north
  ///
  /// In en, this message translates to:
  /// **'magnetic north'**
  String get ui8745cffb3401;

  /// name
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get ui6ae999552a0d;

  /// none
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get ui71f8e7976e4c;

  /// reconciliation_error
  ///
  /// In en, this message translates to:
  /// **'reconciliation_error'**
  String get ui3032bf2db789;

  /// required
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get ui1a77d416224c;

  /// site_sync
  ///
  /// In en, this message translates to:
  /// **'site_sync'**
  String get uiac82a1d4da3f;

  /// travel direction
  ///
  /// In en, this message translates to:
  /// **'travel direction'**
  String get ui519742fe8995;

  /// warning
  ///
  /// In en, this message translates to:
  /// **'warning'**
  String get ui383fd7bf84aa;

  /// {v0}  •  session #{v1}
  ///
  /// In en, this message translates to:
  /// **'{v0}  •  session #{v1}'**
  String ui16ae235ff3fa(String v0, String v1);

  /// {v0}  •  {v1}  •  draft
  ///
  /// In en, this message translates to:
  /// **'{v0}  •  {v1}  •  draft'**
  String ui3047ae0d6f0b(String v0, String v1);

  /// {v0} / {v1} features
  ///
  /// In en, this message translates to:
  /// **'{v0} / {v1} features'**
  String ui74286a1f17a8(String v0, String v1);

  /// {v0} / {v1} resources · {v2}
  ///
  /// In en, this message translates to:
  /// **'{v0} / {v1} resources · {v2}'**
  String uib31c43e0e100(String v0, String v1, String v2);

  /// {v0} MB
  ///
  /// In en, this message translates to:
  /// **'{v0} MB'**
  String ui856ae446a4d6(String v0);

  /// {v0} captured
  ///
  /// In en, this message translates to:
  /// **'{v0} captured'**
  String uid2ec3044ad26(String v0);

  /// {v0} features
  ///
  /// In en, this message translates to:
  /// **'{v0} features'**
  String uid4e292ed91bd(String v0);

  /// {v0} features, full history for team merge
  ///
  /// In en, this message translates to:
  /// **'{v0} features, full history for team merge'**
  String ui56d31f5a5e0f(String v0);

  /// {v0} matching records
  /// {v1} waiting to sync
  ///
  /// In en, this message translates to:
  /// **'{v0} matching records\n{v1} waiting to sync'**
  String ui12126260f1ba(String v0, String v1);

  /// {v0} matching site(s)
  ///
  /// In en, this message translates to:
  /// **'{v0} matching site(s)'**
  String uia98956288877(String v0);

  /// {v0} new features, {v1} incoming revisions, {v2} unchanged or older versions.
  ///
  /// In en, this message translates to:
  /// **'{v0} new features, {v1} incoming revisions, {v2} unchanged or older versions.'**
  String ui775784f1b2ec(String v0, String v1, String v2);

  /// {v0} questions
  ///
  /// In en, this message translates to:
  /// **'{v0} questions'**
  String ui572d0978e0f5(String v0);

  /// {v0} readings
  ///
  /// In en, this message translates to:
  /// **'{v0} readings'**
  String ui8f1a22d54d2c(String v0);

  /// {v0} records, including {v1} waiting to sync. Cloud copies remain unchanged.
  ///
  /// In en, this message translates to:
  /// **'{v0} records, including {v1} waiting to sync. Cloud copies remain unchanged.'**
  String ui21c0f7d95d18(String v0, String v1);

  /// {v0} saved
  ///
  /// In en, this message translates to:
  /// **'{v0} saved'**
  String uib66d8dcb4ef4(String v0);

  /// {v0} source file(s) included in project package
  ///
  /// In en, this message translates to:
  /// **'{v0} source file(s) included in project package'**
  String ui41dbbb7c36bc(String v0);

  /// {v0} unassigned map sites
  ///
  /// In en, this message translates to:
  /// **'{v0} unassigned map sites'**
  String ui763b3b758174(String v0);

  /// {v0} vertices • Tap map to add vertices
  ///
  /// In en, this message translates to:
  /// **'{v0} vertices • Tap map to add vertices'**
  String uibbb4b809c6ba(String v0);

  /// {v0} — copy complete code
  ///
  /// In en, this message translates to:
  /// **'{v0} — copy complete code'**
  String uiaa45b4005be5(String v0);

  /// {v0} • Survey record {v1}
  ///
  /// In en, this message translates to:
  /// **'{v0} • Survey record {v1}'**
  String ui2255f673779e(String v0, String v1);

  /// {v0} • version {v1}
  ///
  /// In en, this message translates to:
  /// **'{v0} • version {v1}'**
  String ui1c1707c84f0d(String v0, String v1);

  /// {v0} • {v1} questionnaires
  ///
  /// In en, this message translates to:
  /// **'{v0} • {v1} questionnaires'**
  String uie09431d672e4(String v0, String v1);

  /// {v0}. Your last saved draft is preserved.
  ///
  /// In en, this message translates to:
  /// **'{v0}. Your last saved draft is preserved.'**
  String ui89f846bf7eed(String v0);

  /// {v0}/{v1} photos
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1} photos'**
  String ui13d9100a93a2(String v0, String v1);

  /// {v0}: enter a valid {v1}
  ///
  /// In en, this message translates to:
  /// **'{v0}: enter a valid {v1}'**
  String uic7c34d515c8f(String v0, String v1);

  /// {v0}: {v1} vertices. Tap map to add vertices.
  ///
  /// In en, this message translates to:
  /// **'{v0}: {v1} vertices. Tap map to add vertices.'**
  String uib0b6457093f6(String v0, String v1);

  /// "{v0}" (version {v1}) is already on this device.
  ///
  /// In en, this message translates to:
  /// **'\"{v0}\" (version {v1}) is already on this device.'**
  String ui55cedac6145e(String v0, String v1);

  /// "{v0}" (version {v1}).
  ///
  /// This code carries project information only. Ask the sender for the project file (.mbproj) or an import QR code to add it to this phone.
  ///
  /// In en, this message translates to:
  /// **'\"{v0}\" (version {v1}).\n\nThis code carries project information only. Ask the sender for the project file (.mbproj) or an import QR code to add it to this phone.'**
  String ui98df2bcb058d(String v0, String v1);

  /// A backup from a previous MapBanai install was found. Restore settings and survey responses?
  ///
  /// In en, this message translates to:
  /// **'A backup from a previous MapBanai install was found. Restore settings and survey responses?'**
  String get ui0c158c664316;

  /// Archive "{v0}"? It will be hidden from project setup. Its data is kept and can be restored later.
  ///
  /// In en, this message translates to:
  /// **'Archive \"{v0}\"? It will be hidden from project setup. Its data is kept and can be restored later.'**
  String ui14aec94c06c0(String v0);

  /// Choose an export option above — the file will be shared or saved where you want it.
  ///
  /// In en, this message translates to:
  /// **'Choose an export option above — the file will be shared or saved where you want it.'**
  String get uid11a9f1a48ea;

  /// Connect this project to a Google Apps Script Web App for background sync.
  ///
  /// In en, this message translates to:
  /// **'Connect this project to a Google Apps Script Web App for background sync.'**
  String get ui460b96b24627;

  /// Current accuracy ({v0}) is worse than the configured threshold ({v1}). Save anyway?
  ///
  /// In en, this message translates to:
  /// **'Current accuracy ({v0}) is worse than the configured threshold ({v1}). Save anyway?'**
  String ui745bc847aafd(String v0, String v1);

  /// Default max acceptable accuracy used when recording points in this project.
  ///
  /// In en, this message translates to:
  /// **'Default max acceptable accuracy used when recording points in this project.'**
  String get uic3651ce80dea;

  /// Delete "{v0}" and all its survey responses and GIS features? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{v0}\" and all its survey responses and GIS features? This cannot be undone.'**
  String ui6e54655f0424(String v0);

  /// Delete "{v0}"? This cannot be undone.{v1}
  ///
  /// In en, this message translates to:
  /// **'Delete \"{v0}\"? This cannot be undone.{v1}'**
  String ui576e9079ff22(String v0, String v1);

  /// Download failed. Please check your connection and try again.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please check your connection and try again.'**
  String get ui4babe44dc2a9;

  /// Enter your name — it will be attached to every survey response, GPS log entry and export. You can change it later in the three-bar menu → My name.
  ///
  /// In en, this message translates to:
  /// **'Enter your name — it will be attached to every survey response, GPS log entry and export. You can change it later in the three-bar menu → My name.'**
  String get uie99acc1c25e6;

  /// Every photo must contain GPS coordinates. Stay at the photo location until GPS is confirmed. Gallery photos keep their existing GPS when valid.
  ///
  /// In en, this message translates to:
  /// **'Every photo must contain GPS coordinates. Stay at the photo location until GPS is confirmed. Gallery photos keep their existing GPS when valid.'**
  String get ui4d6aba3a7042;

  /// GPS fix ready · ±{v0} m — photo will be geotagged
  ///
  /// In en, this message translates to:
  /// **'GPS fix ready · ±{v0} m — photo will be geotagged'**
  String ui5413a24d990a(String v0);

  /// Line  •  {v0} vertices  •  {v1}
  ///
  /// In en, this message translates to:
  /// **'Line  •  {v0} vertices  •  {v1}'**
  String ui60064654441d(String v0, String v1);

  /// Need at least {v0} vertices to finish ({v1} collected)
  ///
  /// In en, this message translates to:
  /// **'Need at least {v0} vertices to finish ({v1} collected)'**
  String ui4e046e2d5e0a(String v0, String v1);

  /// No logs yet. Create one to record coordinates, time, elevation and accuracy into a CSV file.
  ///
  /// In en, this message translates to:
  /// **'No logs yet. Create one to record coordinates, time, elevation and accuracy into a CSV file.'**
  String get ui8150b88a8de7;

  /// No projects yet — open Project Settings on Home to create one, or use Import Project to import a .mbproj file
  ///
  /// In en, this message translates to:
  /// **'No projects yet — open Project Settings on Home to create one, or use Import Project to import a .mbproj file'**
  String get ui2b0631b176cd;

  /// No projects yet — open Project Settings to create one, or use Import Project to import a .mbproj file
  ///
  /// In en, this message translates to:
  /// **'No projects yet — open Project Settings to create one, or use Import Project to import a .mbproj file'**
  String get uib9f28dea1644;

  /// One questionnaire supplies Survey, GIS and Study Area questions. You can create a form, edit it, or import an XLSForm (.xlsx) file.
  ///
  /// In en, this message translates to:
  /// **'One questionnaire supplies Survey, GIS and Study Area questions. You can create a form, edit it, or import an XLSForm (.xlsx) file.'**
  String get ui21e3b0114215;

  /// Online project links are not supported yet. Ask the sender for the project file (.mbproj) or a project QR code.
  ///
  /// In en, this message translates to:
  /// **'Online project links are not supported yet. Ask the sender for the project file (.mbproj) or a project QR code.'**
  String get ui587e48c342b7;

  /// Open the device settings and enable "Allow from this source", then tap Download & Install again.
  ///
  /// In en, this message translates to:
  /// **'Open the device settings and enable \"Allow from this source\", then tap Download & Install again.'**
  String get ui771de57db095;

  /// Paste this code into MapBanai → Import → Paste project code:
  ///
  /// In en, this message translates to:
  /// **'Paste this code into MapBanai → Import → Paste project code:'**
  String get uif29d53eb9d2b;

  /// Point
  /// {v0}, {v1}{v2}
  ///
  /// In en, this message translates to:
  /// **'Point\n{v0}, {v1}{v2}'**
  String uia490dc30efac(String v0, String v1, String v2);

  /// Point saves the current fix once with a note; continuous recording below drives line/track logging.
  ///
  /// In en, this message translates to:
  /// **'Point saves the current fix once with a note; continuous recording below drives line/track logging.'**
  String get uib3b06ed785b2;

  /// Polygon  •  {v0} vertices
  /// area: {v1}  •  perimeter: {v2}
  ///
  /// In en, this message translates to:
  /// **'Polygon  •  {v0} vertices\narea: {v1}  •  perimeter: {v2}'**
  String ui2181a49983f5(String v0, String v1, String v2);

  /// Project invite received. Open the .mbproj file in MapBanai to import it.
  ///
  /// In en, this message translates to:
  /// **'Project invite received. Open the .mbproj file in MapBanai to import it.'**
  String get ui793e65ec7509;

  /// Scan or paste this code on another phone to import this project.
  ///
  /// In en, this message translates to:
  /// **'Scan or paste this code on another phone to import this project.'**
  String get uib8a8c7d48bb2;

  /// Set a user name in Settings first — it is required to confirm a data reset.
  ///
  /// In en, this message translates to:
  /// **'Set a user name in Settings first — it is required to confirm a data reset.'**
  String get uie4fce3e26420;

  /// Share a full project with responses, a project setup without responses, or only saved responses. Project packages include GIS files, forms, settings, web URL and API key by default.
  ///
  /// In en, this message translates to:
  /// **'Share a full project with responses, a project setup without responses, or only saved responses. Project packages include GIS files, forms, settings, web URL and API key by default.'**
  String get ui2e3341bacb66;

  /// Share the project file instead; this code lets the receiving phone confirm it got the right project.
  ///
  /// In en, this message translates to:
  /// **'Share the project file instead; this code lets the receiving phone confirm it got the right project.'**
  String get ui7a263d9455ed;

  /// Slow on mobile data? Open in browser to use your phone’s browser download, then open the downloaded APK to install.
  ///
  /// In en, this message translates to:
  /// **'Slow on mobile data? Open in browser to use your phone’s browser download, then open the downloaded APK to install.'**
  String get ui33a5e91c7ff1;

  /// The matching DBF attribute file is not accessible. Choose the folder containing the SHP, DBF, SHX, PRJ and CPG files, or import geometry only. You can also select those files together.
  ///
  /// In en, this message translates to:
  /// **'The matching DBF attribute file is not accessible. Choose the folder containing the SHP, DBF, SHX, PRJ and CPG files, or import geometry only. You can also select those files together.'**
  String get ui71529ccaf336;

  /// This permanently deletes all projects, survey responses, stored forms and GPS logs. Type your user name exactly as shown to confirm:
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all projects, survey responses, stored forms and GPS logs. Type your user name exactly as shown to confirm:'**
  String get ui7e91262eef11;

  /// You can add it as a new copy, or replace the existing project. Replacing deletes the current project and everything collected in it.
  ///
  /// In en, this message translates to:
  /// **'You can add it as a new copy, or replace the existing project. Replacing deletes the current project and everything collected in it.'**
  String get ui2ebc6f4e9cc1;

  /// {v0}
  ///
  /// {v1} history records will be deleted, including {v2} waiting to sync.
  /// {v3}{v4}
  /// This cannot be undone. Copies already uploaded to the cloud remain there.
  ///
  /// In en, this message translates to:
  /// **'{v0}\n\n{v1} history records will be deleted, including {v2} waiting to sync.\n{v3}{v4}\nThis cannot be undone. Copies already uploaded to the cloud remain there.'**
  String uic2f438460953(String v0, String v1, String v2, String v3, String v4);

  /// {v0} / {v1}
  ///
  /// Remove all {v2} map points? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'{v0} / {v1}\n\nRemove all {v2} map points? This cannot be undone.'**
  String ui1881010a6775(String v0, String v1, String v2);

  /// {v0} readings{v1}{v2}
  ///
  /// In en, this message translates to:
  /// **'{v0} readings{v1}{v2}'**
  String ui6090069a7609(String v0, String v1, String v2);

  /// {v0} · {v1}
  /// Zoom {v2}–{v3}
  /// {v4}
  ///
  /// In en, this message translates to:
  /// **'{v0} · {v1}\nZoom {v2}–{v3}\n{v4}'**
  String ui42346e017b40(String v0, String v1, String v2, String v3, String v4);

  /// {v0}{v1} details
  ///
  /// In en, this message translates to:
  /// **'{v0}{v1} details'**
  String ui8bba0bdb8c5f(String v0, String v1);

  ///
  /// Includes {v0} other records linked to the same removed points.
  ///
  ///
  /// In en, this message translates to:
  /// **'\nIncludes {v0} other records linked to the same removed points.\n'**
  String ui7b693d8137e8(String v0);

  ///  and {v0} map points
  ///
  /// In en, this message translates to:
  /// **' and {v0} map points'**
  String uid8c8c3da6665(String v0);

  /// 1. Create a new project in MapBanai. Open Project Details or Help and copy its project ID (the long UUID).
  /// 2. Create a fresh Google spreadsheet for this project, or open your XLSForm .xlsx in Google Sheets. Keep the exact questionnaire tab names: survey, choices, settings.
  /// 3. Keep the XLSForm header row. Common survey columns: type, name, label, required, relevant, constraint, constraint_message, calculation. Choice columns: list_name, name, label. Settings: form_title, form_id, version.
  /// 4. You do not need to create data tabs or a photo folder. The setup script creates responses, features, photos, revisions and a private Drive photo folder automatically.
  /// 5. Use a fresh spreadsheet and script for each new project. For the recommended single-spreadsheet setup, you do not need to copy spreadsheet IDs.
  ///
  /// In en, this message translates to:
  /// **'1. Create a new project in MapBanai. Open Project Details or Help and copy its project ID (the long UUID).\n2. Create a fresh Google spreadsheet for this project, or open your XLSForm .xlsx in Google Sheets. Keep the exact questionnaire tab names: survey, choices, settings.\n3. Keep the XLSForm header row. Common survey columns: type, name, label, required, relevant, constraint, constraint_message, calculation. Choice columns: list_name, name, label. Settings: form_title, form_id, version.\n4. You do not need to create data tabs or a photo folder. The setup script creates responses, features, photos, revisions and a private Drive photo folder automatically.\n5. Use a fresh spreadsheet and script for each new project. For the recommended single-spreadsheet setup, you do not need to copy spreadsheet IDs.'**
  String get ui54c0efcf9fc5;

  /// 1. From your new Google spreadsheet, open Extensions → Apps Script. This connects the script to that spreadsheet; this is what “bound workbook” means.
  /// 2. Copy the complete Code.gs below into the editor. Add two HTML files named Map and Charts, then paste the matching HTML files below.
  /// 3. At the top of Code.gs, replace only PASTE_PROJECT_ID_FROM_MAPBANAI with the project ID you copied. Keep the quotation marks. Leave questionnaireSheetId, dataSheetId, apiKey and photoFolderId at their placeholder values.
  /// 4. Save. Select setupMapBanai in the function dropdown and click Run. Authorize spreadsheet and Drive access with your manager account. It uses this spreadsheet for both questions and collected data, generates a private API key, creates a photo folder and creates the data tabs.
  /// 5. Reload your spreadsheet. Open MapBanai → Connection and setup guide and copy the API key. You can also find MAPBANAI_API_KEY in Apps Script → Project Settings → Script properties. This is a MapBanai password; you do not need Google Cloud API credentials.
  /// 6. In Apps Script, choose Deploy → New deployment → Web app. Set Execute as: Me and Who has access: Anyone. Click Deploy, authorize if asked, and copy the Web app URL ending /exec. Copy the full URL, not the editor address. If Anyone is unavailable, ask your Google Workspace administrator.
  /// 7. In MapBanai Project Details → Cloud Sync, paste the URL and API key. Tap Save, then Test Connection. This verifies the project ID, key and data-sheet access without sending records.
  /// 8. Open Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. Collect one test response, sync from Home and check the spreadsheet. Edit the response and sync again to verify revision history.
  /// 9. Export the project with Include sync connection for your trusted field team. Enumerators import it and set My name in the Home three-bar menu. Repeat this fresh setup for each new project.
  ///
  /// In en, this message translates to:
  /// **'1. From your new Google spreadsheet, open Extensions → Apps Script. This connects the script to that spreadsheet; this is what “bound workbook” means.\n2. Copy the complete Code.gs below into the editor. Add two HTML files named Map and Charts, then paste the matching HTML files below.\n3. At the top of Code.gs, replace only PASTE_PROJECT_ID_FROM_MAPBANAI with the project ID you copied. Keep the quotation marks. Leave questionnaireSheetId, dataSheetId, apiKey and photoFolderId at their placeholder values.\n4. Save. Select setupMapBanai in the function dropdown and click Run. Authorize spreadsheet and Drive access with your manager account. It uses this spreadsheet for both questions and collected data, generates a private API key, creates a photo folder and creates the data tabs.\n5. Reload your spreadsheet. Open MapBanai → Connection and setup guide and copy the API key. You can also find MAPBANAI_API_KEY in Apps Script → Project Settings → Script properties. This is a MapBanai password; you do not need Google Cloud API credentials.\n6. In Apps Script, choose Deploy → New deployment → Web app. Set Execute as: Me and Who has access: Anyone. Click Deploy, authorize if asked, and copy the Web app URL ending /exec. Copy the full URL, not the editor address. If Anyone is unavailable, ask your Google Workspace administrator.\n7. In MapBanai Project Details → Cloud Sync, paste the URL and API key. Tap Save, then Test Connection. This verifies the project ID, key and data-sheet access without sending records.\n8. Open Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. Collect one test response, sync from Home and check the spreadsheet. Edit the response and sync again to verify revision history.\n9. Export the project with Include sync connection for your trusted field team. Enumerators import it and set My name in the Home three-bar menu. Repeat this fresh setup for each new project.'**
  String get ui0d72badb9fca;

  /// Acres (ac)
  ///
  /// In en, this message translates to:
  /// **'Acres (ac)'**
  String get ui0daa4f380987;

  /// Atlas stays at Connecting: this is initialization/loading, not the number of sites. Replace the complete matching Map.html and Code.gs, save, close and reopen the atlas from the spreadsheet menu. Read its visible status/error; check Apps Script → Executions if loading takes more than 45 seconds. The manager map loads pinned Leaflet over HTTPS; internet is required.
  ///
  /// Invalid JSON/405: use the deployed /exec web-app URL, not an editor URL or /dev. Check doPost exists and deploy a new script version.
  ///
  /// Wrong project/key: compare the project ID and key in Code.gs with Project Details; Save the settings in the app.
  ///
  /// Permission/setup failure: run setupMapBanai as the owner, check spreadsheet/folder IDs and reserved output-tab headers. Check Apps Script Executions privately for diagnostics.
  ///
  /// Questionnaire errors: verify exact tab/header names, stable form_id and valid XLSForm syntax. Avoid formulas that evaluate differently from the intended XLSForm text; store expressions as plain text.
  ///
  /// Slow/busy uploads: completed batches are preserved. Retry Sync to send the remaining records. A server timeout is reported separately from loss of internet. Google service quotas apply; very large deployments need a dedicated server. A record can contain up to 160,000 JSON characters in this supplied backend.
  ///
  /// Official references: developers.google.com/apps-script/guides/web and developers.google.com/apps-script/reference/spreadsheet/range.
  ///
  /// In en, this message translates to:
  /// **'Atlas stays at Connecting: this is initialization/loading, not the number of sites. Replace the complete matching Map.html and Code.gs, save, close and reopen the atlas from the spreadsheet menu. Read its visible status/error; check Apps Script → Executions if loading takes more than 45 seconds. The manager map loads pinned Leaflet over HTTPS; internet is required.\n\nInvalid JSON/405: use the deployed /exec web-app URL, not an editor URL or /dev. Check doPost exists and deploy a new script version.\n\nWrong project/key: compare the project ID and key in Code.gs with Project Details; Save the settings in the app.\n\nPermission/setup failure: run setupMapBanai as the owner, check spreadsheet/folder IDs and reserved output-tab headers. Check Apps Script Executions privately for diagnostics.\n\nQuestionnaire errors: verify exact tab/header names, stable form_id and valid XLSForm syntax. Avoid formulas that evaluate differently from the intended XLSForm text; store expressions as plain text.\n\nSlow/busy uploads: completed batches are preserved. Retry Sync to send the remaining records. A server timeout is reported separately from loss of internet. Google service quotas apply; very large deployments need a dedicated server. A record can contain up to 160,000 JSON characters in this supplied backend.\n\nOfficial references: developers.google.com/apps-script/guides/web and developers.google.com/apps-script/reference/spreadsheet/range.'**
  String get uid3d9949c92a8;

  /// Automatic
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get uiac9041e76816;

  /// Choose the project and questionnaire, answer the questions, follow required fields and validation messages, then save. Conditional questions follow the XLSForm rules supported by the importer. Review import warnings before fieldwork. Date questions use the date picker. Field quality checks list only saved GPS/photo readings above your selected accuracy review limit. Use Accept accuracy to keep a suitable reading and hide that finding permanently on this device, or View record to inspect it. The limit and decisions are saved per project; Undo restores a just-accepted finding. This does not block photos or alter data. Save drafts to resume incomplete interviews.
  ///
  /// In en, this message translates to:
  /// **'Choose the project and questionnaire, answer the questions, follow required fields and validation messages, then save. Conditional questions follow the XLSForm rules supported by the importer. Review import warnings before fieldwork. Date questions use the date picker. Field quality checks list only saved GPS/photo readings above your selected accuracy review limit. Use Accept accuracy to keep a suitable reading and hide that finding permanently on this device, or View record to inspect it. The limit and decisions are saved per project; Undo restores a just-accepted finding. This does not block photos or alter data. Save drafts to resume incomplete interviews.'**
  String get uie1fb894bb078;

  /// Edit survey/choices/settings cells in Google Sheets. In the app, select the project → Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. New interviews and attribute editors use the new questions. Existing saved records and drafts retain their original form version. Updates require internet; collection remains offline.
  ///
  /// One online XLSForm is served per project by this script; other locally imported forms remain available. Change the displayed label freely, but keep existing question names and form_id stable. Removing/renaming questions can change how historical answers are interpreted. Check warnings and pilot every revised questionnaire before field deployment.
  ///
  /// In en, this message translates to:
  /// **'Edit survey/choices/settings cells in Google Sheets. In the app, select the project → Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. New interviews and attribute editors use the new questions. Existing saved records and drafts retain their original form version. Updates require internet; collection remains offline.\n\nOne online XLSForm is served per project by this script; other locally imported forms remain available. Change the displayed label freely, but keep existing question names and form_id stable. Removing/renaming questions can change how historical answers are interpreted. Check warnings and pilot every revised questionnaire before field deployment.'**
  String get ui58167ff8f947;

  /// Enumerator: collect, correct and sync
  ///
  /// In en, this message translates to:
  /// **'Enumerator: collect, correct and sync'**
  String get ui7514aeee4771;

  /// Feet (ft)
  ///
  /// In en, this message translates to:
  /// **'Feet (ft)'**
  String get ui7d5c63dab944;

  /// GIS Mode: draw and enter attributes
  ///
  /// In en, this message translates to:
  /// **'GIS Mode: draw and enter attributes'**
  String get ui9a35340e0499;

  /// GPS Mode and geotagged photos
  ///
  /// In en, this message translates to:
  /// **'GPS Mode and geotagged photos'**
  String get uid21c6a5da671;

  /// GPS Mode is independent of projects. It provides location diagnostics and recording. Its compass uses orientation sensors relative to magnetic north, with GPS travel bearing explicitly labelled as a fallback; keep the phone flat and calibrate away from metal when prompted. GNSS altitude is an absolute satellite estimate, not height above your building’s ground floor; indoor reception can give unreliable altitude. Check outdoor reception and vertical accuracy where available.
  ///
  /// Photos require a valid location for geotagging. Accuracy is recorded for review but a strict accuracy threshold does not block taking a photo. Allow location and camera permissions, and give the device time to acquire a location.
  ///
  /// In en, this message translates to:
  /// **'GPS Mode is independent of projects. It provides location diagnostics and recording. Its compass uses orientation sensors relative to magnetic north, with GPS travel bearing explicitly labelled as a fallback; keep the phone flat and calibrate away from metal when prompted. GNSS altitude is an absolute satellite estimate, not height above your building’s ground floor; indoor reception can give unreliable altitude. Check outdoor reception and vertical accuracy where available.\n\nPhotos require a valid location for geotagging. Accuracy is recorded for review but a strict accuracy threshold does not block taking a photo. Allow location and camera permissions, and give the device time to acquire a location.'**
  String get uibf3148392176;

  /// Hectares (ha)
  ///
  /// In en, this message translates to:
  /// **'Hectares (ha)'**
  String get ui65e00a1aa4fc;

  /// Import forms, project packages and study maps before leaving connectivity. Prepare offline basemaps where supported; online map tiles need internet. Save field records locally and sync the selected project when connected. Sync sends responses, GIS/study features and photos. Records sync in sequential batches of at most 20. Busy-server responses retry automatically; completed batches remain synced after interruption. Retry sends only remaining records. The supplied backend updates stable record IDs and reuses photo IDs. Saved edits increment response_revision and return to the upload queue. The revisions tab preserves uploaded versions; several offline edits before sync upload only the final version. Deploy the new Code.gs to sync corrections. A conflict stays on the phone for manager review.
  ///
  /// Managers: reload the Google spreadsheet → MapBanai → Map workspace or Charts workspace. Maps use the app’s basemaps, designs, independent fonts, category colours and symbols, editable legends and PNG/JPEG downloads. Manager maps accept multiple GeoJSON or shapefile ZIP overlays. Both map and chart workspaces have Fullscreen, with an expanded Sheets dialog when browser fullscreen is blocked. Charts include aggregation, themes and PNG/JPEG/SVG export. These workspaces require an authenticated manager and are not public links.
  ///
  /// Collected records are stored as full JSON (including geometry and answers) across json_1 to json_4 output columns. Concatenate those columns to reconstruct a record. The photos tab includes readable metadata, embedded thumbnails and Open photo in Drive links. New uploads add previews automatically. For previously synced photos, reload the spreadsheet and choose MapBanai → Refresh photo previews (up to 50 missing previews per run). Files remain private; the spreadsheet shows embedded thumbnails to its viewers. If a preview cannot be created, use its Drive link. This backend is an upload destination; it does not automatically download other enumerators’ records into your phone.
  ///
  /// In en, this message translates to:
  /// **'Import forms, project packages and study maps before leaving connectivity. Prepare offline basemaps where supported; online map tiles need internet. Save field records locally and sync the selected project when connected. Sync sends responses, GIS/study features and photos. Records sync in sequential batches of at most 20. Busy-server responses retry automatically; completed batches remain synced after interruption. Retry sends only remaining records. The supplied backend updates stable record IDs and reuses photo IDs. Saved edits increment response_revision and return to the upload queue. The revisions tab preserves uploaded versions; several offline edits before sync upload only the final version. Deploy the new Code.gs to sync corrections. A conflict stays on the phone for manager review.\n\nManagers: reload the Google spreadsheet → MapBanai → Map workspace or Charts workspace. Maps use the app’s basemaps, designs, independent fonts, category colours and symbols, editable legends and PNG/JPEG downloads. Manager maps accept multiple GeoJSON or shapefile ZIP overlays. Both map and chart workspaces have Fullscreen, with an expanded Sheets dialog when browser fullscreen is blocked. Charts include aggregation, themes and PNG/JPEG/SVG export. These workspaces require an authenticated manager and are not public links.\n\nCollected records are stored as full JSON (including geometry and answers) across json_1 to json_4 output columns. Concatenate those columns to reconstruct a record. The photos tab includes readable metadata, embedded thumbnails and Open photo in Drive links. New uploads add previews automatically. For previously synced photos, reload the spreadsheet and choose MapBanai → Refresh photo previews (up to 50 missing previews per run). Files remain private; the spreadsheet shows embedded thumbnails to its viewers. If a preview cannot be created, use its Drive link. This backend is an upload destination; it does not automatically download other enumerators’ records into your phone.'**
  String get ui2e2fa0ad4e93;

  /// Kilometers (km)
  ///
  /// In en, this message translates to:
  /// **'Kilometers (km)'**
  String get ui6d3be8e36078;

  /// Manager setup: one workbook or two?
  ///
  /// In en, this message translates to:
  /// **'Manager setup: one workbook or two?'**
  String get uif836181704ed;

  /// Manager setup: paste and deploy the script
  ///
  /// In en, this message translates to:
  /// **'Manager setup: paste and deploy the script'**
  String get uie1ca88d502bf;

  /// Manager setup: prepare Google Sheets
  ///
  /// In en, this message translates to:
  /// **'Manager setup: prepare Google Sheets'**
  String get uia120af7937ca;

  /// Manager: create a project, import its XLSForm, select a questionnaire and add study-area maps. Configure the cloud connection if needed. Export/share the project package with “Include sync connection” selected for trusted enumerators.
  ///
  /// Enumerator: Home → three-bar menu → My name. Import the project package and select it. Survey Mode → Sync questionnaire checks for updated questions. Collect offline in Survey Mode, GIS Mode or Visit a study site. Home → three-bar menu → My responses lets you review and edit saved responses. Home → Cloud Sync uploads new records and corrections when connected. Each correction keeps the original collector and stable ID, records the editor and advances the response revision; it is separate from questionnaire version. The same project and questions are used in GIS and Study Area modes. GPS Mode works independently.
  ///
  /// In en, this message translates to:
  /// **'Manager: create a project, import its XLSForm, select a questionnaire and add study-area maps. Configure the cloud connection if needed. Export/share the project package with “Include sync connection” selected for trusted enumerators.\n\nEnumerator: Home → three-bar menu → My name. Import the project package and select it. Survey Mode → Sync questionnaire checks for updated questions. Collect offline in Survey Mode, GIS Mode or Visit a study site. Home → three-bar menu → My responses lets you review and edit saved responses. Home → Cloud Sync uploads new records and corrections when connected. Each correction keeps the original collector and stable ID, records the editor and advances the response revision; it is separate from questionnaire version. The same project and questions are used in GIS and Study Area modes. GPS Mode works independently.'**
  String get ui8762dae21dde;

  /// Meters (m)
  ///
  /// In en, this message translates to:
  /// **'Meters (m)'**
  String get uiaf34806a7287;

  /// Miles (mi)
  ///
  /// In en, this message translates to:
  /// **'Miles (mi)'**
  String get uib0b04ac9caed;

  /// Offline work, cloud sync and photos
  ///
  /// In en, this message translates to:
  /// **'Offline work, cloud sync and photos'**
  String get ui682761a623ce;

  /// Open Project Details → Reusable templates. Save the whole project or its selected layer and questionnaire. From Project Setup → Reusable templates, create a new project from a saved template. Project Details also lets you add template layers to the current project. Templates preserve forms, layer names and setup; they exclude site geometry, visits, photos and cloud keys. New projects and added layers receive fresh identities. Configure the new project’s cloud connection separately. Templates are local and included in database backups. To share with another phone, create a project from the template and export its project package.
  ///
  /// In en, this message translates to:
  /// **'Open Project Details → Reusable templates. Save the whole project or its selected layer and questionnaire. From Project Setup → Reusable templates, create a new project from a saved template. Project Details also lets you add template layers to the current project. Templates preserve forms, layer names and setup; they exclude site geometry, visits, photos and cloud keys. New projects and added layers receive fresh identities. Configure the new project’s cloud connection separately. Templates are local and included in database backups. To share with another phone, create a project from the template and export its project package.'**
  String get uia71aaef663f0;

  /// Open WebMap for the selected project. Use Explore → Colours & categories: choose any text/numeric answer column (such as layer), then Categories for per-value colours and visibility or Graduated for numeric colours. Geometry type is the uniform default. Edit category names, colours and symbols in Download Map. Filter and inspect features, choose a map theme, turn labels on/off, and compose a poster or map-only image with a title and subtitle. Export PNG for clear graphics or JPEG for smaller files. Tap the separate Download Map button to open 12 designs, custom colours, portrait/landscape, aspect ratio and pixel resolution (HD, Full HD, QHD, 4K or custom). Download PNG/JPEG opens the phone file picker; Share PNG/JPEG opens sharing. Basemap tiles must be loaded and exportable; offline/data-only exports may lack the basemap. Rename mapped legend categories, choose point symbols/line patterns/polygon outlines or upload PNG/self-contained SVG icons (up to 512 KB and 2048 pixels per side). Title, subtitle and legend fonts can be chosen independently, with four bundled offline fonts. Text, symbols and north arrow scale with image resolution; choose Standard/Large/Extra large for readability. The map covers over 80% of the exported poster, with a compact title and legend below. Map extent defaults to Fit visible data; choose Current map view to preserve your framing. Coordinates below the title are omitted. Only included basemaps receive attribution; record counts and no-basemap notices are omitted.
  ///
  /// In en, this message translates to:
  /// **'Open WebMap for the selected project. Use Explore → Colours & categories: choose any text/numeric answer column (such as layer), then Categories for per-value colours and visibility or Graduated for numeric colours. Geometry type is the uniform default. Edit category names, colours and symbols in Download Map. Filter and inspect features, choose a map theme, turn labels on/off, and compose a poster or map-only image with a title and subtitle. Export PNG for clear graphics or JPEG for smaller files. Tap the separate Download Map button to open 12 designs, custom colours, portrait/landscape, aspect ratio and pixel resolution (HD, Full HD, QHD, 4K or custom). Download PNG/JPEG opens the phone file picker; Share PNG/JPEG opens sharing. Basemap tiles must be loaded and exportable; offline/data-only exports may lack the basemap. Rename mapped legend categories, choose point symbols/line patterns/polygon outlines or upload PNG/self-contained SVG icons (up to 512 KB and 2048 pixels per side). Title, subtitle and legend fonts can be chosen independently, with four bundled offline fonts. Text, symbols and north arrow scale with image resolution; choose Standard/Large/Extra large for readability. The map covers over 80% of the exported poster, with a compact title and legend below. Map extent defaults to Fit visible data; choose Current map view to preserve your framing. Coordinates below the title are omitted. Only included basemaps receive attribution; record counts and no-basemap notices are omitted.'**
  String get ui78f2a306509a;

  /// Open a study-area feature → Site timeline / add observation, or select a feature in the guided visit screen → Site timeline. Choose Add observation / start visit to record another measurement. Finish each visit separately; earlier answers remain linked to the same stable feature UUID. Choose a questionnaire and numeric question (such as salinity) to compare visits. Keep question names and units consistent. Export all observations as CSV; feature_uuid joins them to study-map GeoJSON. Imported visit history is included and deduplicated with local interviews. Timelines show locally available history; cloud sync does not download other devices’ visits.
  ///
  /// In en, this message translates to:
  /// **'Open a study-area feature → Site timeline / add observation, or select a feature in the guided visit screen → Site timeline. Choose Add observation / start visit to record another measurement. Finish each visit separately; earlier answers remain linked to the same stable feature UUID. Choose a questionnaire and numeric question (such as salinity) to compare visits. Keep question names and units consistent. Export all observations as CSV; feature_uuid joins them to study-map GeoJSON. Imported visit history is included and deduplicated with local interviews. Timelines show locally available history; cloud sync does not download other devices’ visits.'**
  String get ui0f3c63f41614;

  /// Project packages share project definitions, forms and study-layer configuration; they are not a backup of responses or photos. “Include sync connection” is optional and includes the URL and key. Preserve the same project identity across the team; duplicating a project creates a different identity that needs its own backend configuration.
  ///
  /// Use the app backup/export tools for collected data and keep copies outside the phone. Installing an update over the existing signed app preserves local storage; uninstalling or clearing app storage removes local information. Save cloud connection settings before exporting a package.
  ///
  /// In en, this message translates to:
  /// **'Project packages share project definitions, forms and study-layer configuration; they are not a backup of responses or photos. “Include sync connection” is optional and includes the URL and key. Preserve the same project identity across the team; duplicating a project creates a different identity that needs its own backend configuration.\n\nUse the app backup/export tools for collected data and keep copies outside the phone. Installing an update over the existing signed app preserves local storage; uninstalling or clearing app storage removes local information. Save cloud connection settings before exporting a package.'**
  String get ui4452be7b875c;

  /// Recommended: one Google workbook + one Apps Script web app + one private API key per project. Keep questionnaire tabs (survey, choices, settings) and output tabs (responses, features, photos, revisions) in the same workbook. No second URL or key is needed.
  ///
  /// For separate storage, use two workbooks: questionnaireSheetId points to the XLSForm workbook; dataSheetId points to the collected-data workbook. The same script handles both, so the app still uses one URL and key. Two independent deployments/keys are not configured in this version.
  ///
  /// Use a separate setup for each project. Keep questionnaire editing with managers; enumerators only need the MapBanai project package. API keys give access to the project endpoint; share packages containing them only with your field team.
  ///
  /// In en, this message translates to:
  /// **'Recommended: one Google workbook + one Apps Script web app + one private API key per project. Keep questionnaire tabs (survey, choices, settings) and output tabs (responses, features, photos, revisions) in the same workbook. No second URL or key is needed.\n\nFor separate storage, use two workbooks: questionnaireSheetId points to the XLSForm workbook; dataSheetId points to the collected-data workbook. The same script handles both, so the app still uses one URL and key. Two independent deployments/keys are not configured in this version.\n\nUse a separate setup for each project. Keep questionnaire editing with managers; enumerators only need the MapBanai project package. API keys give access to the project endpoint; share packages containing them only with your field team.'**
  String get ui48f8d1dd5266;

  /// Reference vector layers and backgrounds
  ///
  /// In en, this message translates to:
  /// **'Reference vector layers and backgrounds'**
  String get uifd76b27cda7d;

  /// Repeated observations and site timelines
  ///
  /// In en, this message translates to:
  /// **'Repeated observations and site timelines'**
  String get ui12432a3ccda1;

  /// Reusable project and layer templates
  ///
  /// In en, this message translates to:
  /// **'Reusable project and layer templates'**
  String get ui6cb726ab7ebc;

  /// Select the project and one of its study-area maps. Import from the top toolbar; GeoJSON and GeoPackage can be selected regardless of Android MIME filtering. ZIP shapefile companions together for attributes. Files opened externally offer an existing project, new project or view-only preview. Add new Layer is inside the study-layer selector; the plus button opens the questionnaire at a fresh GPS position. Edit feature requires a questionnaire for new/Updated features; other statuses have an optional Fill questionnaire checkbox. Skipping keeps previous answers. Categories & colors includes Verification status coloring and starts with a single color and lets you explicitly choose a column, category colors/visibility and point size.  Use separate named maps for salinity rounds, household verification or the full study area. Start/resume a field visit for that selected area. Verify existing sites, record new information or update attributes using the selected questionnaire. Visit history preserves the review trail. Assign old unassigned sites to a project explicitly. Export the updated area after fieldwork.
  ///
  /// In en, this message translates to:
  /// **'Select the project and one of its study-area maps. Import from the top toolbar; GeoJSON and GeoPackage can be selected regardless of Android MIME filtering. ZIP shapefile companions together for attributes. Files opened externally offer an existing project, new project or view-only preview. Add new Layer is inside the study-layer selector; the plus button opens the questionnaire at a fresh GPS position. Edit feature requires a questionnaire for new/Updated features; other statuses have an optional Fill questionnaire checkbox. Skipping keeps previous answers. Categories & colors includes Verification status coloring and starts with a single color and lets you explicitly choose a column, category colors/visibility and point size.  Use separate named maps for salinity rounds, household verification or the full study area. Start/resume a field visit for that selected area. Verify existing sites, record new information or update attributes using the selected questionnaire. Visit history preserves the review trail. Assign old unassigned sites to a project explicitly. Export the updated area after fieldwork.'**
  String get ui1a25286391c7;

  /// Select the project, layer and survey. Add a point, line or polygon, then enter information using the selected survey questions. Existing geometry can be edited and its attributes updated. Define questions in the selected survey form; the separate Project Settings field editor has been removed, while old field values remain stored. Use consistent identifiers to connect a feature with a site or repeat visit. Export spatial data when you need analysis in GIS software.
  ///
  /// In en, this message translates to:
  /// **'Select the project, layer and survey. Add a point, line or polygon, then enter information using the selected survey questions. Existing geometry can be edited and its attributes updated. Define questions in the selected survey form; the separate Project Settings field editor has been removed, while old field values remain stored. Use consistent identifiers to connect a feature with a site or repeat visit. Export spatial data when you need analysis in GIS software.'**
  String get ui3ba9b97177d2;

  /// Sharing, backups and app updates
  ///
  /// In en, this message translates to:
  /// **'Sharing, backups and app updates'**
  String get uicba2a97abd4c;

  /// Square feet (ft²)
  ///
  /// In en, this message translates to:
  /// **'Square feet (ft²)'**
  String get ui1cc6418b3dc4;

  /// Square kilometers (km²)
  ///
  /// In en, this message translates to:
  /// **'Square kilometers (km²)'**
  String get ui397fb00a21fd;

  /// Square meters (m²)
  ///
  /// In en, this message translates to:
  /// **'Square meters (m²)'**
  String get ui65e207ca8636;

  /// Study Area Mode: visits and repeated campaigns
  ///
  /// In en, this message translates to:
  /// **'Study Area Mode: visits and repeated campaigns'**
  String get ui35e941e250ac;

  /// Study Area points will stay on the map.
  ///
  ///
  /// In en, this message translates to:
  /// **'Study Area points will stay on the map.\n'**
  String get uicf8de9900977;

  /// Survey Mode and field quality checks
  ///
  /// In en, this message translates to:
  /// **'Survey Mode and field quality checks'**
  String get ui1cfa4ca96cef;

  /// Tap the map to choose a location
  ///
  /// In en, this message translates to:
  /// **'Tap the map to choose a location'**
  String get ui55cabd86f046;

  /// Tap the map to move this point
  ///
  /// In en, this message translates to:
  /// **'Tap the map to move this point'**
  String get ui38a1e2db198c;

  /// This project ID: {v0}
  ///
  /// In en, this message translates to:
  /// **'This project ID: {v0}'**
  String ui9fd1493c60ac(String v0);

  /// Troubleshooting cloud setup
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting cloud setup'**
  String get uia3ce2bacb32e;

  /// Updating questionnaires online
  ///
  /// In en, this message translates to:
  /// **'Updating questionnaires online'**
  String get ui693379c73728;

  /// Use GPS position
  ///
  /// In en, this message translates to:
  /// **'Use GPS position'**
  String get ui0a045ba7552d;

  /// WebMap → Layers → Add vector layers. Select multiple shapefile ZIP bundles, or each .shp together with its .dbf/.shx/.prj/.cpg files. GeoJSON FeatureCollections are supported. Reproject layers to WGS84 (EPSG:4326) before importing; missing .prj assumes WGS84. Choose visibility, colour and opacity for each project layer. Reference layers are separate from collected observations, persist locally and travel in project packages and shared HTML maps. Use Explore → Background map to select Street, Imagery, Topographic, Humanitarian, Cycling or No background. Visible vector layers appear in image exports. Import supports up to 64 MB and 50,000 reference features per project.
  ///
  /// In en, this message translates to:
  /// **'WebMap → Layers → Add vector layers. Select multiple shapefile ZIP bundles, or each .shp together with its .dbf/.shx/.prj/.cpg files. GeoJSON FeatureCollections are supported. Reproject layers to WGS84 (EPSG:4326) before importing; missing .prj assumes WGS84. Choose visibility, colour and opacity for each project layer. Reference layers are separate from collected observations, persist locally and travel in project packages and shared HTML maps. Use Explore → Background map to select Street, Imagery, Topographic, Humanitarian, Cycling or No background. Visible vector layers appear in image exports. Import supports up to 64 MB and 50,000 reference features per project.'**
  String get uif202ba19ecbc;

  /// WebMap, map styling and images
  ///
  /// In en, this message translates to:
  /// **'WebMap, map styling and images'**
  String get ui18f2b9281b8e;

  /// completed
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get ui231e564db4cd;

  /// needsReview
  ///
  /// In en, this message translates to:
  /// **'needsReview'**
  String get uif0f6ea94f6ad;

  /// newFeature
  ///
  /// In en, this message translates to:
  /// **'newFeature'**
  String get ui7e3cbb17832c;

  /// notFound
  ///
  /// In en, this message translates to:
  /// **'notFound'**
  String get uib18d1e57ecc0;

  /// pending
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get uie22586930a5b;

  /// updated
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get ui13a1891af75c;

  /// verified
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get uiec734b651574;

  /// {v0} linked Study Area points will also be removed.
  ///
  ///
  /// In en, this message translates to:
  /// **'{v0} linked Study Area points will also be removed.\n'**
  String ui1a9356ff587e(String v0);

  /// Accuracy
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get ui12a3a4f498b2;

  /// Accuracy check
  ///
  /// In en, this message translates to:
  /// **'Accuracy check'**
  String get ui89ee1223f2e1;

  /// Cancel recording?
  ///
  /// In en, this message translates to:
  /// **'Cancel recording?'**
  String get uib375acb22bce;

  /// Delete feature
  ///
  /// In en, this message translates to:
  /// **'Delete feature'**
  String get ui744d0bab1b52;

  /// Delete log
  ///
  /// In en, this message translates to:
  /// **'Delete log'**
  String get uidff896de7cef;

  /// Dhaka time (GMT+6)
  ///
  /// In en, this message translates to:
  /// **'Dhaka time (GMT+6)'**
  String get uia84949c694a9;

  /// Draft survey — {v0}
  ///
  /// In en, this message translates to:
  /// **'Draft survey — {v0}'**
  String uiec4dd3969fea(String v0);

  /// Drafts
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get ui22a31d86e018;

  /// Elapsed
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get ui5fc97790c6a8;

  /// Feature {v0}
  ///
  /// In en, this message translates to:
  /// **'Feature {v0}'**
  String ui88bbbbe65742(String v0);

  /// GNSS altitude
  ///
  /// In en, this message translates to:
  /// **'GNSS altitude'**
  String get uif5c66da8133d;

  /// GPS log {v0}
  ///
  /// In en, this message translates to:
  /// **'GPS log {v0}'**
  String ui93db01b4b539(String v0);

  /// GeoJSON
  ///
  /// In en, this message translates to:
  /// **'GeoJSON'**
  String get ui97eeda258d4d;

  /// GeoPackage
  ///
  /// In en, this message translates to:
  /// **'GeoPackage'**
  String get ui04b47027708e;

  /// Google Earth / GIS
  ///
  /// In en, this message translates to:
  /// **'Google Earth / GIS'**
  String get uib1ddccafa588;

  /// KML
  ///
  /// In en, this message translates to:
  /// **'KML'**
  String get uic5bd90689147;

  /// MapBanai Study Area export
  ///
  /// In en, this message translates to:
  /// **'MapBanai Study Area export'**
  String get uid2521a9d2adb;

  /// MapBanai WebMap
  ///
  /// In en, this message translates to:
  /// **'MapBanai WebMap'**
  String get ui0c409607d527;

  /// Measurement sites
  ///
  /// In en, this message translates to:
  /// **'Measurement sites'**
  String get ui7dbb0cc1dc12;

  /// New point log
  ///
  /// In en, this message translates to:
  /// **'New point log'**
  String get ui695385e41e56;

  /// Perimeter
  ///
  /// In en, this message translates to:
  /// **'Perimeter'**
  String get ui329d3a41479d;

  /// Project description
  ///
  /// In en, this message translates to:
  /// **'Project description'**
  String get uif9e31cfd1b72;

  /// Record track
  ///
  /// In en, this message translates to:
  /// **'Record track'**
  String get uiaecc2a7055a2;

  /// Rename log
  ///
  /// In en, this message translates to:
  /// **'Rename log'**
  String get uic1ea3d0bd91c;

  /// Round {v0}
  ///
  /// In en, this message translates to:
  /// **'Round {v0}'**
  String uidc4de6540089(String v0);

  /// SQLite + WKB geometry
  ///
  /// In en, this message translates to:
  /// **'SQLite + WKB geometry'**
  String get ui29053fbf93da;

  /// Satellites (in use / in view)
  ///
  /// In en, this message translates to:
  /// **'Satellites (in use / in view)'**
  String get ui5205fe16c422;

  /// Speed
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get ui2d2cb022bc3d;

  /// Survey and map history
  ///
  /// In en, this message translates to:
  /// **'Survey and map history'**
  String get uiaa45b267e05e;

  /// Tabular data with WKT geometry
  ///
  /// In en, this message translates to:
  /// **'Tabular data with WKT geometry'**
  String get uifbea242d37f8;

  /// UTC time (GPS)
  ///
  /// In en, this message translates to:
  /// **'UTC time (GPS)'**
  String get ui998249c59a6e;

  /// Vertices
  ///
  /// In en, this message translates to:
  /// **'Vertices'**
  String get uib3a015034320;

  /// View
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get ui69bd4ef9fbd0;

  /// Web / QGIS
  ///
  /// In en, this message translates to:
  /// **'Web / QGIS'**
  String get ui7f85f35d7ca2;

  /// {v0} — observations
  ///
  /// In en, this message translates to:
  /// **'{v0} — observations'**
  String ui824755f37e73(String v0);

  /// A collection round with this name already exists.
  ///
  /// In en, this message translates to:
  /// **'A collection round with this name already exists.'**
  String get ui0bcc30904efc;

  /// A draft cannot change its linked feature.
  ///
  /// In en, this message translates to:
  /// **'A draft cannot change its linked feature.'**
  String get ui88896e6489d6;

  /// Add a change or review note for this visit outcome.
  ///
  /// In en, this message translates to:
  /// **'Add a change or review note for this visit outcome.'**
  String get ui89c343833e83;

  /// Choose a collection round for this layer.
  ///
  /// In en, this message translates to:
  /// **'Choose a collection round for this layer.'**
  String get ui7da0faaccb67;

  /// Choose a form from this project.
  ///
  /// In en, this message translates to:
  /// **'Choose a form from this project.'**
  String get ui462afc2c8051;

  /// Choose a recurring layer from this project.
  ///
  /// In en, this message translates to:
  /// **'Choose a recurring layer from this project.'**
  String get ui117493d4eef6;

  /// Choose a site from this project and workflow.
  ///
  /// In en, this message translates to:
  /// **'Choose a site from this project and workflow.'**
  String get ui361f7065ffe8;

  /// Choose a visit outcome: verified, updated, not found or needs review.
  ///
  /// In en, this message translates to:
  /// **'Choose a visit outcome: verified, updated, not found or needs review.'**
  String get ui36e876a95151;

  /// Complete and save the selected survey first.
  ///
  /// In en, this message translates to:
  /// **'Complete and save the selected survey first.'**
  String get uic502d96e61cd;

  /// Current feature belongs to another project.
  ///
  /// In en, this message translates to:
  /// **'Current feature belongs to another project.'**
  String get ui2c4d8c966796;

  /// Draft changed while finalizing. Reload it.
  ///
  /// In en, this message translates to:
  /// **'Draft changed while finalizing. Reload it.'**
  String get ui1103b1a10bbd;

  /// Draft changed. Reload it before finishing.
  ///
  /// In en, this message translates to:
  /// **'Draft changed. Reload it before finishing.'**
  String get ui03b6c1a0b4ac;

  /// Enter a collection round name.
  ///
  /// In en, this message translates to:
  /// **'Enter a collection round name.'**
  String get uibe390c0ef7b4;

  /// Enter a layer name
  ///
  /// In en, this message translates to:
  /// **'Enter a layer name'**
  String get uif7299773137e;

  /// Enter a layer name.
  ///
  /// In en, this message translates to:
  /// **'Enter a layer name.'**
  String get ui4a355a1939ef;

  /// Feature geometry is missing or invalid.
  ///
  /// In en, this message translates to:
  /// **'Feature geometry is missing or invalid.'**
  String get uiebf870d13fa8;

  /// Feature was removed. Restore or review the study map before applying this visit.
  ///
  /// In en, this message translates to:
  /// **'Feature was removed. Restore or review the study map before applying this visit.'**
  String get ui8bc3895df8c2;

  /// Form does not belong to this project
  ///
  /// In en, this message translates to:
  /// **'Form does not belong to this project'**
  String get ui1761acebd70a;

  /// Invalid collection status.
  ///
  /// In en, this message translates to:
  /// **'Invalid collection status.'**
  String get uiba63f7620f2b;

  /// Map changed again during review. Reload and compare the versions.
  ///
  /// In en, this message translates to:
  /// **'Map changed again during review. Reload and compare the versions.'**
  String get ui86fa10d3afc9;

  /// No saved measurements with point locations match this selection.
  ///
  /// In en, this message translates to:
  /// **'No saved measurements with point locations match this selection.'**
  String get ui5877c7c71c31;

  /// Only a saved pending visit can be rebased.
  ///
  /// In en, this message translates to:
  /// **'Only a saved pending visit can be rebased.'**
  String get ui1bd927bf4b76;

  /// Only saved visits can reconcile the map.
  ///
  /// In en, this message translates to:
  /// **'Only saved visits can reconcile the map.'**
  String get ui5076a1f7ffb8;

  /// Open Study Area from Home and select Field Verification, Recurring Collection or Study Area Visits. Choose the project, site layer and questionnaire. Assign each uploaded layer to its workflows in Project layers. Field Verification updates baseline features; tap a site and its questionnaire button to start or resume a guided visit. Recurring Collection uses a Collection round with a name, optional period/season and date. Each round keeps independent collected, not collected and needs review states. To build recurring sites from first measurements, choose Create layer from responses, then the source questionnaire and numeric measurement. Original responses remain intact. Study Area Visits supports quick done, undone and review states with optional questionnaires. Open Google Maps from the selected site for external navigation. Timelines preserve previous observations. Uploaded site names and attributes remain as supplied; choose a bilingual XLSForm to translate questionnaire labels.
  ///
  /// In en, this message translates to:
  /// **'Open Study Area from Home and select Field Verification, Recurring Collection or Study Area Visits. Choose the project, site layer and questionnaire. Assign each uploaded layer to its workflows in Project layers. Field Verification updates baseline features; tap a site and its questionnaire button to start or resume a guided visit. Recurring Collection uses a Collection round with a name, optional period/season and date. Each round keeps independent collected, not collected and needs review states. To build recurring sites from first measurements, choose Create layer from responses, then the source questionnaire and numeric measurement. Original responses remain intact. Study Area Visits supports quick done, undone and review states with optional questionnaires. Open Google Maps from the selected site for external navigation. Timelines preserve previous observations. Uploaded site names and attributes remain as supplied; choose a bilingual XLSForm to translate questionnaire labels.'**
  String get uice44f8239f96;

  /// Project no longer exists
  ///
  /// In en, this message translates to:
  /// **'Project no longer exists'**
  String get uicbcd0cfd27d2;

  /// Project no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Project no longer exists.'**
  String get ui325826737355;

  /// Project packages share definitions, questionnaires, layers and setup. Select Include collected responses and photos when those records should travel too; a setup-only package is not a backup of collected data. Include sync connection adds the URL and API key for trusted field teams. Keep the same project identity across the team. Creating a new copy gives it a separate identity and backend setup.
  ///
  /// Keep backups outside the phone. Installing an update over the same signed app preserves local storage; uninstalling or clearing app storage removes local data. Save cloud connection settings before exporting.
  ///
  /// In en, this message translates to:
  /// **'Project packages share definitions, questionnaires, layers and setup. Select Include collected responses and photos when those records should travel too; a setup-only package is not a backup of collected data. Include sync connection adds the URL and API key for trusted field teams. Keep the same project identity across the team. Creating a new copy gives it a separate identity and backend setup.\n\nKeep backups outside the phone. Installing an update over the same signed app preserves local storage; uninstalling or clearing app storage removes local data. Save cloud connection settings before exporting.'**
  String get uib71084f5010f;

  /// Save the selected questionnaire to complete this collection.
  ///
  /// In en, this message translates to:
  /// **'Save the selected questionnaire to complete this collection.'**
  String get uie6e161cc9336;

  /// Select a numeric measurement from this questionnaire.
  ///
  /// In en, this message translates to:
  /// **'Select a numeric measurement from this questionnaire.'**
  String get ui3dc7df584218;

  /// Select a questionnaire and measurement.
  ///
  /// In en, this message translates to:
  /// **'Select a questionnaire and measurement.'**
  String get ui36e792741f9f;

  /// Select a questionnaire from this project.
  ///
  /// In en, this message translates to:
  /// **'Select a questionnaire from this project.'**
  String get ui0808b5a3481d;

  /// Study layer does not belong to this project
  ///
  /// In en, this message translates to:
  /// **'Study layer does not belong to this project'**
  String get ui24607fcc859f;

  /// This collection round belongs to another layer.
  ///
  /// In en, this message translates to:
  /// **'This collection round belongs to another layer.'**
  String get ui01f762c7c32b;

  /// This draft changed in another screen. Reload before saving.
  ///
  /// In en, this message translates to:
  /// **'This draft changed in another screen. Reload before saving.'**
  String get uib7287c8bc71b;

  /// This draft changed. Reopen it before saving.
  ///
  /// In en, this message translates to:
  /// **'This draft changed. Reopen it before saving.'**
  String get ui937151b52477;

  /// This feature belongs to a different project.
  ///
  /// In en, this message translates to:
  /// **'This feature belongs to a different project.'**
  String get ui2c9f263743c4;

  /// This visit is already finalized. Reload its saved record.
  ///
  /// In en, this message translates to:
  /// **'This visit is already finalized. Reload its saved record.'**
  String get ui547bca6d008d;

  /// Visit changed during review. Reload it.
  ///
  /// In en, this message translates to:
  /// **'Visit changed during review. Reload it.'**
  String get ui5f30a4c4489e;

  /// Visit does not exist.
  ///
  /// In en, this message translates to:
  /// **'Visit does not exist.'**
  String get ui85f5c6c2edf4;

  /// Visit draft no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Visit draft no longer exists.'**
  String get uieda6aa29be81;

  /// Visit was deleted.
  ///
  /// In en, this message translates to:
  /// **'Visit was deleted.'**
  String get ui0aabe5893a27;

  /// 16:10 · Laptop
  ///
  /// In en, this message translates to:
  /// **'16:10 · Laptop'**
  String get ui6ecd86a8f125;

  /// 16:9 · Wallpaper
  ///
  /// In en, this message translates to:
  /// **'16:9 · Wallpaper'**
  String get uif05d6690fa2d;

  /// 1:1 · Square
  ///
  /// In en, this message translates to:
  /// **'1:1 · Square'**
  String get uia57dc941dcd3;

  /// 21:9 · Ultrawide
  ///
  /// In en, this message translates to:
  /// **'21:9 · Ultrawide'**
  String get uib4381bea81cf;

  /// 3:2 · Photo
  ///
  /// In en, this message translates to:
  /// **'3:2 · Photo'**
  String get ui2823d71dd313;

  /// 4:3 · Classic
  ///
  /// In en, this message translates to:
  /// **'4:3 · Classic'**
  String get ui4bfeadd27478;

  /// All forms / types
  ///
  /// In en, this message translates to:
  /// **'All forms / types'**
  String get uidd24b455a6e9;

  /// All statuses
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get ui6405179d241b;

  /// Areas
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get ui14ce09a8dd4e;

  /// Aspect ratio
  ///
  /// In en, this message translates to:
  /// **'Aspect ratio'**
  String get ui4e077cf8bf92;

  /// Attribute table
  ///
  /// In en, this message translates to:
  /// **'Attribute table'**
  String get ui9bffcb9f06c2;

  /// Background
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get ui64dd60fe1a04;

  /// Background map
  ///
  /// In en, this message translates to:
  /// **'Background map'**
  String get uid0d92ae1cf5e;

  /// Basemap colour treatment
  ///
  /// In en, this message translates to:
  /// **'Basemap colour treatment'**
  String get ui601cd5a75b27;

  /// Black & white
  ///
  /// In en, this message translates to:
  /// **'Black & white'**
  String get ui019728575b52;

  /// Blueprint
  ///
  /// In en, this message translates to:
  /// **'Blueprint'**
  String get ui06992d2c6a4f;

  /// Caption alignment
  ///
  /// In en, this message translates to:
  /// **'Caption alignment'**
  String get ui76d1fadb362e;

  /// Categories · column values
  ///
  /// In en, this message translates to:
  /// **'Categories · column values'**
  String get uia1e4a4404fb7;

  /// Centre
  ///
  /// In en, this message translates to:
  /// **'Centre'**
  String get ui16e5447a8046;

  /// Choose a design and image size. Pan or zoom the map before downloading.
  ///
  /// In en, this message translates to:
  /// **'Choose a design and image size. Pan or zoom the map before downloading.'**
  String get ui253444ab88a5;

  /// Classic serif
  ///
  /// In en, this message translates to:
  /// **'Classic serif'**
  String get ui219c06043a26;

  /// Close Download Map
  ///
  /// In en, this message translates to:
  /// **'Close Download Map'**
  String get ui0f8dabf7dc77;

  /// Coastal blue
  ///
  /// In en, this message translates to:
  /// **'Coastal blue'**
  String get ui0c4b831492a5;

  /// Collections
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get ui4bbb632f02fd;

  /// Collector
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get uie3199d24849e;

  /// Colour by
  ///
  /// In en, this message translates to:
  /// **'Colour by'**
  String get ui653bfaa2a80f;

  /// Colour shows site status
  ///
  /// In en, this message translates to:
  /// **'Colour shows site status'**
  String get ui02dabdeefe20;

  /// Colours & categories
  ///
  /// In en, this message translates to:
  /// **'Colours & categories'**
  String get ui8d30cc74f67e;

  /// Current basemap
  ///
  /// In en, this message translates to:
  /// **'Current basemap'**
  String get ui8b8025fc854d;

  /// Current map view
  ///
  /// In en, this message translates to:
  /// **'Current map view'**
  String get uie11f3a510f6a;

  /// Custom colours
  ///
  /// In en, this message translates to:
  /// **'Custom colours'**
  String get ui134d207372fc;

  /// Custom dimensions
  ///
  /// In en, this message translates to:
  /// **'Custom dimensions'**
  String get ui915add28af82;

  /// Data only
  ///
  /// In en, this message translates to:
  /// **'Data only'**
  String get uic646cf24f147;

  /// Desert sand
  ///
  /// In en, this message translates to:
  /// **'Desert sand'**
  String get ui160e0e54c6f5;

  /// Download JPEG
  ///
  /// In en, this message translates to:
  /// **'Download JPEG'**
  String get uiaa30393c7650;

  /// Download PNG
  ///
  /// In en, this message translates to:
  /// **'Download PNG'**
  String get ui0c8309d1f4d0;

  /// Download ready
  ///
  /// In en, this message translates to:
  /// **'Download ready'**
  String get ui6dc7d6db796a;

  /// Everyone
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get uic756f6af1f03;

  /// Explore
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get uib965ae66fcc4;

  /// Explore your field data
  ///
  /// In en, this message translates to:
  /// **'Explore your field data'**
  String get uie1a3f6c998b3;

  /// Exporting…
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get ui583cccdcd165;

  /// Extra large
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get ui05128f46d8c8;

  /// Feature labels
  ///
  /// In en, this message translates to:
  /// **'Feature labels'**
  String get uicbb7a61052e1;

  /// Field atlas
  ///
  /// In en, this message translates to:
  /// **'Field atlas'**
  String get ui45b8b762d80d;

  /// Find a site or answer
  ///
  /// In en, this message translates to:
  /// **'Find a site or answer'**
  String get uid509f832e48f;

  /// Fit results
  ///
  /// In en, this message translates to:
  /// **'Fit results'**
  String get uib20486dfffd5;

  /// Fit visible data
  ///
  /// In en, this message translates to:
  /// **'Fit visible data'**
  String get uic7c22ccaf35b;

  /// Forest
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get uif41c4e4dab0b;

  /// From
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get ui3f66052a107e;

  /// Full HD · 1920
  ///
  /// In en, this message translates to:
  /// **'Full HD · 1920'**
  String get ui839e01b3dcb2;

  /// Geometry type
  ///
  /// In en, this message translates to:
  /// **'Geometry type'**
  String get uic5a6470c3d70;

  /// Graduated · numeric values
  ///
  /// In en, this message translates to:
  /// **'Graduated · numeric values'**
  String get ui53b0911438aa;

  /// HD · 1280
  ///
  /// In en, this message translates to:
  /// **'HD · 1280'**
  String get uib1ef9dd05873;

  /// Height (pixels)
  ///
  /// In en, this message translates to:
  /// **'Height (pixels)'**
  String get uif81c3e5ae1c6;

  /// Hide table
  ///
  /// In en, this message translates to:
  /// **'Hide table'**
  String get uif2468877acc4;

  /// Ink on paper
  ///
  /// In en, this message translates to:
  /// **'Ink on paper'**
  String get ui9bcbf7e9ceb7;

  /// Landscape
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get ui7dc4bea61853;

  /// Large
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get ui738fd1d2452f;

  /// Lavender
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get ui75c88f3a0072;

  /// Layout
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get ui972ad8d8a503;

  /// Left
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get ui8ae1c34bd37f;

  /// Legend font
  ///
  /// In en, this message translates to:
  /// **'Legend font'**
  String get uif40b6a07a9d0;

  /// Legend names & symbols
  ///
  /// In en, this message translates to:
  /// **'Legend names & symbols'**
  String get ui5b8fbe24bfd9;

  /// Lines
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get uic6fd3870c86e;

  /// Lobster · script
  ///
  /// In en, this message translates to:
  /// **'Lobster · script'**
  String get ui36360d6d8c2a;

  /// Lora · book serif
  ///
  /// In en, this message translates to:
  /// **'Lora · book serif'**
  String get ui6d14f8cbd660;

  /// Map extent
  ///
  /// In en, this message translates to:
  /// **'Map extent'**
  String get ui304ceba28849;

  /// Map filters
  ///
  /// In en, this message translates to:
  /// **'Map filters'**
  String get uidb1a9c33957d;

  /// Map layers
  ///
  /// In en, this message translates to:
  /// **'Map layers'**
  String get uifdee43176a62;

  /// Map only
  ///
  /// In en, this message translates to:
  /// **'Map only'**
  String get uidf2a2bdfd1ae;

  /// Map poster
  ///
  /// In en, this message translates to:
  /// **'Map poster'**
  String get uia418467db07d;

  /// Map tiles require internet; your data works offline
  ///
  /// In en, this message translates to:
  /// **'Map tiles require internet; your data works offline'**
  String get ui708370785b57;

  /// Map title
  ///
  /// In en, this message translates to:
  /// **'Map title'**
  String get ui889a7e8464fa;

  /// MapBanai · Project Atlas
  ///
  /// In en, this message translates to:
  /// **'MapBanai · Project Atlas'**
  String get ui08a159c05728;

  /// Match design
  ///
  /// In en, this message translates to:
  /// **'Match design'**
  String get ui09ee4407bee8;

  /// Maximum
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get uia8df2fec28d8;

  /// Maximum measurement
  ///
  /// In en, this message translates to:
  /// **'Maximum measurement'**
  String get ui8b4b0b8ee2ca;

  /// Midnight
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get ui558287ddcc35;

  /// Minimum
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get ui5d398eef3ecc;

  /// Minimum measurement
  ///
  /// In en, this message translates to:
  /// **'Minimum measurement'**
  String get ui4a0c5b771fb5;

  /// Modern sans serif
  ///
  /// In en, this message translates to:
  /// **'Modern sans serif'**
  String get ui08b10f41c999;

  /// My location
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get uidef80ab2391e;

  /// Name, ID, salinity…
  ///
  /// In en, this message translates to:
  /// **'Name, ID, salinity…'**
  String get ui9825e8466d49;

  /// Names
  ///
  /// In en, this message translates to:
  /// **'Names'**
  String get ui2b7c08c3ab75;

  /// Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get uibc981983e7f5;

  /// No background
  ///
  /// In en, this message translates to:
  /// **'No background'**
  String get ui416010b25189;

  /// Nunito · rounded
  ///
  /// In en, this message translates to:
  /// **'Nunito · rounded'**
  String get uibd4d569dbbb2;

  /// Off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get uie3de5ab0ca4c;

  /// Orientation
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get ui86e4e3875420;

  /// Original
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get uic0a8060f3b11;

  /// Oswald · condensed
  ///
  /// In en, this message translates to:
  /// **'Oswald · condensed'**
  String get ui7a297fcb17e0;

  /// Paper
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get ui22d507f2ba74;

  /// Points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get ui4b2a6a314956;

  /// Portrait
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get ui92b6b1bf71e0;

  /// Preparing image…
  ///
  /// In en, this message translates to:
  /// **'Preparing image…'**
  String get ui1643936014d7;

  /// Previous
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get ui50f94286ba30;

  /// Project map
  ///
  /// In en, this message translates to:
  /// **'Project map'**
  String get uif842de4b00d7;

  /// Pure monochrome
  ///
  /// In en, this message translates to:
  /// **'Pure monochrome'**
  String get ui30891032b07f;

  /// QHD · 2560
  ///
  /// In en, this message translates to:
  /// **'QHD · 2560'**
  String get ui6f43b588ef53;

  /// Reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get ui44c57abd888a;

  /// Resolution
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get ui516aae52959d;

  /// Right
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get ui954daa8b0033;

  /// Rose quartz
  ///
  /// In en, this message translates to:
  /// **'Rose quartz'**
  String get ui4c7311ae72a1;

  /// Sage & cream
  ///
  /// In en, this message translates to:
  /// **'Sage & cream'**
  String get ui3e2479c4685a;

  /// Share JPEG
  ///
  /// In en, this message translates to:
  /// **'Share JPEG'**
  String get uieb61da0ddb23;

  /// Share PNG
  ///
  /// In en, this message translates to:
  /// **'Share PNG'**
  String get ui69b2ba27ee1a;

  /// Show
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get uid97d1ee339e4;

  /// Show table
  ///
  /// In en, this message translates to:
  /// **'Show table'**
  String get ui445d12dec2a5;

  /// Site status
  ///
  /// In en, this message translates to:
  /// **'Site status'**
  String get ui17480c963f26;

  /// Sites & collections
  ///
  /// In en, this message translates to:
  /// **'Sites & collections'**
  String get ui8684c3cda710;

  /// Soft muted
  ///
  /// In en, this message translates to:
  /// **'Soft muted'**
  String get ui25e0ca14c327;

  /// Standard · scales with resolution
  ///
  /// In en, this message translates to:
  /// **'Standard · scales with resolution'**
  String get ui564186be1ef2;

  /// Study sites
  ///
  /// In en, this message translates to:
  /// **'Study sites'**
  String get ui1f214e692623;

  /// Style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get ui99a0efc6cfd8;

  /// Subtitle
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get uie159d05a124c;

  /// Subtitle font
  ///
  /// In en, this message translates to:
  /// **'Subtitle font'**
  String get ui68731e7bff79;

  /// Survey form / type
  ///
  /// In en, this message translates to:
  /// **'Survey form / type'**
  String get ui54041909beab;

  /// Symbology
  ///
  /// In en, this message translates to:
  /// **'Symbology'**
  String get ui5c55024681cc;

  /// Table
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get ui0424f6e7026f;

  /// Technical mono
  ///
  /// In en, this message translates to:
  /// **'Technical mono'**
  String get uida6453b3fe00;

  /// Terracotta
  ///
  /// In en, this message translates to:
  /// **'Terracotta'**
  String get ui8be6e64eb5c3;

  /// Text & symbol size
  ///
  /// In en, this message translates to:
  /// **'Text & symbol size'**
  String get ui5da8b6d504e5;

  /// To
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get uiae79ea1e9c63;

  /// Typography
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get uif4beb9af58f7;

  /// Visible features
  ///
  /// In en, this message translates to:
  /// **'Visible features'**
  String get ui6c3b0475960a;

  /// Vivid
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get ui3b2f5b0cf572;

  /// Warm vintage
  ///
  /// In en, this message translates to:
  /// **'Warm vintage'**
  String get ui26606552151f;

  /// Width (pixels)
  ///
  /// In en, this message translates to:
  /// **'Width (pixels)'**
  String get uie73a0adf49ce;

  /// Your project name
  ///
  /// In en, this message translates to:
  /// **'Your project name'**
  String get ui046786ec74e0;

  /// e.g. Salinity · October field visit
  ///
  /// In en, this message translates to:
  /// **'e.g. Salinity · October field visit'**
  String get uid74015d4e00f;

  /// Feature UUID: {v0}
  ///
  /// In en, this message translates to:
  /// **'Feature UUID: {v0}'**
  String ui6313520ac1e1(String v0);

  /// Observation UUID: {v0}
  ///
  /// In en, this message translates to:
  /// **'Observation UUID: {v0}'**
  String uia68e9ddcf3b8(String v0);

  /// More actions
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get uia1e34f91579d;

  /// Choose a workflow
  ///
  /// In en, this message translates to:
  /// **'Choose a workflow'**
  String get uie93c7af975cb;

  /// Workflow requirements
  ///
  /// In en, this message translates to:
  /// **'Workflow requirements'**
  String get uibce757708457;

  /// Configure required steps before sharing this project with the field team. Share an updated project package after changing these settings.
  ///
  /// In en, this message translates to:
  /// **'Configure required steps before sharing this project with the field team. Share an updated project package after changing these settings.'**
  String get ui339529eee4c0;

  /// Require questionnaire
  ///
  /// In en, this message translates to:
  /// **'Require questionnaire'**
  String get uicd39c5d4c2d2;

  /// Require geotagged photo
  ///
  /// In en, this message translates to:
  /// **'Require geotagged photo'**
  String get uic184e2bde3f6;

  /// Save requirements
  ///
  /// In en, this message translates to:
  /// **'Save requirements'**
  String get ui8caa0a53724d;

  /// Photo is optional.
  ///
  /// In en, this message translates to:
  /// **'Photo is optional.'**
  String get ui551b1994e409;

  /// Complete the required steps to finish. You can save a draft at any time.
  ///
  /// In en, this message translates to:
  /// **'Complete the required steps to finish. You can save a draft at any time.'**
  String get ui0b0a3f8c430f;

  /// Nearest unvisited sites
  ///
  /// In en, this message translates to:
  /// **'Nearest unvisited sites'**
  String get ui6e4c1e3c8ad1;

  /// Straight-line distance from your GPS location.
  ///
  /// In en, this message translates to:
  /// **'Straight-line distance from your GPS location.'**
  String get ui66fc75da8df4;

  /// No recent GPS location. Sites are sorted by name.
  ///
  /// In en, this message translates to:
  /// **'No recent GPS location. Sites are sorted by name.'**
  String get ui701b8859c071;

  /// Refresh location
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get uic9704e072a21;

  /// No unvisited sites in this layer.
  ///
  /// In en, this message translates to:
  /// **'No unvisited sites in this layer.'**
  String get ui3362f0a776a1;

  /// Location permission is required.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get ui51848b274f3e;

  /// A geotagged photo is required.
  ///
  /// In en, this message translates to:
  /// **'A geotagged photo is required.'**
  String get ui45f4f4818756;

  /// Complete the required questionnaire and photo before marking this site done.
  ///
  /// In en, this message translates to:
  /// **'Complete the required questionnaire and photo before marking this site done.'**
  String get ui0ded61d14817;

  /// Invalid workflow requirements.
  ///
  /// In en, this message translates to:
  /// **'Invalid workflow requirements.'**
  String get uif8e4834eedd0;

  /// Required questionnaires and photos for each workflow
  ///
  /// In en, this message translates to:
  /// **'Required questionnaires and photos for each workflow'**
  String get ui39854cbe2f78;
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
