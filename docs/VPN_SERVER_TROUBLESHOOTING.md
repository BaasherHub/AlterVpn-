# VPN server troubleshooting (London + multiple devices)

## UK / London not connecting

1. **`configs/uk_london.ovpn`** must be a **real** profile exported from your **UK droplet’s** OpenVPN Access Server — not the placeholder in the repo. See `configs/UK_ACCESS_SERVER.md`.
2. On the **UK droplet**, confirm Access Server is running and firewall allows the same ports you use on US (typically **TCP 443**, **UDP 1194**, admin **TCP 943**).
3. After replacing the file, **redeploy** the backend/static host that serves `/configs/uk_london.ovpn`, then pull to refresh in the app.

---

## US works on one device but disconnects when a second connects

This is usually **not** a hidden “user limit” in the Access Server UI. Common causes:

### 1. Same profile / same certificate (most common)

OpenVPN traditionally allows **only one active session per client certificate** unless the server explicitly allows **duplicate** common names.

- **Symptom:** Second phone connects → first drops (or vice versa).
- **Fix (pick one):**
  - **A — Two users in Access Server:** Create **User B**, download a **second `.ovpn`**, and use a **second server entry** in the app (or rotate profiles per device). Each cert = one concurrent session unless duplicate-cn is on.
  - **B — Allow duplicate connections (same user on multiple devices):** On the **Access Server**, add a **custom OpenVPN directive** (Admin → **Configuration → Advanced VPN** / **Config Profiles** / **Custom directives**, wording varies by AS version):

    ```text
    duplicate-cn
    ```

    Apply and restart VPN services. **Implications:** weaker uniqueness guarantees; only use if you accept that tradeoff.

  - **C — Classic OpenVPN (non-AS):** In `server.conf`, `duplicate-cn` does the same thing.

### 2. Where to look in OpenVPN Access Server

- **User Management:** Per-user **concurrent connection** limits (if set to `1`, only one session).
- **Server / VPN Settings:** Any **max clients** or **topology** limits.
- **Logs:** AS admin → **Status** / **Log Reports** when the second client connects — look for `MULTIPLE` / `certificate` / `auth failed` messages.

### 3. Not related to “windows”

The app does **not** enforce a single-connection policy. Disconnection when two devices connect is **server-side** (profile/cert/session rules).

---

## Quick checklist

| Issue | Check |
|--------|--------|
| London dead | Real `uk_london.ovpn`, droplet up, firewall, HTTPS `ovpn_url` |
| Two devices fight | Duplicate-cn **or** two users/profiles, concurrent limit per user |
