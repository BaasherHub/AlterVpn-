# Changelog

All notable changes to AlterVPN are documented here. Version numbers follow `pubspec.yaml` (`versionName+versionCode`).

## [Unreleased]

### Changed
- Privacy policy for Play Store / in-app: public `web/privacy.html` on Railway; `AppStrings.privacyPolicyUrl` uses `ApiConstants.backendBaseUrl` + `/privacy.html` (works when GitHub repo is private)

### Added
- `PRIVATE_REPO.md` — implications of a private repository
- `LICENSE` (MIT), `SECURITY.md`, `CONTRIBUTING.md`
- GitHub issue template config (security contact link), feature request template
- Go-live `SUBMISSION_CHECKLIST.md`, `SUPPORT.md`, GitHub bug report issue template

## [1.0.0] - 2026-03-24

### Added
- Initial Play Store preparation docs (checklist, store listing copy, store assets guide)
- Optional GitHub Actions workflow for signed AAB (`build-aab.yml`)
- Data Safety and VPN Play policy reference docs

### Status
- VPN connectivity verified on Android device
- Rewarded ads disabled by default (`AdConfig.adsEnabled`)
