/** MapBanai manager workspace — one bound spreadsheet, one deployment, one API key.
 * New project: set only projectId, leave the other placeholders, run setupMapBanai.
 * Open this script through the new spreadsheet: Extensions > Apps Script.
 * Map.html and Charts.html are optional companion files for the spreadsheet menu.
 */
const MAPBANAI = {
  projectId: 'PASTE_PROJECT_ID_FROM_MAPBANAI',
  questionnaireSheetId: 'PASTE_GOOGLE_SPREADSHEET_ID', // leave unchanged: setup uses this spreadsheet
  dataSheetId: 'PASTE_GOOGLE_SPREADSHEET_ID', // same workbook by default
  apiKey: 'REPLACE_WITH_A_LONG_RANDOM_PRIVATE_KEY', // leave unchanged: setup generates your private key
  photoFolderId: 'PASTE_GOOGLE_DRIVE_FOLDER_ID', // leave unchanged: setup creates your photo folder
};
function configured_(value) {
  return value && !/^(PASTE_|REPLACE_)/.test(value);
}
function config_() {
  const props = PropertiesService.getScriptProperties();
  const result = {};
  Object.keys(MAPBANAI).forEach(
    (k) =>
      (result[k] = configured_(MAPBANAI[k])
        ? MAPBANAI[k]
        : props.getProperty('MAPBANAI_' + k)),
  );
  result.apiKey = configured_(MAPBANAI.apiKey)
    ? MAPBANAI.apiKey
    : props.getProperty('MAPBANAI_API_KEY');
  result.photoFolderId = configured_(MAPBANAI.photoFolderId)
    ? MAPBANAI.photoFolderId
    : props.getProperty('PHOTOS_FOLDER_ID');
  return result;
}
function requireManager_() {
  const active = Session.getActiveUser().getEmail();
  const effective = Session.getEffectiveUser().getEmail();
  if (!active || active !== effective)
    throw new Error(
      'Open this workspace from the spreadsheet with your manager account.',
    );
}
function setupMapBanai() {
  requireManager_();
  const props = PropertiesService.getScriptProperties();
  const bound = SpreadsheetApp.getActiveSpreadsheet();
  const cfg = config_();
  if (!cfg.projectId)
    throw new Error(
      'Copy the project ID from MapBanai project settings into MAPBANAI.projectId.',
    );
  cfg.dataSheetId = cfg.dataSheetId || (bound && bound.getId());
  cfg.questionnaireSheetId = cfg.questionnaireSheetId || cfg.dataSheetId;
  if (!cfg.dataSheetId)
    throw new Error(
      'Bind this script to a Google Sheet, or set its spreadsheet ID.',
    );
  cfg.apiKey = cfg.apiKey || Utilities.getUuid() + Utilities.getUuid();
  cfg.photoFolderId =
    cfg.photoFolderId || DriveApp.createFolder('MapBanai field photos').getId();
  Object.keys(cfg).forEach((k) => props.setProperty('MAPBANAI_' + k, cfg[k]));
  props.setProperty('MAPBANAI_API_KEY', cfg.apiKey);
  props.setProperty('PHOTOS_FOLDER_ID', cfg.photoFolderId);
  const questions = SpreadsheetApp.openById(cfg.questionnaireSheetId);
  const headings = {
    survey: ['type', 'name', 'label'],
    choices: ['list_name', 'name', 'label'],
    settings: ['form_id', 'form_title', 'version'],
  };
  Object.keys(headings).forEach((name) => {
    if (!questions.getSheetByName(name)) {
      const tab = questions.insertSheet(name);
      capacity_(tab, 1, headings[name].length);
      tab.getRange(1, 1, 1, headings[name].length).setValues([headings[name]]);
    }
  });
  const book = SpreadsheetApp.openById(cfg.dataSheetId);
  ['responses', 'features', 'photos', 'revisions'].forEach((name) =>
    dataTab_(book, name),
  );
  DriveApp.getFolderById(cfg.photoFolderId).getName();
  console.log('MapBanai setup complete. API key: ' + cfg.apiKey);
  console.log(
    'Copy the Web app /exec URL from Deploy > Manage deployments. Keep this API key private.',
  );
}
function setup() {
  setupMapBanai();
}
function reply_(value) {
  return ContentService.createTextOutput(JSON.stringify(value)).setMimeType(
    ContentService.MimeType.JSON,
  );
}
function doGet() {
  return reply_({ ok: true, service: 'MapBanai', revisionSupport: true });
}
function doPost(e) {
  let lock;
  try {
    const body = JSON.parse(e.postData.contents),
      cfg = config_();
    if (
      !cfg.apiKey ||
      body.apiKey !== cfg.apiKey ||
      body.projectId !== cfg.projectId
    )
      return reply_({
        ok: false,
        error: 'Project ID or API key does not match.',
      });
    if (body.action === 'test_connection') {
      SpreadsheetApp.openById(cfg.dataSheetId).getName();
      return reply_({
        ok: true,
        connectionVerified: true,
        revisionSupport: true,
      });
    }
    if (body.action === 'get_questionnaire') return questionnaire_();
    if (!['sync_data', 'upload_photo'].includes(body.action))
      return reply_({ ok: false, error: 'Unknown action.' });
    lock = LockService.getScriptLock();
    if (!lock.tryLock(10000))
      return reply_({ ok: false, error: 'Server busy. Retry sync.' });
    const book = SpreadsheetApp.openById(cfg.dataSheetId);
    if (body.action === 'upload_photo') return uploadPhoto_(book, body);
    const responses = records_(body.responses, 'response_id'),
      features = records_(body.features, 'feature_id');
    // Preflight both collections before changing any latest records.
    const responsePlan = plan_(
      dataTab_(book, 'responses'),
      responses,
      'response',
    );
    const featurePlan = plan_(dataTab_(book, 'features'), features, 'feature');
    const history = dataTab_(book, 'revisions');
    // History first: a failed write can be retried without losing an earlier revision.
    upsert_(history, [...responsePlan.history, ...featurePlan.history]);
    upsert_(responsePlan.sheet, responsePlan.rows);
    upsert_(featurePlan.sheet, featurePlan.rows);
    SpreadsheetApp.flush();
    return reply_({
      ok: true,
      responses: responsePlan.rows.length,
      features: featurePlan.rows.length,
      revisionSupport: true,
    });
  } catch (err) {
    return reply_({
      ok: false,
      error:
        err && err.conflict
          ? err.message
          : 'Setup or request failed. Check project ID, spreadsheet/folder permissions and deployed version.',
    });
  } finally {
    if (lock && lock.hasLock()) lock.releaseLock();
  }
}
function questionnaire_() {
  const cfg = config_(),
    book = SpreadsheetApp.openById(cfg.questionnaireSheetId),
    sheets = {};
  ['survey', 'choices', 'settings'].forEach((name) => {
    const tab = book.getSheetByName(name);
    if (!tab) {
      if (name === 'survey') throw Error('Missing survey');
      return;
    }
    if (tab.getLastRow() > 10000 || tab.getLastColumn() > 200)
      throw Error('Sheet too large');
    sheets[name] = tab
      .getDataRange()
      .getValues()
      .map((row) =>
        row.map((value) =>
          value instanceof Date
            ? Utilities.formatDate(
                value,
                book.getSpreadsheetTimeZone(),
                "yyyy-MM-dd'T'HH:mm:ss",
              )
            : String(value),
        ),
      );
  });
  return reply_({
    ok: true,
    projectId: cfg.projectId,
    fileName: 'online_survey.xlsx',
    sheets,
  });
}
function capacity_(sheet, rows, columns) {
  if (rows > sheet.getMaxRows())
    sheet.insertRowsAfter(sheet.getMaxRows(), rows - sheet.getMaxRows());
  if (columns > sheet.getMaxColumns())
    sheet.insertColumnsAfter(
      sheet.getMaxColumns(),
      columns - sheet.getMaxColumns(),
    );
}
function dataTab_(book, name) {
  let sheet =
    book.getSheetByName(name) ||
    book.getSheetByName(name[0].toUpperCase() + name.slice(1));
  if (!sheet) sheet = book.insertSheet(name);
  const headers = [
    'record_id',
    'received_at',
    'project_id',
    'json_1',
    'json_2',
    'json_3',
    'json_4',
  ];
  if (!sheet.getLastRow()) {
    capacity_(sheet, 1, 7);
    sheet.getRange(1, 1, 1, 7).setValues([headers]);
  } else {
    const existing = sheet
      .getRange(1, 1, 1, sheet.getLastColumn())
      .getValues()[0];
    if (
      !['record_id', 'response_id', 'feature_id'].includes(String(existing[0]))
    )
      throw Error('Incompatible output tab');
    headers.forEach((h) => {
      if (!existing.includes(h)) existing.push(h);
    });
    capacity_(sheet, 1, existing.length);
    sheet.getRange(1, 1, 1, existing.length).setValues([existing]);
  }
  return sheet;
}
function literal_(value) {
  return typeof value === 'string' && /^[=+@\-]/.test(value)
    ? "'" + value
    : value;
}
function record_(id, item) {
  const json = JSON.stringify(item);
  if (json.length > 160000) throw Error('Record exceeds JSON limit');
  const row = [id, new Date().toISOString(), config_().projectId];
  for (let i = 0; i < 4; i++) row.push(json.slice(i * 40000, (i + 1) * 40000));
  return row;
}
function records_(items, key) {
  if (!Array.isArray(items) || items.length > 10000)
    throw Error('Invalid batch');
  const ids = new Set();
  return items.map((item) => {
    const id = item && item[key],
      revision = item && item.response_revision;
    if (typeof id !== 'string' || !id || id.length > 200 || ids.has(id))
      throw Error('Missing or duplicate stable ID');
    ids.add(id);
    if (
      revision !== undefined &&
      (!Number.isSafeInteger(revision) || revision < 1)
    )
      throw Error('Invalid revision');
    return record_(id, { ...item, response_revision: revision || 1 });
  });
}
function canonical_(obj) {
  if (Array.isArray(obj)) return obj.map(canonical_);
  if (obj && typeof obj === 'object') {
    const out = Object.create(null);
    Object.keys(obj)
      .sort()
      .forEach((k) => (out[k] = canonical_(obj[k])));
    return out;
  }
  return obj;
}
function parseJSON_(value, fallback) {
  try {
    return typeof value === 'string' ? JSON.parse(value) : value || fallback;
  } catch (_) {
    return fallback;
  }
}
function fromCells_(headers, cells, kind) {
  const row = {};
  headers.forEach((h, i) => {
    if (h) row[String(h)] = cells[i] === undefined ? '' : cells[i];
  });
  const encoded = ['json_1', 'json_2', 'json_3', 'json_4']
    .map((h) => row[h] || '')
    .join('');
  if (encoded) return parseJSON_(encoded, {});
  // Read the attached legacy backend's rows without rewriting or deleting them.
  const answers = parseJSON_(row.answers_json, {});
  return {
    ...row,
    _legacy: true,
    [kind === 'feature' ? 'feature_id' : 'response_id']: String(
      row.record_id || row.response_id || row.feature_id || '',
    ),
    response_revision: Number(row.response_revision) || 1,
    answers,
    attributes:
      kind === 'feature'
        ? { ...answers, ...parseJSON_(row.attributes, {}) }
        : undefined,
    geojson: parseJSON_(row.geojson, null),
  };
}
function plan_(sheet, rows, kind) {
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0],
    index = new Map();
  if (sheet.getLastRow() > 1)
    sheet
      .getRange(2, 1, sheet.getLastRow() - 1, headers.length)
      .getValues()
      .forEach((cells) => {
        const old = fromCells_(headers, cells, kind);
        index.set(String(old.response_id || old.feature_id || cells[0]), old);
      });
  const plan = { sheet, rows: [], history: [] };
  rows.forEach((row) => {
    const item = JSON.parse(row.slice(3).join('')),
      old = index.get(row[0]),
      revision = item.response_revision;
    if (old) {
      const previous = Number(old.response_revision) || 1;
      const same =
        JSON.stringify(canonical_(item)) === JSON.stringify(canonical_(old));
      const legacyCompatible =
        old._legacy &&
        (kind === 'response'
          ? JSON.stringify(canonical_(item.answers || {})) ===
            JSON.stringify(canonical_(old.answers || {}))
          : JSON.stringify(canonical_(item.geojson || {})) ===
            JSON.stringify(canonical_(old.geojson || {})));
      if (
        revision < previous ||
        (revision === previous && !same && !legacyCompatible)
      ) {
        const err = Error(
          'Revision conflict for ' +
            row[0] +
            '. The server has revision ' +
            previous +
            '. Keep this response and ask your manager to review.',
        );
        err.conflict = true;
        throw err;
      }
      if (revision === previous && !old._legacy) return;
      if (old._legacy && revision === previous) {
        plan.history.push(
          record_(kind + ':' + row[0] + ':legacy', {
            ...old,
            record_kind: kind,
          }),
        );
      } else
        plan.history.push(
          record_(kind + ':' + row[0] + ':' + previous, {
            ...old,
            record_kind: kind,
          }),
        );
    }
    plan.rows.push(row);
    plan.history.push(
      record_(kind + ':' + row[0] + ':' + revision, {
        ...item,
        record_kind: kind,
      }),
    );
  });
  return plan;
}
function upsert_(sheet, rows) {
  if (!rows.length) return;
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0],
    index = new Map(),
    changes = new Map();
  let next = sheet.getLastRow() + 1;
  const keyColumn = headers.indexOf('record_id'),
    legacyColumn = headers[0];
  if (sheet.getLastRow() > 1)
    sheet
      .getRange(2, 1, sheet.getLastRow() - 1, headers.length)
      .getValues()
      .forEach((cells, i) =>
        index.set(String(cells[keyColumn] || cells[0]), i + 2),
      );
  const items = rows.map((row) => ({
    row,
    item: JSON.parse(row.slice(3).join('')),
  }));
  const readable = [
    'response_revision',
    'form_version',
    'study_workflow',
    'record_kind',
    'site_id',
    'round_id',
    'collection_round',
    'outcome',
    'observed_at',
    'project_name',
    'surveyor',
    'form_name',
    'edited_at',
    'edited_by',
    'latitude',
    'longitude',
    'answers_json',
    'geojson',
  ];
  if (sheet.getName().toLowerCase() === 'photos')
    readable.push('photo_id', 'filename', 'response_id', 'file_id', 'url', 'mime_type', 'photo_preview', 'photo_link');
  readable.forEach((h) => {
    if (!headers.includes(h)) headers.push(h);
  });
  items.forEach(({ item }) =>
    Object.keys(item.answers || item.attributes || {}).forEach((k) => {
      if (!headers.includes('answer:' + k)) headers.push('answer:' + k);
    }),
  );
  if (headers.length > 500) throw Error('Too many answer columns');
  capacity_(sheet, 1, headers.length);
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  items.forEach(({ row, item }) => {
    const target = index.has(row[0]) ? index.get(row[0]) : next++;
    index.set(row[0], target);
    const answers = item.answers || item.attributes || {},
      point = point_(item);
    const values = {
      ...answers,
      ...item,
      record_id: row[0],
      received_at: row[1],
      synced_at: row[1],
      project_id: row[2],
      latitude: point ? point[1] : '',
      longitude: point ? point[0] : '',
      answers_json: JSON.stringify(answers),
      geojson: item.geojson ? JSON.stringify(item.geojson) : '',
    };
    if (legacyColumn === 'response_id') values.response_id = row[0];
    if (legacyColumn === 'feature_id') values.feature_id = row[0];
    for (let i = 0; i < 4; i++) values['json_' + (i + 1)] = row[i + 3];
    Object.keys(answers).forEach((k) => (values['answer:' + k] = answers[k]));
    changes.set(
      target,
      headers.map((h) => {
        let v = values[h];
        if (v === undefined || v === null) return '';
        if (typeof v === 'object') v = JSON.stringify(v);
        if (String(v).length > 40000) return '[See JSON chunks]';
        return literal_(v);
      }),
    );
  });
  const targets = [...changes.keys()].sort((a, b) => a - b);
  capacity_(sheet, targets[targets.length - 1], headers.length);
  for (let i = 0; i < targets.length; ) {
    const start = targets[i],
      values = [changes.get(start)];
    i++;
    while (i < targets.length && targets[i] === start + values.length)
      values.push(changes.get(targets[i++]));
    sheet.getRange(start, 1, values.length, headers.length).setValues(values);
  }
}
function point_(item) {
  const g = parseJSON_(item.geojson || item.geometry, null);
  if (g && g.type === 'Point') return g.coordinates;
  if (
    item.latitude !== '' &&
    item.latitude != null &&
    item.longitude !== '' &&
    item.longitude != null &&
    Number.isFinite(Number(item.latitude)) &&
    Number.isFinite(Number(item.longitude))
  )
    return [Number(item.longitude), Number(item.latitude)];
  const answers = item.answers || item.attributes || {},
    priority = [
      'location_point',
      'gps',
      'geopoint',
      'location',
      'coordinates',
      'gps_point',
    ];
  for (const k of [...new Set([...priority, ...Object.keys(answers)])]) {
    const v = answers[k];
    if (typeof v !== 'string') continue;
    const match =
      /^\s*(-?\d+(?:\.\d+)?)\s*[, ]\s*(-?\d+(?:\.\d+)?)(?:\s*[, ]\s*-?\d+(?:\.\d+)?){0,2}\s*$/.exec(
        v,
      );
    if (
      match &&
      Math.abs(Number(match[1])) <= 90 &&
      Math.abs(Number(match[2])) <= 180
    )
      return [Number(match[2]), Number(match[1])];
  }
  return null;
}
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('MapBanai')
    .addItem('Open map workspace', 'launchMapModal')
    .addItem('Open charts workspace', 'launchChartModal')
    .addItem('Refresh photo previews', 'refreshPhotoPreviews')
    .addItem('Connection and setup guide', 'showConnectionInfo')
    .addToUi();
}
function launchMapModal() {
  requireManager_();
  SpreadsheetApp.getUi().showModalDialog(
    HtmlService.createHtmlOutputFromFile('Map').setWidth(1400).setHeight(860),
    'MapBanai · Project atlas',
  );
}
function launchChartModal() {
  requireManager_();
  SpreadsheetApp.getUi().showModalDialog(
    HtmlService.createHtmlOutputFromFile('Charts')
      .setWidth(1350)
      .setHeight(850),
    'MapBanai · Field insights',
  );
}
function showConnectionInfo() {
  requireManager_();
  const cfg = config_(),
    ui = SpreadsheetApp.getUi();
  ui.alert(
    'MapBanai connection',
    'API key: ' +
      (cfg.apiKey || 'Run setupMapBanai first') +
      '\n\nProject ID: ' +
      (cfg.projectId || 'Not configured') +
      '\n\nWeb app URL: Apps Script → Deploy → Manage deployments → copy the URL ending /exec.\n\nUpdating code: edit the existing deployment → New version → Deploy. Keep the URL and key.\n\nOne workbook may hold survey/choices/settings and collected Responses/Features. Do not type collected answers in the survey tab.',
    ui.ButtonSet.OK,
  );
}
function getSheetNames() {
  requireManager_();
  const book = SpreadsheetApp.openById(config_().dataSheetId);
  return [
    'All collections',
    ...['responses', 'features']
      .map(
        (n) =>
          book.getSheetByName(n) ||
          book.getSheetByName(n[0].toUpperCase() + n.slice(1)),
      )
      .filter(Boolean)
      .map((s) => s.getName()),
  ];
}
function getMapDataPayload(sheetName) {
  requireManager_();
  const cfg = config_(),
    book = SpreadsheetApp.openById(cfg.dataSheetId),
    rows = [];
  let total = 0;
  const names =
    sheetName && sheetName !== 'All collections'
      ? [sheetName]
      : ['responses', 'features'];
  names.forEach((name) => {
    if (!/^(responses|features)$/i.test(name))
      throw Error('Select a collection sheet.');
    const sheet =
      book.getSheetByName(name) ||
      book.getSheetByName(name[0].toUpperCase() + name.slice(1));
    if (!sheet || sheet.getLastRow() < 2) return;
    const count = sheet.getLastRow() - 1;
    total += count;
    const take = Math.min(count, 25000 - rows.length);
    if (take <= 0) return;
    const headers = sheet
        .getRange(1, 1, 1, sheet.getLastColumn())
        .getValues()[0],
      kind = /features/i.test(name) ? 'feature' : 'response';
    sheet
      .getRange(2, 1, take, headers.length)
      .getValues()
      .forEach((cells) => {
        const item = fromCells_(headers, cells, kind),
          answers = item.answers || item.attributes || {},
          point = point_(item);
        const row = {
          ...answers,
          ...item,
          _record_kind: kind,
          _rowIndex: rows.length + 1,
        };
        delete row.answers;
        delete row.attributes;
        if (point) {
          row.latitude = point[1];
          row.longitude = point[0];
        }
        row.response_revision = Number(item.response_revision) || 1;
        row.answers_json = JSON.stringify(answers);
        if (typeof row.geojson === 'object' && row.geojson)
          row.geojson = JSON.stringify(row.geojson);
        Object.keys(row).forEach((k) => {
          if (row[k] instanceof Date) row[k] = row[k].toISOString();
          else if (row[k] && typeof row[k] === 'object')
            row[k] = JSON.stringify(row[k]);
        });
        rows.push(row);
      });
  });
  const features = [];
  rows.forEach((row) => {
    const answers = parseJSON_(row.answers_json, {}),
      g = parseJSON_(row.geojson, null),
      point = point_(row),
      site = parseJSON_(row.study_site, null);
    const geometry =
      g && g.type === 'Feature'
        ? g.geometry
        : g || (point ? { type: 'Point', coordinates: point } : null);
    const props = {
      id: row.response_id || row.feature_id || row.record_id,
      name: row.name || row.site_name || row.form_name || 'Collection',
      project_name: row.project_name,
      project_id: row.project_id || cfg.projectId,
      form_name: row.form_name || row.geometry_type || row._record_kind,
      surveyor: row.surveyor,
      submitted_at: row.submitted_at || row.received_at || row.synced_at,
      source: site ? 'study_area' : row._record_kind === 'feature' ? 'gis' : 'collection',
      site_status: site ? site.status : row.site_status,
      status: site ? site.status : row.status,
      revision: site ? site.revision : row.response_revision,
      layer_id: row.layer_id || 'default',
      layer_name: row.layer_id || 'Main layer',
      response_revision: row.response_revision,
      form_version: row.form_version,
      edited_by: row.edited_by,
      answers,
    };
    if (geometry && geometry.type)
      features.push({ type: 'Feature', geometry, properties: props });
    Object.keys(answers).forEach((key) => {
      const extra = parseJSON_(answers[key], null);
      if (
        extra &&
        ['LineString', 'Polygon', 'MultiLineString', 'MultiPolygon'].includes(
          extra.type,
        )
      )
        features.push({
          type: 'Feature',
          geometry: extra,
          properties: { ...props, id: props.id + ':' + key, name: key },
        });
    });
  });
  return JSON.parse(JSON.stringify({
    data: rows,
    headers: [...new Set(rows.flatMap((row) => Object.keys(row)))],
    sheetName: sheetName || 'All collections',
    total,
    truncated: total > rows.length,
    featureCollection: {
      type: 'FeatureCollection',
      features,
      vector_layers: [],
    },
  }));
}

