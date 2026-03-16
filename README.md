# AlterVPN

> **Minimal. Secure. Free.**

A privacy-first VPN client for Android built with Flutter, connecting to the [VPNGate](https://www.vpngate.net/) public relay network — no subscriptions, no accounts, no data collection.

---

## Download APK

**[⬇ Download the latest APK from Releases](https://github.com/BaasherHub/AlterVpn-/releases/latest)**

### How to install on Android

1. Open the link above **on your Android device**
2. Tap the `.apk` file to download it
3. Open the downloaded file — if prompted, enable **"Install from unknown sources"** in your device Settings
4. Tap **Install** and open AlterVPN

> **Minimum requirement:** Android 5.0 (Lollipop) or newer

---

## Features

- 🔒 **OpenVPN-based encryption** — industry-standard tunnel via `openvpn_flutter`
- 🌍 **300+ free servers** fetched live from VPNGate API
- ⚡ **One-tap connect** — select a server and tap the ring
- 📊 **Real-time stats** — live download/upload speed and session timer
- 🌙 **Dark / Light theme** — minimal palette with Playfair Display + DM Sans
- 🔧 **Kill Switch & Auto-Connect** settings (stored locally, no cloud)
- 🗂 **Country grouping** — servers sorted by ping, grouped by country with flag emoji
- 🔍 **Search** — filter servers by country or hostname

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3 + Material 3 |
| State | flutter_riverpod 2 |
| VPN | openvpn_flutter (MethodChannel) |
| API | VPNGate CSV API via dio + csv |
| Storage | shared_preferences |
| Fonts | Google Fonts — Playfair Display, DM Sans, JetBrains Mono |

## Design Palette

| Token | Dark | Light |
|-------|------|-------|
| Background | `#0A0A0A` | `#FAFAF8` |
| Surface | `#141414` | `#F0EFEB` |
| Accent green | `#1B4332` | — |
| Gold | `#C9A96E` | — |
| Text | `#FAFAF8` | `#1A1A1A` |

## Project Structure

```
lib/
├── app/              # Root MaterialApp
├── core/
│   ├── constants/    # Colors, typography, spacing, strings
│   ├── errors/       # Failure types
│   └── utils/        # Extensions, formatters
├── features/
│   ├── connection/   # VPN connection state & controller
│   ├── home/         # Home screen
│   ├── onboarding/   # First-run onboarding
│   ├── servers/      # Server list, API, repository
│   ├── settings/     # Preferences
│   └── splash/       # Animated splash screen
├── services/
│   ├── storage/      # SharedPreferences wrapper
│   └── vpn/          # VPN engine, config & status models
├── theme/            # AlterTheme (dark + light)
└── widgets/          # Shared UI components
```

## Monetization — Ad-Supported Free Model

AlterVPN is **100% free** with no subscriptions. It uses Google AdMob rewarded video ads to sustain development.

### How it works

| Step | What happens |
|------|-------------|
| 1 | User taps **"Watch Ad & Connect"** |
| 2 | Ad-gate dialog appears with streak progress |
| 3 | User taps **"Watch & Connect"** → 30-second rewarded video plays |
| 4 | User earns reward → VPN connects → **2-hour session** starts |
| 5 | Timer counts down on the home screen (`HH:MM:SS`) |
| 6 | After 3 ads in one day → **24-hour free pass** unlocks (no more ads until midnight) |
| 7 | When session expires → VPN disconnects → user taps to watch another ad |

> **Graceful failure:** If no ad is available, the user is connected for free anyway — the app never blocks access.

### Ad streak & 24-hour free pass

- **Streak dots** at the top of the home screen show today's progress (e.g. ●●○ = 2 of 3)
- After watching 3 ads in a single calendar day the dots turn gold and a free-pass banner appears
- The free pass expires at midnight and the streak resets the next day

### Replace test ad IDs with real ones

All ad unit IDs are in `lib/services/ads/ad_config.dart`. Search for `TODO` to find them:

```dart
// lib/services/ads/ad_config.dart

// TODO: Replace with your real Android Rewarded Ad Unit ID from AdMob console.
static const String androidRewardedAdUnitId = 'ca-app-pub-XXXXXX/XXXXXXXX';

// TODO: Replace with your real iOS Rewarded Ad Unit ID from AdMob console.
static const String iosRewardedAdUnitId = 'ca-app-pub-XXXXXX/XXXXXXXX';
```

Also update the AdMob Application ID in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- TODO: Replace with your real AdMob Application ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXX~XXXXXXXXXX"/>
```

### Session & streak constants

```dart
// lib/services/ads/ad_config.dart
sessionDurationSeconds = 7200;   // 2-hour VPN session
streakThreshold        = 3;      // Ads needed for 24-hr free pass
adCooldownSeconds      = 5;      // Minimum gap between ad shows
```

### Web preview

Ads do not run in the browser (web build). On web:
- `showRewardedAd()` returns `true` immediately
- A small banner says "Ads are disabled in web preview mode"
- The session timer still works for UI testing

---



AlterVPN ships with a Railway-ready configuration so you can test the full UI in a browser before building the APK.  
On web, VPN connection is **simulated** (no real tunnel — that requires Android). All screens, animations, and server browsing work normally.

### One-click deploy

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/github?repo=BaasherHub/AlterVpn-)

### Manual steps

1. Go to [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**
2. Select `BaasherHub/AlterVpn-`
3. Railway auto-detects `railway.toml` and builds the Dockerfile
4. Once deployed, open the generated URL (e.g. `https://altervpn-production.up.railway.app`)

### Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `PORT` | `8080` | Injected automatically by Railway — no action needed |

> **Build time:** Flutter web builds take ~3–5 minutes. Railway's 15-minute build timeout is more than enough.

---

## Build Instructions (Android APK)

### Prerequisites

- Flutter 3.19+ (`flutter --version`)
- Android SDK 21+
- A physical Android device or emulator (VPN requires real device for full functionality)

### Steps

```bash
# 1. Clone
git clone https://github.com/BaasherHub/AlterVpn-.git
cd AlterVpn-

# 2. Install dependencies
flutter pub get

# 3. Run on connected device
flutter run

# 4. Build release APK
flutter build apk --release
```

> **Note:** The `openvpn_flutter` plugin requires real device testing for VPN connectivity. The UI and server list work fine on emulators.

## Architecture

The app follows a layered architecture with Riverpod for dependency injection and state management:

```
UI Layer (screens / widgets)
    ↕ ConsumerWidget / ref.watch
Domain Layer (controllers / notifiers)
    ↕ providers
Data Layer (repositories / APIs / services)
```

## Server List — Source & Configuration

AlterVPN fetches its live server list through a **Railway backend relay** hosted at:

```
https://altervpn-production.up.railway.app
```

The relay proxies the [VPNGate Public VPN Relay Service](https://www.vpngate.net/) CSV API, ensuring the server list is reachable even from regions where `vpngate.net` is blocked (e.g. UAE).

### Where the endpoint is configured

The production URL is defined in a single place:

```dart
// lib/core/constants/api_constants.dart
static const String backendBaseUrl =
    'https://altervpn-production.up.railway.app';
```

To point the app at a different relay, change `backendBaseUrl` in that file — no other file needs editing.

### How server loading works

1. On app launch the `ServerController` calls `VpnGateApi.fetchServers()`.
2. `VpnGateApi` issues a GET request to the Railway backend at `https://altervpn-production.up.railway.app/api/iphone/`.
3. The Railway nginx relay forwards the request to `vpngate.net` and returns the same CSV payload.
4. CSV rows are parsed and decoded; each row's column 14 contains the Base64-encoded OpenVPN config.
5. Results are sorted by quality score (config present → active sessions → lower ping) and cached for 30 minutes.

### Required backend fields for a connectable server entry

The app supports two backend response formats: **VPNGate CSV** (default) and **JSON array**.

#### VPNGate CSV (relay mode)
The standard VPNGate CSV column layout.  Column 14 (`OpenVPN_ConfigData_Base64`) must be non-empty for a server to be connectable.  The base64 string may contain embedded newlines — the app strips them before decoding.

```
#HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,…,OpenVPN_ConfigData_Base64
```

#### JSON array (custom backend)
If your backend returns a JSON array, each object must include at least one config field:

| JSON field | Required? | Notes |
|---|---|---|
| `hostName` or `serverName` | ✓ | Unique identifier shown in the server list |
| `ip` | ✓ | Server IP address |
| `countryLong` or `country` | ✓ | Full country name for grouping (e.g. `"Germany"`) |
| `countryShort` or `countryCode` | ✓ | ISO 3166-1 alpha-2 code for flag emoji (e.g. `"DE"`) |
| `ovpnConfig` | one of these | Raw plain-text OpenVPN config (takes precedence) |
| `openVpnConfigDataBase64` or `openVpnConfig` | one of these | Base64-encoded OpenVPN config |
| `numVpnSessions` or `sessions` | optional | Active session count for UI display |
| `ping` | optional | Ping latency in ms; `0` = unknown |
| `speed` | optional | Speed in bytes/s |

A server entry with **no config field** is treated as non-connectable and shown greyed-out in the list.

### Why you might see an empty server list

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Spinner never stops | No internet / Railway backend unreachable | Check connectivity |
| "Unable to reach the server-list backend" | Network error or backend temporarily down | Pull-to-refresh; the full error is shown to help diagnose |
| List loads but server shows "Unavailable" | Server entry has no OpenVPN config | Ensure backend includes `ovpnConfig` or `openVpnConfigDataBase64` |
| List loads but VPN won't connect | VPN permission not yet granted | Tap Connect — Android will show a permission dialog; approve it |

### Required runtime permissions (Android)

`openvpn_flutter` requires:
- `android.permission.INTERNET` — already in `AndroidManifest.xml`
- `android.permission.FOREGROUND_SERVICE` — already in `AndroidManifest.xml`
- **VPN permission** — prompted at runtime when the user first taps Connect; handled via `onActivityResult` in `MainActivity.kt`

### No hardcoded credentials needed

VPNGate servers use the standard OpenVPN username/password `vpn` / `vpn`, which are embedded in the downloaded config. AlterVPN extracts these automatically from the config or falls back to that default — no secrets in the codebase.

---



MIT License — see [LICENSE](LICENSE) for details.

---

*Made with ♡ using Flutter*

AlterVpn 
