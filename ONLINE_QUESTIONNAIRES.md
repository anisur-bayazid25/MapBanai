# Google Sheets questionnaire sync — v2.6.5

For each new project, use one fresh Google spreadsheet, one Apps Script deployment and one private API key. Follow [the complete new-project setup](server/manager/README.md). The same Code.gs, Map.html and Charts.html are copyable offline in Home → three-bar menu → Help & manager setup.

Create the project in MapBanai and copy its UUID. From the new spreadsheet open Extensions → Apps Script. Paste the three supplied files and replace only MAPBANAI.projectId in Code.gs. Leave all four other placeholders unchanged. Run setupMapBanai to use that spreadsheet for questions and answers, generate the key, create the photo folder and prepare data tabs.

Reload the spreadsheet → MapBanai → Connection and setup guide to copy the key. Deploy a new Web app with Execute as: Me and Who has access: Anyone. Copy the complete /exec URL. Save both URL and key in MapBanai Project Details → Cloud Sync, then Test Connection.

Survey Mode → Sync questionnaire checks and applies questions. Home → Cloud Sync uploads data. The Home three-bar menu contains My name and My responses. Corrections keep stable IDs, increment response_revision and upload the latest record alongside its revision history. Use a fresh setup for each new project.

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
