# MapBanai - Licenses & Legal

**Version:** 1.0.0  
**Last Updated:** 2026-08-17  
**Status:** Foundation - To be updated with actual dependency versions

---

## MapBanai Core License

**MapBanai** is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

### Rationale for AGPLv3

- **Freedom:** Ensures all users can access and modify the source code
- **Community:** Encourages contributions and community-driven development
- **No Tracking:** Protects user privacy; no tracking or analytics
- **Non-Commercial Friendly:** Free for non-commercial use, nonprofits, NGOs
- **Commercial Friendly:** Commercial organizations can use under AGPLv3
- **No Warranties:** Provided "as-is" without warranty

### AGPLv3 Summary

```
You are free to:
  ✓ Use the software for any purpose
  ✓ Copy and modify the software
  ✓ Distribute modified versions
  ✓ Distribute over a network (AGPL requirement)

You must:
  ✗ Provide source code to users who access the app over a network
  ✗ License derivatives under AGPLv3
  ✗ Include copyright notice and license
  ✗ State changes made to the software
```

**Full License:** See `LICENSE` file in project root.

---

## Dependencies & Third-Party Licenses

### Framework & SDK

| Package | Version | License | Purpose |
|---------|---------|---------|---------|
| Flutter | ^3.16.0 | BSD 3-Clause | UI framework |
| Dart | ^3.0.0 | BSD 3-Clause | Programming language |
| Android SDK | 34+ | Apache 2.0 | Android platform |

### Core Libraries (Permissive)

| Package | License | Purpose | Status |
|---------|---------|---------|--------|
| provider | MIT | Dependency injection | ✅ Approved |
| riverpod | MIT | State management | ✅ Approved |
| drift | Apache 2.0 | SQLite ORM | ✅ Approved |
| sqlite3 | Public Domain | Database engine | ✅ Approved |
| go_router | BSD 3-Clause | Navigation | ✅ Approved |
| freezed | MIT | Code generation | ✅ Approved |
| json_serializable | BSD 3-Clause | JSON parsing | ✅ Approved |
| http | BSD 3-Clause | HTTP client | ✅ Approved |
| geolocator | Apache 2.0 | Location services | ✅ Approved |
| image_picker | Apache 2.0 | Camera/gallery | ✅ Approved |
| path_provider | BSD 3-Clause | File system | ✅ Approved |
| intl | BSD 3-Clause | Localization | ✅ Approved |
| sqflite | BSD 3-Clause | SQLite wrapper | ✅ Approved |
| uuid | MIT | UUID generation | ✅ Approved |
| timeago | MIT | Time formatting | ✅ Approved |
| permission_handler | MIT | Permission management | ✅ Approved |
| connectivity_plus | Apache 2.0 | Network detection | ✅ Approved |
| shared_preferences | BSD 3-Clause | Preferences storage | ✅ Approved |
| url_launcher | BSD 3-Clause | Open URLs | ✅ Approved |
| uni_links | MIT | Deep links | ✅ Approved |
| flutter_local_notifications | Apache 2.0 | Notifications | ✅ Approved |
| workmanager | Apache 2.0 | Background tasks | ✅ Approved |
| device_info_plus | Apache 2.0 | Device info | ✅ Approved |
| platform | Apache 2.0 | Platform detection | ✅ Approved |

### Mapping & GIS

| Package | License | Purpose | Status |
|---------|---------|---------|--------|
| maplibre_gl | BSD 2-Clause | Vector mapping | ✅ Approved |
| geopoint | MIT | Coordinate utilities | ✅ Approved |
| geodesy | Apache 2.0 | GIS calculations | ✅ Approved |
| geom | MIT | Geometry algorithms | ✅ Approved |
| wkt | Apache 2.0 | WKT parsing | ✅ Approved |

### Data & Serialization

| Package | License | Purpose | Status |
|---------|---------|---------|--------|
| csv | BSD 3-Clause | CSV parsing | ✅ Approved |
| xml | MIT | XML parsing | ✅ Approved |
| geojson | MIT | GeoJSON handling | ✅ Approved |
| gpx | MIT | GPX format | ✅ Approved |

### Testing

