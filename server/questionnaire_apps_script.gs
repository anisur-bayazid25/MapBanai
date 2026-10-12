/**
 * Add this handler to your EXISTING sync Apps Script project.
 * In doPost, after JSON.parse(e.postData.contents), before the sync branch:
 *   if (payload.action === 'get_questionnaire') return mapbanaiQuestionnaire(payload);
 * Existing response/photo sync handlers remain as they are.
 * Script property MAPBANAI_QUESTIONNAIRES contains JSON:
 * {"PROJECT_UUID":{"spreadsheetId":"GOOGLE_SHEET_ID","apiKey":"ENUMERATOR_KEY"}}
 * This property is private to the script. Do not put API keys in public sheets.
 */
function mapbanaiQuestionnaire(payload) {
  function reply(data) {
    return ContentService.createTextOutput(JSON.stringify(data))
      .setMimeType(ContentService.MimeType.JSON);
  }
  try {
    var sources = JSON.parse(PropertiesService.getScriptProperties()
      .getProperty('MAPBANAI_QUESTIONNAIRES') || '{}');
    var source = sources[String(payload.projectId || '')];
    if (!source || !source.apiKey || String(payload.apiKey || '') !== String(source.apiKey)) {
      return reply({ok:false,error:'Unauthorized questionnaire request'});
    }
    var workbook = SpreadsheetApp.openById(source.spreadsheetId);
    var sheets = {};
    ['survey','choices','settings'].forEach(function(name) {
      var sheet = workbook.getSheetByName(name);
      if (sheet) {
        if (sheet.getLastRow() > 10000 || sheet.getLastColumn() > 200) throw new Error('Sheet too large');
        sheets[name] = sheet.getDataRange().getValues().map(function(row) {
          return row.map(function(cell) {
            if (cell instanceof Date) return Utilities.formatDate(cell, workbook.getSpreadsheetTimeZone(), "yyyy-MM-dd'T'HH:mm:ss");
            return cell == null ? '' : String(cell);
          });
        });
      }
    });
    if (!sheets.survey) return reply({ok:false,error:'Missing survey tab'});
    return reply({ok:true,projectId:payload.projectId,
      fileName:workbook.getName()+'.xlsx',sheets:sheets});
  } catch (_) {
    return reply({ok:false,error:'Questionnaire unavailable. Check the configured spreadsheet and script permissions.'});
  }
}
