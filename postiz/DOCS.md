# Postiz - Social Media Manager

## About

Postiz is an open-source social media scheduling and analytics tool. This Home Assistant add-on packages Postiz with all its dependencies (PostgreSQL, Redis, nginx) into a single container for easy deployment.

## Features

- Schedule posts across multiple social media platforms
- Analytics and engagement tracking
- AI-powered content suggestions (requires OpenAI API key)
- Multi-user support with registration control
- Local file storage for media uploads

## Supported Platforms

- X (Twitter)
- LinkedIn
- Reddit
- Facebook & Instagram (via Facebook API)
- YouTube
- TikTok
- Pinterest
- Discord
- Slack
- Mastodon
- Threads
- Dribbble

## Configuration

### Required Settings

| Option | Description |
|--------|-------------|
| `JWT_SECRET` | **Change this!** Random string for JWT token signing. Use a long random string. |
| `MAIN_URL` | External URL for Postiz (e.g., `http://192.168.1.50:5000`). Required for social media OAuth callbacks. |

### Optional Settings

| Option | Description |
|--------|-------------|
| `DISABLE_REGISTRATION` | Set to `true` to prevent new user signups after initial setup. |
| `IS_GENERAL` | Enable general mode (default: `true`). |
| `POSTGRES_PASSWORD` | PostgreSQL password (default: `postiz-password`). |
| `OPENAI_API_KEY` | OpenAI API key for AI content features. |

### Social Media API Keys

Each platform requires its own API credentials. Visit the respective developer portals to obtain them:

- **X/Twitter**: [developer.twitter.com](https://developer.twitter.com)
- **LinkedIn**: [linkedin.com/developers](https://www.linkedin.com/developers/)
- **Facebook/Instagram**: [developers.facebook.com](https://developers.facebook.com)
- **YouTube**: [console.cloud.google.com](https://console.cloud.google.com)
- **TikTok**: [developers.tiktok.com](https://developers.tiktok.com)
- **Reddit**: [reddit.com/prefs/apps](https://www.reddit.com/prefs/apps)
- **Pinterest**: [developers.pinterest.com](https://developers.pinterest.com)
- **Discord**: [discord.com/developers](https://discord.com/developers)
- **Mastodon**: Your instance's developer settings

## Data Storage

All data is persisted in `/data/` which maps to the add-on's persistent storage:

- `/data/postgres/` — PostgreSQL database files
- `/data/redis/` — Redis append-only file

Uploaded media is stored at `/uploads/` inside the container.

## Network

| Port | Description |
|------|-------------|
| 5000 | Postiz Web UI (nginx reverse proxy) |

The add-on uses `host_network: true` for direct port access. Ingress is disabled because Postiz is a SPA that doesn't work through HA's ingress proxy.

## Architecture

This add-on runs the following processes managed by s6-overlay:

1. **PostgreSQL 17** — Main database (from official PGDG repo)
2. **Redis** — Caching and queue management
3. **nginx** — Reverse proxy on port 5000 (proxies frontend on 4200 and backend on 3000)
4. **pm2** — Process manager for Postiz backend, frontend, and orchestrator

The Dockerfile uses a multi-stage build:
- Stage 1: Official Postiz image (`ghcr.io/gitroomhq/postiz-app:latest`) as source
- Stage 2: HA Debian base (`ghcr.io/hassio-addons/debian-base:9.1.0`) with PostgreSQL, Redis, Node.js 22, nginx, pnpm, pm2

> **Note:** Temporal workflow engine is not included in v1.0 to reduce resource usage. Basic scheduling works without it.

## Troubleshooting

### Add-on won't start
Check the add-on logs in Home Assistant. Common issues:
- JWT_SECRET not changed from default
- Port 5000 already in use by another service
- Insufficient disk space for PostgreSQL

### Can't connect to Postiz
- Access Postiz directly at `http://<your-ha-ip>:5000`
- Ensure port 5000 is not blocked by your firewall
- Check that PostgreSQL and Redis are healthy in the logs

### OAuth callbacks not working
- Make sure `MAIN_URL` is set to the externally reachable URL (e.g., `http://192.168.1.50:5000`)
- The URL must match what you configured in each social media developer portal

### Database issues
PostgreSQL data is stored in `/data/postgres/`. If you need to reset:
1. Stop the add-on
2. Delete `/data/postgres/` via SSH
3. Restart the add-on (will reinitialize)
