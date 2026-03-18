# Postiz - Social Media Manager

## About

Postiz is an open-source social media scheduling and analytics tool. This Home Assistant add-on packages Postiz with all its dependencies (PostgreSQL, Redis) into a single container for easy deployment.

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

### Optional Settings

| Option | Description |
|--------|-------------|
| `MAIN_URL` | External URL for Postiz. Leave empty to use HA ingress URL. |
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
- `/data/uploads/` — Uploaded media files
- `/data/config/` — Configuration files

## Network

| Port | Description |
|------|-------------|
| 4007 | Postiz Web UI (also used for ingress) |

## Architecture

This add-on runs three processes managed by s6-overlay:

1. **PostgreSQL 17** — Main database
2. **Redis 7** — Caching and queue management
3. **Postiz** — The application itself (Node.js)

> **Note:** Temporal workflow engine is not included in v1.0 to reduce resource usage. Basic scheduling works without it. Temporal support may be added in a future version.

## Troubleshooting

### Add-on won't start
Check the add-on logs in Home Assistant. Common issues:
- JWT_SECRET not changed from default
- Port 4007 already in use
- Insufficient disk space for PostgreSQL

### Can't connect to Postiz
- Ensure port 4007 is not blocked by your firewall
- If using ingress, access via the Home Assistant sidebar
- Check that PostgreSQL and Redis are healthy in the logs

### Database issues
PostgreSQL data is stored in `/data/postgres/`. If you need to reset:
1. Stop the add-on
2. Delete `/data/postgres/` via SSH
3. Restart the add-on (will reinitialize)