function uploadPhoto_(book, payload) {
  if (
    typeof payload.photoId !== 'string' ||
    !/^[a-f0-9]{64}$/.test(payload.photoId) ||
    typeof payload.base64 !== 'string' ||
    payload.base64.length > 20 * 1024 * 1024 ||
    !['image/jpeg', 'image/png', 'image/webp'].includes(payload.mimeType)
  )
    throw new Error('Invalid photo');
  const folder = DriveApp.getFolderById(config_().photoFolderId);
  const name = config_().projectId + '_' + payload.photoId;
  const existing = folder.getFilesByName(name);
  const file = existing.hasNext()
    ? existing.next()
    : folder.createFile(
        Utilities.newBlob(
          Utilities.base64Decode(payload.base64),
          payload.mimeType,
          name,
        ),
      );
  // Drive access follows the manager's folder permissions; this code makes no public link.
  upsert_(dataTab_(book, 'photos'), [
    record_(payload.photoId, {
      photo_id: payload.photoId,
      filename: payload.filename,
      response_id: payload.responseId,
      file_id: file.getId(),
      url: file.getUrl(),
      mime_type: payload.mimeType,
    }),
  ]);
  const sheet = dataTab_(book, 'photos');
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const rows = sheet.getDataRange().getValues();
  const row = rows.findIndex((cells, i) => i > 0 && String(cells[headers.indexOf('record_id')]) === payload.photoId) + 1;
  photoPreview_(sheet, row, headers, file, payload.photoId);
  SpreadsheetApp.flush();
  return reply_({ ok: true, fileId: file.getId() });
}

