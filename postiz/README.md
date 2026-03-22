# Postiz Home Assistant Add-on

Self-hosted social media scheduling and analytics, packaged as a Home Assistant add-on.

## Installation

### Method 1: Add Custom Repository (Recommended)

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Click the **⋮** menu (top right) → **Repositories**
3. Add this URL:
   ```
   https://github.com/eddie-jarvis/postiz-app
   ```
4. Click **Add** → **Close**
5. Find "Postiz - Social Media Manager" in the store and click **Install**

### Method 2: Local Build

1. Clone the repository:
   ```bash
   git clone https://github.com/eddie-jarvis/postiz-app.git
   cd postiz-app/ha-addon
   ```
2. Copy the `ha-addon/` directory to your HA `addons/` folder (accessible via Samba/SSH add-ons)
3. In HA, go to **Settings → Add-ons → Add-on Store**
4. Click the **⋮** menu → **Check for updates**
5. The add-on should appear under **Local add-ons**

## First-time Setup

1. After installing, go to the add-on **Configuration** tab
2. **Change `JWT_SECRET`** to a random string (important for security!)
3. Set `MAIN_URL` to `http://<your-ha-ip>:5000` (required for OAuth callbacks)
4. Add API keys for any social media platforms you want to use
5. Click **Save**
6. Go to the **Info** tab and click **Start**
7. Access Postiz at `http://<your-ha-ip>:5000`

> **Note:** Ingress is disabled — Postiz is a SPA that doesn't work through HA's ingress proxy. Access it directly via port 5000.

## What's Included

| Component    | Version | Purpose                    |
|-------------|---------|----------------------------|
| Postiz      | latest  | Social media management    |
| PostgreSQL  | 17      | Database                   |
| Redis       | 7       | Cache & queues             |
| nginx       | -       | Reverse proxy (port 5000)  |

## What's NOT Included (v1.0)

- **Temporal** — Workflow engine for advanced scheduling. Skipped in v1.0 to keep resource usage low. Basic scheduling works without it.

## Resource Requirements

- **RAM**: ~512MB minimum, 1GB recommended
- **Disk**: ~2GB for the container image + space for your data
- **CPU**: Any modern x86_64 or ARM64 processor

## File Structure

```
postiz/
├── config.yaml          # HA add-on configuration & schema
├── Dockerfile           # Multi-stage build (Postiz + PG + Redis)
├── build.yaml           # Build configuration
├── DOCS.md              # User documentation
├── README.md            # This file
├── CHANGELOG.md         # Version history
├── translations/
│   └── en.yaml          # English translations
└── rootfs/
    └── etc/
        ├── postiz-init.sh           # Initialization (DB setup, env vars)
        └── s6-overlay/
            └── s6-rc.d/
                ├── init-postiz/     # Oneshot: initialization
                ├── postgresql/      # Longrun: PostgreSQL 17
                ├── redis/           # Longrun: Redis 7
                └── postiz/          # Longrun: nginx + pm2 (backend, frontend, orchestrator)
```

## Updating

When a new version of the add-on is released:
1. Go to **Settings → Add-ons → Postiz**
2. Click **Update** (if available)
3. The add-on will rebuild with the latest Postiz image
4. Your data in `/data/` is preserved across updates

## Backup

The add-on data is included in Home Assistant's backup system. You can also manually back up:
- `/data/postgres/` — Database (most important)
- `/uploads/` — Uploaded media files

## License

Postiz is licensed under the [Apache 2.0 License](https://github.com/gitroomhq/postiz-app/blob/main/LICENSE).
This add-on packaging is provided as-is.
