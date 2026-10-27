// UI-only translation. Never rewrite input values, GeoJSON, map popups or tables.
(function () {
  'use strict';
  const language = __MAPBANAI_LANGUAGE__;
  const captions = __MAPBANAI_UI_MESSAGES__;
  if (language !== 'bn') return;
  document.documentElement.lang = language;
  const scopes = 'header,#sidebar,#download-dialog,#table-panel,#message';
  const data = '#project-name,#vector-layer-list,#category-editor,#legend-items,#table-content,script,style,code,[data-user-content]';
  const dataSelectors = '#filter-form,#filter-surveyor,#filter-layer,#value-field';
  function translate(text) {
    const trimmed = text.trim();
    return Object.prototype.hasOwnProperty.call(captions, trimmed)
      ? text.replace(trimmed, captions[trimmed]) : text;
  }
  function isData(element) {
    if (!element || element.closest(data)) return true;
    const option = element.closest('option');
    return !!(option && option.closest(dataSelectors) && option.value && option.value !== '@status');
  }
  function localize(root) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      if (isData(node.parentElement)) continue;
      const next = translate(node.nodeValue);
      if (next !== node.nodeValue) node.nodeValue = next;
    }
    for (const element of root.querySelectorAll('[title],[placeholder],[aria-label]')) {
      if (isData(element)) continue;
      for (const name of ['title', 'placeholder', 'aria-label']) {
        const current = element.getAttribute(name);
        if (current === null) continue;
        const next = translate(current);
        if (next !== current) element.setAttribute(name, next);
      }
    }
  }
  function start() {
    for (const root of document.querySelectorAll(scopes)) {
      localize(root);
      let queued = false;
      new MutationObserver(() => {
        if (queued) return;
        queued = true;
        requestAnimationFrame(() => { queued = false; localize(root); });
      }).observe(root, {subtree: true, childList: true, characterData: true,
        attributes: true, attributeFilter: ['title', 'placeholder', 'aria-label']});
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start, {once: true});
  else start();
})();
