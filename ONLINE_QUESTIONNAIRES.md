# Google Sheets questionnaire sync

A project can distribute its questions and sync connection to enumerators, then pull updated XLSForm questions from a Google Sheet. This client implementation needs the accompanying Apps Script handler deployed on your existing endpoint. It does not automatically modify an existing Google deployment.

## Recommended complete setup (also bundled in app Help)

Open **Help & manager setup** from Home, Settings or Project Details. It works offline and includes all field-mode instructions plus a copyable complete backend: `assets/help/manager_apps_script.gs`. From Project Details, copied code already includes that project UUID. Fill the remaining spreadsheet IDs, Drive folder ID and private key; run `setupMapBanai`, then deploy as a web app and save its `/exec` URL/key in Project Details.

One workbook with questionnaire and output tabs is simplest. Two workbooks can use the same deployment/key by assigning different `questionnaireSheetId` and `dataSheetId` values. Separate deployments/keys are not configurable in the current client. Use one setup per project. The output tabs `responses`, `features`, `photos` contain stable IDs and complete JSON split into four columns to respect Sheets cell limits; concatenate `json_1`–`json_4` for the full record. Photo rows reference private Drive files and response IDs. Stable record and photo IDs make retries idempotent. Data sync uploads records; it does not download other enumerators’ records.

The complete backend needs the updated client, which includes top-level project IDs in data/photo requests and content-based photo IDs. It does not silently replace an existing deployment. Pilot it on a new backend first.

## Existing backend: questionnaire adapter alternative

1. Keep your XLSForm in a Google Spreadsheet with `survey`, `choices` and `settings` tabs. Use the normal XLSForm headers. In `settings`, give it a stable `form_id` matching the form already imported in MapBanai. Avoid changing that ID when editing questions. The current implementation links one live XLSForm workbook per project; other local forms are kept.
2. Configure the project's HTTPS Google Apps Script `/exec` URL and enumerator API key in MapBanai's project settings.
3. Obtain the project UUID from `project.json` in its exported `.mbproj` package (a ZIP file), or the project ID shown in settings. Keep the same project identity across the team; do not import as a new copy for this shared field campaign.
4. Add [questionnaire_apps_script.gs](server/questionnaire_apps_script.gs) to your existing Apps Script project. After your existing `doPost` parses its request, route `get_questionnaire` before its existing data-sync handling:

```javascript
if (payload.action === 'get_questionnaire') {
  return mapbanaiQuestionnaire(payload);
}
```

Use the variable name your script uses for its parsed request instead of `payload`. Keep your existing collection/photo upload branches.

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
