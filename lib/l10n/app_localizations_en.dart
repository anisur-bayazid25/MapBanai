import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MapBanai';

  @override
  String get homeTitle => 'MapBanai';

  @override
  String get homeSubtitle => 'Offline field data collection';

  @override
  String get surveyModeTitle => 'Survey Mode';

  @override
  String get surveyModeSubtitle => 'Simple form-based field capture';

  @override
  String get gisModeTitle => 'GIS Mode';

  @override
  String get gisModeSubtitle => 'Map-based spatial editing and layers';

  @override
  String get gpsModeTitle => 'GPS Mode';

  @override
  String get gpsModeSubtitle => 'Live GPS readings and coordinate logging';

  @override
  String get studyAreaModeTitle => 'Study Area Mode';

  @override
  String get studyAreaModeSubtitle =>
      'Site visits with status tracking & navigation';

  @override
  String get gpsCsvViewerTitle => 'GPS CSV Viewer';

  @override
  String get gpsCsvViewerSubtitle => 'View logs & project tracks on WebMap';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncSubtitle => 'Upload responses & photos to cloud';

  @override
  String get syncSetupTitle => 'Set up cloud sync';

  @override
  String syncSetupSubtitle(String project) {
    return 'Configure sync for \"$project\"';
  }

  @override
  String syncLastSynced(String date) {
    return 'Last synced: $date';
  }

  @override
  String get syncNever => 'Never synced';

  @override
  String get syncNoInternet => 'No internet connection';

  @override
  String get webMapTitle => 'WebMap';

  @override
  String get webMapSubtitle => 'Offline HTML map with filters and popups';

  @override
  String projectSelectorTitle(String project) {
    return 'Current project: $project';
  }

  @override
  String get noProjectSelected => 'No project selected — tap to choose one';

  @override
  String get selectProject => 'Select project';

  @override
  String collectedDataTitle(String project) {
    return 'Collected data — $project';
  }

  @override
  String get collectedDataHint =>
      'Select a project above to see its collected data.';

  @override
  String get surveyResponses => 'Survey Responses';

  @override
  String get gisFeatures => 'GIS Features';

  @override
  String get open => 'Open';

  @override
  String get history => 'History';

  @override
  String get export => 'Export';

  @override
  String get importProject => 'Import Project';

  @override
  String get settings => 'Settings';

  @override
  String get settingsUserTitle => 'User';

  @override
  String get settingsUserSubtitle =>
      'Your name is attached to every survey response, GPS log entry and export produced by the app.';

  @override
  String get userNameLabel => 'User name';

  @override
  String get userNameHint => 'e.g., John Doe';

  @override
  String get userNameLeaveEmpty => 'Leave empty to clear.';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSubtitle =>
      'Choose your preferred language. System default follows the device language.';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get systemDefault => 'System default';

  @override
  String get english => 'English';

  @override
  String get bangla => 'Bangla';

  @override
  String get themeSection => 'Appearance';

  @override
  String get themeSubtitle => 'Choose light, dark, or follow the system theme.';

  @override
  String get preferredTheme => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get measurementSection => 'Measurement units';

  @override
  String get measurementSubtitle =>
      'Used by the GIS distance and area tools. Automatic picks metres/kilometres and square metres or hectares.';

  @override
  String get distance => 'Distance';

  @override
  String get area => 'Area';

  @override
  String get dataSection => 'Data';

  @override
  String get dataSubtitle => 'Delete all locally stored survey data.';

  @override
  String get resetData => 'Reset data';

  @override
  String get resetDataConfirmTitle => 'Final confirmation';

  @override
  String get updatesSection => 'Updates';

  @override
  String get updatesSubtitle =>
      'Checks the GitHub releases feed for a newer version.';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String checkForUpdatesWithVersion(String version) {
    return 'Check for updates — v$version installed';
  }

  @override
  String get aboutSection => 'About';

  @override
  String get aboutTagline => 'Offline field data collection GIS';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get save => 'Save';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get saveResponses => 'Save responses';

  @override
  String get saveAsDraft => 'Save as draft';

  @override
  String gpsRecordingActive(String name) {
    return 'GPS recording active — \"$name\"';
  }

  @override
  String get gpsRecordingHint =>
      'Logging continues with the screen off. Leave GPS Mode any time; come back here to stop.';

  @override
  String get openGpsMode => 'Open GPS Mode';

  @override
  String get stop => 'Stop';

  @override
  String get surveyMode => 'Survey Mode';

  @override
  String get selectSurveyForm => 'Select a survey form';

  @override
  String projectLabel(String project) {
    return 'Project: $project';
  }

  @override
  String get myForms => 'My forms';

  @override
  String get noFormsHint =>
      'No forms yet for this project. Tap to build or import your first survey form.';

  @override
  String get startBuildingForm => 'Start building survey form';

  @override
  String formQuestionsCount(String count) {
    return '$count questions';
  }

  @override
  String get buildOrImportForm => 'Build or import a survey form';

  @override
  String get formLanguage => 'Form language';

  @override
  String get formLanguageHint =>
      'Switch between languages defined in the XLSForm';

  @override
  String get captureGps => 'Capture';

  @override
  String get measureAccuracy => 'Measure';

  @override
  String get attachPhoto => 'Attach';

  @override
  String get replacePhoto => 'Replace';

  @override
  String get tapToCaptureGps => 'Tap to capture GPS location';

  @override
  String get tapToMeasureAccuracy => 'Tap to measure accuracy';

  @override
  String get photoAttached => 'Photo attached';

  @override
  String get geotaggedPhoto => 'Geotagged photo attached';

  @override
  String requiredField(String label) {
    return '$label is required';
  }

  @override
  String constraintError(String label, String error) {
    return '$label: $error';
  }

  @override
  String get enterText => 'Enter text';

  @override
  String get enterLongText => 'Enter long text';

  @override
  String get enterNumber => 'Enter number';

  @override
  String get enterDecimal => 'Enter decimal number';

  @override
  String get selectOption => 'Select an option';

  @override
  String get chooseOption => 'Choose an option';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get selectDateTime => 'Select date and time';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get studyAreaTitle => 'Study Area';

  @override
  String get projectTitle => 'Project';

  @override
  String get projectSettings => 'Project settings';

  @override
  String get renameProject => 'Rename project';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get shareProject => 'Share project';

  @override
  String get lightThemeApplied => 'Light theme applied';

  @override
  String get darkThemeApplied => 'Dark theme applied';
}
