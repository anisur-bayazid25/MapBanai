const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.join(__dirname, '../assets/webmap/localization.js'), 'utf8');
const captions = JSON.parse(fs.readFileSync(path.join(__dirname, '../assets/webmap/ui_bn.json'), 'utf8'));
function element(kind, attrs = {}) {
  return {kind, attrs, value: 'Download Map',
    closest(selector) {
      if (selector === 'option') return kind === 'data-option' ? this : null;
      if (selector.includes('#filter-form')) return kind === 'data-option' ? this : null;
      if (selector.includes('#project-name')) return kind === 'data' ? this : null;
      return null;
    },
    getAttribute(name) { return this.attrs[name] ?? null; },
    setAttribute(name, value) { this.attrs[name] = value; }
  };
}
const control = {nodeValue: 'Download Map', parentElement: element('control')};
const record = {nodeValue: 'Download Map', parentElement: element('data')};
const option = {nodeValue: 'Point', parentElement: element('data-option')};
const field = element('control', {placeholder: 'Name, ID, salinity…'});
const root = {texts: [control, record, option], querySelectorAll: () => [field]};
const document = {
  readyState: 'complete', documentElement: {lang: 'en'},
  querySelectorAll: () => [root],
  createTreeWalker(root) { let i = 0; return {nextNode: () => root.texts[i++]}; }
};
let observed = false;
const script = (language) => source
  .replace('__MAPBANAI_LANGUAGE__', JSON.stringify(language))
  .replace('__MAPBANAI_UI_MESSAGES__', JSON.stringify(captions));
vm.runInNewContext(script('bn'), {document, NodeFilter: {SHOW_TEXT: 4},
  MutationObserver: class {observe() { observed = true; }}, requestAnimationFrame: fn => fn()});
assert.equal(document.documentElement.lang, 'bn');
assert.equal(control.nodeValue, 'মানচিত্র ডাউনলোড');
assert.equal(field.attrs.placeholder, 'নাম, আইডি, লবণাক্ততা…');
assert.equal(field.value, 'Download Map', 'user-entered values must remain intact');
assert.equal(record.nodeValue, 'Download Map', 'project names and record content must remain intact');
assert.equal(option.nodeValue, 'Point', 'data column/form options keep source names and values');
assert.equal(observed, true, 'dynamic UI controls must also be localized');
const english = {documentElement: {lang: 'en'}};
vm.runInNewContext(script('en'), {document: english});
assert.equal(english.documentElement.lang, 'en');
console.log('WebMap localization: controls, dynamic observer and data preservation passed.');

const atlas = fs.readFileSync('assets/webmap/atlas.html', 'utf8');
const nativeControls = atlas.match(/<script id="native-viewer-controls">([\s\S]*?)<\/script>/)[1];
for (const native of [true, false]) {
  const download = {style: {}};
  vm.runInNewContext(nativeControls, {window: native ? {MapBanaiExport: {}} : {},
    document: {getElementById: id => {assert.equal(id, 'open-studio'); return download;}}});
  assert.equal(download.style.display, native ? 'none' : undefined);
}
console.log('WebMap native viewer keeps only its bottom download control; standalone maps retain their header action.');
