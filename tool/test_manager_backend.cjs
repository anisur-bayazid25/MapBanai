// Contract checks for the exact Apps Script code bundled in Help, using fake Google services.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
class Sheet {
  constructor(rows=[],name='') { this.rows=rows; this.capacity=Math.max(2,rows.length); this.columns=26; this.name=name; }
  getName(){return this.name;}
  getMaxColumns(){return this.columns;}
  insertColumnsAfter(start,n){this.columns+=n;}
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
const book={getSheetByName:n=>tabs[n],insertSheet:n=>(tabs[n]=new Sheet([],n)),getSpreadsheetTimeZone:()=> 'Asia/Dhaka'};
const properties=new Map();let activeUser='manager@example.com';
const files=new Map(); let writes=0; let locked=false;
const context=vm.createContext({
  console:{log:()=>{}},
  PropertiesService:{getScriptProperties:()=>({getProperty:k=>properties.get(k),setProperty:(k,v)=>properties.set(k,v)})},
  Session:{getActiveUser:()=>({getEmail:()=>activeUser}),getEffectiveUser:()=>({getEmail:()=> 'manager@example.com'})},
  ContentService:{MimeType:{JSON:'json'},createTextOutput:s=>({setMimeType:()=>JSON.parse(s)})},
  SpreadsheetApp:{getActiveSpreadsheet:()=>book,openById:id=>{assert(['questions','data'].includes(id));return book;},flush:()=>{}},
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
const recordAt=(sheet,row=1)=>JSON.parse(['json_1','json_2','json_3','json_4'].map(h=>sheet.rows[row][sheet.rows[0].indexOf(h)]||'').join(''));
const batch={action:'sync_data',responses:[{response_id:'r1',answers:{name:'Alice'}}],features:[{feature_id:'f1',geojson:{type:'Point',coordinates:[90,23]}}]};
assert.equal(call(batch).ok,true); assert.equal(tabs.responses.getLastRow(),2);assert.equal(tabs.revisions.getLastRow(),3);
batch.responses[0].answers.name='Updated';batch.responses[0].response_revision=2; assert.equal(call(batch).ok,true);
assert.equal(tabs.responses.getLastRow(),2);assert.equal(tabs.revisions.getLastRow(),4);assert.equal(recordAt(tabs.responses).answers.name,'Updated');
assert.equal(call({action:'sync_data',responses:[{response_id:'r2',text:'x'.repeat(90000)},{response_id:'r3'}],features:[]}).ok,true);
assert.equal(tabs.responses.getLastRow(),4);assert.equal(recordAt(tabs.responses,2).text.length,90000);
assert.equal(call({action:'sync_data',responses:[{response_id:'r4'}],features:[{}]}).ok,false);
assert.equal(tabs.responses.getLastRow(),4); // Validation failure cannot acknowledge/partially write responses.
assert.equal(call({action:'sync_data',responses:[{response_id:'=IMPORTXML("url")'}],features:[]}).ok,true);
const photo={action:'upload_photo',photoId:'a'.repeat(64),responseId:'r1',filename:'a.jpg',mimeType:'image/jpeg',base64:'YWJj'};
assert.equal(call(photo).ok,true);assert.equal(call(photo).ok,true);assert.equal(writes,1);assert.equal(tabs.photos.getLastRow(),2);
assert.equal(call({...photo,mimeType:'application/javascript'}).ok,false);assert.equal(writes,1);
assert.equal(call({action:'sync_data',responses:[{response_id:'huge',text:'x'.repeat(160000)}],features:[]}).ok,false);
assert.equal(locked,false);
assert.equal(call(batch).ok,true);
const historyCount=tabs.revisions.getLastRow();
assert.equal(call({action:'sync_data',responses:[{response_id:'r1',response_revision:1,answers:{name:'stale'}}],features:[]}).ok,false);
assert.equal(recordAt(tabs.responses).answers.name,'Updated');assert.equal(tabs.revisions.getLastRow(),historyCount);
assert.equal(call({action:'sync_data',responses:[{response_id:'r1',response_revision:2,answers:{name:'conflict'}}],features:[]}).ok,false);
assert.equal(call({action:'sync_data',responses:[{response_id:'must-not-write'}],features:[{feature_id:'f1',response_revision:1,geojson:{type:'Point',coordinates:[91,24]}}]}).ok,false);
assert(!tabs.responses.rows.some(r=>r[0]==='must-not-write'));
activeUser='';assert.throws(()=>context.getMapDataPayload('responses'));activeUser='manager@example.com';
const payload=context.getMapDataPayload('responses');assert.equal(payload.total,4);assert.equal(payload.data[0].response_revision,2);
const original=tabs.responses;delete tabs.responses;
tabs.Responses=new Sheet([['response_id','project_name','surveyor','submitted_at','form_name','answers_json'],['legacy','Project A','Alice','2026-10-01','Salt','{"salinity":2,"gps":"23.8,90.4"}']], 'Responses');
assert.equal(call({action:'sync_data',responses:[{response_id:'legacy',response_revision:2,project_name:'Project A',surveyor:'Alice',answers:{salinity:3,gps:'23.8,90.4'}}],features:[]}).ok,true);
assert.equal(tabs.Responses.getLastRow(),2);assert.equal(recordAt(tabs.Responses).answers.salinity,3);
assert.equal(context.getMapDataPayload('Responses').featureCollection.features[0].geometry.coordinates[0],90.4);
delete tabs.Responses;tabs.responses=original;
tabs.responses.rows[0][0]='incompatible';assert.equal(call(batch).ok,false);
console.log('Manager backend contract checks passed: auth, project isolation, questionnaire, updates, chunking, expansion, validation, retries and photo deduplication.');


for(const [a,b] of [['assets/help/manager_apps_script.gs','server/manager/Code.gs'],['assets/help/Map.html','server/manager/Map.html'],['assets/help/Charts.html','server/manager/Charts.html']]) assert.equal(fs.readFileSync(a,'utf8'),fs.readFileSync(b,'utf8'));
