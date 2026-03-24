# Play Store Assets

Place your Play Store graphics here. These files are not committed — add them before creating your Play Console release.

## Required Files

| File | Size | Format | Notes |
|------|------|--------|-------|
| `app-icon.png` | 512×512 px | PNG, 32-bit, no transparency | Used for high-res icon on store |
| `feature-graphic.png` | 1024×500 px | PNG or JPEG | Banner at top of store listing |
| `phone-screenshot-1.png` | 1080×1920 or 1080×2340 | PNG or JPEG | 16:9 or 9:16 |
| `phone-screenshot-2.png` | Same | PNG or JPEG | At least 2 required |
| `phone-screenshot-3.png` | Same | PNG or JPEG | Optional but recommended |

## Brand Colors (for designers)

| Token | Hex |
|-------|-----|
| Background (dark) | `#0A0A0A` |
| Surface | `#141414` |
| Accent green | `#1B4332` |
| Gold | `#C9A96E` |
| Text | `#FAFAF8` |

## Screenshot Ideas

1. **Home (connected)** — Connection ring with "Connected", server name, stats
2. **Servers** — Server list with country groups
3. **Home (disconnected)** — Tap-to-connect state
4. **Onboarding** — One of the intro screens
5. **Settings** — Dark mode, Install VPN Profile

## Creating the App Icon

The app uses `@drawable/ic_launcher` in Android. To get a 512×512 store icon:

- Export your design at 512×512, or
- Use [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) and export the largest size, or
- Create a square icon with the AlterVPN branding (shield/lock + "ALTER VPN" text)

## Feature Graphic Tips

- Keep text minimal (e.g. "AlterVPN — Minimal. Secure. Free.")
- Use dark background (#0A0A0A) to match app theme
- Accent green or gold for highlights
- Avoid small text — the graphic is shown at various sizes
