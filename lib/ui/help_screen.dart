import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled field and manager instructions, available without a network connection.
class HelpScreen extends StatelessWidget {
  final String? projectId;
  const HelpScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & manager setup')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('One project connects your questions, maps and fieldwork.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (projectId != null) ...[
            SelectableText('This project ID: $projectId'),
            TextButton.icon(
                onPressed: () => _copy(context, projectId!),
                icon: const Icon(Icons.copy),
                label: const Text('Copy project ID')),
          ],
          for (final section in _sections)
            Card(
                child: ExpansionTile(
                    title: Text(section.$1),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [SelectableText(section.$2)])),
          for (final file in [
            ('Code.gs', 'assets/help/manager_apps_script.gs'),
            ('Map.html', 'assets/help/Map.html'),
            ('Charts.html', 'assets/help/Charts.html'),
          ])
            Card(
                child: ExpansionTile(
              title: Text('${file.$1} — copy complete code'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                Text(file.$1 == 'Code.gs'
                    ? 'Paste into Code.gs. Set projectId below; setupMapBanai retains or creates the connection key and photo folder.'
                    : 'In Apps Script, add an HTML file named ${file.$1.split('.').first}, then paste this code.'),
                FutureBuilder<String>(
                  future: rootBundle.loadString(file.$2),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Text('Could not load code. Reopen Help.');
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    final code = projectId == null
                        ? snapshot.data!
                        : snapshot.data!.replaceAll(
                            'PASTE_PROJECT_ID_FROM_MAPBANAI', projectId!);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FilledButton.icon(
                              onPressed: () => _copy(context, code),
                              icon: const Icon(Icons.copy_all),
                              label: Text('Copy ${file.$1}')),
                          const SizedBox(height: 12),
                          SizedBox(
                              height: 240,
                              child: SingleChildScrollView(
                                  child: SelectableText(code,
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12)))),
                        ]);
                  },
                ),
              ],
            )),
          const SizedBox(height: 24),
        ]),
      );

  static Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }
}

