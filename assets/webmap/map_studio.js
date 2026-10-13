function openMapStudio(){ $('download-dialog').showModal(); }
$('open-studio').onclick=openMapStudio;
$('studio-close').onclick=()=>$('download-dialog').close();
// Map studio: current-view image composition without a remote screenshot service.
const studioThemes={
 field:{paper:'#f7faf7',ink:'#203d40',accent:'#267c76',line:'#dce8e1',filter:'none',point:'#c36f59',lineColour:'#467ca1',polygon:'#498a70'},
 sage:{paper:'#f3f1e6',ink:'#324a40',accent:'#527a66',line:'#d4dbcd',filter:'saturate(.35) sepia(.18)',point:'#b17457',lineColour:'#648c82',polygon:'#67856b'},
 ink:{paper:'#f6f3eb',ink:'#222b2e',accent:'#39464b',line:'#d8d5cd',filter:'grayscale(1) contrast(1.12)',point:'#a65442',lineColour:'#39464b',polygon:'#717d73'},
 night:{paper:'#172b34',ink:'#e5eee7',accent:'#7db8ad',line:'#36505b',filter:'grayscale(1) invert(.88) hue-rotate(160deg)',point:'#e3aa80',lineColour:'#8cc4cb',polygon:'#78a795'},
 clay:{paper:'#f6eadc',ink:'#603c35',accent:'#ab6550',line:'#e4ccbd',filter:'sepia(.5) saturate(.55)',point:'#b34c38',lineColour:'#758d94',polygon:'#aa896a'}
};
const extraThemes={ocean:['#eaf3f5','#24475c','#287c9b','#e18b65','#327ba2','#65b3a7','saturate(.45) hue-rotate(10deg)'],forest:['#e7eee3','#234532','#4f7950','#db9e63','#57888b','#37734e','sepia(.25) saturate(.55)'],rose:['#faedf0','#654451','#b66b86','#bf627e','#7396ab','#ba8c9f','sepia(.3) saturate(.5)'],sand:['#f1e5c8','#554d38','#9c8552','#bd7750','#648d95','#9d9a68','sepia(.65) saturate(.5)'],lavender:['#efeaf6','#484164','#8a78a9','#bf839a','#7f9bbc','#9c8fb2','saturate(.35)'],blueprint:['#163b61','#e6f2fa','#8fbdd9','#f2c975','#a6d5f0','#80b4d0','grayscale(1) invert(.9) sepia(.4) hue-rotate(165deg)'],mono:['#ffffff','#191919','#4c4c4c','#191919','#555555','#999999','grayscale(1)']};
Object.entries(extraThemes).forEach(([key,v])=>studioThemes[key]={paper:v[0],ink:v[1],accent:v[2],line:v[2],point:v[3],lineColour:v[4],polygon:v[5],filter:v[6]});
let studioTheme={...studioThemes.field};
function updateDimensions(){
 const [a,b]=$('image-ratio').value.split(':').map(Number),n=Number($('image-resolution').value);
 if(a&&b){let w=n,h=Math.round(n*b/a);if($('image-orientation').value==='portrait')[w,h]=[h,w];$('image-width').value=w;$('image-height').value=h;}
 const w=Number($('image-width').value),h=Number($('image-height').value);
 $('image-dimensions').textContent=w+' × '+h+' px · '+(w*h/1000000).toFixed(1)+' megapixels (maximum 8.4 MP)';
}
['image-ratio','image-resolution','image-orientation'].forEach(id=>$(id).onchange=updateDimensions);
['image-width','image-height'].forEach(id=>$(id).oninput=()=>{$('image-ratio').value='custom';updateDimensions()});updateDimensions();
function paintTheme(){
 const root=document.documentElement.style;
 [['--paper','paper'],['--ink','ink'],['--teal','accent'],['--line','line'],['--map-paper','paper'],['--tile-filter','filter']].forEach(([key,value])=>root.setProperty(key,studioTheme[value]));root.setProperty('--muted',studioTheme.ink);
 const legend=$('legend');[['.dot','point'],['.line','lineColour'],['.poly','polygon']].forEach(([selector,key])=>legend.querySelector(selector).style.background=studioTheme[key]);renderFiltered();updateCaption();
}
const customColours={'paper-colour':'paper','ink-colour':'ink','point-colour':'point','line-colour':'lineColour','polygon-colour':'polygon'};
Object.entries(customColours).forEach(([id,key])=>$(id).oninput=()=>{studioTheme[key]=$(id).value;paintTheme()});
$('tile-treatment').onchange=()=>{studioTheme.filter=$('tile-treatment').value==='theme'?studioThemes[$('map-theme').value].filter:$('tile-treatment').value;paintTheme()};

