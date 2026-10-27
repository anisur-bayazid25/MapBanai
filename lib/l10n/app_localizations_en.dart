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
  String get homeSubtitle => 'Easy Geospatial Data Collection';

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
  String get aboutTagline => 'Easy Geospatial Data Collection';

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

  @override
  String ui146d90ab8a12(String v0) {
    return '\"$v0\" created';
  }

  @override
  String uidb9502050d6e(String v0) {
    return '1. Verify $v0';
  }

  @override
  String get uica8002883856 => '2. Collect information';

  @override
  String get uie2d42900f048 => '3. Geotagged evidence photo';

  @override
  String get uia71b74276db0 => 'A photo is required before finishing.';

  @override
  String ui6eb4c6ceec88(String v0) {
    return 'A project named \"$v0\" already exists';
  }

  @override
  String get uicf678cab87dc => 'API key';

  @override
  String get ui6b21fb791ac0 => 'About';

  @override
  String get uifa7cafd4738a => 'Acc (m)';

  @override
  String get uiece911f43765 => 'Accept accuracy';

  @override
  String get uid110ce480b6b =>
      'Accuracy accepted. Your data and photo are kept.';

  @override
  String uiee4a56b9d330(String v0) {
    return 'Accuracy: $v0 (max 20 m)';
  }

  @override
  String get ui5d9540ff93a7 => 'Acknowledgments';

  @override
  String get ui61cc55aa0453 => 'Add';

  @override
  String get ui05448f4011e4 => 'Add Option';

  @override
  String get uif353ad702eca => 'Add Point';

  @override
  String get uib86c7f055ded => 'Add Question';

  @override
  String get uia5f99b5076d1 => 'Add a project questionnaire';

  @override
  String get ui912d424ade4e =>
      'Add an XLSForm to this project before finishing a visit.';

  @override
  String ui512ece25554d(String v0) {
    return 'Add at least $v0 distinct vertices.';
  }

  @override
  String ui92c3d4711cb2(String v0) {
    return 'Add at least $v0 vertices.';
  }

  @override
  String get ui6632e5c07446 => 'Add form';

  @override
  String get ui6f689eeab092 => 'Add information';

  @override
  String get uifaac648b07cd => 'Add layers to this project';

  @override
  String get ui259983d5b67d => 'Add line (tap vertices)';

  @override
  String get ui69ba1bebc021 => 'Add new Layer';

  @override
  String get uic4c2f28a653e => 'Add observation / start visit';

  @override
  String get uia20144055a2c => 'Add option';

  @override
  String get uid14349309573 => 'Add photo';

  @override
  String get uia6e0524cd9f4 => 'Add polygon (tap vertices)';

  @override
  String get uidfa9ad191cbb =>
      'Add study-area, facility and road layers. Source files travel with project exports.';

  @override
  String get uif51add823fef =>
      'Add study-area, facility or road layers. Supported files: shapefile or ZIP, CSV, Excel, GeoJSON and GeoPackage. Road layers can provide shortest-path directions in Study Area Mode. Use WGS84 (EPSG:4326).';

  @override
  String get ui29924533fad1 => 'Add vector layers';

  @override
  String get ui79ba5e1b3f99 => 'After';

  @override
  String get ui6a72085653e4 => 'All';

  @override
  String get uib4f794cdbb77 => 'All days';

  @override
  String get ui152d422f80e6 => 'All layers';

  @override
  String uic622d843608e(String v0) {
    return 'All observations ($v0)';
  }

  @override
  String get ui755046a16371 => 'All record types';

  @override
  String get ui524a33d9c5f7 => 'All sites';

  @override
  String get uidd402a4a59f8 => 'All sync statuses';

  @override
  String get ui3ad0e3698278 => 'Allow';

  @override
  String get ui209e0391343c => 'Allow installation';

  @override
  String get uia0354233e8e7 => 'Allow location permission to use GPS.';

  @override
  String get ui483ff5e64f97 => 'Already synced';

  @override
  String get ui12e0f83d72ab => 'Also clear survey history and sync queue';

  @override
  String get ui6742711abf37 => 'Also remove linked Study Area points';

  @override
  String get ui789bda938348 => 'Alt (m)';

  @override
  String get uib2482df07055 => 'Answers updated — ready to sync';

  @override
  String get ui41def7a0febe => 'Appearance';

  @override
  String get uicfea419c3b4e => 'Apply';

  @override
  String get uie4e3653eb728 => 'Apply import';

  @override
  String get uic64add5b7c88 => 'Apply questionnaire update';

  @override
  String get ui036a2c32985f => 'Apply reviewed visit';

  @override
  String get uif7110953e0c1 => 'Apps Script Web App URL';

  @override
  String get ui6baacf7ea93e => 'Archive project';

  @override
  String get uieddc813f35b1 => 'Archived';

  @override
  String get ui371c4c745268 => 'Archived project';

  @override
  String get ui2745debaa64a => 'Area';

  @override
  String get ui5de953ada8ae => 'Assign previous unassigned sites';

  @override
  String get uibc9e681ab30c => 'Assign selected';

  @override
  String ui775f4f08081b(String v0) {
    return 'At least 3 vertices required ($v0/3)';
  }

  @override
  String get ui1afff0157ce3 => 'Attach';

  @override
  String get ui29d7b5c69a0f => 'Attach photo (geotagged)';

  @override
  String get ui48b5d713528c => 'Attached to each new submission.';

  @override
  String ui0e89f1ba582f(String v0) {
    return 'Attribute \"$v0\" already exists';
  }

  @override
  String get uia6652617f2c7 => 'Attributes';

  @override
  String get ui541903fcabc1 => 'Backup restore failed. Data was not changed.';

  @override
  String get ui557ebe872d79 => 'Backup restored successfully.';

  @override
  String get ui68ea04ad6c84 => 'Bangla';

  @override
  String get uicc0720785428 => 'Basemap';

  @override
  String get ui74f39697ac32 => 'Before';

  @override
  String get ui6cd36c7dc22c => 'Brief description of this form';

  @override
  String get ui4dcbe4e8a47b => 'Build or import a survey form';

  @override
  String get ui3281188351b8 => 'CSV';

  @override
  String get ui757d86654eda => 'Calculated';

  @override
  String get uidc6751bd6532 => 'Calculation';

  @override
  String get ui77dfd2135f4d => 'Cancel';

  @override
  String get ui67bb11d08df2 => 'Cancel download';

  @override
  String ui57d7674a7613(String v0) {
    return 'Cancel failed: $v0';
  }

  @override
  String get uifda8429a704c => 'Cancel recording';

  @override
  String ui6ca1964345a5(String v0) {
    return 'Cannot load icon: $v0';
  }

  @override
  String ui34ebd759c2a4(String v0) {
    return 'Cannot load project: $v0';
  }

  @override
  String uied3764fb600f(String v0) {
    return 'Cannot load study area: $v0. Stored data was preserved.';
  }

  @override
  String ui4b101071fd57(String v0) {
    return 'Cannot open map styles: $v0';
  }

  @override
  String ui81c619629565(String v0) {
    return 'Cannot open project map: $v0';
  }

  @override
  String uiaeb0cf0b59f1(String v0) {
    return 'Cannot reload layers: $v0';
  }

  @override
  String uiad5108d1542b(String v0) {
    return 'Cannot review accuracy: $v0';
  }

  @override
  String get ui772a4bcb6564 => 'Capture';

  @override
  String get ui70dd605f2b73 => 'Capture Photo';

  @override
  String get ui31c77e404ec9 => 'Capture photo';

  @override
  String ui72d06195a7a3(String v0) {
    return 'Captured $v0';
  }

  @override
  String get ui721731bb86ab => 'Categories & colors';

  @override
  String get ui8af155f38c5a => 'Category color';

  @override
  String get uib55970d156d0 => 'Center on GPS';

  @override
  String get ui7624e54f7a04 => 'Center on site';

  @override
  String get uid9789c629cfe => 'Change from previous';

  @override
  String get uia76e5f7556db => 'Change or review note';

  @override
  String get ui46b25978ee0b => 'Changed features only (GeoJSON)';

  @override
  String get ui1728436a320d => 'Check Google Sheet';

  @override
  String get ui736b9062b336 => 'Check for updates';

  @override
  String get uie08b2e193e7a => 'Check imported files';

  @override
  String get ui66a60b5d2de0 => 'Check locations and update existing features.';

  @override
  String get uia357678fa469 => 'Checking recorded GPS accuracy…';

  @override
  String get ui398872e1510b =>
      'Checks the GitHub releases feed for a newer version.';

  @override
  String get uib8c6c4d83ff6 => 'Choose .mbproj file';

  @override
  String get ui410406660ffe =>
      'Choose a baseline feature to verify, update and document.';

  @override
  String get ui94e9ca725723 =>
      'Choose a project, then narrow the records by layer or recorded day. Deleting history also removes those records from the sync queue.';

  @override
  String get uiec39521dd3d0 => 'Choose a resolution';

  @override
  String get uie6e18a5753f1 => 'Choose a site';

  @override
  String get ui45b9ce6e2d69 => 'Choose an option';

  @override
  String get ui5910acf0395e => 'Choose files';

  @override
  String get ui1838a4158f39 => 'Choose folder';

  @override
  String get ui3caef71ba23a =>
      'Choose light, dark, or follow the system theme.';

  @override
  String get ui05047674386b =>
      'Choose where this map belongs. Importing lets you verify and update its features.';

  @override
  String get ui470bd9b52bf6 =>
      'Choose your preferred language. System default follows the device language.';

  @override
  String get ui518b074e92aa => 'Clean up history';

  @override
  String get ui0c8b3d42e61a => 'Clean up survey history';

  @override
  String get ui719ea396ad92 => 'Clear';

  @override
  String get ui105f261a16bf => 'Clear all sites';

  @override
  String get ui526b4d80fe1b => 'Clear study layer';

  @override
  String get uibbfa773e5a63 => 'Close';

  @override
  String get uiaf5d06a7b201 => 'Close feature';

  @override
  String get uid997d8d3a964 => 'Cloud Sync';

  @override
  String get ui0bd870fd34a8 => 'Code.gs';

  @override
  String get ui68188254a969 => 'Collect area';

  @override
  String get ui42688f506949 => 'Collect line';

  @override
  String get ui5e9981b89e91 =>
      'Collect measurements at the same sites each round.';

  @override
  String get uiada29d015b1d => 'Collect point';

  @override
  String get ui5b0f7590d06f => 'Collected';

  @override
  String get ui6f83084a2ae4 => 'Collection round';

  @override
  String get ui309ecfafed02 => 'Color by column';

  @override
  String get uif28563a477a9 => 'Colour';

  @override
  String get uid401aac0a65d => 'Compare both versions';

  @override
  String get ui17ccc7b6d715 => 'Compare map and saved visit';

  @override
  String get ui9d5c8e519d85 => 'Compass';

  @override
  String get ui5b96e7e9c657 =>
      'Compass needs calibration: move the phone in a figure-eight, away from metal.';

  @override
  String uicac0b9c25835(String v0) {
    return 'Conditional: $v0';
  }

  @override
  String get ui04a212215ef9 => 'Confirm';

  @override
  String ui8b1bf24a6905(String v0) {
    return 'Conflict resolution failed: $v0';
  }

  @override
  String get ui222f2eac34b3 => 'Constraint (optional)';

  @override
  String get ui70404424ca5b => 'Constraint message (optional)';

  @override
  String get ui2e02623966f9 => 'Continue';

  @override
  String get ui9201f5c65f25 => 'Coordinates copied to clipboard';

  @override
  String get ui1a19a2434337 => 'Coordinates out of range';

  @override
  String get ui0e7383487387 => 'Copied to clipboard';

  @override
  String get ui9959dcff1e40 => 'Copy coordinates';

  @override
  String get ui9b6827cfc0c2 => 'Copy project ID';

  @override
  String uifa1b57908cec(String v0) {
    return 'Copy $v0';
  }

  @override
  String ui975a22c89e46(String v0) {
    return 'Could not calculate a road route: $v0';
  }

  @override
  String ui22545c204602(String v0) {
    return 'Could not clear sites: $v0';
  }

  @override
  String uifc746e880c1f(String v0) {
    return 'Could not delete package: $v0';
  }

  @override
  String ui0334890fbaf4(String v0) {
    return 'Could not get accuracy: $v0';
  }

  @override
  String ui9a95131ae123(String v0) {
    return 'Could not get location: $v0';
  }

  @override
  String get uie4ee1b598563 => 'Could not load code. Reopen Help.';

  @override
  String get uic305018ed35e => 'Could not open Google Maps.';

  @override
  String uif515a67aeb4d(String v0) {
    return 'Could not open Google Maps: $v0';
  }

  @override
  String get uiff2ce6da5800 => 'Could not open link';

  @override
  String ui50a313090b94(String v0) {
    return 'Could not open map: $v0';
  }

  @override
  String get ui17cb282d8d29 =>
      'Could not open the file picker. Please try again.';

  @override
  String get uie5e1f203c3e2 => 'Could not read the QR code';

  @override
  String get uibe443a8c429f => 'Could not read the selected file';

  @override
  String get uid77db0286a5e => 'Could not read this draft';

  @override
  String uif3267458c32e(String v0) {
    return 'Could not save acceptance: $v0';
  }

  @override
  String uia8114024834a(String v0) {
    return 'Could not save draft: $v0. Answers remain here.';
  }

  @override
  String ui5d7ba60622b7(String v0) {
    return 'Could not save feature: $v0';
  }

  @override
  String ui8607427fbc53(String v0) {
    return 'Could not save form: $v0. Your form is still here.';
  }

  @override
  String ui6e35c572c083(String v0) {
    return 'Could not save responses: $v0. Your answers are still here.';
  }

  @override
  String ui269629dbe7bf(String v0) {
    return 'Could not save the feature: $v0';
  }

  @override
  String ui31eee97bbcb3(String v0) {
    return 'Could not share log: $v0';
  }

  @override
  String get ui6e157c5da441 => 'Create';

  @override
  String get ui81199e796010 => 'Create a project from Home first.';

  @override
  String get ui4040d68479ef => 'Create custom survey form';

  @override
  String get uib6fff06b1ea9 => 'Create layer from responses';

  @override
  String get uieb8f1b5942ac => 'Create measurement layer';

  @override
  String get uid147959adb0d => 'Create or import a project to start.';

  @override
  String get ui79ed912d242b => 'Create or open a project';

  @override
  String get uie41bffcbf8fd =>
      'Create or select a project before building a form';

  @override
  String get uia8d8ff51e4c8 => 'Create project';

  @override
  String get uid7fd23efd3fb => 'Create recurring layer';

  @override
  String get ui5fa4376dd93d => 'Create your first round';

  @override
  String get ui1e95852771e8 => 'Current accuracy';

  @override
  String ui5ba408a14004(String v0, String v1, String v2) {
    return 'Current map (revision $v0):\n$v1\n\nSaved visit proposal:\n$v2\n\nApplying the saved visit replaces current attributes and geometry. Both versions remain in revision history.';
  }

  @override
  String get uid1f86d5227e9 => 'Custom fields';

  @override
  String get ui2bc69d616e9c => 'Custom layer colour';

  @override
  String get uiae1ef0143294 => 'Dark';

  @override
  String get uidd144a4c66ee => 'Dark theme applied';

  @override
  String get uie5e429bcc9c2 => 'Data';

  @override
  String get uieb9a4bc1c0c1 => 'Date';

  @override
  String get ui7eb29d356518 => 'Date & time';

  @override
  String get uie4c3a2d0cc24 => 'Decimal';

  @override
  String get uic9a6edbbca9b => 'Default value (optional)';

  @override
  String get uif6fdbe48dc54 => 'Delete';

  @override
  String ui322a3ca0f18f(String v0) {
    return 'Delete \"$v0\" and its CSV file?';
  }

  @override
  String uia761ad78efaa(String v0) {
    return 'Delete \"$v0\"?';
  }

  @override
  String ui97f85ee5e056(String v0) {
    return 'Delete \"$v0\"? This cannot be undone.';
  }

  @override
  String get ui163dbcf2cb0b => 'Delete all locally stored survey data.';

  @override
  String get uib6ea094ee1dd => 'Delete draft';

  @override
  String get uie51f1f6721d0 => 'Delete form';

  @override
  String get uicee51ffefd08 => 'Delete package';

  @override
  String get uifc700472e1c8 => 'Delete photo';

  @override
  String get uiaf1456f256eb => 'Delete project';

  @override
  String get uib81097a6dff1 => 'Delete response';

  @override
  String get ui8516a714a234 => 'Delete selected';

  @override
  String get uia154a9f139a0 => 'Delete selected history?';

  @override
  String get uidead9e2fceca => 'Delete site';

  @override
  String get uibbb829eb5d99 =>
      'Delete this draft? The unfinished data will be lost.';

  @override
  String get ui0ddb0f574d68 => 'Delete unassigned sites?';

  @override
  String ui2823144885b8(String v0) {
    return 'Delete $v0 records';
  }

  @override
  String uic140eb8d4089(String v0) {
    return 'Delete $v0?';
  }

  @override
  String ui417f5c09f20f(String v0, String v1) {
    return 'Deleted $v0 history records$v1.';
  }

  @override
  String get ui55f8ebc805e6 => 'Description';

  @override
  String get ui85cce1e14782 => 'Deselect all';

  @override
  String get ui36fff63ccbcd => 'Discard';

  @override
  String get ui423208095dd7 => 'Distance';

  @override
  String get uie9b450d14bc2 => 'Done';

  @override
  String get uia479c9c34e87 => 'Download';

  @override
  String get uiff0c13412b0c => 'Download & Install';

  @override
  String get ui0ff9a69a76f5 => 'Download Map';

  @override
  String get ui0800a145edde =>
      'Download a bounded field area before leaving internet coverage. Completed packages appear in the Basemap selector on every collection map.';

  @override
  String uib5da8ffe86ea(String v0) {
    return 'Download failed. $v0';
  }

  @override
  String get uia2853733787f => 'Download field area';

  @override
  String uib5491539e2b3(String v0) {
    return 'Downloading... $v0%';
  }

  @override
  String get uic584016080ca =>
      'Draft cannot be saved: repeated records are not supported. Import a form with one submission per feature.';

  @override
  String get ui263f1461e992 =>
      'Draft restored — continue, finish, or save it again';

  @override
  String get uia706abd0fea1 => 'Draft saved';

  @override
  String get uibdb71d0f6f36 => 'Draft saved — resume it from History later';

  @override
  String get uife6f67656743 => 'Draft updated';

  @override
  String ui319e1cedce84(String v0) {
    return 'Draft visit $v0. Leaving this screen saves the feature edits.';
  }

  @override
  String get ui24673e67421a => 'Drag the point on the map to move it.';

  @override
  String get uibb2708352747 => 'Draw Line';

  @override
  String get ui779c76ee322b => 'Draw Polygon';

  @override
  String get ui0f873fbc3146 => 'Draw on map';

  @override
  String get uifc2d12b944ac => 'Dropdown';

  @override
  String get ui35ec8f11252e =>
      'Each completed visit is a separate observation. Earlier measurements stay in the timeline. Comparisons use the same questionnaire and question name; keep measurement units consistent across versions.';

  @override
  String get ui4c0f7e66bf0e => 'Easy Geospatial Data Collection';

  @override
  String get ui5301648dcf6b => 'Edit';

  @override
  String get ui8ad0e04ead5b => 'Edit Option';

  @override
  String get ui7ff2c7ac7f1d => 'Edit answers';

  @override
  String get uid630d038b3ad => 'Edit feature';

  @override
  String get uif1d8720160a4 => 'Edit form';

  @override
  String get ui28134edb87d4 => 'Edit on map';

  @override
  String get ui6091ce867967 => 'Edit or remove this site in Study Area mode';

  @override
  String get ui7f9c8e468af6 => 'Edit project name';

  @override
  String uiedf5a9152284(String v0) {
    return 'Edit site $v0';
  }

  @override
  String ui12faa0f2ccff(String v0) {
    return 'Edit — $v0';
  }

  @override
  String get ui84add5b29527 => 'Email';

  @override
  String get ui649df08a448e => 'English';

  @override
  String get ui75320322f7f3 => 'Enter a MapBanai QR code or link';

  @override
  String get ui7f84073ce3b4 => 'Enter decimal number';

  @override
  String get ui02b5062f9c93 => 'Enter long text';

  @override
  String get uib616e9721b5f => 'Enter number';

  @override
  String get ui9c05f58f3dcc => 'Enter text';

  @override
  String get ui0bd3df97dc75 => 'Enter your name so submissions identify you.';

  @override
  String get ui0e2d6a433d92 => 'Excel (XLSX)';

  @override
  String get ui00db23ce33b1 => 'Excel-compatible CSV';

  @override
  String get uif3e4fadb9e37 => 'Export';

  @override
  String ui919004e0521f(String v0, String v1) {
    return 'Export \"$v0\" (v$v1)';
  }

  @override
  String get ui59e9d9bc60d6 => 'Export / Share project';

  @override
  String get ui882b3940804a => 'Export / share CSV';

  @override
  String get uif601e90879bd => 'Export Data';

  @override
  String get ui98228e8633b0 => 'Export GIS data as';

  @override
  String get uid2ee1c2ac834 => 'Export all observations as CSV';

  @override
  String get ui8016ab2ed7ba => 'Export cancelled.';

  @override
  String get ui6b65ee8c6ffb => 'Export failed. Please try again.';

  @override
  String ui0026e4743f02(String v0) {
    return 'Export failed: $v0';
  }

  @override
  String ui0fc874762a39(String v0) {
    return 'Export ready: $v0';
  }

  @override
  String get uia463fe0ed8cd => 'Export sites';

  @override
  String get ui9d0a833e883c => 'Facilities';

  @override
  String ui01387ee23eea(String v0) {
    return 'Failed to generate webmap: $v0';
  }

  @override
  String uicd17064d090a(String v0) {
    return 'Failed to load: $v0';
  }

  @override
  String get uief523b46ad00 => 'Failed to reset data';

  @override
  String uie7926fb16618(String v0) {
    return 'Failed to save line: $v0';
  }

  @override
  String ui3a80d1d372c5(String v0) {
    return 'Failed to save point: $v0';
  }

  @override
  String uif7f1a2f5375b(String v0) {
    return 'Failed to save polygon: $v0';
  }

  @override
  String get uidf0ddc77356e => 'Feature Info';

  @override
  String get ui4bd0951a03e8 => 'Feature deleted';

  @override
  String get ui255785f96e54 => 'Feature saved';

  @override
  String get ui8723967a8e50 => 'Feature updated — ready to sync';

  @override
  String get ui897fa3cadce1 =>
      'Fetch the latest XLSForm from your project’s Google Sheet using its Apps Script connection.';

  @override
  String get ui4c0d84107ddc => 'Field Verification';

  @override
  String get uif08ab394a08f => 'Field name';

  @override
  String get uie59928316474 => 'Field name (no spaces)';

  @override
  String get uifd507b95760d =>
      'Field names stay fixed so existing answers and form rules remain linked.';

  @override
  String get ui9a5b8203dea6 => 'Field quality checks';

  @override
  String ui04da12f4ecb1(String v0) {
    return 'Field quality$v0';
  }

  @override
  String get ui3f996677147b => 'Fieldworker name';

  @override
  String ui5e39bef6ecec(String v0) {
    return 'Fieldworker: $v0';
  }

  @override
  String get uib2a03b9b7a06 => 'Fill questionnaire';

  @override
  String get ui28620a15f945 => 'Fill questionnaire (optional)';

  @override
  String get ui61b933ebc0cf => 'Filter status';

  @override
  String get uic3c626512bc9 => 'Final confirmation';

  @override
  String get uib74bdee9c34f => 'Finish';

  @override
  String get ui26b73a211708 => 'Finish visit and update map';

  @override
  String uia72abb53ded4(String v0, String v1, String v2) {
    return 'First: $v0 • Latest: $v1 • Change: $v2';
  }

  @override
  String get ui6671587fff89 => 'Fit all sites';

  @override
  String get uib64b0d0a894d => 'Follow me';

  @override
  String get ui736e35f71fc4 =>
      'For a new project, paste into Code.gs and replace only projectId. Leave the other four placeholders unchanged; setupMapBanai creates your API key, photo folder and data tabs.';

  @override
  String ui8e0113e9ab9a(String v0) {
    return 'Form \"$v0\" saved';
  }

  @override
  String ui6b40badab021(String v0, String v1) {
    return 'Form \"$v0\" saved in $v1';
  }

  @override
  String ui6c07b56f89a1(String v0) {
    return 'Form \"$v0\" updated';
  }

  @override
  String get uic3de47ae9bd2 => 'Form Details';

  @override
  String get uib6ab025c2d78 => 'Form deleted';

  @override
  String get ui16dd86a84b5d => 'Form details';

  @override
  String get ui9fd01570e232 => 'Form language';

  @override
  String get uib93262f4bc3e => 'Form name';

  @override
  String ui16d3ca31f7bc(String v0, String v1) {
    return 'Free device storage: $v0 · Map cache: $v1';
  }

  @override
  String get ui0eace7f71b6c =>
      'Full geometry, attributes and revision baseline';

  @override
  String get uiaa77c8a72989 =>
      'Full line/polygon geometry is retained. Coordinates show its reference vertex.';

  @override
  String get uid78c401e571e => 'GIS Features';

  @override
  String get uidca76b4d8ff0 => 'GIS Mode';

  @override
  String ui43688d96e197(String v0) {
    return 'GIS Mode - $v0';
  }

  @override
  String get uib6cadf4fa6c5 => 'GIS data';

  @override
  String get ui350358829580 => 'GIS feature';

  @override
  String get uieeddcc3bc1da => 'GIS features';

  @override
  String get ui2159e983c6a6 => 'GPS CSV Viewer';

  @override
  String ui816774591672(String v0) {
    return 'GPS Logs ($v0)';
  }

  @override
  String get uied430db463ff => 'GPS Mode';

  @override
  String get uiefc3f88b78d7 => 'GPS Point';

  @override
  String get uida3c038f839c => 'GPS accuracy';

  @override
  String get ui881050d044a5 => 'GPS accuracy review limit';

  @override
  String ui5af8da29a579(String v0) {
    return 'GPS accuracy threshold set to $v0 m';
  }

  @override
  String get ui68d8c2dfacb1 => 'GPS accuracy: unavailable';

  @override
  String ui17dd2295e5dc(String v0) {
    return 'GPS accuracy: $v0 m';
  }

  @override
  String ui17ff8208bb50(String v0) {
    return 'GPS accuracy: ±$v0 m';
  }

  @override
  String uib412d9b03d31(String v0, String v1) {
    return 'GPS accuracy: ±$v0 m · Limit: $v1 m';
  }

  @override
  String get uie8b468b0e65c =>
      'GPS direction of travel; this does not show where a stationary phone faces.';

  @override
  String get ui1139289ac231 => 'GPS settings';

  @override
  String ui70ae5325e6b1(String v0) {
    return 'GPS unavailable: $v0';
  }

  @override
  String get ui436b10d50cf3 => 'GPS vertex';

  @override
  String get uid79fea5a85f4 => 'GPS: Searching...';

  @override
  String uiefa204b85e3c(String v0, String v1) {
    return 'GPS: $v0, $v1';
  }

  @override
  String get ui9c30a3485a58 => 'Gallery';

  @override
  String ui8f5281dddc73(String v0) {
    return 'Generating webmap for $v0 features — this may take a moment...';
  }

  @override
  String get ui7bd3c4506e38 => 'Geometry only';

  @override
  String get uief385e8b9394 => 'Geotagged';

  @override
  String get ui127e22e72c01 => 'Geotagged photo attached';

  @override
  String get uic6651994b242 => 'GitHub repository';

  @override
  String uie8adeb7a2680(String v0) {
    return 'Guided visit$v0';
  }

  @override
  String ui1bfc2126eb38(String v0) {
    return 'Height change from your reference: $v0';
  }

  @override
  String get uib7b664830ea7 => 'Help & manager setup';

  @override
  String get uidaafa6d492ee => 'Hex colour';

  @override
  String get uid4c2792a7245 => 'Hidden';

  @override
  String get ui088c4ac92ba8 => 'Hide all';

  @override
  String get uia0419d944de6 => 'Hide from project setup; data is kept';

  @override
  String get ui2daccedccf3f => 'Hint text (optional)';

  @override
  String get ui90ccd6497400 => 'History';

  @override
  String ui4b923abc4390(String v0) {
    return 'History: $v0';
  }

  @override
  String get ui4f57a1ce99e6 => 'Horizontal';

  @override
  String get uid3cddd6b7a18 =>
      'I have permission to download this source for offline use.';

  @override
  String get ui89f89c02cf47 => 'ID';

  @override
  String ui37983e6e11cc(String v0) {
    return 'ID  $v0';
  }

  @override
  String ui4f710ef77383(String v0, String v1, String v2) {
    return 'ID: $v0\n$v1$v2';
  }

  @override
  String get ui50e19fda0d5b => 'Image';

  @override
  String get uid6fbc9d2bdd5 => 'Import';

  @override
  String get ui62d55664db41 => 'Import Project';

  @override
  String get ui05b32fd31a55 => 'Import XLSForm';

  @override
  String get ui8e37624a8c4f => 'Import a form';

  @override
  String get ui9c5252af721c => 'Import as new copy';

  @override
  String get uifbae892997d9 => 'Import failed';

  @override
  String ui5f2e5f60d176(String v0) {
    return 'Import failed: $v0';
  }

  @override
  String get ui31fb23cfff40 => 'Import form';

  @override
  String get uib5d0a38444e6 => 'Import from XLSForm (.xlsx)';

  @override
  String get ui831d2e664b77 => 'Import or select a project first';

  @override
  String get ui447a25af708e => 'Import project';

  @override
  String get ui3901be0cffb1 => 'Import sites';

  @override
  String get uia0256e6f7c6a =>
      'Import study-area features first to begin a guided baseline visit.';

  @override
  String ui18e5cf926e50(String v0, String v1) {
    return 'Imported \"$v0\" with $v1 questions';
  }

  @override
  String uicd9469193dca(String v0, String v1, String v2) {
    return 'Imported $v0 new features, updated $v1, kept $v2 local versions.';
  }

  @override
  String uic1cb782ca0df(String v0) {
    return 'In Apps Script, add an HTML file named $v0, then paste this code.';
  }

  @override
  String get ui9e7815322ba3 => 'Include collected responses and photos';

  @override
  String get uidf228157de13 => 'Include sync connection';

  @override
  String get uic075b040daff =>
      'Include the Apps Script URL and API key for trusted enumerators. Recipients can read the key.';

  @override
  String get uieb897be763fc => 'Include unfinished drafts';

  @override
  String get ui2147c24042cf =>
      'Includes other history records linked to those points. Imported source files and project settings are kept.';

  @override
  String get ui95949d0c4089 =>
      'Includes survey history, drafts and current Study Area points.';

  @override
  String get ui80cf9d54825e => 'Incoming file';

  @override
  String ui233771f44a3f(String v0, String v1) {
    return 'Incoming: $v0, $v1';
  }

  @override
  String get ui370b7d97d11f =>
      'Indoor readings, including negative values, may be unreliable. Test outdoors before setting a ground reference.';

  @override
  String get ui9edcffff4461 => 'Integer';

  @override
  String get uia2f0dfadaaeb => 'Invalid coordinates';

  @override
  String get uicdc2fc2b9596 => 'Keep both as separate features';

  @override
  String get uib1617f6d12ea => 'Keep current map';

  @override
  String get ui7b0d52c5669d => 'Keep local version';

  @override
  String get ui74341e3c271d => 'Label';

  @override
  String get uid95033fb8177 => 'Label and name are required';

  @override
  String get ui89b86ab0e66f => 'Language';

  @override
  String uid44a265f1b26(String v0) {
    return 'Last synced: $v0';
  }

  @override
  String get uiced3905ec822 => 'Latitude';

  @override
  String get ui4343635cf237 => 'Layer';

  @override
  String ui78f4d55f17c1(String v0) {
    return 'Layer  $v0';
  }

  @override
  String get ui66f2d76aa42a => 'Layer name';

  @override
  String get ui7d86eb32993a => 'Layer points cleared; history kept';

  @override
  String get ui3a809dffc14e => 'Layer points, history and sync queue cleared';

  @override
  String get ui28d177aa2889 => 'Layer removed.';

  @override
  String get ui8a398db6aeb3 => 'Layer type';

  @override
  String get uif055f18aeadc => 'Layers';

  @override
  String get ui92b53dd55ccd => 'Layers and questionnaires added';

  @override
  String get ui50fe884f3bed => 'Leave empty to clear.';

  @override
  String get uia36ef8aba229 => 'Light';

  @override
  String get ui566016d4e5ce => 'Light theme applied';

  @override
  String get uiea9676003762 => 'Line';

  @override
  String get ui762185bb9c08 => 'Line saved';

  @override
  String get ui0c803e02a46e => 'Live GPS readings and coordinate logging';

  @override
  String ui2f494babf600(String v0, String v1) {
    return 'Local revision $v0; incoming revision $v1';
  }

  @override
  String get ui55a6907830e4 => 'Locate';

  @override
  String get uid219c68101f5 => 'Location';

  @override
  String uid745ebd37fd5(String v0) {
    return 'Location  $v0';
  }

  @override
  String get uie6eb0764038f => 'Location Removed';

  @override
  String get ui2276b254455d => 'Location changed';

  @override
  String ui6965945ee3f4(String v0) {
    return 'Location error: $v0';
  }

  @override
  String get uid98b3dea33e0 => 'Location permission not granted';

  @override
  String get uic9b51a096e5c => 'Location permission required';

  @override
  String get uib47a40701451 => 'Location removed';

  @override
  String get ui3a171968d250 =>
      'Logging continues with the screen off. Leave GPS Mode any time; come back here to stop.';

  @override
  String get ui862b905c967b => 'Long text';

  @override
  String get ui6f9f011c5d36 => 'Longitude';

  @override
  String get ui624beb5cfdac => 'Main study area';

  @override
  String get uie3dda04d8ad4 => 'Manage project files and layers';

  @override
  String get uie5dae44b774f => 'Manage project files and road layers';

  @override
  String get uie29679599257 => 'Map Layers';

  @override
  String ui06cd4e58b2d2(String v0) {
    return 'Map export failed: $v0';
  }

  @override
  String get ui55592984d7c8 => 'Map image saved';

  @override
  String ui61e2ca3a278c(String v0) {
    return 'Map preview could not update. Geometry is retained: $v0';
  }

  @override
  String ui997f080ca254(String v0) {
    return 'Map preview failed: $v0. Stored features are retained.';
  }

  @override
  String ui2997787343d9(String v0) {
    return 'Map still needs review: $v0';
  }

  @override
  String get uif001c704b2c4 =>
      'Map tiles need internet. Saved geometry stays on this device.';

  @override
  String uia81b9bf05314(String v0) {
    return 'Map update still needs review: $v0';
  }

  @override
  String get ui6e34e5bb76d4 => 'Map-based spatial editing and layers';

  @override
  String get uib5b7b220e6fc => 'MapBanai';

  @override
  String get uibfd3beb1d90d =>
      'MapBanai gratefully acknowledges the contributions of the CARE project and BRAC James P Grant School of Public Health, BRAC University, to its development.';

  @override
  String get ui0911cce79bf0 => 'Mark done';

  @override
  String get ui67c691a7034c => 'Mark not collected';

  @override
  String get uibd37e4010390 => 'Mark undone';

  @override
  String get ui6d9883bf2564 =>
      'Matching DBF not found in that folder. Select SHP and companions together or import their ZIP.';

  @override
  String get uidf64ffd50ab4 => 'Max acceptable accuracy';

  @override
  String get uic4af0cbf2c57 => 'Maximum download size';

  @override
  String get uid4fd0a232ee5 => 'Measure';

  @override
  String get uiff3c5f95f7ed => 'Measure Area';

  @override
  String get ui44d5eb4c451a => 'Measure Distance';

  @override
  String get uiacca68cf2978 => 'Measure area — tap points on the map';

  @override
  String get uif9387f539eef => 'Measure distance — tap points on the map';

  @override
  String get uide10edfac7e7 => 'Measurement';

  @override
  String get ui31d24b69ea44 => 'Measurement (e.g. salinity)';

  @override
  String get ui7f4511910c62 => 'Measurement units';

  @override
  String get ui57f5f5efbc59 => 'Menu';

  @override
  String get uif729a52d65af => 'More site details';

  @override
  String get uib5b2f93a6b40 =>
      'Move is available for points. Use Redraw geometry for lines and areas.';

  @override
  String get uica80cd791254 => 'Move with GPS to get a heading fix';

  @override
  String get uif0948991d684 => 'Multipart geometry';

  @override
  String get ui51a144b4a026 => 'My enumerator name';

  @override
  String get ui53f1631a0c9a => 'My forms';

  @override
  String get uia8f40df7087b => 'My name';

  @override
  String get ui3e2d598760ca => 'My responses';

  @override
  String get ui709a23220f2c => 'Name';

  @override
  String ui1dc947fc26a5(String v0) {
    return 'Name  $v0';
  }

  @override
  String get ui9c9f03a83941 => 'Name (optional)';

  @override
  String get uie997727f66e0 => 'Name used in change history';

  @override
  String get ui3158214aeaa5 => 'Native Excel workbook';

  @override
  String get ui33a506cf6ec5 => 'Needs review';

  @override
  String get ui8d5addc5f483 => 'Never synced';

  @override
  String get ui19770feca231 =>
      'New and updated features require a questionnaire. Select a survey form first.';

  @override
  String get ui5dcfe56ae106 => 'New collection round';

  @override
  String get ui26445874a106 => 'New key';

  @override
  String get uia9cbc7c7f1b8 => 'New log (new CSV)…';

  @override
  String get uie5bcbe241fab => 'New project';

  @override
  String get ui2769be10eb54 => 'New study layer';

  @override
  String ui7a022d6fe436(String v0) {
    return 'New version: $v0';
  }

  @override
  String get ui816c52fd2bdd => 'No';

  @override
  String get ui392acae55a83 =>
      'No GIS features found for the selected project(s)';

  @override
  String get ui433fd35b58a5 => 'No GPS logs yet';

  @override
  String get uif617dbefda4a => 'No GPS readings above the limit need review.';

  @override
  String get uie4dc9d32f051 => 'No answers recorded.';

  @override
  String get ui43572a512bc0 => 'No attributes';

  @override
  String get ui87d822a81929 =>
      'No completed observations yet. Add the first visit.';

  @override
  String get ui5c8ea1c2ed1a =>
      'No conflicts. Imported revisions include their original data and change history.';

  @override
  String get uied30d59a8d6d =>
      'No connected road route found. Add a road layer in Project settings.';

  @override
  String get ui853fb4fdd27f => 'No coordinates available';

  @override
  String get uie2dbdc3a52a2 => 'No coordinates were available at capture time';

  @override
  String get uif354c94fcf63 => 'No description';

  @override
  String get ui904b785a37ab =>
      'No forms yet for this project. Tap to build or import your first survey form.';

  @override
  String get ui92d5dd12f567 =>
      'No forms yet. Add one or import an XLSForm file.';

  @override
  String get ui2f5bb047a0f6 => 'No geometry captured';

  @override
  String get ui036703da6a32 => 'No heading yet';

  @override
  String get ui836f41ede479 => 'No internet connection';

  @override
  String get ui6087965952b8 => 'No layer recorded';

  @override
  String get uiae6b04b93c15 => 'No matching sites';

  @override
  String get uidfa7f347627b => 'No newer version is available.';

  @override
  String get uiae25632243b8 => 'No offline packages downloaded yet.';

  @override
  String get ui382cac49e35d => 'No options yet. Add at least one.';

  @override
  String get ui48c8c8d3aa3b =>
      'No photos yet.\nCapture photos from a survey form to see them here.';

  @override
  String get uie92a1f7c42cf => 'No project selected';

  @override
  String get uie5fafd1c8ebb => 'No project selected — tap to choose one';

  @override
  String get ui6665189f3494 => 'No projects available.';

  @override
  String get uicac330d7f9c7 => 'No projects yet';

  @override
  String get ui8f998ef5b30b =>
      'No projects yet. Create one to start collecting data.';

  @override
  String get uib463f7374d70 => 'No questions yet. Add one to get started.';

  @override
  String uie9ee6096e679(String v0) {
    return 'No readings in \"$v0\" to project';
  }

  @override
  String get ui151474224c7d => 'No readings in selected logs';

  @override
  String get ui7640fd2eb8bb => 'No readings to project';

  @override
  String get ui9b6d98a4e333 => 'No readings yet';

  @override
  String get uife1834e75700 =>
      'No recorded changes yet. Imported baseline is preserved when the first edit is saved.';

  @override
  String get ui87becd98de59 => 'No reference layers added to this project yet.';

  @override
  String get ui8899a85385a5 => 'No release notes were provided.';

  @override
  String get ui8b43f54f33b8 => 'No saved map data in the selected projects';

  @override
  String get ui8c878a00b717 => 'No saved responses or drafts yet';

  @override
  String get ui19979c176042 => 'No saved responses to export';

  @override
  String get uiaf682dd08f05 => 'No saved responses yet';

  @override
  String get ui58128e2f84a1 =>
      'No saved templates. Open a configured project → Reusable templates to save one.';

  @override
  String get uif30931fdc702 =>
      'No sites found in file. Check format and lat/lon columns.';

  @override
  String get uic548672fb2d6 => 'No sites to export';

  @override
  String get ui7e2d4edf8815 => 'No sites yet';

  @override
  String get uif26623d21a06 =>
      'No survey responses found for the selected project(s)';

  @override
  String get uiac6625252c3f => 'No unassigned sites';

  @override
  String get ui2a5fc945373b => 'Not collected';

  @override
  String get ui7bf902055995 => 'Not computed yet';

  @override
  String get ui9f7b8e910f33 => 'Not geotagged';

  @override
  String get uie45714907316 => 'Not now';

  @override
  String get ui2c924e308820 => 'Note';

  @override
  String get ui4e39567064b6 => 'Note (optional)';

  @override
  String get ui70440046a3dc => 'Notes';

  @override
  String get ui4d56ca9be0c8 => 'Notes (optional)';

  @override
  String get ui9ce3bd4224c8 => 'OK';

  @override
  String get ui998c59e3a961 => 'Offline HTML map with filters and popups';

  @override
  String get ui119fc20f71cb => 'Offline maps';

  @override
  String ui954017dab827(String v0, String v1, String v2) {
    return 'Offline · zoom $v0–$v1\n$v2';
  }

  @override
  String ui952291e4cc99(String v0, String v1, String v2, String v3) {
    return 'Offline: $v0 · zoom $v1–$v2\n$v3';
  }

  @override
  String get uia7f9620cca32 => 'On this device';

  @override
  String get ui439fd7184b90 =>
      'One project connects your questions, maps and fieldwork.';

  @override
  String ui2e563e00b757(String v0) {
    return 'Online · $v0';
  }

  @override
  String get uia8076ae6d925 =>
      'Only readings above this limit appear. Accepted readings stay hidden; photos and records remain saved.';

  @override
  String get uif0fa69f38b14 => 'Opacity';

  @override
  String get uicf9b77061f7b => 'Open';

  @override
  String get ui805e12a18145 => 'Open GPS Mode';

  @override
  String get uif8063877dde0 => 'Open app permission settings';

  @override
  String get ui672b0208a0f6 => 'Open camera';

  @override
  String get ui2150bfbc8020 => 'Open device location settings';

  @override
  String get ui5ebdd4c27529 => 'Open in Google Maps';

  @override
  String get ui052269b2c823 => 'Open in browser';

  @override
  String get uie56f29da2af3 => 'Open map';

  @override
  String get uicb29cc08fc8f => 'Open study-area map';

  @override
  String get ui7a5cbb59b55f => 'Open survey';

  @override
  String get ui942b4ee5ed69 => 'Open the camera to scan a project code';

  @override
  String get ui3f7389db6ed3 => 'Option name and label are required';

  @override
  String ui7ef766113146(String v0) {
    return 'Options ($v0)';
  }

  @override
  String get uia6aab53912af => 'Original imported data';

  @override
  String get ui5651e882f4a9 => 'Other response formats';

  @override
  String get ui55007921901d => 'Paste instead';

  @override
  String get uie5dc642cc6a3 => 'Paste project code';

  @override
  String get ui5c5260ab99c7 => 'Paste the MapBanai code here';

  @override
  String get ui781961bc81c2 => 'Pause';

  @override
  String get uie1f973e6e1a9 => 'Pause GPS stream';

  @override
  String get uif0ac0a5c9beb => 'Pending verification';

  @override
  String get ui8bc8ef67bedc => 'Period / season (optional)';

  @override
  String get ui5f602ed63d66 =>
      'Phone direction · magnetic north. Keep the phone reasonably flat.';

  @override
  String get uia6685fdd7078 => 'Photo attached';

  @override
  String get ui568e6f033820 => 'Photo attached with embedded GPS.';

  @override
  String get ui782facfeed05 => 'Photo gallery';

  @override
  String ui431dc8d2e072(String v0) {
    return 'Photo: $v0';
  }

  @override
  String get uic8b2e864eccb => 'Photos';

  @override
  String get ui4cec4b3d3d96 => 'Pick a QR image from your gallery';

  @override
  String get uid3a2a512adb0 => 'Pick a project package from your device';

  @override
  String get uia41391d44a4e => 'Please add at least one question';

  @override
  String get ui0e992c42efc9 => 'Please enter a form name';

  @override
  String get uic9bcbcdab335 => 'Please enter a project name';

  @override
  String get uif79a28423ed1 => 'Point';

  @override
  String get uic958a23eb380 => 'Point moved';

  @override
  String get ui5be4bcfb8831 => 'Point saved';

  @override
  String ui27c764375b49(String v0) {
    return 'Point size: $v0';
  }

  @override
  String get ui85066b2ca9c0 => 'Polygon';

  @override
  String get uidd91219a18cb => 'Polygon saved';

  @override
  String get uic2519dfe070d => 'Polygon vertices must enclose an area.';

  @override
  String get ui70f0551a5274 => 'Portable HTML map';

  @override
  String get uifc0196129453 => 'Positioning…';

  @override
  String get ui1c7b0d771fbc => 'Preferred language';

  @override
  String get ui90aee2f30cc4 => 'Preview matching sites';

  @override
  String get uib08dc534b1c0 => 'Previous data backup found';

  @override
  String get uif6f4da8d93e8 => 'Project';

  @override
  String ui1e7149806327(String v0) {
    return 'Project \"$v0\" deleted';
  }

  @override
  String get uibd3091d453d7 => 'Project Atlas';

  @override
  String get uib23aff4a7cbf => 'Project QR code';

  @override
  String get ui431c23dde814 => 'Project already exists';

  @override
  String get ui225209bf7dec => 'Project archived';

  @override
  String get uib23910158f74 => 'Project code';

  @override
  String uib56eb4f4a3ed(String v0) {
    return 'Project created: $v0';
  }

  @override
  String get ui15626cd209c8 => 'Project exported successfully.';

  @override
  String get ui966c4d7db1ab => 'Project files and map layers';

  @override
  String get ui5276d025220f => 'Project imported successfully.';

  @override
  String get ui379ec791fb77 => 'Project is too large for direct QR transfer.';

  @override
  String get ui9c8bf2326c83 => 'Project layers';

  @override
  String get ui0a71e1dcd500 => 'Project multiple logs on WebMap';

  @override
  String get uib046dc8ee258 => 'Project multiple on WebMap';

  @override
  String get uiab9773fcf6b2 => 'Project name';

  @override
  String get uiaf9d308f03d7 => 'Project not found for this draft';

  @override
  String uicdaab9257a39(String v0) {
    return 'Project not found: $v0';
  }

  @override
  String get ui62d5732e064a => 'Project on WebMap';

  @override
  String get uibf395c9c1cc0 => 'Project options';

  @override
  String ui8f59a4be38fd(String v0) {
    return 'Project renamed to \"$v0\"';
  }

  @override
  String get uicd1b8386c131 => 'Project restored';

  @override
  String get ui95590645e1aa => 'Project settings';

  @override
  String get uia0e72cd3d2e8 => 'Project setup';

  @override
  String get ui2e5be53bba6a => 'Project survey form';

  @override
  String get uibd1dec2f2c71 => 'Project vector layers';

  @override
  String get ui36043cc2443b => 'Project with responses (.mbproj)';

  @override
  String get uia476649af65d => 'Project without responses (.mbproj)';

  @override
  String ui343f53c678de(String v0) {
    return 'Project $v0 logs';
  }

  @override
  String ui29bccf013ea5(String v0) {
    return 'Project: $v0';
  }

  @override
  String get uiabba02fcdd8b => 'QR code';

  @override
  String get uif4c26c16fcc1 => 'Question label';

  @override
  String ui16b39146c10b(String v0) {
    return 'Question names must be valid and unique: $v0';
  }

  @override
  String get uia60d848de552 => 'Question type';

  @override
  String get ui42d2c2bca9d8 => 'Questionnaire';

  @override
  String get ui4be7ca321825 =>
      'Questionnaire required for new or updated features.';

  @override
  String get ui8ff5b8ed3fbd => 'Questionnaire to compare';

  @override
  String get ui9a1fc1731f62 => 'Questions';

  @override
  String ui1e9664cb649f(String v0) {
    return 'Questions ($v0)';
  }

  @override
  String get uicfee98bac20a =>
      'Record GPS tracks in GPS Mode. They will appear here for viewing and WebMap overlay.';

  @override
  String get ui607b32a9959b => 'Record Line';

  @override
  String get uiaec89b24cf54 => 'Record Point';

  @override
  String get uid8bada38f2f6 => 'Record Polygon';

  @override
  String get ui2a0da2391fbd => 'Record Track';

  @override
  String get uid5237368f5b8 => 'Record survey at GPS';

  @override
  String get uic28f100b78f1 => 'Record to this log';

  @override
  String get uidb83f96c32b4 => 'Record type';

  @override
  String get ui0161dce2f8e3 => 'Recorded day (local time)';

  @override
  String get ui460b7c299f9e => 'Recording stopped';

  @override
  String uidea4c38150d8(String v0) {
    return 'Recording to \"$v0\"';
  }

  @override
  String get uif67cf3727042 => 'Recurring Collection';

  @override
  String get uic5d2acf8e03c => 'Redraw geometry';

  @override
  String get ui07e6773d4d9c => 'Reference layer';

  @override
  String get ui56e3badc4e6c => 'Refresh';

  @override
  String get uif2fe9f375cdd => 'Refresh GPS';

  @override
  String get uia06a8c2c4e63 => 'Refresh accuracy review';

  @override
  String get ui78b1a724f71d => 'Refresh packages';

  @override
  String get ui43f7ea278bf5 => 'Refresh road directions';

  @override
  String get ui526e453413f1 => 'Relevance (optional)';

  @override
  String get uie963907dac5c => 'Remove';

  @override
  String get uif08d9c42d5af => 'Remove geometry';

  @override
  String get uia1cc8f73a0c8 => 'Remove imported file and its points';

  @override
  String get ui307eeae7c0c0 => 'Remove imported file?';

  @override
  String get uif8ed171e210e => 'Remove layer';

  @override
  String get ui2bd3912b6424 => 'Remove layer?';

  @override
  String get uic8f5eda8ace9 => 'Remove photo';

  @override
  String get ui12605ebbc10b => 'Remove template';

  @override
  String get ui67d95d8bf8e4 =>
      'Remove this photo from the device? This cannot be undone.';

  @override
  String uid6db25dad8ea(String v0) {
    return 'Remove $v0 selected map sites and their local histories? This cannot be undone.';
  }

  @override
  String ui3122a19db20f(String v0) {
    return 'Removed $v0 imported points and their history.';
  }

  @override
  String get uid3f4cb898fbe => 'Rename';

  @override
  String get ui633018f5a717 => 'Rename project';

  @override
  String get uia7cf7b25a703 => 'Replace';

  @override
  String get uif16ae4a6851b => 'Replace existing project';

  @override
  String get uia89003cf0f13 => 'Replace photo';

  @override
  String get uieed6bfb41051 => 'Required';

  @override
  String get uif83e688e4165 => 'Reset data';

  @override
  String get ui6e617e4fc9da => 'Response';

  @override
  String ui224ce158da54(String v0) {
    return 'Response revision $v0';
  }

  @override
  String get ui69618bf63a73 => 'Responses only (JSON)';

  @override
  String get ui3cbe6d6b9a8d => 'Restore';

  @override
  String uid2dd4647b6a1(String v0) {
    return 'Restore \"$v0\"? It will appear in project setup again.';
  }

  @override
  String ui04d55c7638dc(String v0) {
    return 'Restore failed: $v0';
  }

  @override
  String get uib3bd0b5a7049 => 'Resume';

  @override
  String get ui7e5b0347808e => 'Resume GPS stream';

  @override
  String get ui21b653c8009c => 'Resume saved draft';

  @override
  String get uibd0551d8ee60 => 'Resume survey draft';

  @override
  String get ui16457335a763 => 'Retake';

  @override
  String get ui9f5cd8a2e880 => 'Retry';

  @override
  String get uifce3486f03c9 => 'Retry GPS for selected photo';

  @override
  String get ui6514e3faf04e => 'Retry map update';

  @override
  String get ui29ae74246d4f => 'Reusable templates';

  @override
  String get ui42468c5b8e1a =>
      'Reuse questionnaires and named layers for a new campaign. Templates contain setup only; each new project gets a fresh identity and needs its own cloud connection. Existing visits and photos stay in the original project.';

  @override
  String get ui5d4f7bae5f1d =>
      'Review GPS accuracy above your limit. Accept a reading if it is suitable for your fieldwork.';

  @override
  String get ui4554e09dd77d =>
      'Review and apply changes when connected. New surveys use the new version; saved records and drafts keep their original questions.';

  @override
  String get ui617ceeb41a65 => 'Review deletion';

  @override
  String get ui98bd92828e31 => 'Review form import';

  @override
  String get ui0f667a68b0fb => 'Review map conflict';

  @override
  String get ui6fc4758d8c5b => 'Review or edit geometry';

  @override
  String get uif960c9515a5b => 'Review saved survey';

  @override
  String get uicaacc870d2ec => 'Review team import';

  @override
  String get uib5bb91f5eb74 => 'Review visit / retry map update';

  @override
  String ui39b253e1a983(String v0) {
    return 'Revision history ($v0)';
  }

  @override
  String get uia4c9e7ac0818 => 'Road network';

  @override
  String get ui1e975193e087 => 'Run survey';

  @override
  String get uid0d3749eff6d => 'SAVE PROJECT FILE';

  @override
  String get uif5c9eb0215b6 => 'SHARE PROJECT';

  @override
  String get uiefc007a393f6 => 'Save';

  @override
  String get uid69b9213e0b9 => 'Save Point';

  @override
  String get ui80f3d11ef8a0 => 'Save anyway…';

  @override
  String get ui77d9d7593ba8 => 'Save as draft';

  @override
  String get ui4f25637a5b7e => 'Save draft';

  @override
  String uie89b75ddfae2(String v0) {
    return 'Save failed: $v0. Your edits are retained.';
  }

  @override
  String get uia8a28cda227e => 'Save feature';

  @override
  String get ui1194006347b8 => 'Save geometry';

  @override
  String get ui48b133194fc7 => 'Save line';

  @override
  String get uie5c47400711a => 'Save location';

  @override
  String get uib38557160b3a => 'Save point';

  @override
  String get uidb6b0a422ee8 => 'Save point to…';

  @override
  String get uieba0e7af2b62 => 'Save polygon';

  @override
  String get uif8132b134652 => 'Save responses';

  @override
  String get uiae8411a6278d => 'Save selected layer and questionnaire';

  @override
  String get uiaefec51925dd =>
      'Save the questionnaire and attach a photo to finish. You can save a draft at any time.';

  @override
  String get ui9797b0b4a5c1 => 'Save this project as template';

  @override
  String get uie30f8f020ce6 => 'Saved answers';

  @override
  String get ui57dd6e65063e => 'Saved on this phone · waiting to sync';

  @override
  String get ui2391ec16d44b => 'Saved projects';

  @override
  String uic1b9736fedd0(String v0) {
    return 'Saved response for $v0';
  }

  @override
  String get ui28bb6965aeec =>
      'Saved responses appear here; unfinished work is kept as drafts';

  @override
  String get uibf4522143a41 => 'Saved visit';

  @override
  String get uiae7e887517b0 => 'Saving...';

  @override
  String get uie7d8c30678ab => 'Scan QR code';

  @override
  String get uif64c3fbefbf2 => 'Scan QR from gallery';

  @override
  String get ui555b8b1249e2 => 'Search by name or location';

  @override
  String get ui5c562a19562f =>
      'Select GeoJSON, GeoPackage, SHP/ZIP, CSV, Excel or KML/KMZ.';

  @override
  String get uif19de55e63d0 =>
      'Select a project above to see its collected data.';

  @override
  String get uif386a8052a3a => 'Select a project and survey form first.';

  @override
  String get ui410ffc9a264e => 'Select a project before building a form';

  @override
  String get ui4405857e86b5 => 'Select a project before drawing';

  @override
  String get ui65c52d24239c => 'Select a project first';

  @override
  String get uia1444962ecdb => 'Select a project questionnaire first.';

  @override
  String get ui7e607015bb18 => 'Select a project, then import its site layer.';

  @override
  String get ui74d7e0804c5c =>
      'Select a questionnaire and collection round first.';

  @override
  String get ui3b1a1262ef90 => 'Select a survey form';

  @override
  String get ui913afff1faf7 => 'Select all';

  @override
  String uifdc38dcd3912(String v0) {
    return 'Select all ($v0 selected)';
  }

  @override
  String get uiebaab4e02ce5 => 'Select an active project first';

  @override
  String get ui08d7aa35da9a => 'Select an option';

  @override
  String get ui648c09b587f6 => 'Select at least one project';

  @override
  String get ui3e009481cb29 => 'Select basemap';

  @override
  String get uib84a6ecbc04c => 'Select date';

  @override
  String get ui94c7b6109333 => 'Select date and time';

  @override
  String get ui7e8fcd733d84 => 'Select logs to project';

  @override
  String get ui1181e5025b41 => 'Select multiple';

  @override
  String get ui4998e80cffcd => 'Select one';

  @override
  String get uib4b37dd6ce6d => 'Select project';

  @override
  String get ui4978072af3ac => 'Select projects to export';

  @override
  String get uia7cf335d4076 =>
      'Select the questionnaire and measurement to separate, such as salinity. Only saved responses with that measurement and a point location become sites. Original responses stay intact.';

  @override
  String get ui3d7f91e8e71b => 'Select time';

  @override
  String get uic72ef626fe86 => 'Set relative height reference here';

  @override
  String get ui74a6ff25d6dd => 'Set up cloud sync';

  @override
  String get uicc1544692441 => 'Set up cloud sync for this project first';

  @override
  String get uic7f73bb54d92 => 'Settings';

  @override
  String get uiaef97bb06af4 => 'Settings saved';

  @override
  String get uica90d5bc4a0e => 'Shapefile companion files';

  @override
  String get ui348cf86fa1bc => 'Shapefile, CSV, Excel, GeoJSON and GeoPackage';

  @override
  String get ui09ca55ca52d2 => 'Share';

  @override
  String get ui142e4a88490f => 'Share CSV';

  @override
  String get ui25dac6eacbc4 => 'Share HTML file';

  @override
  String uifdf43a7041a5(String v0) {
    return 'Share failed: $v0';
  }

  @override
  String get uic282b0009d54 => 'Share project';

  @override
  String get uib5f97af82c42 =>
      'Share the URL and API key only with trusted enumerators.';

  @override
  String get uidf6284851e35 => 'Shared secret token';

  @override
  String uid94a0488d308(String v0) {
    return 'Sharing failed: $v0';
  }

  @override
  String get ui9a7f5c9f9c01 => 'Sharing is not available right now.';

  @override
  String get uidd2e0b7ceac6 => 'Sharing project…';

  @override
  String uia137ead9a9c9(String v0) {
    return 'Shortest road route  $v0';
  }

  @override
  String get ui50a279de829f => 'Show all';

  @override
  String get uib666c5857d85 => 'Show road directions';

  @override
  String get ui6b97e76a48a2 => 'Shown when the constraint is violated';

  @override
  String get ui2ff741423601 => 'Simple form-based field capture';

  @override
  String get ui51b35f60ed25 => 'Single color';

  @override
  String get uif8115c6458d3 => 'Site deleted';

  @override
  String get ui03611ed63fe3 => 'Site layer';

  @override
  String get ui70648b5ca5bb => 'Site observation';

  @override
  String get ui72a6527e5742 => 'Site timeline';

  @override
  String get ui73c4785414b8 => 'Site timeline / add observation';

  @override
  String get uif08625843372 => 'Site timeline / compare observations';

  @override
  String get uidc61591e7417 => 'Site visits';

  @override
  String get ui046c5d454e0a => 'Site visits with status tracking & navigation';

  @override
  String get ui3da474537ac3 => 'Skip';

  @override
  String get ui952f375412e8 => 'Start';

  @override
  String get ui2932e9a9f29d => 'Start another visit';

  @override
  String get ui02c86d972b56 => 'Start building survey form';

  @override
  String get uie92d02d3d165 => 'Start recording';

  @override
  String get ui814036be3ced => 'Start visit';

  @override
  String get uibae7d5be7082 => 'Status';

  @override
  String get ui9e253470c876 => 'Stop';

  @override
  String get ui72d339ddaa22 => 'Stop following';

  @override
  String get uiee0d9dc8eb5e => 'Stop recording';

  @override
  String get ui794e05ff6f15 => 'Study Area';

  @override
  String get ui7454029d069c => 'Study Area Mode';

  @override
  String get ui792ac04306e0 => 'Study Area Visits';

  @override
  String get uiafa82e671a4d => 'Study Area points / imports';

  @override
  String get ui140781d627c5 => 'Study Area — View only';

  @override
  String get ui2e09116ca6c8 => 'Study area';

  @override
  String get uiaec7160f7d63 => 'Study layer';

  @override
  String get ui3d5101991a4b => 'Study workspace';

  @override
  String get uibae35f4f69ef => 'Survey Form Builder';

  @override
  String get uifd8eb8a44d22 => 'Survey History';

  @override
  String get ui6a0244a36b78 => 'Survey Mode';

  @override
  String get ui15b4700cfe17 => 'Survey Response';

  @override
  String get ui56eaf8c1a78e => 'Survey Responses';

  @override
  String get ui27429641f3a8 => 'Survey and GIS map (GeoJSON)';

  @override
  String get ui1cdf92b9422d => 'Survey feature saved';

  @override
  String get ui0f50e6cd5d73 => 'Survey form';

  @override
  String get ui61cd448fd742 => 'Survey form not found for this draft';

  @override
  String get ui26ae75d9a213 => 'Survey forms';

  @override
  String ui1bbe80df74aa(String v0) {
    return 'Survey response: $v0';
  }

  @override
  String get uidb7d0e51a156 => 'Survey responses';

  @override
  String get uia7d7ae64cf27 => 'Survey responses (CSV)';

  @override
  String get uibd39220a2d4d => 'Survey saved; map update needs attention';

  @override
  String get uia515beba342a =>
      'Switch between languages defined in the XLSForm';

  @override
  String get ui905f63092ff2 => 'Sync';

  @override
  String get uia625528186cb => 'Sync complete';

  @override
  String get ui39040109b600 => 'Sync failed';

  @override
  String get uiecbe8bb3855d => 'Sync finished';

  @override
  String get ui3e2b9221a8fb => 'Sync questionnaire';

  @override
  String get ui12df0ea3611e => 'Sync status';

  @override
  String get ui9f462978795c => 'Synced · edit to send a new revision';

  @override
  String get uie5c7727a106e => 'Syncing...';

  @override
  String get ui9d8d3808063b => 'System default';

  @override
  String get ui02de1f69347b => 'Tap a feature on the map to see details';

  @override
  String get ui434e87b69d53 => 'Tap a feature on the map to see its details';

  @override
  String get uic12b336a09df => 'Tap the map to add the first point';

  @override
  String get uic11008251fcb =>
      'Tap the map to place this feature at its new location.';

  @override
  String get ui3033c8b8aac7 => 'Tap to capture GPS location';

  @override
  String get ui38d2049ea91a => 'Tap to measure accuracy';

  @override
  String get ui580f6ab716ab => 'Test Connection';

  @override
  String get ui15ccc83272b1 => 'Testing...';

  @override
  String get uic3328c39b0e2 => 'Text';

  @override
  String get ui8a9c91641630 =>
      'The .mbproj package includes forms, GIS source files, map layers, settings and cloud setup scripts. Choose whether to include collected responses and their photos.';

  @override
  String get ui1341db575a04 => 'The collected vertices will be discarded.';

  @override
  String get ui0f6a7c9875c9 =>
      'The draft project is unavailable. Restore the project before resuming.';

  @override
  String get uia797e30923ac => 'Theme';

  @override
  String get ui2a2618391b6d =>
      'These are stored map sites without a project assignment. Review their details before assigning or deleting them. They are separate from survey responses.';

  @override
  String ui8a91047b84cc(String v0) {
    return 'This complete geometry is preserved. Edit its parts in GIS software and merge the revised GeoJSON to redraw it.\n\n$v0';
  }

  @override
  String get ui1644de68ca1f =>
      'This draft’s site or questionnaire is no longer available.';

  @override
  String get ui5163769c6478 =>
      'This feature changed elsewhere. Reopen it and review the latest version.';

  @override
  String get ui845d01d70891 =>
      'This field already exists. Edit its value above.';

  @override
  String get ui7aae0b62872a => 'This form has no questions yet.';

  @override
  String get ui4991b992a518 =>
      'This layer has no points or survey history to clear.';

  @override
  String get ui7e8c2ede22e2 =>
      'This legacy form has unsupported repeats. Import a form with one submission per feature before collecting more data.';

  @override
  String get ui7fa6ed0dde94 => 'This question type needs at least one option';

  @override
  String get uid8245487967c =>
      'This removes its offline resources. Your surveyed features and photos stay on the device.';

  @override
  String ui0178bef432ea(String v0) {
    return 'This will remove “$v0” from this project.';
  }

  @override
  String uia87ef6452c2d(String v0, String v1) {
    return 'This will remove “$v0”, its map layer, $v1 imported points, and their local history.';
  }

  @override
  String get ui6c82e6dd8680 => 'Time';

  @override
  String get ui19eabc961735 => 'Timestamp';

  @override
  String get uid79eb0a68863 => 'Track name (optional)';

  @override
  String get uib41665a86980 => 'Turn on location services.';

  @override
  String ui4f1b0f8aa40a(String v0) {
    return 'Type: $v0';
  }

  @override
  String get ui51ed65113221 => 'Unchanged';

  @override
  String get ui39fc72124884 => 'Undo';

  @override
  String get uib528b0fe2e94 => 'Undone';

  @override
  String ui47091b4936c3(String v0) {
    return 'Update v$v0 is available';
  }

  @override
  String uifc3b7a12bc25(String v0) {
    return 'Updated \"$v0\" from XLSForm';
  }

  @override
  String get uif33de2a5a459 => 'Updated map (GeoJSON)';

  @override
  String get uic76d18079a07 => 'Updates';

  @override
  String get ui3f90215b1701 => 'Upload responses & photos to cloud';

  @override
  String get ui5874b63bbc58 => 'Use area around my GPS location';

  @override
  String get uiab731c818a80 => 'Use distinct vertices.';

  @override
  String get uif3d5a30b0ad2 => 'Use incoming version';

  @override
  String get ui3f546b7d94c3 => 'Use layers in';

  @override
  String get uia75e1e286eed => 'Use photo';

  @override
  String get ui2dec1c905e5d =>
      'Use the top Import button for GeoJSON, GeoPackage, zipped shapefiles, CSV, Excel or KML/KMZ.';

  @override
  String get ui890fcb6fc818 =>
      'Use your own server or a provider that permits offline downloads. Built-in OSM, CARTO and Esri basemaps remain online-only. Keep the app open while downloading. Packages are not part of survey backups; re-download them after reinstall.';

  @override
  String get uib9d2e508d3e7 =>
      'Used by the GIS distance and area tools. Automatic picks metres/kilometres and square metres or hectares.';

  @override
  String get ui9f8a2389a20c => 'User';

  @override
  String get ui542fc71480de => 'User name';

  @override
  String get ui8dce170de238 => 'Value';

  @override
  String get uibe37e18e12ab => 'Value (no spaces)';

  @override
  String get uibc23d6952888 => 'Verification / change note';

  @override
  String get ui062e095d2e00 => 'Verification Complete';

  @override
  String get ui760fa1d0a21b => 'Verification status';

  @override
  String get ui08f9848508a4 => 'Verify with questionnaire';

  @override
  String ui93af16ef7e20(String v0) {
    return 'Version $v0';
  }

  @override
  String ui6b6212f516b9(String v0) {
    return 'Version $v0 is available';
  }

  @override
  String get uie21d16e2187b =>
      'Vertical accuracy unavailable. GNSS altitude is not a reliable floor-height measurement indoors.';

  @override
  String ui670ea96a1459(String v0) {
    return 'Vertical uncertainty ±$v0 m · WGS84 ellipsoid, not sea level or height above ground.';
  }

  @override
  String get ui9db62a629ff2 => 'View / edit information';

  @override
  String get ui70144df223fc => 'View CSV';

  @override
  String get ui32105310ab3b => 'View and filter features in a browser';

  @override
  String get uia08f63479914 => 'View logs & project tracks on WebMap';

  @override
  String get ui78caa7422cf5 => 'View only — do not import';

  @override
  String get ui5ceea82d3743 => 'View record';

  @override
  String get uidbad9f126b33 => 'Viewer';

  @override
  String get uiae28ae06cab2 => 'Visit a study site';

  @override
  String get ui2f33af1452b9 =>
      'Visit and photo are saved. Study map update is pending.';

  @override
  String get ui13db299e703f => 'Visit another feature';

  @override
  String get uifcb7f8e18aa1 => 'Visit date';

  @override
  String get ui18a8706ac9c3 => 'Visit draft saved. You can resume it later.';

  @override
  String get uibacabffc7265 =>
      'Visit facilities and track done, pending or review.';

  @override
  String get uid983c98256a6 => 'Visit outcome';

  @override
  String get ui06547aa978e8 => 'Visit saved and study map updated.';

  @override
  String ui8d3b6ce77936(String v0) {
    return 'Visit saved; map update needs review: $v0';
  }

  @override
  String get uiaea1d8c3ba27 =>
      'Wait for a fresh GPS location before recording a site.';

  @override
  String get uidbeb4f38e866 =>
      'Wait for a fresh, accurate GPS fix (within 25 m and 30 seconds), or tap the map manually.';

  @override
  String get ui1599512dd4fa => 'Waiting for GPS fix';

  @override
  String get ui69d5b3e27393 => 'Waiting for a GPS fix';

  @override
  String get ui0f1b5fa21d3e => 'Waiting for a GPS fix before saving a point';

  @override
  String get uib933ed0f85ce => 'Waiting for a GPS fix before saving the draft';

  @override
  String get ui46d1bd7a4fe5 => 'Waiting for a GPS fix to place the point';

  @override
  String get ui403fb7e4a07b => 'Waiting for position…';

  @override
  String get uie8f3a099b17e => 'Waiting to sync';

  @override
  String get ui3650b57a63bc => 'Waiting…';

  @override
  String get ui203aa501a2cf => 'Walk along the boundary while recording';

  @override
  String get ui112c28094e9c => 'WebMap';

  @override
  String ui8524c9daa511(String v0) {
    return 'WebMap failed: $v0';
  }

  @override
  String get ui83476ddef06c => 'Welcome to MapBanai';

  @override
  String get uib16023bdc345 => 'XLSForm import limitations';

  @override
  String get ui5397e0583f14 => 'Yes';

  @override
  String get ui9f628b61ae0f => 'Yes/No';

  @override
  String get ui5fc15792a3b6 => 'You\'re up to date';

  @override
  String get uiab42293e29e1 => 'Your name';

  @override
  String get ui91dd05f1187c =>
      'Your name is attached to every survey response, GPS log entry and export produced by the app.';

  @override
  String get ui50ee0028c989 =>
      'Zoom 18 maximum; 6,000 tiles maximum. Download covers only these bounds and zooms. Larger areas need lower zoom or separate packages.';

  @override
  String get uic0b885fe691b => 'applied';

  @override
  String get ui0e7766b460fd => 'draft';

  @override
  String get ui2f232eece4a3 => 'e.g. Riverbank survey';

  @override
  String get ui7e6a1fc501ab => 'e.g. Salinity — October';

  @override
  String get ui3f29e0058e85 => 'e.g., \${field_name} = \"value\"';

  @override
  String get uie5aad6660c17 => 'e.g., \${width} * \${length}';

  @override
  String get uic4425e81a34d => 'e.g., . > 0 and . < 150';

  @override
  String get uidef3966f9daf => 'e.g., John Doe';

  @override
  String get ui89a91669c66b => 'e.g., Mild';

  @override
  String get ui4486060d3535 => 'e.g., Riverbank Survey';

  @override
  String get ui92d4bd903a26 => 'e.g., Site A boundary walk';

  @override
  String get ui3aedaef1c98d => 'e.g., Standing water at footbridge';

  @override
  String get uidac85c4db8ef => 'e.g., mild';

  @override
  String get uif4bce9423af7 => 'e.g., site_name';

  @override
  String get ui3744336ac6a4 => 'form_validated';

  @override
  String get uif408daa3bbc7 => 'import_batch_id';

  @override
  String get ui8745cffb3401 => 'magnetic north';

  @override
  String get ui6ae999552a0d => 'name';

  @override
  String get ui71f8e7976e4c => 'none';

  @override
  String get ui3032bf2db789 => 'reconciliation_error';

  @override
  String get ui1a77d416224c => 'required';

  @override
  String get uiac82a1d4da3f => 'site_sync';

  @override
  String get ui519742fe8995 => 'travel direction';

  @override
  String get ui383fd7bf84aa => 'warning';

  @override
  String ui16ae235ff3fa(String v0, String v1) {
    return '$v0  •  session #$v1';
  }

  @override
  String ui3047ae0d6f0b(String v0, String v1) {
    return '$v0  •  $v1  •  draft';
  }

  @override
  String ui74286a1f17a8(String v0, String v1) {
    return '$v0 / $v1 features';
  }

  @override
  String uib31c43e0e100(String v0, String v1, String v2) {
    return '$v0 / $v1 resources · $v2';
  }

  @override
  String ui856ae446a4d6(String v0) {
    return '$v0 MB';
  }

  @override
  String uid2ec3044ad26(String v0) {
    return '$v0 captured';
  }

  @override
  String uid4e292ed91bd(String v0) {
    return '$v0 features';
  }

  @override
  String ui56d31f5a5e0f(String v0) {
    return '$v0 features, full history for team merge';
  }

  @override
  String ui12126260f1ba(String v0, String v1) {
    return '$v0 matching records\n$v1 waiting to sync';
  }

  @override
  String uia98956288877(String v0) {
    return '$v0 matching site(s)';
  }

  @override
  String ui775784f1b2ec(String v0, String v1, String v2) {
    return '$v0 new features, $v1 incoming revisions, $v2 unchanged or older versions.';
  }

  @override
  String ui572d0978e0f5(String v0) {
    return '$v0 questions';
  }

  @override
  String ui8f1a22d54d2c(String v0) {
    return '$v0 readings';
  }

  @override
  String ui21c0f7d95d18(String v0, String v1) {
    return '$v0 records, including $v1 waiting to sync. Cloud copies remain unchanged.';
  }

  @override
  String uib66d8dcb4ef4(String v0) {
    return '$v0 saved';
  }

  @override
  String ui41dbbb7c36bc(String v0) {
    return '$v0 source file(s) included in project package';
  }

  @override
  String ui763b3b758174(String v0) {
    return '$v0 unassigned map sites';
  }

  @override
  String uibbb4b809c6ba(String v0) {
    return '$v0 vertices • Tap map to add vertices';
  }

  @override
  String uiaa45b4005be5(String v0) {
    return '$v0 — copy complete code';
  }

  @override
  String ui2255f673779e(String v0, String v1) {
    return '$v0 • Survey record $v1';
  }

  @override
  String ui1c1707c84f0d(String v0, String v1) {
    return '$v0 • version $v1';
  }

  @override
  String uie09431d672e4(String v0, String v1) {
    return '$v0 • $v1 questionnaires';
  }

  @override
  String ui89f846bf7eed(String v0) {
    return '$v0. Your last saved draft is preserved.';
  }

  @override
  String ui13d9100a93a2(String v0, String v1) {
    return '$v0/$v1 photos';
  }

  @override
  String uic7c34d515c8f(String v0, String v1) {
    return '$v0: enter a valid $v1';
  }

  @override
  String uib0b6457093f6(String v0, String v1) {
    return '$v0: $v1 vertices. Tap map to add vertices.';
  }

  @override
  String ui55cedac6145e(String v0, String v1) {
    return '\"$v0\" (version $v1) is already on this device.';
  }

  @override
  String ui98df2bcb058d(String v0, String v1) {
    return '\"$v0\" (version $v1).\n\nThis code carries project information only. Ask the sender for the project file (.mbproj) or an import QR code to add it to this phone.';
  }

  @override
  String get ui0c158c664316 =>
      'A backup from a previous MapBanai install was found. Restore settings and survey responses?';

  @override
  String ui14aec94c06c0(String v0) {
    return 'Archive \"$v0\"? It will be hidden from project setup. Its data is kept and can be restored later.';
  }

  @override
  String get uid11a9f1a48ea =>
      'Choose an export option above — the file will be shared or saved where you want it.';

  @override
  String get ui460b96b24627 =>
      'Connect this project to a Google Apps Script Web App for background sync.';

  @override
  String ui745bc847aafd(String v0, String v1) {
    return 'Current accuracy ($v0) is worse than the configured threshold ($v1). Save anyway?';
  }

  @override
  String get uic3651ce80dea =>
      'Default max acceptable accuracy used when recording points in this project.';

  @override
  String ui6e54655f0424(String v0) {
    return 'Delete \"$v0\" and all its survey responses and GIS features? This cannot be undone.';
  }

  @override
  String ui576e9079ff22(String v0, String v1) {
    return 'Delete \"$v0\"? This cannot be undone.$v1';
  }

  @override
  String get ui4babe44dc2a9 =>
      'Download failed. Please check your connection and try again.';

  @override
  String get uie99acc1c25e6 =>
      'Enter your name — it will be attached to every survey response, GPS log entry and export. You can change it later in the three-bar menu → My name.';

  @override
  String get ui4d6aba3a7042 =>
      'Every photo must contain GPS coordinates. Stay at the photo location until GPS is confirmed. Gallery photos keep their existing GPS when valid.';

  @override
  String ui5413a24d990a(String v0) {
    return 'GPS fix ready · ±$v0 m — photo will be geotagged';
  }

  @override
  String ui60064654441d(String v0, String v1) {
    return 'Line  •  $v0 vertices  •  $v1';
  }

  @override
  String ui4e046e2d5e0a(String v0, String v1) {
    return 'Need at least $v0 vertices to finish ($v1 collected)';
  }

  @override
  String get ui8150b88a8de7 =>
      'No logs yet. Create one to record coordinates, time, elevation and accuracy into a CSV file.';

  @override
  String get ui2b0631b176cd =>
      'No projects yet — open Project Settings on Home to create one, or use Import Project to import a .mbproj file';

  @override
  String get uib9f28dea1644 =>
      'No projects yet — open Project Settings to create one, or use Import Project to import a .mbproj file';

  @override
  String get ui21e3b0114215 =>
      'One questionnaire supplies Survey, GIS and Study Area questions. You can create a form, edit it, or import an XLSForm (.xlsx) file.';

  @override
  String get ui587e48c342b7 =>
      'Online project links are not supported yet. Ask the sender for the project file (.mbproj) or a project QR code.';

  @override
  String get ui771de57db095 =>
      'Open the device settings and enable \"Allow from this source\", then tap Download & Install again.';

  @override
  String get uif29d53eb9d2b =>
      'Paste this code into MapBanai → Import → Paste project code:';

  @override
  String uia490dc30efac(String v0, String v1, String v2) {
    return 'Point\n$v0, $v1$v2';
  }

  @override
  String get uib3b06ed785b2 =>
      'Point saves the current fix once with a note; continuous recording below drives line/track logging.';

  @override
  String ui2181a49983f5(String v0, String v1, String v2) {
    return 'Polygon  •  $v0 vertices\narea: $v1  •  perimeter: $v2';
  }

  @override
  String get ui793e65ec7509 =>
      'Project invite received. Open the .mbproj file in MapBanai to import it.';

  @override
  String get uib8a8c7d48bb2 =>
      'Scan or paste this code on another phone to import this project.';

  @override
  String get uie4fce3e26420 =>
      'Set a user name in Settings first — it is required to confirm a data reset.';

  @override
  String get ui2e3341bacb66 =>
      'Share a full project with responses, a project setup without responses, or only saved responses. Project packages include GIS files, forms, settings, web URL and API key by default.';

  @override
  String get ui7a263d9455ed =>
      'Share the project file instead; this code lets the receiving phone confirm it got the right project.';

  @override
  String get ui33a5e91c7ff1 =>
      'Slow on mobile data? Open in browser to use your phone’s browser download, then open the downloaded APK to install.';

  @override
  String get ui71529ccaf336 =>
      'The matching DBF attribute file is not accessible. Choose the folder containing the SHP, DBF, SHX, PRJ and CPG files, or import geometry only. You can also select those files together.';

  @override
  String get ui7e91262eef11 =>
      'This permanently deletes all projects, survey responses, stored forms and GPS logs. Type your user name exactly as shown to confirm:';

  @override
  String get ui2ebc6f4e9cc1 =>
      'You can add it as a new copy, or replace the existing project. Replacing deletes the current project and everything collected in it.';

  @override
  String uic2f438460953(String v0, String v1, String v2, String v3, String v4) {
    return '$v0\n\n$v1 history records will be deleted, including $v2 waiting to sync.\n$v3$v4\nThis cannot be undone. Copies already uploaded to the cloud remain there.';
  }

  @override
  String ui1881010a6775(String v0, String v1, String v2) {
    return '$v0 / $v1\n\nRemove all $v2 map points? This cannot be undone.';
  }

  @override
  String ui6090069a7609(String v0, String v1, String v2) {
    return '$v0 readings$v1$v2';
  }

  @override
  String ui42346e017b40(String v0, String v1, String v2, String v3, String v4) {
    return '$v0 · $v1\nZoom $v2–$v3\n$v4';
  }

  @override
  String ui8bba0bdb8c5f(String v0, String v1) {
    return '$v0$v1 details';
  }

  @override
  String ui7b693d8137e8(String v0) {
    return '\nIncludes $v0 other records linked to the same removed points.\n';
  }

  @override
  String uid8c8c3da6665(String v0) {
    return ' and $v0 map points';
  }

  @override
  String get ui54c0efcf9fc5 =>
      '1. Create a new project in MapBanai. Open Project Details or Help and copy its project ID (the long UUID).\n2. Create a fresh Google spreadsheet for this project, or open your XLSForm .xlsx in Google Sheets. Keep the exact questionnaire tab names: survey, choices, settings.\n3. Keep the XLSForm header row. Common survey columns: type, name, label, required, relevant, constraint, constraint_message, calculation. Choice columns: list_name, name, label. Settings: form_title, form_id, version.\n4. You do not need to create data tabs or a photo folder. The setup script creates responses, features, photos, revisions and a private Drive photo folder automatically.\n5. Use a fresh spreadsheet and script for each new project. For the recommended single-spreadsheet setup, you do not need to copy spreadsheet IDs.';

  @override
  String get ui0d72badb9fca =>
      '1. From your new Google spreadsheet, open Extensions → Apps Script. This connects the script to that spreadsheet; this is what “bound workbook” means.\n2. Copy the complete Code.gs below into the editor. Add two HTML files named Map and Charts, then paste the matching HTML files below.\n3. At the top of Code.gs, replace only PASTE_PROJECT_ID_FROM_MAPBANAI with the project ID you copied. Keep the quotation marks. Leave questionnaireSheetId, dataSheetId, apiKey and photoFolderId at their placeholder values.\n4. Save. Select setupMapBanai in the function dropdown and click Run. Authorize spreadsheet and Drive access with your manager account. It uses this spreadsheet for both questions and collected data, generates a private API key, creates a photo folder and creates the data tabs.\n5. Reload your spreadsheet. Open MapBanai → Connection and setup guide and copy the API key. You can also find MAPBANAI_API_KEY in Apps Script → Project Settings → Script properties. This is a MapBanai password; you do not need Google Cloud API credentials.\n6. In Apps Script, choose Deploy → New deployment → Web app. Set Execute as: Me and Who has access: Anyone. Click Deploy, authorize if asked, and copy the Web app URL ending /exec. Copy the full URL, not the editor address. If Anyone is unavailable, ask your Google Workspace administrator.\n7. In MapBanai Project Details → Cloud Sync, paste the URL and API key. Tap Save, then Test Connection. This verifies the project ID, key and data-sheet access without sending records.\n8. Open Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. Collect one test response, sync from Home and check the spreadsheet. Edit the response and sync again to verify revision history.\n9. Export the project with Include sync connection for your trusted field team. Enumerators import it and set My name in the Home three-bar menu. Repeat this fresh setup for each new project.';

  @override
  String get ui0daa4f380987 => 'Acres (ac)';

  @override
  String get uid3d9949c92a8 =>
      'Atlas stays at Connecting: this is initialization/loading, not the number of sites. Replace the complete matching Map.html and Code.gs, save, close and reopen the atlas from the spreadsheet menu. Read its visible status/error; check Apps Script → Executions if loading takes more than 45 seconds. The manager map loads pinned Leaflet over HTTPS; internet is required.\n\nInvalid JSON/405: use the deployed /exec web-app URL, not an editor URL or /dev. Check doPost exists and deploy a new script version.\n\nWrong project/key: compare the project ID and key in Code.gs with Project Details; Save the settings in the app.\n\nPermission/setup failure: run setupMapBanai as the owner, check spreadsheet/folder IDs and reserved output-tab headers. Check Apps Script Executions privately for diagnostics.\n\nQuestionnaire errors: verify exact tab/header names, stable form_id and valid XLSForm syntax. Avoid formulas that evaluate differently from the intended XLSForm text; store expressions as plain text.\n\nSlow/busy uploads: completed batches are preserved. Retry Sync to send the remaining records. A server timeout is reported separately from loss of internet. Google service quotas apply; very large deployments need a dedicated server. A record can contain up to 160,000 JSON characters in this supplied backend.\n\nOfficial references: developers.google.com/apps-script/guides/web and developers.google.com/apps-script/reference/spreadsheet/range.';

  @override
  String get uiac9041e76816 => 'Automatic';

  @override
  String get uie1fb894bb078 =>
      'Choose the project and questionnaire, answer the questions, follow required fields and validation messages, then save. Conditional questions follow the XLSForm rules supported by the importer. Review import warnings before fieldwork. Date questions use the date picker. Field quality checks list only saved GPS/photo readings above your selected accuracy review limit. Use Accept accuracy to keep a suitable reading and hide that finding permanently on this device, or View record to inspect it. The limit and decisions are saved per project; Undo restores a just-accepted finding. This does not block photos or alter data. Save drafts to resume incomplete interviews.';

  @override
  String get ui58167ff8f947 =>
      'Edit survey/choices/settings cells in Google Sheets. In the app, select the project → Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. New interviews and attribute editors use the new questions. Existing saved records and drafts retain their original form version. Updates require internet; collection remains offline.\n\nOne online XLSForm is served per project by this script; other locally imported forms remain available. Change the displayed label freely, but keep existing question names and form_id stable. Removing/renaming questions can change how historical answers are interpreted. Check warnings and pilot every revised questionnaire before field deployment.';

  @override
  String get ui7514aeee4771 => 'Enumerator: collect, correct and sync';

  @override
  String get ui7d5c63dab944 => 'Feet (ft)';

  @override
  String get ui9a35340e0499 => 'GIS Mode: draw and enter attributes';

  @override
  String get uid21c6a5da671 => 'GPS Mode and geotagged photos';

  @override
  String get uibf3148392176 =>
      'GPS Mode is independent of projects. It provides location diagnostics and recording. Its compass uses orientation sensors relative to magnetic north, with GPS travel bearing explicitly labelled as a fallback; keep the phone flat and calibrate away from metal when prompted. GNSS altitude is an absolute satellite estimate, not height above your building’s ground floor; indoor reception can give unreliable altitude. Check outdoor reception and vertical accuracy where available.\n\nPhotos require a valid location for geotagging. Accuracy is recorded for review but a strict accuracy threshold does not block taking a photo. Allow location and camera permissions, and give the device time to acquire a location.';

  @override
  String get ui65e00a1aa4fc => 'Hectares (ha)';

  @override
  String get ui2e2fa0ad4e93 =>
      'Import forms, project packages and study maps before leaving connectivity. Prepare offline basemaps where supported; online map tiles need internet. Save field records locally and sync the selected project when connected. Sync sends responses, GIS/study features and photos. Records sync in sequential batches of at most 20. Busy-server responses retry automatically; completed batches remain synced after interruption. Retry sends only remaining records. The supplied backend updates stable record IDs and reuses photo IDs. Saved edits increment response_revision and return to the upload queue. The revisions tab preserves uploaded versions; several offline edits before sync upload only the final version. Deploy the new Code.gs to sync corrections. A conflict stays on the phone for manager review.\n\nManagers: reload the Google spreadsheet → MapBanai → Map workspace or Charts workspace. Maps use the app’s basemaps, designs, independent fonts, category colours and symbols, editable legends and PNG/JPEG downloads. Manager maps accept multiple GeoJSON or shapefile ZIP overlays. Both map and chart workspaces have Fullscreen, with an expanded Sheets dialog when browser fullscreen is blocked. Charts include aggregation, themes and PNG/JPEG/SVG export. These workspaces require an authenticated manager and are not public links.\n\nCollected records are stored as full JSON (including geometry and answers) across json_1 to json_4 output columns. Concatenate those columns to reconstruct a record. The photos tab includes readable metadata, embedded thumbnails and Open photo in Drive links. New uploads add previews automatically. For previously synced photos, reload the spreadsheet and choose MapBanai → Refresh photo previews (up to 50 missing previews per run). Files remain private; the spreadsheet shows embedded thumbnails to its viewers. If a preview cannot be created, use its Drive link. This backend is an upload destination; it does not automatically download other enumerators’ records into your phone.';

  @override
  String get ui6d3be8e36078 => 'Kilometers (km)';

  @override
  String get uif836181704ed => 'Manager setup: one workbook or two?';

  @override
  String get uie1ca88d502bf => 'Manager setup: paste and deploy the script';

  @override
  String get uia120af7937ca => 'Manager setup: prepare Google Sheets';

  @override
  String get ui8762dae21dde =>
      'Manager: create a project, import its XLSForm, select a questionnaire and add study-area maps. Configure the cloud connection if needed. Export/share the project package with “Include sync connection” selected for trusted enumerators.\n\nEnumerator: Home → three-bar menu → My name. Import the project package and select it. Survey Mode → Sync questionnaire checks for updated questions. Collect offline in Survey Mode, GIS Mode or Visit a study site. Home → three-bar menu → My responses lets you review and edit saved responses. Home → Cloud Sync uploads new records and corrections when connected. Each correction keeps the original collector and stable ID, records the editor and advances the response revision; it is separate from questionnaire version. The same project and questions are used in GIS and Study Area modes. GPS Mode works independently.';

  @override
  String get uiaf34806a7287 => 'Meters (m)';

  @override
  String get uib0b04ac9caed => 'Miles (mi)';

  @override
  String get ui682761a623ce => 'Offline work, cloud sync and photos';

  @override
  String get uia71aaef663f0 =>
      'Open Project Details → Reusable templates. Save the whole project or its selected layer and questionnaire. From Project Setup → Reusable templates, create a new project from a saved template. Project Details also lets you add template layers to the current project. Templates preserve forms, layer names and setup; they exclude site geometry, visits, photos and cloud keys. New projects and added layers receive fresh identities. Configure the new project’s cloud connection separately. Templates are local and included in database backups. To share with another phone, create a project from the template and export its project package.';

  @override
  String get ui78f2a306509a =>
      'Open WebMap for the selected project. Use Explore → Colours & categories: choose any text/numeric answer column (such as layer), then Categories for per-value colours and visibility or Graduated for numeric colours. Geometry type is the uniform default. Edit category names, colours and symbols in Download Map. Filter and inspect features, choose a map theme, turn labels on/off, and compose a poster or map-only image with a title and subtitle. Export PNG for clear graphics or JPEG for smaller files. Tap the separate Download Map button to open 12 designs, custom colours, portrait/landscape, aspect ratio and pixel resolution (HD, Full HD, QHD, 4K or custom). Download PNG/JPEG opens the phone file picker; Share PNG/JPEG opens sharing. Basemap tiles must be loaded and exportable; offline/data-only exports may lack the basemap. Rename mapped legend categories, choose point symbols/line patterns/polygon outlines or upload PNG/self-contained SVG icons (up to 512 KB and 2048 pixels per side). Title, subtitle and legend fonts can be chosen independently, with four bundled offline fonts. Text, symbols and north arrow scale with image resolution; choose Standard/Large/Extra large for readability. The map covers over 80% of the exported poster, with a compact title and legend below. Map extent defaults to Fit visible data; choose Current map view to preserve your framing. Coordinates below the title are omitted. Only included basemaps receive attribution; record counts and no-basemap notices are omitted.';

  @override
  String get ui0f3c63f41614 =>
      'Open a study-area feature → Site timeline / add observation, or select a feature in the guided visit screen → Site timeline. Choose Add observation / start visit to record another measurement. Finish each visit separately; earlier answers remain linked to the same stable feature UUID. Choose a questionnaire and numeric question (such as salinity) to compare visits. Keep question names and units consistent. Export all observations as CSV; feature_uuid joins them to study-map GeoJSON. Imported visit history is included and deduplicated with local interviews. Timelines show locally available history; cloud sync does not download other devices’ visits.';

  @override
  String get ui4452be7b875c =>
      'Project packages share project definitions, forms and study-layer configuration; they are not a backup of responses or photos. “Include sync connection” is optional and includes the URL and key. Preserve the same project identity across the team; duplicating a project creates a different identity that needs its own backend configuration.\n\nUse the app backup/export tools for collected data and keep copies outside the phone. Installing an update over the existing signed app preserves local storage; uninstalling or clearing app storage removes local information. Save cloud connection settings before exporting a package.';

  @override
  String get ui48f8d1dd5266 =>
      'Recommended: one Google workbook + one Apps Script web app + one private API key per project. Keep questionnaire tabs (survey, choices, settings) and output tabs (responses, features, photos, revisions) in the same workbook. No second URL or key is needed.\n\nFor separate storage, use two workbooks: questionnaireSheetId points to the XLSForm workbook; dataSheetId points to the collected-data workbook. The same script handles both, so the app still uses one URL and key. Two independent deployments/keys are not configured in this version.\n\nUse a separate setup for each project. Keep questionnaire editing with managers; enumerators only need the MapBanai project package. API keys give access to the project endpoint; share packages containing them only with your field team.';

  @override
  String get uifd76b27cda7d => 'Reference vector layers and backgrounds';

  @override
  String get ui12432a3ccda1 => 'Repeated observations and site timelines';

  @override
  String get ui6cb726ab7ebc => 'Reusable project and layer templates';

  @override
  String get ui1a25286391c7 =>
      'Select the project and one of its study-area maps. Import from the top toolbar; GeoJSON and GeoPackage can be selected regardless of Android MIME filtering. ZIP shapefile companions together for attributes. Files opened externally offer an existing project, new project or view-only preview. Add new Layer is inside the study-layer selector; the plus button opens the questionnaire at a fresh GPS position. Edit feature requires a questionnaire for new/Updated features; other statuses have an optional Fill questionnaire checkbox. Skipping keeps previous answers. Categories & colors includes Verification status coloring and starts with a single color and lets you explicitly choose a column, category colors/visibility and point size.  Use separate named maps for salinity rounds, household verification or the full study area. Start/resume a field visit for that selected area. Verify existing sites, record new information or update attributes using the selected questionnaire. Visit history preserves the review trail. Assign old unassigned sites to a project explicitly. Export the updated area after fieldwork.';

  @override
  String get ui3ba9b97177d2 =>
      'Select the project, layer and survey. Add a point, line or polygon, then enter information using the selected survey questions. Existing geometry can be edited and its attributes updated. Define questions in the selected survey form; the separate Project Settings field editor has been removed, while old field values remain stored. Use consistent identifiers to connect a feature with a site or repeat visit. Export spatial data when you need analysis in GIS software.';

  @override
  String get uicba2a97abd4c => 'Sharing, backups and app updates';

  @override
  String get ui1cc6418b3dc4 => 'Square feet (ft²)';

  @override
  String get ui397fb00a21fd => 'Square kilometers (km²)';

  @override
  String get ui65e207ca8636 => 'Square meters (m²)';

  @override
  String get ui35e941e250ac => 'Study Area Mode: visits and repeated campaigns';

  @override
  String get uicf8de9900977 => 'Study Area points will stay on the map.\n';

  @override
  String get ui1cfa4ca96cef => 'Survey Mode and field quality checks';

  @override
  String get ui55cabd86f046 => 'Tap the map to choose a location';

  @override
  String get ui38a1e2db198c => 'Tap the map to move this point';

  @override
  String ui9fd1493c60ac(String v0) {
    return 'This project ID: $v0';
  }

  @override
  String get uia3ce2bacb32e => 'Troubleshooting cloud setup';

  @override
  String get ui693379c73728 => 'Updating questionnaires online';

  @override
  String get ui0a045ba7552d => 'Use GPS position';

  @override
  String get uif202ba19ecbc =>
      'WebMap → Layers → Add vector layers. Select multiple shapefile ZIP bundles, or each .shp together with its .dbf/.shx/.prj/.cpg files. GeoJSON FeatureCollections are supported. Reproject layers to WGS84 (EPSG:4326) before importing; missing .prj assumes WGS84. Choose visibility, colour and opacity for each project layer. Reference layers are separate from collected observations, persist locally and travel in project packages and shared HTML maps. Use Explore → Background map to select Street, Imagery, Topographic, Humanitarian, Cycling or No background. Visible vector layers appear in image exports. Import supports up to 64 MB and 50,000 reference features per project.';

  @override
  String get ui18f2b9281b8e => 'WebMap, map styling and images';

  @override
  String get ui231e564db4cd => 'completed';

  @override
  String get uif0f6ea94f6ad => 'needsReview';

  @override
  String get ui7e3cbb17832c => 'newFeature';

  @override
  String get uib18d1e57ecc0 => 'notFound';

  @override
  String get uie22586930a5b => 'pending';

  @override
  String get ui13a1891af75c => 'updated';

  @override
  String get uiec734b651574 => 'verified';

  @override
  String ui1a9356ff587e(String v0) {
    return '$v0 linked Study Area points will also be removed.\n';
  }

  @override
  String get ui12a3a4f498b2 => 'Accuracy';

  @override
  String get ui89ee1223f2e1 => 'Accuracy check';

  @override
  String get uib375acb22bce => 'Cancel recording?';

  @override
  String get ui744d0bab1b52 => 'Delete feature';

  @override
  String get uidff896de7cef => 'Delete log';

  @override
  String get uia84949c694a9 => 'Dhaka time (GMT+6)';

  @override
  String uiec4dd3969fea(String v0) {
    return 'Draft survey — $v0';
  }

  @override
  String get ui22a31d86e018 => 'Drafts';

  @override
  String get ui5fc97790c6a8 => 'Elapsed';

  @override
  String ui88bbbbe65742(String v0) {
    return 'Feature $v0';
  }

  @override
  String get uif5c66da8133d => 'GNSS altitude';

  @override
  String ui93db01b4b539(String v0) {
    return 'GPS log $v0';
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
  String get uid2521a9d2adb => 'MapBanai Study Area export';

  @override
  String get ui0c409607d527 => 'MapBanai WebMap';

  @override
  String get ui7dbb0cc1dc12 => 'Measurement sites';

  @override
  String get ui695385e41e56 => 'New point log';

  @override
  String get ui329d3a41479d => 'Perimeter';

  @override
  String get uif9e31cfd1b72 => 'Project description';

  @override
  String get uiaecc2a7055a2 => 'Record track';

  @override
  String get uic1ea3d0bd91c => 'Rename log';

  @override
  String uidc4de6540089(String v0) {
    return 'Round $v0';
  }

  @override
  String get ui29053fbf93da => 'SQLite + WKB geometry';

  @override
  String get ui5205fe16c422 => 'Satellites (in use / in view)';

  @override
  String get ui2d2cb022bc3d => 'Speed';

  @override
  String get uiaa45b267e05e => 'Survey and map history';

  @override
  String get uifbea242d37f8 => 'Tabular data with WKT geometry';

  @override
  String get ui998249c59a6e => 'UTC time (GPS)';

  @override
  String get uib3a015034320 => 'Vertices';

  @override
  String get ui69bd4ef9fbd0 => 'View';

  @override
  String get ui7f85f35d7ca2 => 'Web / QGIS';

  @override
  String ui824755f37e73(String v0) {
    return '$v0 — observations';
  }

  @override
  String get ui0bcc30904efc =>
      'A collection round with this name already exists.';

  @override
  String get ui88896e6489d6 => 'A draft cannot change its linked feature.';

  @override
  String get ui89c343833e83 =>
      'Add a change or review note for this visit outcome.';

  @override
  String get ui7da0faaccb67 => 'Choose a collection round for this layer.';

  @override
  String get ui462afc2c8051 => 'Choose a form from this project.';

  @override
  String get ui117493d4eef6 => 'Choose a recurring layer from this project.';

  @override
  String get ui361f7065ffe8 => 'Choose a site from this project and workflow.';

  @override
  String get ui36e876a95151 =>
      'Choose a visit outcome: verified, updated, not found or needs review.';

  @override
  String get uic502d96e61cd => 'Complete and save the selected survey first.';

  @override
  String get ui2c4d8c966796 => 'Current feature belongs to another project.';

  @override
  String get ui1103b1a10bbd => 'Draft changed while finalizing. Reload it.';

  @override
  String get ui03b6c1a0b4ac => 'Draft changed. Reload it before finishing.';

  @override
  String get uibe390c0ef7b4 => 'Enter a collection round name.';

  @override
  String get uif7299773137e => 'Enter a layer name';

  @override
  String get ui4a355a1939ef => 'Enter a layer name.';

  @override
  String get uiebf870d13fa8 => 'Feature geometry is missing or invalid.';

  @override
  String get ui8bc3895df8c2 =>
      'Feature was removed. Restore or review the study map before applying this visit.';

  @override
  String get ui1761acebd70a => 'Form does not belong to this project';

  @override
  String get uiba63f7620f2b => 'Invalid collection status.';

  @override
  String get ui86fa10d3afc9 =>
      'Map changed again during review. Reload and compare the versions.';

  @override
  String get ui5877c7c71c31 =>
      'No saved measurements with point locations match this selection.';

  @override
  String get ui1bd927bf4b76 => 'Only a saved pending visit can be rebased.';

  @override
  String get ui5076a1f7ffb8 => 'Only saved visits can reconcile the map.';

  @override
  String get uice44f8239f96 =>
      'Open Study Area from Home and select Field Verification, Recurring Collection or Study Area Visits. Choose the project, site layer and questionnaire. Assign each uploaded layer to its workflows in Project layers. Field Verification updates baseline features; tap a site and its questionnaire button to start or resume a guided visit. Recurring Collection uses a Collection round with a name, optional period/season and date. Each round keeps independent collected, not collected and needs review states. To build recurring sites from first measurements, choose Create layer from responses, then the source questionnaire and numeric measurement. Original responses remain intact. Study Area Visits supports quick done, undone and review states with optional questionnaires. Open Google Maps from the selected site for external navigation. Timelines preserve previous observations. Uploaded site names and attributes remain as supplied; choose a bilingual XLSForm to translate questionnaire labels.';

  @override
  String get uicbcd0cfd27d2 => 'Project no longer exists';

  @override
  String get ui325826737355 => 'Project no longer exists.';

  @override
  String get uib71084f5010f =>
      'Project packages share definitions, questionnaires, layers and setup. Select Include collected responses and photos when those records should travel too; a setup-only package is not a backup of collected data. Include sync connection adds the URL and API key for trusted field teams. Keep the same project identity across the team. Creating a new copy gives it a separate identity and backend setup.\n\nKeep backups outside the phone. Installing an update over the same signed app preserves local storage; uninstalling or clearing app storage removes local data. Save cloud connection settings before exporting.';

  @override
  String get uie6e161cc9336 =>
      'Save the selected questionnaire to complete this collection.';

  @override
  String get ui3dc7df584218 =>
      'Select a numeric measurement from this questionnaire.';

  @override
  String get ui36e792741f9f => 'Select a questionnaire and measurement.';

  @override
  String get ui0808b5a3481d => 'Select a questionnaire from this project.';

  @override
  String get ui24607fcc859f => 'Study layer does not belong to this project';

  @override
  String get ui01f762c7c32b =>
      'This collection round belongs to another layer.';

  @override
  String get uib7287c8bc71b =>
      'This draft changed in another screen. Reload before saving.';

  @override
  String get ui937151b52477 => 'This draft changed. Reopen it before saving.';

  @override
  String get ui2c9f263743c4 => 'This feature belongs to a different project.';

  @override
  String get ui547bca6d008d =>
      'This visit is already finalized. Reload its saved record.';

  @override
  String get ui5f30a4c4489e => 'Visit changed during review. Reload it.';

  @override
  String get ui85f5c6c2edf4 => 'Visit does not exist.';

  @override
  String get uieda6aa29be81 => 'Visit draft no longer exists.';

  @override
  String get ui0aabe5893a27 => 'Visit was deleted.';

  @override
  String get ui6ecd86a8f125 => '16:10 · Laptop';

  @override
  String get uif05d6690fa2d => '16:9 · Wallpaper';

  @override
  String get uia57dc941dcd3 => '1:1 · Square';

  @override
  String get uib4381bea81cf => '21:9 · Ultrawide';

  @override
  String get ui2823d71dd313 => '3:2 · Photo';

  @override
  String get ui4bfeadd27478 => '4:3 · Classic';

  @override
  String get uidd24b455a6e9 => 'All forms / types';

  @override
  String get ui6405179d241b => 'All statuses';

  @override
  String get ui14ce09a8dd4e => 'Areas';

  @override
  String get ui4e077cf8bf92 => 'Aspect ratio';

  @override
  String get ui9bffcb9f06c2 => 'Attribute table';

  @override
  String get ui64dd60fe1a04 => 'Background';

  @override
  String get uid0d92ae1cf5e => 'Background map';

  @override
  String get ui601cd5a75b27 => 'Basemap colour treatment';

  @override
  String get ui019728575b52 => 'Black & white';

  @override
  String get ui06992d2c6a4f => 'Blueprint';

  @override
  String get ui76d1fadb362e => 'Caption alignment';

  @override
  String get uia1e4a4404fb7 => 'Categories · column values';

  @override
  String get ui16e5447a8046 => 'Centre';

  @override
  String get ui253444ab88a5 =>
      'Choose a design and image size. Pan or zoom the map before downloading.';

  @override
  String get ui219c06043a26 => 'Classic serif';

  @override
  String get ui0f8dabf7dc77 => 'Close Download Map';

  @override
  String get ui0c4b831492a5 => 'Coastal blue';

  @override
  String get ui4bbb632f02fd => 'Collections';

  @override
  String get uie3199d24849e => 'Collector';

  @override
  String get ui653bfaa2a80f => 'Colour by';

  @override
  String get ui02dabdeefe20 => 'Colour shows site status';

  @override
  String get ui8d30cc74f67e => 'Colours & categories';

  @override
  String get ui8b8025fc854d => 'Current basemap';

  @override
  String get uie11f3a510f6a => 'Current map view';

  @override
  String get ui134d207372fc => 'Custom colours';

  @override
  String get ui915add28af82 => 'Custom dimensions';

  @override
  String get uic646cf24f147 => 'Data only';

  @override
  String get ui160e0e54c6f5 => 'Desert sand';

  @override
  String get uiaa30393c7650 => 'Download JPEG';

  @override
  String get ui0c8309d1f4d0 => 'Download PNG';

  @override
  String get ui6dc7d6db796a => 'Download ready';

  @override
  String get uic756f6af1f03 => 'Everyone';

  @override
  String get uib965ae66fcc4 => 'Explore';

  @override
  String get uie1a3f6c998b3 => 'Explore your field data';

  @override
  String get ui583cccdcd165 => 'Exporting…';

  @override
  String get ui05128f46d8c8 => 'Extra large';

  @override
  String get uicbb7a61052e1 => 'Feature labels';

  @override
  String get ui45b8b762d80d => 'Field atlas';

  @override
  String get uid509f832e48f => 'Find a site or answer';

  @override
  String get uib20486dfffd5 => 'Fit results';

  @override
  String get uic7c22ccaf35b => 'Fit visible data';

  @override
  String get uif41c4e4dab0b => 'Forest';

  @override
  String get ui3f66052a107e => 'From';

  @override
  String get ui839e01b3dcb2 => 'Full HD · 1920';

  @override
  String get uic5a6470c3d70 => 'Geometry type';

  @override
  String get ui53b0911438aa => 'Graduated · numeric values';

  @override
  String get uib1ef9dd05873 => 'HD · 1280';

  @override
  String get uif81c3e5ae1c6 => 'Height (pixels)';

  @override
  String get uif2468877acc4 => 'Hide table';

  @override
  String get ui9bcbf7e9ceb7 => 'Ink on paper';

  @override
  String get ui7dc4bea61853 => 'Landscape';

  @override
  String get ui738fd1d2452f => 'Large';

  @override
  String get ui75c88f3a0072 => 'Lavender';

  @override
  String get ui972ad8d8a503 => 'Layout';

  @override
  String get ui8ae1c34bd37f => 'Left';

  @override
  String get uif40b6a07a9d0 => 'Legend font';

  @override
  String get ui5b8fbe24bfd9 => 'Legend names & symbols';

  @override
  String get uic6fd3870c86e => 'Lines';

  @override
  String get ui36360d6d8c2a => 'Lobster · script';

  @override
  String get ui6d14f8cbd660 => 'Lora · book serif';

  @override
  String get ui304ceba28849 => 'Map extent';

  @override
  String get uidb1a9c33957d => 'Map filters';

  @override
  String get uifdee43176a62 => 'Map layers';

  @override
  String get uidf2a2bdfd1ae => 'Map only';

  @override
  String get uia418467db07d => 'Map poster';

  @override
  String get ui708370785b57 =>
      'Map tiles require internet; your data works offline';

  @override
  String get ui889a7e8464fa => 'Map title';

  @override
  String get ui08a159c05728 => 'MapBanai · Project Atlas';

  @override
  String get ui09ee4407bee8 => 'Match design';

  @override
  String get uia8df2fec28d8 => 'Maximum';

  @override
  String get ui8b4b0b8ee2ca => 'Maximum measurement';

  @override
  String get ui558287ddcc35 => 'Midnight';

  @override
  String get ui5d398eef3ecc => 'Minimum';

  @override
  String get ui4a0c5b771fb5 => 'Minimum measurement';

  @override
  String get ui08b10f41c999 => 'Modern sans serif';

  @override
  String get uidef80ab2391e => 'My location';

  @override
  String get ui9825e8466d49 => 'Name, ID, salinity…';

  @override
  String get ui2b7c08c3ab75 => 'Names';

  @override
  String get uibc981983e7f5 => 'Next';

  @override
  String get ui416010b25189 => 'No background';

  @override
  String get uibd4d569dbbb2 => 'Nunito · rounded';

  @override
  String get uie3de5ab0ca4c => 'Off';

  @override
  String get ui86e4e3875420 => 'Orientation';

  @override
  String get uic0a8060f3b11 => 'Original';

  @override
  String get ui7a297fcb17e0 => 'Oswald · condensed';

  @override
  String get ui22d507f2ba74 => 'Paper';

  @override
  String get ui4b2a6a314956 => 'Points';

  @override
  String get ui92b6b1bf71e0 => 'Portrait';

  @override
  String get ui1643936014d7 => 'Preparing image…';

  @override
  String get ui50f94286ba30 => 'Previous';

  @override
  String get uif842de4b00d7 => 'Project map';

  @override
  String get ui30891032b07f => 'Pure monochrome';

  @override
  String get ui6f43b588ef53 => 'QHD · 2560';

  @override
  String get ui44c57abd888a => 'Reset';

  @override
  String get ui516aae52959d => 'Resolution';

  @override
  String get ui954daa8b0033 => 'Right';

  @override
  String get ui4c7311ae72a1 => 'Rose quartz';

  @override
  String get ui3e2479c4685a => 'Sage & cream';

  @override
  String get uieb61da0ddb23 => 'Share JPEG';

  @override
  String get ui69b2ba27ee1a => 'Share PNG';

  @override
  String get uid97d1ee339e4 => 'Show';

  @override
  String get ui445d12dec2a5 => 'Show table';

  @override
  String get ui17480c963f26 => 'Site status';

  @override
  String get ui8684c3cda710 => 'Sites & collections';

  @override
  String get ui25e0ca14c327 => 'Soft muted';

  @override
  String get ui564186be1ef2 => 'Standard · scales with resolution';

  @override
  String get ui1f214e692623 => 'Study sites';

  @override
  String get ui99a0efc6cfd8 => 'Style';

  @override
  String get uie159d05a124c => 'Subtitle';

  @override
  String get ui68731e7bff79 => 'Subtitle font';

  @override
  String get ui54041909beab => 'Survey form / type';

  @override
  String get ui5c55024681cc => 'Symbology';

  @override
  String get ui0424f6e7026f => 'Table';

  @override
  String get uida6453b3fe00 => 'Technical mono';

  @override
  String get ui8be6e64eb5c3 => 'Terracotta';

  @override
  String get ui5da8b6d504e5 => 'Text & symbol size';

  @override
  String get uiae79ea1e9c63 => 'To';

  @override
  String get uif4beb9af58f7 => 'Typography';

  @override
  String get ui6c3b0475960a => 'Visible features';

  @override
  String get ui3b2f5b0cf572 => 'Vivid';

  @override
  String get ui26606552151f => 'Warm vintage';

  @override
  String get uie73a0adf49ce => 'Width (pixels)';

  @override
  String get ui046786ec74e0 => 'Your project name';

  @override
  String get uid74015d4e00f => 'e.g. Salinity · October field visit';

  @override
  String ui6313520ac1e1(String v0) {
    return 'Feature UUID: $v0';
  }

  @override
  String uia68e9ddcf3b8(String v0) {
    return 'Observation UUID: $v0';
  }

  @override
  String get uia1e34f91579d => 'More actions';

  @override
  String get uie93c7af975cb => 'Choose a workflow';

  @override
  String get uibce757708457 => 'Workflow requirements';

  @override
  String get ui339529eee4c0 =>
      'Configure required steps before sharing this project with the field team. Share an updated project package after changing these settings.';

  @override
  String get uicd39c5d4c2d2 => 'Require questionnaire';

  @override
  String get uic184e2bde3f6 => 'Require geotagged photo';

  @override
  String get ui8caa0a53724d => 'Save requirements';

  @override
  String get ui551b1994e409 => 'Photo is optional.';

  @override
  String get ui0b0a3f8c430f =>
      'Complete the required steps to finish. You can save a draft at any time.';

  @override
  String get ui6e4c1e3c8ad1 => 'Nearest unvisited sites';

  @override
  String get ui66fc75da8df4 => 'Straight-line distance from your GPS location.';

  @override
  String get ui701b8859c071 =>
      'No recent GPS location. Sites are sorted by name.';

  @override
  String get uic9704e072a21 => 'Refresh location';

  @override
  String get ui3362f0a776a1 => 'No unvisited sites in this layer.';

  @override
  String get ui51848b274f3e => 'Location permission is required.';

  @override
  String get ui45f4f4818756 => 'A geotagged photo is required.';

  @override
  String get ui0ded61d14817 =>
      'Complete the required questionnaire and photo before marking this site done.';

  @override
  String get uif8e4834eedd0 => 'Invalid workflow requirements.';

  @override
  String get ui39854cbe2f78 =>
      'Required questionnaires and photos for each workflow';
}
