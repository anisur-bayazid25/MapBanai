# Device layout and in-app download review — 27 October 2026

## Layout changes

The supplied device screenshot shows the Project settings / History / Export
buttons squeezed into three equal columns. The icon and button padding leave
too little space for the labels, so words wrap into fragments. Physical pixel
resolution alone does not determine this: Android display size and font size
change the logical space available to Flutter.

- Added a shared responsive grid based on **local available width** and the
  effective text scale. Controls wrap into fewer columns and grow vertically.
- Home mode cards use content-driven height and show their full labels.
  Project actions, utility cards and collected-data summaries reflow.
- Applied the same layout to project form/sync actions, GPS readouts and
  controls, recording statistics, photo actions, feature sheets, form editor
  actions and WebMap download controls.
- Point, line, polygon and photo capture screens scroll when their contents
  exceed the viewport, including short landscape screens and keyboard insets.
- Replaced tightly packed choice segments with wrapping choice chips.
  Dropdown fields expand within their containers and allow variable item height.
- GIS and Study Area workspace selectors now take their natural height in the
  screen body instead of relying on a fixed 112-pixel app-bar slot. Map panels
  scroll within the available space; the GIS icon toolbar wraps. Study Area
  moves secondary toolbar actions into its menu on narrow screens.
- Survey photo/geometry actions and the update dialog allow their contents to
  grow and scroll.

Automated regression coverage includes English/Bangla home screens at logical
sizes 320×568, 360×800, 412×915, 640×360 and 800×1024, text scales 1.0/1.5/2.0,
and a device pixel ratio of 3. Additional cases cover project actions, long
survey choices, media fields, photo capture, recording/GPS controls, Study Area
workspace/selected-feature panels and the update dialog. Physical device
verification remains necessary before the eventual release.

## Download investigation

The user confirmed that the slowdown occurs **inside the app** on mobile data.
Browser downloads are therefore a useful independent fallback.

Read-only checks of the public GitHub release metadata found:

| Release asset | Bytes | Decimal MB |
| --- | ---: | ---: |
| MapBanai v2.6.10 `app-release.apk` | 126,625,062 | 126.6 |
| eQc v1.8.8 Windows installer | 123,869,103 | 123.9 |

Both use GitHub release download URLs and redirect to GitHub's asset delivery
infrastructure. A 4 MiB range request to each asset from this workstation gave:

| Asset | Response | Transfer rate | Total time |
| --- | --- | ---: | ---: |
| MapBanai | 206 | 2,679,857 bytes/s | 1.565 s |
| eQc | 206 | 2,206,930 bytes/s | 1.901 s |

These are single samples from this workstation's connection, **not mobile-data
measurements**. They do not establish a carrier-routing, DNS, IPv4/IPv6 or CDN
problem. Neither asset size nor a general GitHub outage explains the reported
contrast on this evidence.

The in-app downloader did have avoidable per-chunk UI updates and unbounded
queued writes. It now throttles progress notifications to about five per second,
streams to disk with backpressure, explicitly closes the HTTP client on each
attempt, and requests identity encoding for reliable byte offsets. Resume files
are associated with their source release URL, and resumed Content-Range values
are validated before appending. Tests cover interrupted and redirected
downloads, stale release partials, incorrect/ignored ranges and progress volume.

The update dialog also offers **Open in browser**, using the same release URL,
so the phone's browser can handle the download and the downloaded APK can then
be opened for installation. This is a fallback, not evidence that a particular
carrier issue has been fixed.

For the eventual device check, compare the same release URL using the in-app
downloader and browser on the same SIM/device/location, then repeat on Wi-Fi.
Record elapsed time, phone model, carrier and whether the progress pauses. That
comparison is needed to confirm the remaining mobile-only cause and the effect
of these changes.

The existing local APK also contains native libraries for arm64-v8a,
armeabi-v7a, x86 and x86_64 (about 122.2 MB combined). ABI-specific release APKs
are a potential future way to reduce transfer size, but would require matching
the updater to the device ABI. No packaging/workflow change was made here.

## Build status

At the initial investigation stage no APK was built. A later explicit request authorizes the local signed v2.7.0+34 APK build. No release tag, upload or server deployment is authorized.

Validation: all 460 tests passed. Static analysis of `lib` and the added/updated
tests reported no errors or warnings (existing informational lints remain).
The home action area was also rendered with Roboto at 360 logical pixels wide
and 150% text size for visual inspection.
