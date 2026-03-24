# Data Safety — Play Console Answers

Use this when completing **App content → Data safety** in Google Play Console.

**Assumptions:** `AdConfig.adsEnabled = false` (current default), no Firebase Analytics, no crash reporting SDK. Revisit this document if you enable ads or add analytics.

> Google’s form wording changes over time — use this as a guide and answer each screen honestly. [Official Data safety help](https://support.google.com/googleplay/android-developer/answer/10787469)

---

## 1. Does your app collect or share any of the required user data types?

For AlterVPN **with ads disabled** and **no third-party analytics**:

- **Answer:** **No** (the app does not collect or share the required categories of user data for advertising or analytics purposes).

If Play forces you to declare **any** data:

- **Personal info:** Not collected by the app developer for AlterVPN core features (no account).
- **App activity:** Not collected off-device for analytics (unless you add Firebase later).
- **Device or other IDs:** Not collected for tracking by AlterVPN when ads are off.

**Local-only preferences** (theme, server selection, session timers via SharedPreferences) are stored **on device** and are **not** transmitted to AlterVPN’s servers — align with your answers in section 3.

---

## 2. Data types — if you must declare “Yes”

Some consoles ask about **all** data flows. Be accurate:

| Data | Collected? | Shared? | Purpose | Notes |
|------|------------|---------|---------|-------|
| **Crash logs** | Only if you add a crash SDK | — | — | Not in current codebase |
| **App info and performance** | No (unless added) | — | — | — |
| **Device or other IDs** | No when ads off | — | — | AdMob would change this when enabled |

---

## 3. Data handling (when declaring local/device data)

If the form asks about data **stored on device only** and **not sent to your servers**:

- **Encryption in transit:** N/A for data that never leaves the device, or **Yes** for HTTPS when fetching server lists (public JSON over TLS).
- **Users can request deletion:** Users can clear app data in Android Settings.
- **Data is optional:** Preferences are optional for using the app (defaults work).

---

## 4. Privacy policy URL

Use the **same public URL** as in the app (Settings → Privacy Policy). It is served from the Railway web deployment:

```
https://altervpn-production.up.railway.app/privacy.html
```

If you change `ApiConstants.backendBaseUrl`, the in-app URL updates automatically; use that host + `/privacy.html` in Play Console.

See **`PRIVATE_REPO.md`** if the GitHub repo is private (GitHub blob links are not valid for Play).

---

## 5. When you enable AdMob (`adsEnabled = true`)

You must update Data Safety to reflect:

- **Advertising ID** or **Device or other IDs** — collected by Google per AdMob
- **App activity** — ad interactions
- Link to Google’s privacy policy where required
- Declare **“Contains ads”** on the store listing

See also **`PLAY_STORE_CHECKLIST.md`** section 2.7.
