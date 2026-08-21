# Release signing — one keystore, in-place updates

Goal: every release APK is signed with the **same** key so new versions
install as in-place updates (no uninstall, no "package conflicts", data
intact).

## The single source of truth

`android/mapbanai-release.jks` (gitignored — NEVER commit it):

```
Alias:      mapbanai
Type:       PKCS12, 2048-bit RSA
Valid:      2026 → 2054 (10,000 days)
SHA1:       A1:E3:3B:AF:67:BE:A5:D5:52:8A:91:85:BF:96:FD:FD:E8:2E:90:66
SHA256:     91:3B:10:52:C9:4F:0D:DA:17:C9:65:D5:96:45:92:C1:DA:F8:B0:10:02:B2:E1:B7:45:8B:6B:A6:7F:5F:D5:99
Owner:      CN=MapBanai, OU=Development, O=MapBanai, L=Dhaka, ST=Dhaka, C=BD
Passwords:  storePassword == keyPassword (PKCS12 ignores distinct -keypass)
```

Local signing config `android/key.properties` (also gitignored):

```properties
storePassword=pwZkuvElK1ADsUHh
keyPassword=pwZkuvElK1ADsUHh
keyAlias=mapbanai
storeFile=mapbanai-release.jks
```

`android/app/build.gradle` reads that file for `signingConfigs.release`,
and `buildTypes.release.signingConfig = signingConfigs.release`.

## GitHub Actions secrets (REQUIRED or CI fails fast)

`.github/workflows/release.yml` decodes the keystore before building and
aborts with a clear error when the secrets are missing:

| Secret name                 | Value |
|-----------------------------|-------|
| `MAPBANAI_KEYSTORE_BASE64`  | base64 of `android/mapbanai-release.jks` (single line, 3664 chars). Local copy: `C:\Users\CHORUS~1\AppData\Local\Temp\opencode\mapbanai-keystore-base64.txt` |
| `KEYSTORE_PASSWORD`         | `pwZkuvElK1ADsUHh` |
| `KEY_PASSWORD`              | `pwZkuvElK1ADsUHh` |
| `KEY_ALIAS`                 | `mapbanai` |

(legacy name `KEYSTORE_BASE64` also works as a fallback.)

### Set them via the web UI

1. Repo → **Settings → Secrets and variables → Actions**
2. **New repository secret** for each row above.
   For the base64: open the txt file, select all, paste. It must be the
   base64 of the CURRENT `mapbanai-release.jks` — if you regenerate the
   keystore, every already-installed APK stops updating.

### Or via gh CLI

```bash
gh secret set MAPBANAI_KEYSTORE_BASE64 < mapbanai-keystore-base64.txt
gh secret set KEYSTORE_PASSWORD  "pwZkuvElK1ADsUHh"
gh secret set KEY_PASSWORD       "pwZkuvElK1ADsUHh"
gh secret set KEY_ALIAS          "mapbanai"
```

### After setting secrets

Re-run the failed workflow instead of cutting a new tag:
**Actions → failed run → Re-run jobs**, or push a fresh tag.

## Verify a build's signature

```bash
keytool -printcert -jarfile app-release.apk
# must print SHA1 A1:E3:3B:AF:67:BE:A5:D5:52:8A:91:85:BF:96:FD:FD:E8:2E:90:66
```

## One-time transition note

APKs installed from BEFORE this keystore existed (debug-signed or older
CI key) cannot be updated in place — uninstall once, install the first
keystore-signed release. Every release after that updates in place.
