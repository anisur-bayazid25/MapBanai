# MapBanai 2.7.0 — local APK verification

Built 27 October 2026. Version **2.7.0**, build **34**, application ID `com.mapbanai.mapbanai`.

- APK: `build/app/outputs/flutter-apk/MapBanai-2.7.0.apk`
- Size: 129,163,538 bytes (123.2 MiB).
- SHA-256: `B71E4676ECBEBC30472CF89A81FD11127A63D8E7A9E31903FD898431B636A3D7`.
- Android apksigner verification passed. Certificate matches the previous APK: `913b1052c94f0dda17c965d5964592c1daf8b01002b2e1b7458b6ba67f5fd599`.
- All 496 Flutter tests passed; the final catalogue-only addition passed all five localization tests and the WebMap Node test.
- App-source static analysis: no errors or warnings. Repository-wide analysis retains three pre-existing unused-local warnings in `test/gis_map_controller_test.dart` and informational style lints.
- Android aapt2 resource compilation passed. Packaged icon bytes match the new source asset; Bangla WebMap assets are included. Latest Bangla subtitle was confirmed in the compiled Flutter kernel.
- Release optimizer pinned to R8 8.10.21 for Kotlin 2.2 compatibility; active optimizer version confirmed from the running build. The build still emits non-fatal Kotlin metadata diagnostics from Android tooling, and completes successfully. Logs: `E:/Development/mapbanai-2.7.0-build-final.log`.

Install over the existing app; preserve its local storage. No GitHub release, upload, tag, server deployment, or physical-device installation was performed. Native frame-rate profiling and mobile-carrier download-speed checks remain device checks.

Workflow requirements: **Project Settings > Workflow requirements**. Save and share an updated project package to distribute changes. On Study Area maps, use the nearby-arrow button to sort pending sites by GPS distance; without a recent location, the list sorts by name. The external-arrow button opens the selected site (or current map area) in Google Maps.


Subsequent user authorization requests pushing and publishing v2.7.0. Release source also corrects the static About version to 2.7.0+34 and includes the phone-only preview/mirroring helpers. The local APK/checksum above records the earlier local build; GitHub Actions builds the published APK from the tagged source. Emulator support has been removed at the user's request. Phone debug execution was confirmed via ADB, and scrcpy mirroring is installed on E:.
