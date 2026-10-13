# MapBanai v2.6.6

- Poster map fills over 80% of the image, with compact titles/legends and a fit-data extent option. Shared by Android WebMap and Google Sheets atlas.
- WebMap categorical colours, per-value visibility and editable symbols support text fields such as imported layer categories. Added browser GeoJSON/shapefile ZIP overlays and map/chart fullscreen controls.
- Manager atlas startup repaired; clear loading and initialization errors replace blank dropdowns. Study status data is available in the manager map.
- Sync sends at most 20 records per batch, retries busy-server responses and preserves acknowledged progress. Server timeouts no longer appear as internet loss.
- Photos sheet shows readable metadata, private embedded thumbnails and clickable Drive links. Spreadsheet menu can refresh existing photo previews.
- Field quality now reviews only recorded GPS/photo accuracy above the selected limit. Accept accuracy persists per project on the device, with Undo and View record.
- Existing in-app Help explains the updated workflows and includes the complete matching manager scripts.

Install app-release.apk over the existing MapBanai installation to preserve local data. For Google Sheets, replace Code.gs, Map.html and Charts.html with the matching files, keeping the project ID/configuration. Save and deploy a new version for the sync API; reload the spreadsheet and reopen its workspace. Run MapBanai → Refresh photo previews for older uploaded photos.

Browser overlay uploads are temporary and do not change sheet records. Browser GeoPackage import is not included; use the Android importer or convert to GeoJSON. Accuracy acceptance is local and is not uploaded to the manager workbook. Basemap and manager library loading require internet.

Validation: 402 Flutter tests pass; backend contracts and browser map/chart/export checks pass. APK signature and version verified. Full analysis has no errors, with existing test warnings and style notices.
