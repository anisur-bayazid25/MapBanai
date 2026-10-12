// MapBanai complete manager backend. Fill these values before deploying.
// Use the same spreadsheet ID twice for one workbook, or two different IDs.
const MAPBANAI = {
  projectId: 'PASTE_PROJECT_ID_FROM_MAPBANAI',
  questionnaireSheetId: 'PASTE_GOOGLE_SPREADSHEET_ID',
  dataSheetId: 'PASTE_GOOGLE_SPREADSHEET_ID',
  apiKey: 'REPLACE_WITH_A_LONG_RANDOM_PRIVATE_KEY',
  photoFolderId: 'PASTE_GOOGLE_DRIVE_FOLDER_ID'
};

function reply(value) {
  return ContentService.createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}
function doGet() { return reply({ok:true, service:'MapBanai'}); }

// Run once in the editor to authorize access and check the configured resources.
function setupMapBanai() {
  const book = SpreadsheetApp.openById(MAPBANAI.questionnaireSheetId);
  if (!book.getSheetByName('survey')) throw new Error('Import the XLSForm survey tab first.');
  const data = SpreadsheetApp.openById(MAPBANAI.dataSheetId);
  ['responses', 'features', 'photos'].forEach(function(name) { dataTab(data, name); });
  DriveApp.getFolderById(MAPBANAI.photoFolderId).getName();
}

function doPost(e) {
  let lock;
  try {
    const payload = JSON.parse(e.postData.contents);
    if (!MAPBANAI.apiKey || MAPBANAI.apiKey === 'REPLACE_WITH_A_LONG_RANDOM_PRIVATE_KEY' ||
        payload.apiKey !== MAPBANAI.apiKey || payload.projectId !== MAPBANAI.projectId) {
      return reply({ok:false, error:'Project ID or API key does not match.'});
    }
    if (payload.action === 'get_questionnaire') return questionnaire();
    if (payload.action !== 'sync_data' && payload.action !== 'upload_photo') {
      return reply({ok:false, error:'Unknown action.'});
    }
    lock = LockService.getScriptLock();
    if (!lock.tryLock(10000)) return reply({ok:false, error:'Server busy. Retry sync.'});
    const book = SpreadsheetApp.openById(MAPBANAI.dataSheetId);
    if (payload.action === 'sync_data') {
      // Validate both batches before writing. Retrying partial writes is idempotent.
      const responses = records(payload.responses, 'response_id');
      const features = records(payload.features, 'feature_id');
      upsert(dataTab(book, 'responses'), responses);
      upsert(dataTab(book, 'features'), features);
      SpreadsheetApp.flush();
      return reply({ok:true});
    }
    return uploadPhoto(book, payload);
  } catch (err) {
    // Never return submitted records, keys, or Google exception details.
    return reply({ok:false, error:'Setup or request failed. Check spreadsheet/folder IDs, permissions, worksheet limits and deployment version.'});
  } finally {
    if (lock && lock.hasLock()) lock.releaseLock();
  }
}

function questionnaire() {
  const book = SpreadsheetApp.openById(MAPBANAI.questionnaireSheetId);
  const sheets = {};
  ['survey', 'choices', 'settings'].forEach(function(name) {
    const tab = book.getSheetByName(name);
    if (!tab) { if (name === 'survey') throw new Error('Missing survey'); return; }
    if (tab.getLastRow() > 10000 || tab.getLastColumn() > 200) throw new Error('Sheet too large');
    sheets[name] = tab.getDataRange().getValues().map(function(row) {
      return row.map(function(value) {
        return value instanceof Date
          ? Utilities.formatDate(value, book.getSpreadsheetTimeZone(), "yyyy-MM-dd'T'HH:mm:ss")
          : String(value);
      });
    });
  });
  return reply({ok:true, projectId:MAPBANAI.projectId, fileName:'online_survey.xlsx', sheets:sheets});
}