// Embed a private Drive thumbnail rather than an IMAGE formula requiring public URLs.
function photoPreview_(sheet, row, headers, file, photoId) {
  const previewColumn = headers.indexOf('photo_preview') + 1;
  const linkColumn = headers.indexOf('photo_link') + 1;
  const url = 'https://drive.google.com/file/d/' + encodeURIComponent(file.getId()) + '/view';
  sheet.getRange(row, linkColumn).setRichTextValue(
    SpreadsheetApp.newRichTextValue().setText('Open photo in Drive').setLinkUrl(url).build(),
  );
  const marker = 'MapBanai photo:' + photoId;
  const prior = sheet.getImages().find((image) => image.getAltTextTitle() === marker);
  if (prior) {
    prior.setAnchorCell(sheet.getRange(row, previewColumn));
    sheet.setRowHeight(row, 112);
    return true;
  }
  let image;
  try {
    const blob = file.getThumbnail() || file.getBlob();
    if (blob.getBytes().length > 2 * 1024 * 1024)
      throw Error('Image exceeds Sheets preview limit');
    image = sheet.insertImage(blob, previewColumn, row);
    const scale = Math.min(144 / image.getWidth(), 100 / image.getHeight(), 1);
    image.setWidth(Math.max(1, Math.round(image.getWidth() * scale)));
    image.setHeight(Math.max(1, Math.round(image.getHeight() * scale)));
    image.setAltTextTitle(marker);
    image.setAltTextDescription('Field photo; open the adjacent Drive link for the original.');
    sheet.setColumnWidth(previewColumn, 156);
    sheet.setRowHeight(row, 112);
    sheet.getRange(row, previewColumn).setValue('');
    return true;
  } catch (_) {
    if (image) image.remove();
    sheet.getRange(row, previewColumn).setValue('Preview unavailable; use Drive link. Retry Refresh photo previews.');
    return false;
  }
}
function refreshPhotoPreviews() {
  requireManager_();
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(10000)) throw Error('Sync is running. Try again shortly.');
  let completed = 0, failed = 0, remaining = 0;
  try {
    const book = SpreadsheetApp.openById(config_().dataSheetId);
    const sheet = dataTab_(book, 'photos');
    const values = sheet.getDataRange().getValues();
    const headers = values[0];
    const items = values.slice(1).map((cells) => {
      const encoded = ['json_1', 'json_2', 'json_3', 'json_4'].map((h) => cells[headers.indexOf(h)] || '').join('');
      return parseJSON_(encoded, null);
    });
    upsert_(sheet, items.filter((item) => item && item.photo_id && item.file_id).map((item) => record_(item.photo_id, item)));
    const current = sheet.getDataRange().getValues(), columns = current[0];
    const existing = new Set(sheet.getImages().map((image) => image.getAltTextTitle()));
    const started = Date.now();
    let attempted = 0;
    current.slice(1).forEach((cells, index) => {
      const photoId = cells[columns.indexOf('photo_id')], fileId = cells[columns.indexOf('file_id')];
      if (!photoId || !fileId) return;
      if (existing.has('MapBanai photo:' + photoId)) {
        photoPreview_(sheet, index + 2, columns, { getId: () => String(fileId) }, photoId);
        return;
      }
      if (attempted >= 50 || Date.now() - started > 240000) { remaining++; return; }
      attempted++;
      try {
        const file = DriveApp.getFileById(String(fileId));
        if (photoPreview_(sheet, index + 2, columns, file, photoId)) completed++;
        else failed++;
      } catch (_) { failed++; }
    });
    SpreadsheetApp.flush();
  } finally { lock.releaseLock(); }
  SpreadsheetApp.getUi().alert('Photo previews: ' + completed + ' added, ' + failed + ' unavailable, ' + remaining + ' remaining. Run again for remaining photos. Drive links require permission to the photo folder.');
}