| Package | License | Purpose | Status |
|---------|---------|---------|--------|
| test | Apache 2.0 | Unit testing | ✅ Approved |
| mockito | Apache 2.0 | Mocking | ✅ Approved |
| mocktail | MIT | Mocking (simpler) | ✅ Approved |
| integration_test | BSD 3-Clause | E2E testing | ✅ Approved |

### Development & Analysis

| Package | License | Purpose | Status |
|---------|---------|---------|--------|
| build_runner | Apache 2.0 | Code generation | ✅ Approved |
| analyzer | Apache 2.0 | Code analysis | ✅ Approved |
| lints | Apache 2.0 | Lint rules | ✅ Approved |
| very_good_analysis | MIT | Extended lints | ✅ Approved |

---

## Dependency License Compliance

### Approved Licenses

✅ **Permissive Licenses (Compatible with AGPLv3):**
- Apache License 2.0
- MIT License
- BSD License (2-Clause, 3-Clause)
- Public Domain
- ISC License

### Excluded License Types

❌ **NOT ALLOWED:**
- GPL v2 (copyleft, potential conflict with AGPLv3)
- GPL v3 (possible but not preferred)
- LGPL v2 (complications with linking)
- SSPL (too restrictive)
- Proprietary/Closed-source

### License Verification

To verify dependency licenses:

```bash
# Generate license report
flutter pub run license_check

# Manual check
cd pubspec.lock
# Find each package and verify license in package metadata
```

---

## Android & iOS Native Dependencies

### Android

| Library | License | Purpose |
|---------|---------|---------|
| AndroidX Core | Apache 2.0 | Android framework |
| AndroidX Lifecycle | Apache 2.0 | Component lifecycle |
| AndroidX Room | Apache 2.0 | Database abstraction |
| Google Play Services (Location) | Apache 2.0 | Location APIs |
| CameraX | Apache 2.0 | Camera access |

### iOS

| Library | License | Purpose |
|---------|---------|---------|
| CocoaPods | MIT | Dependency manager |
| CoreLocation | Proprietary (Apple) | Location services |
| AVFoundation | Proprietary (Apple) | Camera framework |

**Note:** Apple proprietary frameworks are used under Apple's iOS SDK license terms.

---

## Third-Party Assets & Data

### Map Data

**OpenStreetMap**
- License: ODbL (Open Data Commons Open Database License)
- Attribution: Required
- Commercial Use: Allowed with attribution
- Usage: Default basemap source

**MBTiles Format**
- License: Specification is open
- Attribution: Varies by tile source
- Commercial Use: Allowed with proper attribution

### Icons & UI

- Material Design Icons: Apache 2.0 (via Flutter)
- Custom icons: To be licensed appropriately

---

## Compliance Checklist

### Legal Compliance
- [ ] All dependencies have licenses in `LICENSE` file
- [ ] No GPL v2 dependencies
- [ ] No proprietary closed-source dependencies
- [ ] All permissive licenses documented
- [ ] Attribution included in about screen

### Build & Distribution
- [ ] APK includes `LICENSE` file
- [ ] App includes "About → Licenses" with all dependencies
- [ ] Source code available (GitHub)
- [ ] Build reproducible
- [ ] No code obfuscation (except optional)

### Privacy & Security
- [ ] No analytics code
- [ ] No tracking code
- [ ] No advertisements
- [ ] No required online accounts
- [ ] Privacy policy available (if needed)

### Open Source
- [ ] Source code on GitHub (public)
- [ ] License prominently displayed
- [ ] Contributing guidelines provided
- [ ] Code comments explain complex logic
- [ ] Documentation complete

---

## License Attribution

### In-App Attribution

**Settings → About → Licenses**

Should display:

```
MapBanai v1.0.0
=========================================

Core License:
  GNU Affero General Public License v3.0

Dependencies:
  - Flutter: BSD 3-Clause
  - Dart: BSD 3-Clause
  - Provider: MIT
  - Riverpod: MIT
  - Drift: Apache 2.0
  - MapLibre: BSD 2-Clause
  - [... full list ...]

Map Data:
  - OpenStreetMap Contributors: ODbL

See LICENSE file for full terms.
```

### README Attribution

```markdown
## License

MapBanai is licensed under the GNU Affero General Public License v3.0 (AGPLv3).

### Third-Party Libraries

See LICENSES.md for complete attribution.
```

---

## Contributing & External Code

### Code Contributions

