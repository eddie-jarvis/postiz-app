# Changelog

## 1.0.1

### Fixed
- Switched from Alpine base to Debian base (`ghcr.io/hassio-addons/debian-base:9.1.0`) to match Postiz official image (Debian bookworm)
- Fixed PostgreSQL installation: use official PGDG apt repo with signed-by keyring (apt-key is removed in modern Debian)
- Fixed PostgreSQL paths to use Debian layout (`/usr/lib/postgresql/17/bin/`)
- Removed cont-init.d usage (race condition with s6) — use s6 oneshot service instead
- Disabled ingress (SPA apps don't work through HA ingress proxy)
- Enabled host_network for direct port access
- Changed port from 4007 to 5000 (nginx proxy, matching official Postiz)
- Use official Postiz startup: `nginx && pnpm run pm2` instead of custom node commands
- Copy /app from official image (not /opt/postiz)
- Use `pnpm run prisma-db-push` for DB migrations (official Postiz method)
- Create /data dirs at runtime in init script (HA mounts /data at runtime)
- Fixed Redis config path for Debian (`/etc/redis/redis.conf`)
- Install Node.js 22 from nodesource, pnpm and pm2 via npm

### Changed
- Upload directory set to /uploads (matching official image nginx config)
- Database name changed to `postiz-db` (matching official docs)

## 1.0.0

- Initial release