const _sections = <(String, String)>[
  (
    'Repeated observations and site timelines',
    'Open a study-area feature → Site timeline / add observation, or select a feature in the guided visit screen → Site timeline. Choose Add observation / start visit to record another measurement. Finish each visit separately; earlier answers remain linked to the same stable feature UUID. Choose a questionnaire and numeric question (such as salinity) to compare visits. Keep question names and units consistent. Export all observations as CSV; feature_uuid joins them to study-map GeoJSON. Imported visit history is included and deduplicated with local interviews. Timelines show locally available history; cloud sync does not download other devices’ visits.'
  ),
  (
    'Reusable project and layer templates',
    'Open Project Details → Reusable templates. Save the whole project or its selected layer and questionnaire. From Project Setup → Reusable templates, create a new project from a saved template. Project Details also lets you add template layers to the current project. Templates preserve forms, layer names and setup; they exclude site geometry, visits, photos and cloud keys. New projects and added layers receive fresh identities. Configure the new project’s cloud connection separately. Templates are local and included in database backups. To share with another phone, create a project from the template and export its project package.'
  ),
  (
    'Enumerator: collect, correct and sync',
    'Manager: create a project, import its XLSForm, select a questionnaire and add study-area maps. Configure the cloud connection if needed. Export/share the project package with “Include sync connection” selected for trusted enumerators.\n\nEnumerator: Home → three-bar menu → My name. Import the project package and select it. Survey Mode → Sync questionnaire checks for updated questions. Collect offline in Survey Mode, GIS Mode or Visit a study site. Home → three-bar menu → My responses lets you review and edit saved responses. Home → Cloud Sync uploads new records and corrections when connected. Each correction keeps the original collector and stable ID, records the editor and advances the response revision; it is separate from questionnaire version. The same project and questions are used in GIS and Study Area modes. GPS Mode works independently.'
  ),
  (
    'Manager setup: one workbook or two?',
    'Recommended: one Google workbook + one Apps Script web app + one private API key per project. Keep questionnaire tabs (survey, choices, settings) and output tabs (responses, features, photos, revisions) in the same workbook. No second URL or key is needed.\n\nFor separate storage, use two workbooks: questionnaireSheetId points to the XLSForm workbook; dataSheetId points to the collected-data workbook. The same script handles both, so the app still uses one URL and key. Two independent deployments/keys are not configured in this version.\n\nUse a separate setup for each project. Keep questionnaire editing with managers; enumerators only need the MapBanai project package. API keys give access to the project endpoint; share packages containing them only with your field team.'
  ),
  (
    'Manager setup: prepare Google Sheets',
    '1. Create a Google spreadsheet, or import your XLSForm .xlsx into Google Sheets. Preserve exact tab names: survey, choices, settings.\n2. Keep the XLSForm header row. Common survey columns: type, name, label, required, relevant, constraint, constraint_message, calculation. Choice columns: list_name, name, label. Settings: form_title, form_id, version. Keep form_id and question names stable when updating.\n3. setupMapBanai creates responses, features, photos and revisions. Existing Responses/Features tabs from the older MapBanai script are kept and extended; do not delete them. Back up the workbook before migrating. Unrelated tabs with incompatible headers must be renamed.\n4. Copy the spreadsheet ID from its URL: the text between /d/ and /edit. For one workbook use that ID for both sheet settings.\n5. A private photo folder is created automatically when needed; an existing PHOTOS_FOLDER_ID is retained. You may set photoFolderId to an existing folder ID. Its permissions apply.'
  ),
  (
    'Manager setup: paste and deploy the script',
    '1. Open Google Sheets → Extensions → Apps Script (a desktop browser is easier). Back up your current script and workbook. You can replace the existing MapBanai backend while keeping its response tabs, API key and deployment URL.\n2. Copy the complete code below into Code.gs. Replace projectId with the ID shown in MapBanai Project Details (or open Help from that project). For a script bound to this workbook, leave the other placeholders: setup uses this workbook for questions and data, retains the old Script Property API key/folder, or creates them. Optional spreadsheet IDs allow separate workbooks. This private key is not a Google Cloud API key. Add HTML files named Map and Charts and copy the matching code below.\n3. Save. Select setupMapBanai in the editor and Run. Authorize access to your spreadsheets and Drive folder using the owning account. Resolve setup errors before deploying. Reload the spreadsheet → MapBanai → Connection and setup guide shows your API key. It is also saved in Apps Script → Project Settings → Script properties → MAPBANAI_API_KEY.\n4. Deploy → New deployment → Web app. Execute as: Me. Who has access: Anyone. If your institution blocks this access level, ask its Google Workspace administrator. Deploy and copy the HTTPS URL ending /exec.\n5. In MapBanai Project Details → Cloud Sync, paste that URL and the same API key, then Save. Test Connection checks deployment availability; a successful questionnaire check/data upload also verifies your credentials.\n6. Check and apply the questionnaire, save one test response and sync it. Verify responses/features tabs and any photo in Drive before sharing with enumerators.\n7. For script changes, use Deploy → Manage deployments → Edit → New version → Deploy to retain the URL. Changes to sheet questions alone do not require a script redeployment.'
  ),
  (
    'Updating questionnaires online',
    'Edit survey/choices/settings cells in Google Sheets. In the app, select the project → Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply update. New interviews and attribute editors use the new questions. Existing saved records and drafts retain their original form version. Updates require internet; collection remains offline.\n\nOne online XLSForm is served per project by this script; other locally imported forms remain available. Change the displayed label freely, but keep existing question names and form_id stable. Removing/renaming questions can change how historical answers are interpreted. Check warnings and pilot every revised questionnaire before field deployment.'
  ),
  (
    'Survey Mode and field quality checks',
    'Choose the project and questionnaire, answer the questions, follow required fields and validation messages, then save. Conditional questions follow the XLSForm rules supported by the importer. Review import warnings before fieldwork. Date questions use the date picker. Quality checks help review missing values and location; investigate warnings with the enumerator. Save drafts to resume incomplete interviews.'
  ),
  (
    'GIS Mode: draw and enter attributes',
    'Select the project, layer and survey. Add a point, line or polygon, then enter information using the selected survey questions. Existing geometry can be edited and its attributes updated. Use consistent identifiers to connect a feature with a site or repeat visit. Export spatial data when you need analysis in GIS software.'
  ),
  (
    'Study Area Mode: visits and repeated campaigns',
    'Select the project and one of its study-area maps. Use separate named maps for salinity rounds, household verification or the full study area. Start/resume a field visit for that selected area. Verify existing sites, record new information or update attributes using the selected questionnaire. Visit history preserves the review trail. Assign old unassigned sites to a project explicitly. Export the updated area after fieldwork.'
  ),
  (
    'GPS Mode and geotagged photos',
    'GPS Mode is independent of projects. It provides location diagnostics and recording. GNSS altitude is an absolute satellite estimate, not height above your building’s ground floor; indoor reception can give unreliable altitude. Check outdoor reception and vertical accuracy where available.\n\nPhotos require a valid location for geotagging. Accuracy is recorded for review but a strict accuracy threshold does not block taking a photo. Allow location and camera permissions, and give the device time to acquire a location.'
  ),
  (
    'Offline work, cloud sync and photos',
    'Import forms, project packages and study maps before leaving connectivity. Prepare offline basemaps where supported; online map tiles need internet. Save field records locally and sync the selected project when connected. Sync sends responses, GIS/study features and photos. Retry failed uploads; the supplied backend updates stable record IDs and reuses photo IDs. Saved edits increment response_revision and return to the upload queue. The revisions tab preserves uploaded versions; several offline edits before sync upload only the final version. Deploy the new Code.gs to sync corrections. A conflict stays on the phone for manager review.\n\nManagers: reload the Google spreadsheet → MapBanai → Map workspace or Charts workspace. Maps include themes, filters and PNG/JPEG downloads; charts include aggregation, themes and PNG/JPEG/SVG export. These workspaces require an authenticated manager and are not public links.\n\nCollected records are stored as full JSON (including geometry and answers) across json_1 to json_4 output columns. Concatenate those columns to reconstruct a record. Photo rows include Drive file IDs and response IDs. This backend is an upload destination; it does not automatically download other enumerators’ records into your phone.'
  ),
  (
    'Reference vector layers and backgrounds',
    'WebMap → Layers → Add vector layers. Select multiple shapefile ZIP bundles, or each .shp together with its .dbf/.shx/.prj/.cpg files. GeoJSON FeatureCollections are supported. Reproject layers to WGS84 (EPSG:4326) before importing; missing .prj assumes WGS84. Choose visibility, colour and opacity for each project layer. Reference layers are separate from collected observations, persist locally and travel in project packages and shared HTML maps. Use Explore → Background map to select Street, Imagery, Topographic, Humanitarian, Cycling or No background. Visible vector layers appear in image exports. Import supports up to 64 MB and 50,000 reference features per project.'
  ),
  (
    'WebMap, map styling and images',
    'Open WebMap for the selected project. Filter and inspect features, choose a map theme, turn labels on/off, and compose a poster or map-only image with a title and subtitle. Export PNG for clear graphics or JPEG for smaller files. Tap the separate Download Map button to open 12 designs, custom colours, portrait/landscape, aspect ratio and pixel resolution (HD, Full HD, QHD, 4K or custom). Download PNG/JPEG opens the phone file picker; Share PNG/JPEG opens sharing. Basemap tiles must be loaded and exportable; offline/data-only exports may lack the basemap. Keep attribution when sharing.'
  ),
  (
    'Sharing, backups and app updates',
    'Project packages share project definitions, forms and study-layer configuration; they are not a backup of responses or photos. “Include sync connection” is optional and includes the URL and key. Preserve the same project identity across the team; duplicating a project creates a different identity that needs its own backend configuration.\n\nUse the app backup/export tools for collected data and keep copies outside the phone. Installing an update over the existing signed app preserves local storage; uninstalling or clearing app storage removes local information. Save cloud connection settings before exporting a package.'
  ),
  (
    'Troubleshooting cloud setup',
    'Invalid JSON/405: use the deployed /exec web-app URL, not an editor URL or /dev. Check doPost exists and deploy a new script version.\n\nWrong project/key: compare the project ID and key in Code.gs with Project Details; Save the settings in the app.\n\nPermission/setup failure: run setupMapBanai as the owner, check spreadsheet/folder IDs and reserved output-tab headers. Check Apps Script Executions privately for diagnostics.\n\nQuestionnaire errors: verify exact tab/header names, stable form_id and valid XLSForm syntax. Avoid formulas that evaluate differently from the intended XLSForm text; store expressions as plain text.\n\nSlow/busy uploads: retry on a reliable connection. Google service quotas apply; very large deployments need a dedicated server. A record can contain up to 160,000 JSON characters in this supplied backend.\n\nOfficial references: developers.google.com/apps-script/guides/web and developers.google.com/apps-script/reference/spreadsheet/range.'
  ),
];
