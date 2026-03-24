# VPN App — Google Play Policy Notes

AlterVPN is a **VPN client** (OpenVPN). Use this checklist so your listing and declarations match [Google Play policies](https://support.google.com/googleplay/android-developer/answer/9888170).

---

## 1. App declaration — VPN / tunneling

In Play Console, you may be asked about **sensitive permissions** or **core functionality**:

- The app uses Android’s **VPN** APIs (`VpnService`) via `openvpn_flutter` to route device traffic through a user-selected server.
- **Purpose:** User-requested encrypted connection; not used to collect traffic for advertising or resale by the app developer.

Ensure your **store description** does not promise illegal activity (e.g. bypassing copyright, illegal streaming). Keep claims aligned with **privacy and security** (public Wi‑Fi, encryption).

---

## 2. Permissions (manifest)

Relevant permissions are already declared in `AndroidManifest.xml`:

- `INTERNET`, `ACCESS_NETWORK_STATE`
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_SPECIAL_USE` (VPN foreground service)
- `POST_NOTIFICATIONS` (Android 13+)

No change needed unless you add features.

---

## 3. Misleading behavior

- Do not imply the app is “official” VPNGate or any third-party brand unless you have rights.
- Do not guarantee specific speeds or “100% anonymity” — use honest language (see `STORE_LISTING_COPY.md`).

---

## 4. Target API level

Google requires a recent `targetSdkVersion` for new apps and updates. Flutter sets this via the Flutter SDK — run `flutter build appbundle` before upload and fix any Play Console warnings about target API.

---

## 5. Government / restricted regions

If Google or local law restricts VPN apps in certain countries, distribution may be limited — that is handled in Play Console **Countries/regions**, not in code.

---

## 6. Reviewer testing

- **Login:** Not required — state “all features available without login.”
- **VPN permission:** Reviewers will see the system VPN consent dialog on first connect — brief note in **App access** if asked: “Grant VPN permission when prompted after tapping Connect.”