// Keep full geometry, question answers, and metadata in JSON; IDs permit updates.
// JSON is chunked to stay below Google Sheets' per-cell text limit.
function dataTab(book, name) {
  let sheet = book.getSheetByName(name);
  if (!sheet) sheet = book.insertSheet(name);
  const headers = ['record_id','received_at','project_id','json_1','json_2','json_3','json_4'];
  if (sheet.getLastRow() === 0) sheet.getRange(1,1,1,7).setValues([headers]);
  else if (JSON.stringify(sheet.getRange(1,1,1,7).getValues()[0]) !== JSON.stringify(headers)) {
    throw new Error('Reserved output tab has different headers. Rename it before setup.');
  }
  return sheet;
}
function records(items, key) {
  if (!Array.isArray(items) || items.length > 10000) throw new Error('Invalid batch');
  return items.map(function(item) {
    const id = item && item[key];
    if (typeof id !== 'string' || !id || id.length > 200) throw new Error('Missing stable ID');
    return record(id, item);
  });
}
function literal(value) { return /^[=+@\-]/.test(value) ? "'" + value : value; }
function record(id, item) {
  const json = JSON.stringify(item);
  if (json.length > 160000) throw new Error('Record exceeds JSON limit');
  const row = [literal(id), new Date().toISOString(), MAPBANAI.projectId];
  for (let i=0; i<4; i++) row.push(literal(json.slice(i*40000,(i+1)*40000)));
  return row;
}
function upsert(sheet, rows) {
  const index = Object.create(null);
  const changed = Object.create(null);
  let nextRow = sheet.getLastRow()+1;
  if (sheet.getLastRow() > 1) sheet.getRange(2,1,sheet.getLastRow()-1,1).getValues()
    .forEach(function(row,i) { index[String(row[0])] = i+2; });
  rows.forEach(function(row) {
    const id = String(row[0]).replace(/^'(?=[=+@\-])/, '');
    const target = Object.prototype.hasOwnProperty.call(index,id) ? index[id] : nextRow++;
    changed[target] = row;
    index[id] = target;
  });
  const targets = Object.keys(changed).map(Number).sort(function(a,b) { return a-b; });
  if (!targets.length) return;
  const last = targets[targets.length-1];
  if (last > sheet.getMaxRows()) sheet.insertRowsAfter(sheet.getMaxRows(), last-sheet.getMaxRows());
  // Batch adjacent rows to avoid one Google API call per collected observation.
  for (let i=0; i<targets.length;) {
    const start = targets[i];
    const values = [changed[start]];
    i++;
    while (i<targets.length && targets[i] === start+values.length) values.push(changed[targets[i++]]);
    sheet.getRange(start,1,values.length,7).setValues(values);
  }
}
function uploadPhoto(book, payload) {
  if (typeof payload.photoId !== 'string' || !/^[a-f0-9]{64}$/.test(payload.photoId) ||
      typeof payload.base64 !== 'string' || payload.base64.length > 20*1024*1024 ||
      !['image/jpeg','image/png','image/webp'].includes(payload.mimeType)) throw new Error('Invalid photo');
  const folder = DriveApp.getFolderById(MAPBANAI.photoFolderId);
  const name = MAPBANAI.projectId + '_' + payload.photoId;
  const existing = folder.getFilesByName(name);
  const file = existing.hasNext() ? existing.next() : folder.createFile(
    Utilities.newBlob(Utilities.base64Decode(payload.base64), payload.mimeType, name));
  // Drive access follows the manager's folder permissions; this code makes no public link.
  upsert(dataTab(book, 'photos'), [record(payload.photoId, {
    photo_id:payload.photoId, filename:payload.filename, response_id:payload.responseId,
    file_id:file.getId(), url:file.getUrl(), mime_type:payload.mimeType
  })]);
  SpreadsheetApp.flush();
  return reply({ok:true, fileId:file.getId()});
}
