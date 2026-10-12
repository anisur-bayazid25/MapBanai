// Contract checks for the exact Apps Script code bundled in Help, using fake Google services.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
class Sheet {
  constructor(rows=[]) { this.rows=rows; this.capacity=2; }
  getLastRow() { return this.rows.length; }
  getLastColumn() { return Math.max(0,...this.rows.map(r=>r.length)); }
  getMaxRows() { return this.capacity; }
  insertRowsAfter(start,n) { this.capacity+=n; }
  getDataRange() { return {getValues:()=>this.rows}; }
  getRange(r,c,h,w) { return {
    getValues:()=>Array.from({length:h},(_,i)=>Array.from({length:w},(_,j)=>this.rows[r-1+i]?.[c-1+j]??'')),
    setValues: values=>{ assert(r+h-1<=this.capacity); values.forEach((row,i)=>{this.rows[r-1+i]??=[]; row.forEach((v,j)=>{this.rows[r-1+i][c-1+j]=String(v).replace(/^'(?=[=+@\-])/,'');});}); }
  }; }
}
const tabs = {survey:new Sheet([['type','name','label'],['text','name','Name']]), choices:new Sheet([['list_name','name','label']]),settings:new Sheet([['form_id','form_title'],['test','Test']])};
const book={getSheetByName:n=>tabs[n],insertSheet:n=>(tabs[n]=new Sheet()),getSpreadsheetTimeZone:()=> 'Asia/Dhaka'};
const files=new Map(); let writes=0; let locked=false;
const context=vm.createContext({
  ContentService:{MimeType:{JSON:'json'},createTextOutput:s=>({setMimeType:()=>JSON.parse(s)})},
  SpreadsheetApp:{openById:id=>{assert(['questions','data'].includes(id));return book;},flush:()=>{}},
  LockService:{getScriptLock:()=>({tryLock:()=>{locked=true;return true;},hasLock:()=>locked,releaseLock:()=>{locked=false;}})},
  DriveApp:{getFolderById:id=>({getName:()=> 'Photos',getFilesByName:n=>({hasNext:()=>files.has(n),next:()=>files.get(n)}),createFile:blob=>{writes++;const file={getId:()=> 'file-'+writes,getUrl:()=> 'private-url'};files.set(blob.name,file);return file;}})},
  Utilities:{base64Decode:s=>Buffer.from(s,'base64'),newBlob:(bytes,type,name)=>({bytes,type,name})}
});
vm.runInContext(fs.readFileSync('assets/help/manager_apps_script.gs','utf8'),context);
vm.runInContext("Object.assign(MAPBANAI,{projectId:'project-a',questionnaireSheetId:'questions',dataSheetId:'data',apiKey:'secret',photoFolderId:'folder'});setupMapBanai();",context);
const call=p=>context.doPost({postData:{contents:JSON.stringify({projectId:'project-a',apiKey:'secret',...p})}});
assert.equal(context.doGet().ok,true);
assert.equal(call({action:'get_questionnaire',apiKey:'wrong'}).ok,false);
assert.equal(call({action:'get_questionnaire',projectId:'other-project'}).ok,false);
const form=call({action:'get_questionnaire'}); assert.equal(form.ok,true);assert.equal(form.projectId,'project-a');assert.equal(form.sheets.survey[1][1],'name');
const batch={action:'sync_data',responses:[{response_id:'r1',answers:{name:'Alice'}}],features:[{feature_id:'f1',geojson:{type:'Point',coordinates:[90,23]}}]};
assert.equal(call(batch).ok,true); assert.equal(tabs.responses.getLastRow(),2);
batch.responses[0].answers.name='Updated'; assert.equal(call(batch).ok,true);
assert.equal(tabs.responses.getLastRow(),2);assert.equal(JSON.parse(tabs.responses.rows[1].slice(3).join('')).answers.name,'Updated');
assert.equal(call({action:'sync_data',responses:[{response_id:'r2',text:'x'.repeat(90000)},{response_id:'r3'}],features:[]}).ok,true);
assert.equal(tabs.responses.getLastRow(),4);assert.equal(JSON.parse(tabs.responses.rows[2].slice(3).join('')).text.length,90000);
assert.equal(call({action:'sync_data',responses:[{response_id:'r4'}],features:[{}]}).ok,false);
assert.equal(tabs.responses.getLastRow(),4); // Validation failure cannot acknowledge/partially write responses.
assert.equal(call({action:'sync_data',responses:[{response_id:'=IMPORTXML("url")'}],features:[]}).ok,true);
const photo={action:'upload_photo',photoId:'a'.repeat(64),responseId:'r1',filename:'a.jpg',mimeType:'image/jpeg',base64:'YWJj'};
assert.equal(call(photo).ok,true);assert.equal(call(photo).ok,true);assert.equal(writes,1);assert.equal(tabs.photos.getLastRow(),2);
assert.equal(call({...photo,mimeType:'application/javascript'}).ok,false);assert.equal(writes,1);
assert.equal(call({action:'sync_data',responses:[{response_id:'huge',text:'x'.repeat(160000)}],features:[]}).ok,false);
assert.equal(locked,false);
tabs.responses.rows[0][0]='incompatible';assert.equal(call(batch).ok,false);
console.log('Manager backend contract checks passed: auth, project isolation, questionnaire, updates, chunking, expansion, validation, retries and photo deduplication.');
