# Play Store Deployment Checklist

Use this checklist to publish AlterVPN to Google Play. Work through each section in order.

> **Status:** VPN verified on device ✓ — ready for Play submission once assets and keystore are ready.

> **Day-of upload:** use **`SUBMISSION_CHECKLIST.md`** (single checklist). **Support / Play contact:** **`SUPPORT.md`**.

---

## Phase 1 — Build the Release AAB

### 1.1 Create the upload keystore

Run in your project root (one time only — **keep this file safe**):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Store password and key password: choose strong passwords; you will need them for every release.
- Backup the keystore and passwords somewhere secure (losing them means you cannot update the app on Play Store).

### 1.2 Configure signing

```bash
cp android/keystore.properties.example android/keystore.properties
```

Edit `android/keystore.properties`:

```properties
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

> `storeFile` is relative to the `android/` directory. If you put the keystore at `android/upload-keystore.jks`, use `upload-keystore.jks`.

### 1.3 Build the App Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 1.4 Prepare store assets

Before creating your release, gather these graphics:

| Asset | Spec | Where to put |
|-------|------|--------------|
| App icon | 512×512 PNG, no transparency | `store-assets/app-icon.png` |
| Feature graphic | 1024×500 PNG/JPEG | `store-assets/feature-graphic.png` |
| Phone screenshots | 2+ required, 9:16 or 16:9 | `store-assets/phone-screenshot-*.png` |

See **`store-assets/README.md`** for design tips and brand colors.

**Store listing text** (app name, descriptions) → see **`STORE_LISTING_COPY.md`** (copy-paste ready).

### 1.6 Optional: Build AAB in CI

The repo includes `.github/workflows/build-aab.yml` to build signed AAB on demand. Add these GitHub Actions secrets:

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file (e.g. `base64 -w0 android/upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Store password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | `upload` |

Then run **Actions → Build AAB for Play Store → Run workflow** and download the `app-release-aab` artifact.

---

## Phase 2 — Google Play Console Setup

### 2.1 Create the app

1. Go to [Google Play Console](https://play.google.com/console)
2. **Create app** → Enter name "AlterVPN", default language
3. Select app type: **App** (not game)
4. Declare if it's free or paid (AlterVPN is free)
5. Declare if it contains ads — **No** while `AdConfig.adsEnabled = false` (see §2.7)

### 2.2 Store listing

| Field | Source |
|-------|--------|
| **App name, short & full description** | Copy from **`STORE_LISTING_COPY.md`** |
| **App icon** | `store-assets/app-icon.png` (512×512 PNG, no transparency) |
| **Feature graphic** | `store-assets/feature-graphic.png` (1024×500) |
| **Screenshots** | `store-assets/phone-screenshot-*.png` (at least 2, 9:16 or 16:9) |

### 2.3 Content rating

1. Complete the **Content rating** questionnaire
2. For AlterVPN: typically **Everyone** (no violence, gambling, etc.)
3. Submit and get the rating certificate

### 2.4 Target audience and content

- **Target age groups:** Select as appropriate (likely 13+ or 18+ depending on your jurisdiction)
- **News app:** No
- **COVID-19 app:** No
- **Data safety:** See Phase 2.5

### 2.5 Data safety

**Step-by-step answers (ads off):** see **`DATA_SAFETY_PLAY_CONSOLE.md`**.

Summary:

| Question | Answer (ads disabled) |
|----------|------------------------|
| Does your app collect or share user data? | Typically **No** for developer-collected tracking; confirm each prompt in Console |
| **Privacy policy URL** | `https://github.com/BaasherHub/AlterVpn-/blob/main/PRIVACY.md` |

> The in-app privacy policy link already points to this. Ensure the URL is publicly accessible.

**VPN-specific policy context:** see **`VPN_PLAY_POLICY.md`**.

### 2.6 App access

- All functionality is available without login → **No special access**
- If you have a debug/test build: provide credentials only if needed for reviewers

### 2.7 Ads declaration

- **Current state:** `AdConfig.adsEnabled = false` → declare **"No, the app does not contain ads"** for initial launch
- **When you enable ads later:** Set `adsEnabled = true`, replace test AdMob IDs, then declare **"Yes, the app contains ads"** (rewarded videos, optional)

---

## Phase 3 — Upload & Release

### 3.1 Create a release

1. **Production** → **Create new release**
2. Upload `app-release.aab`
3. Add **Release notes** — copy from **`RELEASE_NOTES_TEMPLATE.md`** (or write your own)
4. **Review and roll out**

### 3.2 Pre-launch report

Google will run automated tests. Fix any crashes or policy violations before promoting to production.

### 3.3 Roll out

- Start with a **limited rollout** (e.g. 20%) if you prefer
- Or **full rollout** when confident

---

## Phase 4 — Post-Release (Optional)

### 4.1 Monitor

- Check **Android Vitals** for crashes and ANRs
- Review **User feedback**
- Watch **Pre-launch report** for new versions

### 4.2 Future updates

1. Bump `version` and `versionCode` in `pubspec.yaml`
2. `flutter build appbundle --release`
3. Create new release in Play Console; upload the new AAB

---

## Quick Reference

| Item | Location |
|------|----------|
| App ID | `com.altervpn.app` (`android/app/build.gradle`) |
| Privacy policy | `PRIVACY.md` (repo root) |
| Data Safety answers | `DATA_SAFETY_PLAY_CONSOLE.md` |
| VPN Play policy notes | `VPN_PLAY_POLICY.md` |
| Store listing copy | `STORE_LISTING_COPY.md` |
| Release notes template | `RELEASE_NOTES_TEMPLATE.md` |
| Changelog | `CHANGELOG.md` |
| Go-live checklist | `SUBMISSION_CHECKLIST.md` |
| Support / contact | `SUPPORT.md` |
| Ad config | `lib/services/ads/ad_config.dart` |
| Version | `pubspec.yaml` |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Keystore was tampered with" | Wrong password; verify `keystore.properties` |
| AAB not accepted | Ensure `minSdk` and `targetSdk` meet Play requirements |
| "Content policy" rejection | Review VPN app policies; ensure no misleading claims |
| Ad policy issues | Ensure AdMob IDs are real (not test IDs) when ads are enabled |
