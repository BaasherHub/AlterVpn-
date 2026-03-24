# Contributing to AlterVPN

Thanks for your interest.

## How to contribute

1. **Issues** — [Open an issue](https://github.com/BaasherHub/AlterVpn-/issues) (bug report template available) for bugs or small feature ideas.
2. **Pull requests** — Fork, branch from `main`, keep changes focused on one topic, and describe what you changed and why.

## Development

- Flutter 3.x + Dart SDK per `pubspec.yaml`
- Run `flutter pub get`, then `flutter analyze` and `flutter test` before submitting.
- Match existing style (see `analysis_options.yaml`).

## Please avoid (without discussion)

- Changing **`lib/core/constants/api_constants.dart`** (production backend URL) — coordinate with maintainers first.
- Committing **`android/keystore.properties`**, `*.jks`, or other secrets.
- Large refactors mixed with bug fixes — split into separate PRs when possible.

## Security

See **[SECURITY.md](SECURITY.md)** for reporting vulnerabilities privately.

## License

By contributing, you agree your contributions are licensed under the same terms as the project — see **[LICENSE](LICENSE)**.
