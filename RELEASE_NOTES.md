MapBanai v2.6.1 — Easy Geospatial Data Collection

- Survey, GIS, Study Area, WebMap and sync share project ownership. GPS stays independent.
- Each project supports multiple named study layers and a shared selected survey form. GIS and Study Area use the same typed form questions as Survey Mode.
- Study Area supports explicit assignment of previous unassigned sites, layer-scoped visits/imports/exports, typed answers and project sync outbox records.
- Sync URLs and API keys survive partial updates, successful sync and replacement of the same project definition. Project sharing retains layer names while excluding credentials.
- GPS reports GNSS altitude and vertical accuracy instead of automatically subtracting the first fix. Relative height requires an explicit reference.
- A responsive project atlas adds filters, measurement colours, answer tables and filtered CSV/GeoJSON exports, including Android sharing.
- Field quality uses isolated, time-bounded form validation, progress reporting and bounded duplicate review.
- Updated home tagline and acknowledgements to the CARE project and BRAC James P Grant School of Public Health, BRAC University.

Install over your existing app using the signed APK below. Photos still require GPS tags; accuracy is recorded but never an accuracy threshold for photos. Credentials already erased by previous versions require re-entry or backup restoration. Indoor GNSS does not reliably measure floor height.

Unassigned legacy study sites require explicit assignment to a project/layer. Shared .mbproj packages contain project definitions, not collected observations. Receiving sync scripts must preserve the new layer/site metadata and upsert stable IDs; remote deletion propagation is not added.

Automated tests, browser atlas checks, static analysis and Android signing verification cover this release. No Android phone/emulator was connected; validate native camera/GNSS and your sync endpoint on your phone before field deployment. See [FIELD_WORKFLOW.md](https://github.com/anisur-bayazid25/MapBanai/blob/main/FIELD_WORKFLOW.md) for the full workflow and research references.
