# MapBanai User Guide

**Offline-first field data collection GIS for Android.**
This guide explains everyday use of MapBanai. For developer/build notes see
`README.md` and `CHANGELOG.md`.

---

## 1. Installing

1. Download `app-release.apk` from the latest
   [GitHub Release](https://github.com/anisur-bayazid25/MapBanai/releases/latest)
   or use **Settings → Check for updates** in the app.
2. Open the APK and allow "install from this source" if Android asks.
3. On first launch you are asked for your **name** — it is stamped on every
   survey response, GPS log and export.

No account, no registration, no internet needed for data collection.

## 2. The Home screen

| Element | What it does |
|---|---|
| Logo + tagline | Large MapBanai logo, top-centre |
| Project selector | Tap to pick the project you are collecting data for |
| **Survey / GIS / GPS / Study Area** | The four collection modes, shown as a 2×2 grid of square tiles |
| **GPS CSV Viewer · Cloud Sync · WebMap** | Utility row under the mode tiles |
| Collected data | Survey-response and GIS-feature counts of the selected project |
| Project settings · History · Export | Project management, past records, and file export |
| ☰ (top-right) | Opens **Settings** |

Everything works offline; tiles open instantly and data stays on the device.

## 3. Projects

- **Home → Project settings → New project**: name + description.
- The selected project appears in the selector at the top of Home.
- Each project keeps its own survey forms, fields, GIS features and
  cloud-sync configuration.
- Archive/restore or delete projects from **Project settings**; deleting
  removes all its collected data (confirm first!).

## 4. Survey Mode

1. Open a project → **Survey**.
2. Import an **XLSForm (.xlsx)** built with ODK/Kobo conventions, or build a
   form with the built-in builder.
   - Multi-language forms (`label::English (en)`, `label::Bangla (bn)`, …)
     let you pick the label language while filling the form.
3. Fill the form: conditional questions appear automatically, calculations
   update live, photos are captured and geotagged, GPS points include
   accuracy.
4. Use **Save as draft** to park an unfinished form — resume any time from
   **History → Drafts**.

## 5. GIS Mode

- Draw **points, lines and polygons** directly on the map with your project's
  attribute fields.
- Recording continues in the background with a foreground notification while
  you draw lines/polygons (survives screen-off).
- Drag draft points to adjust before finishing; tap saved features to view,
  edit or delete them.
- Choose basemaps from the app bar (OSM, CartoDB Light/Dark, Esri imagery).

## 6. GPS Mode

- **Record Track**: creates a CSV log; recording continues in the background
  (red banner on Home shows it is active). Press again to stop.
- **Save Point**: capture one precise fix with an optional note.
- Live readouts: latitude/longitude (7 dp), UTC + Dhaka time, accuracy,
  elevation (relative to first fix), speed, satellites in use/view.
- **Compass**: collapsible card — tap to open a full compass rose with
  N/E/S/W marked, degree ticks and a smooth-rotating dial. The red needle
  stays fixed pointing up (the direction the phone faces) while the dial
  turns underneath, like standard phone compasses. The heading is shown as
  **degrees from North** plus cardinal direction (e.g., *135° SE*).
- Logs can be viewed as CSV, shared, renamed, deleted, or projected onto the
  WebMap.

## 7. Study Area Mode

Site visits with status tracking and walk-to navigation:

1. **Import sites** (blue download icon): CSV, GeoJSON, KML, **KMZ**,
   **SHP**, GeoPackage (.gpkg) or Excel (.xlsx). Choose *Replace all* or
   *Append*.
   - Column names are flexible: `latitude/longitude`, `lat/lon`, `x/y`,
     `point_x/point_y` and similar synonyms all work — or provide a WKT
     geometry column (`POINT (lon lat)`).
2. Sites render as circles: red = pending, green = completed.
3. Tap a site: the panel shows distance and bearing from your live GPS with
   an arrow pointing the way. **Center on site** jumps the map there.
4. Mark sites **Completed/Pending**, edit coordinates and attributes, delete.
5. **Export sites** (green upload icon) back out as CSV or Excel.

## 8. History

**Home → History** lists everything you have collected:

- **Drafts** at the top (orange) — tap *Resume* to continue, or delete.
- Saved sessions grouped by **project (folder)** and then by **date**.
- Every group header is **collapsible** — tap a project or date header to
  fold/unfold that section. Headers show how many items they contain.
- The app-bar photo icon opens the geotagged photo gallery.

## 9. Cloud Sync

1. Select a project, then set up the sync URL + API key in
   **project settings → Cloud Sync** (Google Sheets Apps Script backend).
2. From Home, tap the **Cloud Sync** tile:
   - Not configured yet? It opens the setup screen.
   - Configured? It uploads unsynced responses, features and photos, showing
     progress ("Syncing photos 3/9…") and a final summary.
3. The tile subtitle shows when the project last synced.

## 10. WebMap

- **Home → WebMap** generates a self-contained HTML map of the selected
  project's data (works offline; map tiles need internet once).
- Filters panel (collapsible) lets you search attributes, filter by form,
  surveyor and date range.
- Switch basemaps with the **layers button** (top-right of the map).
- GPS logs can be projected onto a track-only WebMap from GPS Mode or the
  GPS CSV Viewer.

## 11. Sharing projects between phones

- Sender: project ⋮ menu → **Export Project** → save `.mbproj` file or share;
  small projects also fit in a **QR code**.
- Receiver: open the received `.mbproj` ("Open with MapBanai"), or import via
  **camera QR scan**, **QR from gallery image**, or paste the code text.
- Responses/photos are never included in a shared project — only definitions.
- Name conflicts offer *Import as new copy* or *Replace*; nothing is
  overwritten silently.

## 12. Exporting data

**Home → Export** (per project):

- Survey responses: **CSV** (Kobo/ODK-style columns) or JSON.
- GIS features: **CSV / GeoJSON / KML / GeoPackage**.
- Files land in the device's export folder and can be shared to WhatsApp,
  email, Drive, etc. via the share sheet.

## 13. Settings

Top-right ☰ on Home:

- **User** — your name (attached to everything you collect).
- **Language** — English or বাংলা (Bangla), applied immediately.
- **Theme** — System / Light / Dark.
- **About** — version, creator, update check.
- **Reset data** — danger zone; type your name to confirm.

## 14. Updates

MapBanai checks GitHub releases on launch. When a new version exists, a
banner offers **Download & Install**. First update asks for the Android
"install unknown apps" permission — that is standard for self-updates.

## 15. Troubleshooting

| Problem | Fix |
|---|---|
| No GPS fix | Go outside, ensure location permission is "While using" or "Always"; check the status card in GPS Mode |
| Compass shows "No heading" | Heading needs movement or device sensors; walk a few steps |
| Import says no sites found | Check the file has latitude/longitude columns (any common alias works) |
| Backup restore prompt did not appear | Restore only triggers on a fresh install with a backup present; data also survives via Cloud Sync |
| Uninstall warning | All local data lives on-device — export or sync important projects first |

## 16. Support

- GitHub issues: https://github.com/anisur-bayazid25/MapBanai
- Email: anisur.rahman.bayazid@gmail.com
