# AlterVPN

> **Minimal. Secure. Free.**

A privacy-first VPN client for Android built with Flutter, connecting to the [VPNGate](https://www.vpngate.net/) public relay network — no subscriptions, no accounts, no data collection.

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

## Build Instructions

### Prerequisites

- Flutter 3.19+ (`flutter --version`)
- Android SDK 21+
- A physical Android device or emulator (VPN requires real device for full functionality)

### Steps

```bash
# 1. Clone
git clone https://github.com/AlterVpn-/AlterVpn-.git
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

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Made with ♡ using Flutter*

AlterVpn 
