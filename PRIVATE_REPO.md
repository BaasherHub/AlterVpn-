# Private GitHub repository

The AlterVPN source repo may be **private**. That affects a few things:

## Privacy policy URL (Play Store & Data Safety)

Google Play and users must reach a **public** privacy policy. A private repo’s `github.com/.../blob/main/PRIVACY.md` link is **not** suitable — reviewers and users cannot open it without repo access.

**Solution in this project:**

- The canonical public policy is **`web/privacy.html`**, deployed with the Flutter **web** build on Railway.
- Live URL pattern: **`https://<your-backend-host>/privacy.html`** (same host as the server-list API).
- The mobile app opens this URL via `AppStrings.privacyPolicyUrl` (built from `ApiConstants.backendBaseUrl`).

After changing policy text, update both **`web/privacy.html`** and **`PRIVACY.md`** (repo copy for developers) so they stay aligned.

## Redeploy

Push to `main` and let Railway rebuild so **`/privacy.html`** is updated on the public site.

## Other links

| Topic | Private repo impact |
|-------|---------------------|
| **Issues / contributing** | Only collaborators can open issues on a private repo; consider a public **support email** on Play for end users |
| **Security advisories** | GitHub private repos still support **Security → Advisories** for maintainers |
| **APK downloads** | Releases on a private repo are not public; use **Play Store** or distribute APKs elsewhere |
