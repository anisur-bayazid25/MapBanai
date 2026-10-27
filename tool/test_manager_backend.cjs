// Contract checks for the exact Apps Script code bundled in Help, using fake Google services.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
class Sheet {
  constructor(rows=[],name='') { this.rows=rows; this.capacity=Math.max(2,rows.length); this.columns=26; this.name=name; this.images=[]; }
  getImages(){return this.images;}
  setColumnWidth(){}
  setRowHeight(){}
  insertImage(blob,c,r){
    const image={width:640,height:480,title:'',getWidth(){return this.width;},getHeight(){return this.height;},setWidth(v){this.width=v;},setHeight(v){this.height=v;},setAltTextTitle(v){this.title=v;},getAltTextTitle(){return this.title;},setAltTextDescription(){},setAnchorCell(){},remove:()=>{this.images=this.images.filter(i=>i!==image);}};
    this.images.push(image);return image;
  }
  getName(){return this.name;}
  getMaxColumns(){return this.columns;}
  insertColumnsAfter(start,n){this.columns+=n;}
  getLastRow() { return this.rows.length; }
  getLastColumn() { return Math.max(0,...this.rows.map(r=>r.length)); }
  getMaxRows() { return this.capacity; }
  insertRowsAfter(start,n) { this.capacity+=n; }
  getDataRange() { return {getValues:()=>this.rows}; }
  getRange(r,c,h,w) { return {
    setValue:v=>{this.rows[r-1]??=[];this.rows[r-1][c-1]=v;},
    setRichTextValue:v=>{this.rows[r-1]??=[];this.rows[r-1][c-1]=v;},
    getValues:()=>Array.from({length:h},(_,i)=>Array.from({length:w},(_,j)=>this.rows[r-1+i]?.[c-1+j]??'')),
    setValues: values=>{ assert(r+h-1<=this.capacity); values.forEach((row,i)=>{this.rows[r-1+i]??=[]; row.forEach((v,j)=>{this.rows[r-1+i][c-1+j]=String(v).replace(/^'(?=[=+@\-])/,'');});}); }
  }; }
}
const tabs = {survey:new Sheet([['type','name','label'],['text','name','Name']]), choices:new Sheet([['list_name','name','label']]),settings:new Sheet([['form_id','form_title'],['test','Test']])};
const book={getName:()=> 'Manager workbook',getSheetByName:n=>tabs[n],insertSheet:n=>(tabs[n]=new Sheet([],n)),getSpreadsheetTimeZone:()=> 'Asia/Dhaka'};
const properties=new Map();let activeUser='manager@example.com';
const files=new Map(); let writes=0; let locked=false;
const context=vm.createContext({
  console:{log:()=>{}},
  PropertiesService:{getScriptProperties:()=>({getProperty:k=>properties.get(k),setProperty:(k,v)=>properties.set(k,v)})},
  Session:{getActiveUser:()=>({getEmail:()=>activeUser}),getEffectiveUser:()=>({getEmail:()=> 'manager@example.com'})},
  ContentService:{MimeType:{JSON:'json'},createTextOutput:s=>({setMimeType:()=>JSON.parse(s)})},
  SpreadsheetApp:{newRichTextValue:()=>({setText(v){this.text=v;return this;},setLinkUrl(v){this.url=v;return this;},build(){return {text:this.text,url:this.url};}}),getUi:()=>({alert:()=>{}}),getActiveSpreadsheet:()=>book,openById:id=>{assert(['questions','data'].includes(id));return book;},flush:()=>{}},
  LockService:{getScriptLock:()=>({tryLock:()=>{locked=true;return true;},hasLock:()=>locked,releaseLock:()=>{locked=false;}})},
  DriveApp:{getFileById:id=>[...files.values()].find(f=>f.getId()===id),getFolderById:id=>({getName:()=> 'Photos',getFilesByName:n=>({hasNext:()=>files.has(n),next:()=>files.get(n)}),createFile:blob=>{writes++;const file={getId:()=> 'file-'+writes,getUrl:()=> 'private-url',getThumbnail:()=>({getBytes:()=>Buffer.from('preview')}),getBlob:()=>({getBytes:()=>Buffer.from('full')})};files.set(blob.name,file);return file;}})},
  Utilities:{base64Decode:s=>Buffer.from(s,'base64'),newBlob:(bytes,type,name)=>({bytes,type,name})}
});
vm.runInContext(fs.readFileSync('assets/help/manager_apps_script.gs','utf8'),context);
vm.runInContext("Object.assign(MAPBANAI,{projectId:'project-a',questionnaireSheetId:'questions',dataSheetId:'data',apiKey:'secret',photoFolderId:'folder'});setupMapBanai();",context);
const call=p=>context.doPost({postData:{contents:JSON.stringify({projectId:'project-a',apiKey:'secret',...p})}});
assert.equal(context.doGet().ok,true);
const beforeConnection = JSON.stringify(Object.fromEntries(Object.entries(tabs).map(([name, sheet]) => [name, sheet.rows])));
assert.equal(call({action:'test_connection'}).connectionVerified,true);
assert.equal(call({action:'test_connection',apiKey:'wrong'}).ok,false);
assert.equal(JSON.stringify(Object.fromEntries(Object.entries(tabs).map(([name, sheet]) => [name, sheet.rows]))),beforeConnection);
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

const photoCell = name => tabs.photos.rows[1][tabs.photos.rows[0].indexOf(name)];
assert.equal(photoCell('filename'), 'a.jpg');
assert.equal(photoCell('response_id'), 'r1');
assert.equal(photoCell('photo_link').url, 'https://drive.google.com/file/d/file-1/view');
assert.equal(tabs.photos.images.length, 1, 'retries must not duplicate previews');
assert.equal(tabs.photos.images[0].width, 133);
assert.equal(tabs.photos.images[0].height, 100);
// A previously synced JSON-only photo gets readable metadata, link and image.
tabs.photos.images = [];
context.refreshPhotoPreviews();
assert.equal(tabs.photos.images.length, 1);
context.refreshPhotoPreviews();
assert.equal(tabs.photos.images.length, 1);
assert.equal(photoCell('photo_link').text, 'Open photo in Drive');
const savedFile = [...files.values()][0];
tabs.photos.images = [];
savedFile.getThumbnail = () => null;
savedFile.getBlob = () => ({getBytes:()=>({length:3*1024*1024})});
assert.equal(call(photo).ok, true, 'preview failure must not fail uploaded photo');
assert.equal(tabs.photos.images.length, 0);
assert.match(photoCell('photo_preview'), /Preview unavailable/);
assert.equal(photoCell('photo_link').url, 'https://drive.google.com/file/d/file-1/view');
savedFile.getThumbnail = () => ({getBytes:()=>Buffer.from('preview')});
context.refreshPhotoPreviews();
assert.equal(tabs.photos.images.length, 1, 'refresh retries unavailable thumbnails');
activeUser = 'enumerator@example.com';
assert.throws(()=>context.refreshPhotoPreviews(), /manager account/);
activeUser = 'manager@example.com';

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
assert.equal(call({action:'sync_data',responses:[],features:[{feature_id:'study-1',geometry_type:'point',geojson:{type:'Point',coordinates:[90.4,23.8]},study_site:{status:'verified',revision:3},attributes:{layer:'Water points'}}]}).ok,true);
const studyPayload=context.getMapDataPayload('features');
const studyFeature=studyPayload.featureCollection.features.find(f=>f.properties.id==='study-1');
assert.equal(studyFeature.properties.source,'study_area');
assert.equal(studyFeature.properties.site_status,'verified');
assert.equal(studyFeature.properties.answers.layer,'Water points');
assert.equal(JSON.stringify(studyPayload),JSON.stringify(JSON.parse(JSON.stringify(studyPayload))));
// Deletions are revisioned audit rows, excluded from every active geometry.
assert.equal(call({action:'test_connection'}).deletionSupport,true);
const deletedSite={feature_id:'study-deleted',site_id:'site-deleted',feature_uuid:'uuid-deleted',response_revision:1,geometry_type:'point',geojson:{type:'Point',coordinates:[90.4,23.8]}};
assert.equal(call({action:'sync_data',features:[deletedSite],responses:[{response_id:'old-visit',site_id:'site-deleted',answers:{gps:'23.8,90.4'}}]}).ok,true);
const tombstone={...deletedSite,response_revision:2,deleted:true,status:'Deleted',operation:'delete',deleted_at:'2026-10-28T00:00:00Z',deleted_by:'Fieldworker',deletion_id:'op-delete'};
const reply=call({action:'sync_data',features:[tombstone],responses:[]});
assert.equal(reply.deletionSupport,true);
assert.equal(reply.ok,true);
const historyAfterDelete=tabs.revisions.getLastRow();
assert.equal(call({action:'sync_data',features:[tombstone],responses:[]}).ok,true);
assert.equal(tabs.revisions.getLastRow(),historyAfterDelete);
assert.equal(call({action:'sync_data',features:[deletedSite],responses:[]}).ok,false);
const allData=context.getMapDataPayload('All collections');
assert(!allData.featureCollection.features.some(f=>['study-deleted','old-visit'].includes(f.properties.id)));
assert(allData.data.some(row=>row.feature_id==='study-deleted' && row.deleted===true));
assert(!context.getMapDataPayload('responses').featureCollection.features.some(f=>f.properties.id==='old-visit'));
const latestDeletedRow=tabs.features.rows.find(row=>row[tabs.features.rows[0].indexOf('record_id')]==='study-deleted');
assert.equal(latestDeletedRow[tabs.features.rows[0].indexOf('status')],'Deleted');
assert.equal(latestDeletedRow[tabs.features.rows[0].indexOf('deleted_by')],'Fieldworker');

tabs.responses.rows[0][0]='incompatible';assert.equal(call(batch).ok,false);
console.log('Manager backend contract checks passed: auth, project isolation, questionnaire, updates, chunking, expansion, validation, retries and photo deduplication.');


for(const [a,b] of [['assets/help/manager_apps_script.gs','server/manager/Code.gs'],['assets/help/Map.html','server/manager/Map.html'],['assets/help/Charts.html','server/manager/Charts.html']]) assert.equal(fs.readFileSync(a,'utf8'),fs.readFileSync(b,'utf8'));
