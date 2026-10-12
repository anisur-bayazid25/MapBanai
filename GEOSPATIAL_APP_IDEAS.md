# MapBanai design references and priorities

There is no single best field GIS app for every team. The useful comparison is how well it serves enumerators, supervisors and GIS staff. Keep MapBanai's core flow: **Project → Site or new feature → Questions → Evidence → Save → Sync**. A supervisor prepares layers and forms once; enumerators get a ready-to-use project.

| Reference | Useful capability | MapBanai direction |
| --- | --- | --- |
| [SW Maps](https://play.google.com/store/apps/details?id=np.com.softwel.swmaps) | Reusable project/layer templates, offline overlays, attribute labels, external RTK GNSS, exports with photos | v2.6.2 adds reusable project/layer templates. Keep layer/schema setup with supervisors. Future: media-inclusive field packages and optional external GNSS. |
| [Terraink](https://github.com/yousifamanuel/terraink) | Curated palettes, poster layouts, typography, image export | Implemented locally: five palette presets, editable title/subtitle, poster/map-only layouts, current-view PNG/JPEG, labels, scale, north arrow and credits. |
| [QField](https://docs.qfield.org/how-to/data-collection/digitize/) | Geometry and typed attributes, snapping, controlled digitizing | Shared forms are already in MapBanai. Next: optional snapping and geometry overlap checks for GIS users. |
| [ArcGIS Field Maps](https://doc.arcgis.com/en/field-maps/get-started/get-started.htm) | Collection forms, offline maps, related inspection records and tasks | Next: assigned site lists, coverage summaries and a simple daily work queue. |
| [Mergin Maps](https://merginmaps.com/docs/layer/one-to-n-relations/) | Multiple observations linked to a stable feature UUID | v2.6.2 adds a site timeline comparing repeated salinity visits, preserving earlier answers and exporting observations linked by feature UUID. |
| [ODK Collect](https://docs.getodk.org/collect-intro/) | Offline questionnaires and varied question types | Preserve a simple enumerator route and versioned question snapshots. Google Sheets/App Script questionnaire updates are implemented locally with the same XLSForm parser. |

## Map studio limits

The studio exports the current geographic view and filtered features; it is not a screenshot of the controls. It works in a browser and sends images to Android's share/save destinations. Maximum export size is 3072 pixels per side and 8 megapixels, preventing large allocations on field phones. Raster tiles retain their native detail when enlarged.

The presets tone the existing raster background and style collected features. Terraink also controls individual roads, parks, water and buildings using vector data. Equivalent per-layer cartographic control would require a vector basemap/style pipeline in the web atlas. That is a separate next step; the present raster presets should not be described as a full Terraink engine.

Data-only images work offline. Background imagery requires provider connectivity and cross-origin export permission. Missing or blocked tiles are flagged and credits are retained. Exporting the current loaded viewport does not bulk-download an offline basemap. No Terraink source code was copied.

## Suggested next release priorities

1. **Timeline enhancements:** photo previews and chart overlays for the repeated observations now available in v2.6.2.
2. **Enumerator home/work queue:** select assigned site, complete questions, review save status; keep advanced GIS controls optional.
3. **Offline preparation checklist:** forms installed, study map present, permissions ready, connection tested and backup completed.
4. **Vector atlas styles:** separate roads/water/parks/buildings, custom palettes and repeatable print layouts.
5. **GNSS tools for specialists:** optional external receivers and positional averaging, while photo accuracy remains advisory.

These priorities are recommendations, not features claimed as completed.
