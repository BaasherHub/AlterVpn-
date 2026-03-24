# Go-Live Submission Checklist

Use this **single page** on the day you submit to Google Play. Check each box.

---

## Build & signing

- [ ] `android/upload-keystore.jks` created and backed up (passwords stored safely)
- [ ] `android/keystore.properties` filled in (not committed — in `.gitignore`)
- [ ] `flutter build appbundle --release` succeeds
- [ ] `app-release.aab` opens in Play Console without signing errors
- [ ] `pubspec.yaml` version / `versionCode` is correct for this release

---

## Store listing

- [ ] App name, short & full description pasted from **`STORE_LISTING_COPY.md`**
- [ ] 512×512 app icon uploaded
- [ ] 1024×500 feature graphic uploaded
- [ ] At least **2** phone screenshots uploaded
- [ ] **Privacy policy URL** set (same as app): GitHub `PRIVACY.md` link
- [ ] **Contains ads:** **No** (while `AdConfig.adsEnabled = false`)

---

## Policy & compliance

- [ ] **Data safety** completed using **`DATA_SAFETY_PLAY_CONSOLE.md`**
- [ ] **VPN** context reviewed: **`VPN_PLAY_POLICY.md`**
- [ ] **Content rating** questionnaire submitted and approved
- [ ] **Target audience** age groups selected
- [ ] **App access:** no login required (or reviewer instructions provided)

---

## Contact & support (Play Console)

- [ ] Support email or website filled in (see **`SUPPORT.md`**)
- [ ] Release notes pasted from **`RELEASE_NOTES_TEMPLATE.md`**

---

## Final review

- [ ] Tested VPN on a **physical device** after this build (same as submission)
- [ ] No debug-only URLs or test AdMob IDs in production if ads are enabled later

---

When every box is checked → **Review and publish** (or staged rollout).
