MapBanai 2.6.0 improves collection and verification of previous field data.

- Guided visits link baseline sites, reviewed attributes, forms, mandatory geotagged photos and map revisions. Drafts resume safely; failed map updates can be retried.
- GPS accuracy is recorded/displayed, but does not block photos. Valid EXIF coordinates remain mandatory.
- Study Area supports verification/update/new/review/not-found statuses, geometry editing, original baselines, revision history, changed-only exports and reviewed GeoJSON team merges.
- Offline map packages support provider-approved custom style URLs, bounded downloads, storage limits and a shared basemap selector.
- Field quality checks required answers, evidence, recorded GPS quality and possible duplicates.
- XLSForm parsing, editable dates, conditional validation, backup restoration, sync acknowledgements, project selection and track timing are fixed.

Upgrade: install over the existing app and re-import XLSForms under a new name/version to apply parser fixes. Keep your existing collected records. Repeats and other unsupported XLSForm constructs are rejected explicitly.

Use GeoJSON to exchange full revision history; CSV/XLSX are tabular exports. Offline downloads require a provider that permits them, and downloaded caches are not included in backups. Camera location is obtained after the external camera returns; remain at the capture location until saving completes.

Automated tests and signed Android build verification cover this release. No Android device/emulator was connected: validate camera/GNSS, restore and offline downloads on your field phone before deployment. See FIELD_WORKFLOW.md in the repository for instructions.
