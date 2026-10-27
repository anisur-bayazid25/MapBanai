# MapBanai 2.7.1 release checks

Version 2.7.1+35 includes the v2.7.0 feature work and phone-test fixes. The v2.7.0 GitHub build was cancelled before publication.

- All 507 Flutter tests passed. The final Settings Save action/choice-preservation regression also passed after the last UI adjustment; GitHub reruns the complete suite against the tagged source.
- Four production-connection tests cover concurrent first-launch schema creation, independent screen disposal, synchronized watches, and closing/reopening the file. Both .mbproj files copied from the user's phone imported successfully into temporary local storage. Those private files remain outside Git.
- The user confirmed Settings and .mbproj import work after hot restart on the USB-connected phone.
- Map header/empty notice separation passes at narrow and landscape sizes with large text. Project card contrast exceeds 4.5:1 in light and dark themes. Welcome/edit name dialogs survive keyboard focus and route-close animations.
- Save has a 48px action area and no excessive vertical padding; editing pending settings no longer resets them during rebuild.
- The icon outline is the Broadway M already used in assets/logo/MapBanai_logo.svg, in its original #C04F15 color. No font file is distributed. All platform icons and Android adaptive/monochrome/splash resources are regenerated from that outline.
- scrcpy 5.0.1 mirrors the real phone at 1024px, 30fps, 2Mbps with audio off; development tools and caches remain on E:. No emulator is used.

The release APK is built and signed by the existing GitHub Actions workflow, with automated tests, analysis and manager backend checks before publication. No Apps Script server is deployed by this release.
