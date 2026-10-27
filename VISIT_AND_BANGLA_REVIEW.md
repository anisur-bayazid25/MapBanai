# Visit usability and Bangla interface — 27 October 2026

## Visit flow

- Site names recognize case, surrounding spaces and common GIS naming fields,
  including `Name`, `NAME`, `site_name` and facility/station names. Names take
  priority over IDs. An unnamed site shows coordinates instead of a long UUID.
  Stored attributes, feature IDs, UUIDs and links remain unchanged.
- Guided visits initialize the selected uploaded layer themselves. Opening the
  Study Area map first is no longer necessary. Map and visit screens use the
  same Field Verification layer/form selection.
- A searchable site sheet replaces the oversized dropdown. Search checks names,
  locations and attributes, with concise names and location/status summaries.
- Opening a verification questionnaire from the map starts or resumes that
  site's latest draft directly. Existing drafts display readable site names.
- Name/location fields remain visible; other source attributes expand under
  More site details. The outcome picker has three distinct choices.
- The finish action explains its questionnaire/photo requirements and checks
  that the validated questionnaire is the one currently selected. Saving an
  unfinished draft remains available.
- Point geometry instructions distinguish choosing/moving one location from
  adding vertices. GPS placement is labelled Use GPS position. The map panel
  scrolls on short screens and at large text sizes.

## Home and language

Study Area and GIS exchange their Home positions. Responsive-layout tests also
assert the new order in English and Bangla.

Previously hardcoded native buttons, tooltips, menus, dialogs, import/export
controls, forms, map tools, workflow setup, status labels and help now use the
English/Bangla ARB catalogues. Common field captions translate for display;
stored field names and values are preserved. The app language also selects
bilingual XLSForm labels when those translations are supplied by its author.
Imported names and answers are not automatically translated.

The embedded WebMap and image designer receive the resolved app language.
Their control captions, placeholders and accessibility labels translate without
rewriting GeoJSON, table records, project names, data-driven option names or
user-entered poster text. UI changes created after loading are observed too.
Map-provider place names and third-party code remain as supplied.

## Maintenance

`lib/l10n/app_en.arb` and `app_bn.arb` are the translation sources. The helper's
English message selectors map to generated ARB members. To refresh the helper
and WebMap captions after editing the catalogue:

```powershell
. .\tool\development_environment.ps1
python tool/localize_ui.py --refresh
flutter gen-l10n
```

`tool/audit_ui_copy.dart` audits app-owned UI literals, excluding data lookups and
comparison keys. Its optional output path defaults to the development temp
directory. The one-time migration mode validates source spans using Dart's
UTF-16 offsets and retains original files before editing, including CRLF files.

Validation includes catalogue/placeholder parity, changing language, uploaded
layers used directly by visits, draft reuse, name/identity preservation, Home
order and Bangla layouts with large text. The WebMap Node check verifies that
only controls translate and that record content and input values remain intact.

Final results: all **479 Flutter tests passed**, the WebMap localization Node
check passed, and static analysis reported no errors or warnings. Informational
style lints remain. Physical-device confirmation is still needed after the next
authorized installation.

The subsequent user request authorizes a local signed v2.7.0+34 APK build including the map polish, new icon, nearest sites and workflow requirements. Publication and server deployment remain on hold. Android preview instructions remain in `ANDROID_PREVIEW.md`.
