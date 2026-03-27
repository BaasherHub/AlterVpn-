# UK / EU droplet — OpenVPN Access Server (same pattern as US)

Your **US** droplet runs **OpenVPN Access Server (AS)** with its own admin UI and profiles. The **new** droplet needs its **own** AS install — you do not “link” it to the US server.

## 1. On DigitalOcean (new droplet)

1. Create the droplet (Ubuntu 22.04, same region you want for VPN exit, e.g. London/Frankfurt).
2. **Firewall (Networking → Firewalls)** — attach to this droplet and allow:
   - **TCP 22** — SSH (your IP if possible)
   - **TCP 943** — Access Server admin UI (first-time setup)
   - **TCP 443** — AS VPN / web (default AS pattern)
   - **UDP 1194** — VPN data channel  
   (Match what you use on the US droplet; your US screenshot showed tcp/443 and udp/1194.)

## 2. Install OpenVPN Access Server

Use the **same method** you used for **AllanVpn-US**:

- **Marketplace:** DigitalOcean → Create → **Marketplace** → search **OpenVPN Access Server** → create droplet from image, **or**
- **Manual:** Follow OpenVPN’s official install steps for Ubuntu 22.04 on a fresh droplet.

Complete the **first-time web setup** in the browser:

- `https://<NEW_DROPLET_PUBLIC_IP>:943/`

Set admin password, agree terms, etc.

## 3. Create a user and download a profile

1. In AS admin: **User Permissions** → add a user (or use `openvpn` user).
2. Open the **User Portal** (often `https://<IP>:943/` as user) or use **Admin → User** → download **Connection Profile** / **User-locked profile** (`.ovpn`).

Test that profile in **OpenVPN Connect** against the **new droplet IP** before using it in AlterVPN.

## 4. Put the profile in this repo

1. Open `configs/uk_london.ovpn` in this project.
2. **Delete** the placeholder content and **paste the full** `.ovpn` text from Access Server (same as you did for US → `us_northbergen.ovpn`).
3. Save the file.

## 5. Deploy the backend (Railway / Docker)

Push and deploy so:

- `https://<your-host>/configs/uk_london.ovpn` serves the new file.
- `/api/iphone/` already lists **UK - London** with `ovpn_url` pointing at that path (see `nginx.conf`).

## 6. App

Refresh the server list in AlterVPN; pick **UK - London** and connect.

---

**Summary:** New droplet → install **Access Server** on it → download **new** `.ovpn` → replace `configs/uk_london.ovpn` → deploy.
