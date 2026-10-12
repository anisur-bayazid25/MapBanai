// Map studio: current-view image composition without a remote screenshot service.
const studioThemes={
 field:{paper:'#f7faf7',ink:'#203d40',accent:'#267c76',line:'#dce8e1',filter:'none',point:'#c36f59',lineColour:'#467ca1',polygon:'#498a70'},
 sage:{paper:'#f3f1e6',ink:'#324a40',accent:'#527a66',line:'#d4dbcd',filter:'saturate(.35) sepia(.18)',point:'#b17457',lineColour:'#648c82',polygon:'#67856b'},
 ink:{paper:'#f6f3eb',ink:'#222b2e',accent:'#39464b',line:'#d8d5cd',filter:'grayscale(1) contrast(1.12)',point:'#a65442',lineColour:'#39464b',polygon:'#717d73'},
 night:{paper:'#172b34',ink:'#e5eee7',accent:'#7db8ad',line:'#36505b',filter:'grayscale(1) invert(.88) hue-rotate(160deg)',point:'#e3aa80',lineColour:'#8cc4cb',polygon:'#78a795'},
 clay:{paper:'#f6eadc',ink:'#603c35',accent:'#ab6550',line:'#e4ccbd',filter:'sepia(.5) saturate(.55)',point:'#b34c38',lineColour:'#758d94',polygon:'#aa896a'}
};
let studioTheme=studioThemes.field;
function updateCaption(){
 $('poster-heading').textContent=$('poster-title').value.trim()||$('project-name').textContent;
 $('poster-description').textContent=$('poster-subtitle').value.trim();
 const center=map.getCenter();$('poster-coordinates').textContent=center.lat.toFixed(4)+'°, '+center.lng.toFixed(4)+'°';
 document.body.classList.toggle('map-only',$('poster-layout').value==='map');
}
function applyStudioTheme(){
 studioTheme=studioThemes[$('map-theme').value]||studioThemes.field;
 const root=document.documentElement.style;
 [['--paper','paper'],['--ink','ink'],['--teal','accent'],['--line','line'],['--map-paper','paper'],['--tile-filter','filter']].forEach(([key,value])=>root.setProperty(key,studioTheme[value]));
 root.setProperty('--muted',studioTheme.ink);
 const legend=$('legend');[['.dot','point'],['.line','lineColour'],['.poly','polygon']].forEach(([selector,key])=>legend.querySelector(selector).style.background=studioTheme[key]);renderFiltered();updateCaption();
}
$('map-theme').onchange=applyStudioTheme;
['poster-title','poster-subtitle'].forEach(id=>$(id).oninput=updateCaption);
$('poster-layout').onchange=updateCaption;$('site-labels').onchange=renderFiltered;
map.on('moveend',updateCaption);updateCaption();
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
function exportText(ctx,text,x,y,maxWidth,font,align='left'){
 ctx.font=font;ctx.textAlign=align;const words=Array.from(String(text||''));
 while(words.length&&ctx.measureText(words.join('')).width>maxWidth)words.pop();
 ctx.fillText(words.join('')+(words.length<String(text||'').length?'…':''),x,y);
}
function drawExportGeometry(ctx,geometry,color,project){
 const c=geometry.coordinates,type=geometry.type;
 if(type==='GeometryCollection'){(geometry.geometries||[]).forEach(g=>drawExportGeometry(ctx,g,color,project));return}
 if(!Array.isArray(c))return;
 if(type.startsWith('Multi')){c.forEach(part=>drawExportGeometry(ctx,{type:type.slice(5),coordinates:part},color,project));return}
 if(type==='Point'){
  const p=project(c);ctx.beginPath();ctx.arc(p.x,p.y,6,0,Math.PI*2);ctx.fillStyle=color;ctx.fill();ctx.strokeStyle=studioTheme.paper;ctx.lineWidth=1.5;ctx.stroke();return;
 }
 const parts=type==='Polygon'?c:[c];ctx.beginPath();
 parts.forEach(part=>{part.forEach((coordinate,i)=>{const p=project(coordinate);i?ctx.lineTo(p.x,p.y):ctx.moveTo(p.x,p.y)});if(type==='Polygon')ctx.closePath()});
 ctx.strokeStyle=color;ctx.lineWidth=2.5;ctx.stroke();
 if(type==='Polygon'){ctx.globalAlpha=.28;ctx.fillStyle=color;ctx.fill('evenodd');ctx.globalAlpha=1;}
}
async function exportMapImage(format){
 const buttons=[$('download-png'),$('download-jpeg')],sidebar=$('sidebar'),container=map.getContainer();
 buttons.forEach(button=>button.disabled=true);sidebar.inert=true;
 const oldPointer=container.style.pointerEvents;container.style.pointerEvents='none';
 $('image-status').textContent='Preparing image…';
 try{
  map.stop();await pause(80);
  const deadline=Date.now()+5000;
  while(rendering&&Date.now()<deadline)await pause(40);
  if(rendering)throw Error('Map is still rendering. Try again when it finishes.');
  const tiles=Array.from(container.querySelectorAll('.leaflet-tile-pane img.leaflet-tile'));
  if($('image-basemap').value==='on')while(tiles.some(tile=>!tile.complete)&&Date.now()<deadline)await pause(100);
  const size=map.getSize(),scale=Math.min(Number($('image-scale').value),3072/Math.max(size.x+48,size.y+202),Math.sqrt(8000000/((size.x+48)*(size.y+202))));
  const poster=$('poster-layout').value==='poster',margin=poster?24:0,footer=poster?154:52;
  const canvas=document.createElement('canvas');canvas.width=Math.round((size.x+margin*2)*scale);canvas.height=Math.round((size.y+margin*2+footer)*scale);
  const ctx=canvas.getContext('2d');ctx.scale(scale,scale);ctx.fillStyle=studioTheme.paper;ctx.fillRect(0,0,canvas.width/scale,canvas.height/scale);
  const mapRect=container.getBoundingClientRect();let tileCount=0,tileMissing=false;
  ctx.save();ctx.beginPath();ctx.rect(margin,margin,size.x,size.y);ctx.clip();
  if($('image-basemap').value==='on'){
   ctx.filter=studioTheme.filter;
   for(const tile of tiles){
    const r=tile.getBoundingClientRect(),x=r.left-mapRect.left,y=r.top-mapRect.top;
    if(x>=size.x||y>=size.y||x+r.width<=0||y+r.height<=0)continue;
    if(!tile.complete||!tile.naturalWidth){tileMissing=true;continue}
    // Probe separately; one provider lacking CORS must not taint the export.
    try{const probe=document.createElement('canvas');probe.width=1;probe.height=1;const pc=probe.getContext('2d');pc.drawImage(tile,0,0,1,1);pc.getImageData(0,0,1,1);ctx.drawImage(tile,x+margin,y+margin,r.width,r.height);tileCount++;}
    catch(_){tileMissing=true;}
   }
   ctx.filter='none';if(!tileCount)tileMissing=true;
  }
  const project=coordinate=>{const p=map.latLngToContainerPoint([coordinate[1],coordinate[0]]);return {x:p.x+margin,y:p.y+margin}};
  for(let i=0;i<filtered.length;i++){
   const feature=filtered[i];drawExportGeometry(ctx,feature.geometry,colour(feature),project);
   if($('site-labels').value==='on'){
    const layer=L.geoJSON(feature),center=layer.getBounds().getCenter(),p=project([center.lng,center.lat]);
    ctx.fillStyle=studioTheme.ink;exportText(ctx,props(feature).name||props(feature).id,p.x,p.y-10,150,'11px sans-serif','center');
   }
   if(i%200===199)await pause(0);
  }
  ctx.restore();ctx.fillStyle=studioTheme.ink;
  // North arrow and scale remain tied to the current unrotated Leaflet view.
  ctx.beginPath();ctx.moveTo(margin+size.x-26,margin+18);ctx.lineTo(margin+size.x-33,margin+36);ctx.lineTo(margin+size.x-19,margin+36);ctx.closePath();ctx.fill();ctx.font='10px sans-serif';ctx.textAlign='center';ctx.fillText('N',margin+size.x-26,margin+49);
  const metres=map.distance(map.containerPointToLatLng([20,size.y-24]),map.containerPointToLatLng([120,size.y-24]));
  const order=Math.pow(10,Math.floor(Math.log10(metres)));const distance=[5,2,1].map(n=>n*order).find(n=>n<=metres)||order/2;const length=100*distance/metres;
  ctx.strokeStyle=studioTheme.ink;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(margin+20,margin+size.y-24);ctx.lineTo(margin+20+length,margin+size.y-24);ctx.stroke();ctx.textAlign='left';ctx.fillText(distance>=1000?(distance/1000)+' km':distance+' m',margin+20,margin+size.y-30);
  const y=margin+size.y;
  if(poster){
   exportText(ctx,$('poster-heading').textContent,(size.x+margin*2)/2,y+40,size.x-30,'600 27px Georgia,serif','center');
   exportText(ctx,$('poster-description').textContent,(size.x+margin*2)/2,y+66,size.x-30,'13px sans-serif','center');
   exportText(ctx,$('poster-coordinates').textContent,(size.x+margin*2)/2,y+88,size.x-30,'11px sans-serif','center');
   const metric=$('value-field').value,legend=metric?$('value-legend').textContent:'Points · Lines · Polygons';
   exportText(ctx,legend,(size.x+margin*2)/2,y+108,size.x-30,'11px sans-serif','center');
  }
  const attribution=tileCount?container.querySelector('.leaflet-control-attribution').innerText:'No basemap · MapBanai field data';
  exportText(ctx,attribution,margin+12,y+footer-22,size.x-24,'10px sans-serif');
  exportText(ctx,'MapBanai · '+filtered.length+' filtered features · Current view'+(tileMissing?' · Basemap incomplete':''),margin+12,y+footer-8,size.x-24,'9px sans-serif');
  const mime=format==='png'?'image/png':'image/jpeg',data=canvas.toDataURL(mime,.94),name='mapbanai-map.'+(format==='png'?'png':'jpg');
  if(window.MapBanaiExport)window.MapBanaiExport.postMessage(JSON.stringify({content:data,name,type:mime}));
  else{const a=document.createElement('a');a.href=data;a.download=name;a.click();}
  $('image-status').textContent=tileMissing?'Image saved; some basemap tiles were unavailable. Use Data only for an offline export.':'Image ready: '+canvas.width+' × '+canvas.height+' px';
 }catch(error){$('image-status').textContent='Cannot export: '+error.message;message('Image export failed. '+error.message);}
 finally{buttons.forEach(button=>button.disabled=false);sidebar.inert=false;container.style.pointerEvents=oldPointer;}
}
$('download-png').onclick=()=>exportMapImage('png');$('download-jpeg').onclick=()=>exportMapImage('jpeg');
