# Play Store Deployment Checklist

Use this checklist to publish AlterVPN to Google Play. Work through each section in order.

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

### 1.4 Optional: Build AAB in CI

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
5. Declare if it contains ads (yes — AdMob rewarded ads, currently disabled by default)

### 2.2 Store listing

| Field | Value |
|-------|-------|
| **App name** | AlterVPN |
| **Short description** | Minimal. Secure. Free. VPN with no subscriptions. |
| **Full description** | Privacy-first VPN client. Connect to OpenVPN servers with one tap. No accounts, no data collection. Dark/light theme, country grouping, real-time stats. |
| **App icon** | 512×512 PNG (no transparency) |
| **Feature graphic** | 1024×500 PNG/JPEG |
| **Screenshots** | At least 2 phone screenshots (16:9 or 9:16) |

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

Fill out the Data safety form. For AlterVPN:

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | **Yes** (if using AdMob; otherwise **No** for core app data) |
| Data types | If ads enabled: **App activity** (ad interactions) — optional; **Device or other IDs** (advertising ID) |
| Is this data collected or shared? | Collected (for ads) |
| Is this data processed ephemerally? | No |
| Is this data required or optional? | Optional (user chooses to watch ads) |
| **Privacy policy URL** | `https://github.com/BaasherHub/AlterVpn-/blob/main/PRIVACY.md` |

> The in-app privacy policy link already points to this. Ensure the URL is publicly accessible.

### 2.6 App access

- All functionality is available without login → **No special access**
- If you have a debug/test build: provide credentials only if needed for reviewers

### 2.7 Ads declaration

If `AdConfig.adsEnabled = true` in production:
- Declare that the app contains ads
- Ads are rewarded videos (optional viewing)

---

## Phase 3 — Upload & Release

### 3.1 Create a release

1. **Production** → **Create new release**
2. Upload `app-release.aab`
3. Add **Release notes** (e.g. "Initial release" or version-specific changes)
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