Contributors retain copyright on contributions but agree to AGPLv3 license terms.

**Contribution Guidelines:**
1. Submit PR with code
2. Agree to AGPLv3 in PR description
3. Include license headers in new files:

```dart
// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (c) 2026 MapBanai Contributors

/// Your code here
```

### External Code

If incorporating external code:
1. Verify license compatibility
2. Add copyright notice and license header
3. Include attribution in LICENSES.md
4. If GPL, consider refactoring

---

## Data & Privacy

### User Data Ownership

- Users own all data they collect
- MapBanai does not claim ownership
- Data stored locally on device
- Synced to user's cloud account (if configured)
- MapBanai has no access to cloud data

### Data Collection

MapBanai does NOT collect:
- ❌ Location data (only user-recorded data)
- ❌ Usage analytics
- ❌ Device identifiers
- ❌ Personal information
- ❌ Telemetry
- ❌ Crash reports (unless explicitly shared)

### Data Deletion

Users can delete all data:
- App local data: Settings → Clear Data
- Cloud sync: Disable sync
- Photos: Delete via gallery
- Projects: Archive/delete projects

---

## Commercial Use

### For Organizations

**MapBanai can be used by:**
- ✅ Non-profits
- ✅ NGOs
- ✅ Universities & research
- ✅ Government agencies
- ✅ Commercial companies
- ✅ Private individuals

**Under AGPLv3:**
- If distributing modified app, source must be available
- If only using internally, no source code disclosure required
- Attribution required in about screen

### Custom Development

To commission custom features:
1. Contribute directly to project (preferred)
2. Fork and maintain private branch (must share improvements)
3. License separate components (keep MapBanai core open)

---

## Version Control & Attribution

### Git Commits

Include `SPDX-License-Identifier` in commit messages for license-related changes:

```
SPDX-License-Identifier: AGPL-3.0-only

Add photo capture feature

Description...

Co-authored-by: Name <email>
```

### File Headers

All source files should include:

```dart
// SPDX-License-Identifier: AGPL-3.0-only
// MapBanai - Offline-first field data collection GIS
// Copyright (c) 2026 MapBanai Contributors
```

---

## Legal Resources

### Links

- AGPLv3 Full Text: https://www.gnu.org/licenses/agpl-3.0.en.html
- SPDX License List: https://spdx.org/licenses/
- OSI Approved Licenses: https://opensource.org/licenses/
- Open Source Initiative: https://opensource.org/

### Contact

For license inquiries:
- GitHub Issues: Use "license" label
- Email: [To be determined]

---

## Disclaimer

```
DISCLAIMER OF WARRANTIES

MapBanai is provided "AS IS" without warranty of any kind, express or implied,
including but not limited to the warranties of merchantability, fitness for a
particular purpose, and noninfringement.

In no event shall the authors or contributors be liable for any claim, damages,
or other liability, whether in an action of contract, tort, or otherwise,
arising from, out of, or in connection with the software or the use or other
dealings in the software.

Use at your own risk.
```

---

## Future License Considerations

### Dual Licensing

Possible in future (requires contributor agreement):
- Primary: AGPLv3 (open source)
- Secondary: Commercial license (proprietary use)
- Example: Nextcloud, GitLab model

### Moving to Different License

Would require:
- Consent from all contributors
- Community discussion
- Clear migration plan
- Probably not happen (AGPLv3 is good fit)

---

## Compliance Audit

### Regular Review

- Quarterly: Review new dependencies
- Annually: Audit all licenses
- Before release: Verify compliance
- After major update: Check license conflicts

### Tools for Compliance

- **FOSSA**: Automated license scanning (https://fossa.com/)
- **Black Duck**: Commercial scanning (Synopsys)
- **WhiteSource**: Dependency tracking
- **Snyk**: Vulnerability + license scanning

---

## Template License File

See `LICENSE` (in project root) for full AGPLv3 text.

```
MapBanai - Offline-first field data collection GIS
Copyright (C) 2026 MapBanai Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

---

## Questions & Support

For license-related questions:
1. Read this document
2. Check CONTRIBUTING.md
3. Search GitHub issues
4. Open new issue with "license" label
5. Contact maintainers

---

**Last Reviewed:** 2026-08-17  
**Next Review:** 2027-08-17  
**Compliance Status:** ✅ Foundation Phase Ready
