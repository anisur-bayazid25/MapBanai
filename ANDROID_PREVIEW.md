# MapBanai live preview on an Android phone

The Android emulator, API 34 virtual-phone image, virtual-device data and dedicated
AEHD hypervisor driver were removed on 27 October 2026 after repeated PC hangs.
The cause of the hangs has not been established. Use a physical phone for previews.

## Connect a phone

1. On the phone, enable Developer options and USB debugging.
2. Connect it with a USB data cable, unlock it and approve the debugging prompt.
3. In a PowerShell terminal in this project, list devices:

```powershell
.\tool\preview_android.ps1 -ListDevices
```

If listed as `unauthorized`, approve the prompt on the phone. A missing phone may
require a different data cable, USB mode or its manufacturer's USB driver.

## Run and watch changes

```powershell
.\tool\preview_android.ps1
```

With multiple connected devices, select the phone explicitly:

```powershell
.\tool\preview_android.ps1 -DeviceId YOUR_PHONE_SERIAL
```

The launcher uses a physical Android device and never starts an emulator.
The first run builds and installs a debug app. Keep the terminal open:

- `r`: hot reload most Dart/UI changes, preserving current app state.
- `R`: hot restart for initialization changes.
- `q`: end the preview session.

Native Android/Kotlin/plugin changes require stopping and running the preview again.
A phone holding a release app may reject a debug app signed with a different key.
Keep collected field data safe: export/back it up before considering an uninstall,
or use a separate test device or a separate debug application ID.

VS Code with the Flutter extension also supports phone debugging and hot reload
on save. Actual GPS, camera, permissions, files and offline behavior can be tested
on the phone. Chrome/Windows previews do not reproduce these Android integrations.

## Optional PC screen mirror

[scrcpy](https://github.com/Genymobile/scrcpy) displays and controls the connected
phone on the PC. Android runs on the phone rather than in a PC virtual machine.
scrcpy 5.0.1 is installed under `E:\Development\scrcpy` from the official Windows release; its SHA-256 was checked against the release asset digest. Open a mirror using:

```powershell
.\tool\mirror_android.ps1
```

The helper limits video to 1024 pixels, 30 fps and 2 Mbps, with audio disabled. It opens a phone window without a second console and keeps its logs on E:. Close the mirror window to stop mirroring; this leaves the Flutter session running.

Use two terminals only if needed: keep `preview_android.ps1` running in one, and run `mirror_android.ps1` once in another. Edit Dart/UI code and press `r` in the Flutter terminal to see it immediately on the real phone and mirrored window. There is no APK release or Git push for each edit. Flutter still needs an initial debug compilation; native/plugin changes require a new debug run.

The connected phone was confirmed to be running MapBanai 2.7.0 in debug mode. Do not start a second preview build while the existing Flutter session is active. Mirroring is optional; hot reload also works while watching the phone directly. Initial compilation uses the PC and can take time.

## Build tools retained on E:

Flutter: `E:\Development\flutter`; Android SDK: `E:\Android\Sdk`;
Java: `E:\Android\jdk`; Gradle: `E:\gradle-home`; Pub: `E:\pub-cache`;
development temporary files: `E:\DevTemp`.

ADB, build-tools, Android platform SDKs, licenses and signing keys remain.
The `C:\Users\CHORUS-03\.android` junction still points to
`E:\Android\user-home`, retaining signing and ADB keys. The environment helper
continues to apply the migrated development paths to the current terminal.

References: [Android device setup](https://docs.flutter.dev/platform-integration/android/setup),
[Flutter hot reload](https://docs.flutter.dev/tools/hot-reload),
[scrcpy](https://github.com/Genymobile/scrcpy).


## Reopening after disconnecting

Hot reload updates the running Dart session. If the app process closes, launching its icon can load the last installed debug APK, so newer UI edits may appear to have disappeared. Reconnect the phone and run `.\tool\preview_android.ps1` again to compile/install the latest local debug source. This does not push Git changes or publish a release. The apparent rollback reported during phone testing was resolved this way; it was not a field-record restore operation.
