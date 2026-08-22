# MapBanai

**Offline-first field data collection GIS for Android.**

MapBanai turns an Android phone into a complete field data collection
kit: surveys with conditional logic, GPS tracking, point/line/polygon GIS
capture, geotagged photos and CSV/GeoJSON exports — all without an internet
connection. Projects can be packaged into `.mbproj` files and shared with
other phones.

**Latest release: [v2.4.1](https://github.com/anisur-bayazid25/MapBanai/releases/latest)**
(API 23+ / Android 6.0+, recommended Android 8.0+)

---

## Getting started

1. Download the `app-release.apk` from the latest
   [GitHub Release](https://github.com/anisur-bayazid25/MapBanai/releases/latest).
2. Open the APK and install it (allow "install from this source" if asked).
3. First launch asks for your **name** — it is stamped on everything you
   collect.
4. Create a project: **Home → Open → New project**.

No account, no registration, no internet needed.

## Home screen

- **Mode tiles** — Survey, GIS, GPS and Study Area as a 2×2 grid of square
  cards; below them GPS CSV Viewer, Cloud Sync and WebMap in one row.
- **Settings** — the ☰ menu icon in the top-right corner.
- **Project settings** — create, rename, archive or delete projects (the
  former "Open" button).
- **History** — past survey sessions, captured features and **drafts**
  (unfinished forms / drawings you can resume). Groups are **collapsible**:
  tap a project (folder) or date header to fold/unfold it.
- **Export** — export collected data (CSV / GeoJSON).
- **Settings** — language, theme, user name, About, update checks,
  **danger zone** (reset data requires typing your name to confirm).

## Survey mode

- Open a project → **Survey**.
- Import an **XLSForm (.xlsx)** template, or build a form with the form
  builder (text, numbers, yes/no, choice lists, dates, photos, GPS points,
  calculated fields, conditional/relevant logic, validation constraints).
- Run the survey: conditional questions appear automatically, calculations
  update live, responses are saved as you go.
- Every answer is stored **on the device only** — offline-friendly.

## GPS mode

- **Tracks**: start/stop a live track. Recording keeps going in the
  **background** — press Back, open another mode, even lock the screen, and
  fixes keep flowing into the log (foreground notification + wake lock). The
  Home screen shows a red banner while a recording is active.
- **Waypoints**: quick manual points with a label (saved to CSV).
- **Save Point**: capture a precise point from the live position (saved to
  CSV). Track and point CSVs land in the device's `Export/<project>/`
  folder, shareable from the app.
- **Compass** (v2.4.0+): collapsible compass rose — N/E/S/W marked, degree
  ticks, and a smooth-rotating dial with the red needle fixed on the
  direction the phone faces; heading shown as degrees from North.

## Drafts (v2.1.2+)

- **Survey mode**: the form has a **Save as draft** button — a partially
  filled answer set is kept without running required/validation checks.
- **GIS mode**: you can **Save draft** while drawing a point, line or
  polygon, and resume the exact shape later.
- Everything unfinished lives in the **Drafts** section at the top of
  **History** with **Resume** / **Delete**. Drafts are never counted as
  collected data (map annotations, exports, project statistics skip them),
  and saving a resumed draft promotes it to a normal saved entry.

## GIS mode

- Live map with 4 built-in basemaps (OSM, CartoDB Light/Dark, Esri
  Satellite).
- Capture **points, lines and polygons** directly on the map, with
  project-defined attribute fields and GPS accuracy filtering. While a line
  or polygon is being drawn, recording also runs in the background with a
  foreground notification so it survives screen-off.
- Browse and delete captured features via the list/legend panel.

## Study Area mode (v2.3.0+)

- Import sites from **CSV, GeoJSON, KML, KMZ, SHP, GeoPackage (.gpkg) or
  Excel (.xlsx)** and see them on the map as colored circles — red =
  pending, green = completed.
- Flexible columns: `latitude/longitude`, `lat/lon`, `x/y`, `point_x/
  point_y` etc. are all recognized — or supply a **WKT** geometry column
  (`POINT (lon lat)`).
- Tap a site for live GPS **distance + bearing** guidance to walk there,
  then mark it **Completed/Pending**.
- Export the site list back out as **CSV or Excel** (Import = blue download
  icon, Export = green upload icon in the app bar).

## GPS CSV viewer (v2.3.0+)

- Open any recorded GPS log to inspect its readings on an interactive map.
- **Project a log onto the WebMap** to share tracks alongside survey data.

## Language & theme (v2.3.0+)

- **English / বাংলা (Bangla)** interface — switch in Settings → Language;
  applies immediately across the app.
- **System / Light / Dark theme** switch in Settings.
- Multi-language **XLSForm** support: forms authored with ODK-style headers
  (`label::English (en)`, `label::Bangla (bn)`) let enumerators pick the
  label language while filling a survey.

## Data export

Project → **Home → Export** in the selected project view:

- Survey responses as **CSV (Kobo/ODK style)** or JSON
- GIS features as **CSV / GeoJSON / KML / Shapefile-style** files

Files are written to `Android/data/com.mapbanai.mapbanai/files/... /Export/<project>/`
(visible via the phone's file manager). Use **Share** inside the app to
send files to any app (email, WhatsApp, Drive, ...).

## Sharing projects between phones (v2.1.1+)

A MapBanai project (forms, questions, logic, settings, layers) can be
packaged into a `.mbproj` file. **Survey responses and photos are never
included** — only the project definition.

**Researcher (sender):**
1. **Home → Open** →
2. Tap the project's **⋮** menu → **Export Project**,
3. Tap **Save project file** (choose a location via Android's file picker,
   e.g. Downloads) **or Share project** (Android share sheet → WhatsApp,
   email, Bluetooth, Quick Share, USB, ...).

**Enumerator (receiver):**
1. Tap the received `Dhaka_Environmental_Survey_v1.3.mbproj` file,
2. Android asks **"Open with MapBanai"** → confirm,
3. Review name/version → **Import project**.

Done — the project appears in the project list, ready to collect data.

> Importing works even without internet because the file travels locally.
> If a project with the same name already exists, MapBanai lets you
> **Import as new copy** or **Replace** the existing one — it never
> silently overwrites anything.

### QR codes

- Project ⋮ menu → **QR code**: small projects can be sent as a **QR**
  (self-contained); if a project is too large, MapBanai says so and shows a
  **bootstrap QR** with the project information instead.
- On the receiving phone, import via **camera scan**, **scan the QR from a
  saved gallery image** (v2.3.0+), or paste the code text.
- Receive side: paste the QR text or open the `mapbanai://` link → import
  instructions are recognized automatically.

## Checking for updates

MapBanai checks GitHub for new releases on launch and from **Settings**
("Check for updates"). A newer version shows release notes and a
**Download & Install** button. No auto-updates — you decide.

## Troubleshooting & notes

- Everything is stored on-device (`mapbanai.db` in app documents).
  Uninstalling the app erases collected data — export/share important
  projects first.
- Storage permission is not required: Android's system file pickers (SAF)
  are used for export/import.
- The update downloader may ask for "install unknown apps" permission on
  first use; that is Android's standard requirement for self-installs.

## Support & feedback

- GitHub: https://github.com/anisur-bayazid25/MapBanai (issues welcome)
- Email: anisur.rahman.bayazid@gmail.com
- Developer changelog (for maintainers): `CHANGELOG.md`,
  in-depth `AI_CHANGELOG.md`.
