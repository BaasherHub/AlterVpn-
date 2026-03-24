# Security Policy

## Supported versions

We address security issues in the **latest release** on the `main` branch. Use the newest build from [Releases](https://github.com/BaasherHub/AlterVpn-/releases) or Play Store when available.

## Reporting a vulnerability

**Please do not** open a public GitHub issue for undisclosed security vulnerabilities.

Instead:

1. Open a **private security advisory** on GitHub:  
   **Repository → Security → Advisories → Report a vulnerability**  
   Or contact the maintainers through a private channel if one is published on the repo profile.

2. Include:
   - Description of the issue and impact
   - Steps to reproduce (if safe to share)
   - Affected version / commit if known

We will triage and respond as soon as we can. Thank you for helping keep users safe.

## Scope

- In-scope: this app’s code, Android integration, and documented backend behavior.
- Out-of-scope: third-party VPN server operators, user devices with malware, or network attacks outside the app’s control.

## Good practices for contributors

- Never commit **keystores**, `keystore.properties`, API keys, or production `.ovpn` secrets.
- Follow the guidance in **`CONTRIBUTING.md`** for sensitive changes (e.g. backend URLs).