function updateCaption(){
 $('poster-heading').textContent=$('poster-title').value.trim()||$('project-name').textContent;
 $('poster-description').textContent=$('poster-subtitle').value.trim();
 const center=map.getCenter();$('poster-coordinates').textContent=center.lat.toFixed(4)+'°, '+center.lng.toFixed(4)+'°';
 $('poster-heading').style.fontFamily=$('poster-typeface').value;$('poster-caption').style.textAlign=$('poster-alignment').value;
 document.body.classList.toggle('map-only',$('poster-layout').value==='map');
}
function applyStudioTheme(){studioTheme={...studioThemes[$('map-theme').value]};Object.entries(customColours).forEach(([id,key])=>$(id).value=studioTheme[key]);$('tile-treatment').value='theme';paintTheme();}
$('map-theme').onchange=applyStudioTheme;
['poster-title','poster-subtitle'].forEach(id=>$(id).oninput=updateCaption);
['poster-layout','poster-typeface','poster-alignment'].forEach(id=>$(id).onchange=updateCaption);$('site-labels').onchange=renderFiltered;
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
 if(type==='Polygon'){const alpha=ctx.globalAlpha;ctx.globalAlpha=alpha*.28;ctx.fillStyle=color;ctx.fill('evenodd');ctx.globalAlpha=alpha;}
}
let imageExportBusy=false;
async function exportMapImage(format,destination='share'){
 if(imageExportBusy){message('An image is already being prepared.');return}
 imageExportBusy=true;
 const buttons=[$('download-png'),$('download-jpeg'),$('share-png'),$('share-jpeg')],sidebar=$('download-dialog'),container=map.getContainer();
 const oldStyle=container.getAttribute('style'),oldCenter=map.getCenter(),oldZoom=map.getZoom(),oldBounds=map.getBounds();
 buttons.forEach(button=>button.disabled=true);sidebar.inert=true;
 const oldPointer=container.style.pointerEvents;container.style.pointerEvents='none';
 $('image-status').textContent='Preparing image…';
 try{
  map.stop();
  const outputWidth=Number($('image-width').value),outputHeight=Number($('image-height').value);
  if(!Number.isInteger(outputWidth)||!Number.isInteger(outputHeight)||outputWidth<320||outputHeight<320||outputWidth>4096||outputHeight>4096||outputWidth*outputHeight>8400000)throw Error('Use whole-number dimensions from 320 to 4096 pixels, up to 8.4 megapixels.');
  const scale=Math.max(1,Math.min(outputWidth/1200,outputHeight/900,3.2));
  const poster=$('poster-layout').value==='poster',margin=poster?24:0,footer=poster?154:52;
  const viewportWidth=outputWidth-margin*2*scale,viewportHeight=outputHeight-(margin*2+footer)*scale;
  container.style.cssText='position:fixed;inset:auto;left:-10000px;top:0;width:'+viewportWidth+'px;height:'+viewportHeight+'px;pointer-events:none';
  map.invalidateSize({pan:false,animate:false});map.fitBounds(oldBounds,{animate:false,padding:[0,0]});await pause(150);

  const deadline=Date.now()+10000;
  while((rendering||vectorRendering)&&Date.now()<deadline)await pause(40);
  if(rendering||vectorRendering)throw Error('Map is still rendering. Try again when it finishes.');
  const tiles=Array.from(container.querySelectorAll('.leaflet-tile-pane img.leaflet-tile'));
  if($('image-basemap').value==='on'&&activeBasemap!=='No background')while(tiles.some(tile=>!tile.complete)&&Date.now()<deadline)await pause(100);
  const physicalSize=map.getSize(),size={x:physicalSize.x/scale,y:physicalSize.y/scale};
  const canvas=document.createElement('canvas');canvas.width=outputWidth;canvas.height=outputHeight;
  const ctx=canvas.getContext('2d');ctx.scale(scale,scale);ctx.fillStyle=studioTheme.paper;ctx.fillRect(0,0,canvas.width/scale,canvas.height/scale);
  const mapRect=container.getBoundingClientRect();let tileCount=0,tileMissing=false;
  ctx.save();ctx.beginPath();ctx.rect(margin,margin,size.x,size.y);ctx.clip();
  if($('image-basemap').value==='on'&&activeBasemap!=='No background'){
   ctx.filter=studioTheme.filter;
   for(const tile of tiles){
    const r=tile.getBoundingClientRect(),x=(r.left-mapRect.left)/scale,y=(r.top-mapRect.top)/scale;
    if(x>=size.x||y>=size.y||x+r.width/scale<=0||y+r.height/scale<=0)continue;
    if(!tile.complete||!tile.naturalWidth){tileMissing=true;continue}
    // Probe separately; one provider lacking CORS must not taint the export.
    try{const probe=document.createElement('canvas');probe.width=1;probe.height=1;const pc=probe.getContext('2d');pc.drawImage(tile,0,0,1,1);pc.getImageData(0,0,1,1);ctx.drawImage(tile,x+margin,y+margin,r.width/scale,r.height/scale);tileCount++;}
    catch(_){tileMissing=true;}
   }
   ctx.filter='none';if(!tileCount)tileMissing=true;
  }
  const project=coordinate=>{const p=map.latLngToContainerPoint([coordinate[1],coordinate[0]]);return {x:p.x/scale+margin,y:p.y/scale+margin}};
  for(const layer of vectorLayers.filter(l=>l.visible!==false)){
   for(let i=0;i<layer.features.length;i++){ctx.save();ctx.globalAlpha=layer.opacity;drawExportGeometry(ctx,layer.features[i].geometry,layer.color,project);ctx.restore();if(i%200===199)await pause(0)}
  }
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
  const metres=map.distance(map.containerPointToLatLng([20*scale,(size.y-24)*scale]),map.containerPointToLatLng([120*scale,(size.y-24)*scale]));
  const order=Math.pow(10,Math.floor(Math.log10(metres)));const distance=[5,2,1].map(n=>n*order).find(n=>n<=metres)||order/2;const length=100*distance/metres;
  ctx.strokeStyle=studioTheme.ink;ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(margin+20,margin+size.y-24);ctx.lineTo(margin+20+length,margin+size.y-24);ctx.stroke();ctx.textAlign='left';ctx.fillText(distance>=1000?(distance/1000)+' km':distance+' m',margin+20,margin+size.y-30);
  const y=margin+size.y;
  if(poster){
   const align=$('poster-alignment').value,captionX=align==='left'?margin+12:align==='right'?margin+size.x-12:(size.x+margin*2)/2;
   exportText(ctx,$('poster-heading').textContent,captionX,y+40,size.x-30,'600 27px '+$('poster-typeface').value,align);
   exportText(ctx,$('poster-description').textContent,captionX,y+66,size.x-30,'13px sans-serif',align);
   exportText(ctx,$('poster-coordinates').textContent,captionX,y+88,size.x-30,'11px sans-serif',align);
   const metric=$('value-field').value,legend=metric?$('value-legend').textContent:'Points · Lines · Polygons';
   exportText(ctx,legend,captionX,y+108,size.x-30,'11px sans-serif',align);
  }
  const attribution=tileCount?container.querySelector('.leaflet-control-attribution').innerText:'No basemap · MapBanai field data';
  exportText(ctx,attribution,margin+12,y+footer-22,size.x-24,'10px sans-serif');
  exportText(ctx,'MapBanai · '+filtered.length+' filtered features · '+vectorLayers.filter(l=>l.visible!==false).length+' reference layers'+(tileMissing?' · Basemap incomplete':''),margin+12,y+footer-8,size.x-24,'9px sans-serif');
  const mime=format==='png'?'image/png':'image/jpeg',data=canvas.toDataURL(mime,.94),name='mapbanai-map.'+(format==='png'?'png':'jpg');
  if(window.MapBanaiExport)window.MapBanaiExport.postMessage(JSON.stringify({content:data,name,type:mime,destination}));
  else{const a=document.createElement('a');a.href=data;a.download=name;a.click();}
  $('image-status').textContent=tileMissing?'Image saved; some basemap tiles were unavailable. Use Data only for an offline export.':'Image ready: '+canvas.width+' × '+canvas.height+' px';
 }catch(error){$('image-status').textContent='Cannot export: '+error.message;message('Image export failed. '+error.message);}
 finally{imageExportBusy=false;buttons.forEach(button=>button.disabled=false);sidebar.inert=false;if(oldStyle===null)container.removeAttribute('style');else container.setAttribute('style',oldStyle);container.style.pointerEvents=oldPointer;map.invalidateSize({pan:false,animate:false});map.setView(oldCenter,oldZoom,{animate:false});}
}
$('download-png').onclick=()=>exportMapImage('png','save');$('download-jpeg').onclick=()=>exportMapImage('jpeg','save');$('share-png').onclick=()=>exportMapImage('png','share');$('share-jpeg').onclick=()=>exportMapImage('jpeg','share');
