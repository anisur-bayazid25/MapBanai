# Google Sheets questionnaire sync

A project can distribute its questions and sync connection to enumerators, then pull updated XLSForm questions from a Google Sheet. This client implementation needs the accompanying Apps Script handler deployed on your existing endpoint. It does not automatically modify an existing Google deployment.

## Recommended complete setup (v2.6.3)

Use [the manager workspace guide](server/manager/README.md) and its **Code.gs, Map.html, Charts.html**. All three are also copyable in offline Help, reached through the Home **three-bar menu → Help & manager setup**. One bound workbook and one deployment/key per project handle questionnaire updates, data and photos. Run setupMapBanai; it retains an existing key/photo folder and compatible legacy Responses/Features, or creates missing settings/tabs. No manual key generation or second deployment is required.

Home **Cloud Sync** uploads data. **Survey Mode → Sync questionnaire** checks and applies questions. Home three-bar menu **My name / My responses** identifies the enumerator and opens saved records for correction. Corrections retain stable IDs and original collector, increment response_revision and clear upload acknowledgements. The new backend updates latest rows and preserves uploaded versions in revisions. Deploy the updated Code.gs before syncing edits; the client keeps edits queued if an old backend claims success without revision support.

Google Sheets shows readable metadata and answer columns plus authoritative json_1–json_4 chunks. MapBanai's spreadsheet menu opens the redesigned map/chart manager workspaces. See the guide for /exec URL, API key retrieval, deployment upgrades, limits and migration checks.

## Existing backend: questionnaire-only adapter alternative

1. Keep your XLSForm in a Google Spreadsheet with `survey`, `choices` and `settings` tabs. Use the normal XLSForm headers. In `settings`, give it a stable `form_id` matching the form already imported in MapBanai. Avoid changing that ID when editing questions. The current implementation links one live XLSForm workbook per project; other local forms are kept.
2. Configure the project's HTTPS Google Apps Script `/exec` URL and enumerator API key in MapBanai's project settings.
3. Obtain the project UUID from `project.json` in its exported `.mbproj` package (a ZIP file), or the project ID shown in settings. Keep the same project identity across the team; do not import as a new copy for this shared field campaign.
4. Add [questionnaire_apps_script.gs](server/questionnaire_apps_script.gs) to your existing Apps Script project. After your existing `doPost` parses its request, route `get_questionnaire` before its existing data-sync handling:

```javascript
if (payload.action === 'get_questionnaire') {
  return mapbanaiQuestionnaire(payload);
}
```

Use the variable name your script uses for its parsed request instead of `payload`. Keep your existing collection/photo upload branches. This adapter alone does not add response revision support.

5. In Apps Script Project Settings, add script property `MAPBANAI_QUESTIONNAIRES` containing:

```json
{
  "YOUR_PROJECT_UUID": {
    "spreadsheetId": "YOUR_GOOGLE_SPREADSHEET_ID",
    "apiKey": "YOUR_ENUMERATOR_KEY"
  }
}
```

Use the ID between `/d/` and `/edit` in the Google Sheet URL. Additional projects can have independent spreadsheet IDs and keys. The script owner must have access to each Sheet.

6. Update the web-app deployment to a new script version, executing as the owner with access permitted for your app's non-Google-login requests, subject to your organization's restrictions. Authorize spreadsheet access. Reuse the deployed `/exec` URL. Google's [web-app guide](https://developers.google.com/apps-script/guides/web) explains deployment; [ContentService](https://developers.google.com/apps-script/guides/content) explains the JSON response and Google redirect that the app follows.
7. In MapBanai, open Survey Mode or project settings and tap **Sync questionnaire → Check Google Sheet**. Review and apply the result. Test your existing data/photo sync too before distributing the project.

## Share with enumerators

Choose **Export / Share project → Include sync connection**, or enable the same option in Project QR. The `.mbproj` file (and an inline QR when small enough) includes forms, layer configuration, endpoint URL and API key. The option is off by default. Recipients can read the included key; use a key intended for enumerators and share through your trusted team channel.

Importing configures the connection automatically. A replacement package containing an explicit connection updates it; a replacement without one preserves the previous connection. Large questionnaires need a project file rather than inline QR. A bootstrap QR identifies a separately shared package and does not contain all its questions or credentials.

## Update questions in the field

Edit the Sheet's question labels, choices, required flags or supported logic. Enumerators connect to the internet and choose **Sync questionnaire → Check Google Sheet → Apply questionnaire update**. Changed contents generate a new internal revision even if the Sheet's numeric version was not incremented. A stable `form_id` is essential to recognise the same questionnaire.

Only future collections use the updated questions. Existing observations, drafts, original form snapshots, study sites and sync credentials are kept. The previous stored forms remain for history; normal selectors and newly shared packages show the latest online version. There is no background update midway through an interview. Offline collection continues with the last installed questionnaire.

Unsupported XLSForm constructs fail parsing before anything changes. Wrong-project responses, unexpected redirects, oversized payloads and network failures leave the current questionnaire intact. The current supported XLSForm subset remains the same as file import; this is not complete KoBo/ODK form-engine compatibility.

## Protocol

The app sends an HTTPS POST containing `action: get_questionnaire`, `projectId` and `apiKey`. The server authenticates the project/key and returns `ok`, the same project ID, a filename and worksheet rows. The key is in the request body, not a URL parameter. Numeric/boolean cells are sent as unformatted values; dates are serialized rather than passed directly from Apps Script's [Range.getValues](https://developers.google.com/apps-script/reference/spreadsheet/range#getvalues).

No real Google account/deployment was supplied for validation. The bundled handler and client are verified with mocks; deploy and test with your Sheet before field use.
