# ============================================================
# Postiz Home Assistant Add-on
# Multi-process container: PostgreSQL 17 + Redis 7 + Postiz
# s6-overlay v3 managed via hassio-addons base image
# ============================================================

# Stage 1: Pull Postiz app files from official image
FROM ghcr.io/gitroomhq/postiz-app:latest AS postiz-source

# Stage 2: Build the add-on
FROM ghcr.io/hassio-addons/base:19.0.0

# ---- Install PostgreSQL 17 ----
RUN apk add --no-cache \
    postgresql17 \
    postgresql17-client \
    postgresql17-contrib \
    redis \
    nodejs \
    npm \
    curl \
    bash \
    jq \
    su-exec

# ---- Copy Postiz application from official image ----
# The official image is Node-based, app lives in /app
COPY --from=postiz-source /app /opt/postiz
COPY --from=postiz-source /uploads /opt/postiz/uploads-default

# ---- Create persistent data directories ----
RUN mkdir -p \
    /data/postgres \
    /data/redis \
    /data/uploads \
    /data/config \
    /run/postgresql \
    /run/redis

# ---- PostgreSQL s6 service ----
RUN mkdir -p /etc/s6-overlay/s6-rc.d/postgresql/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/postgresql/type /etc/s6-overlay/s6-rc.d/postgresql/type
COPY rootfs/etc/s6-overlay/s6-rc.d/postgresql/run /etc/s6-overlay/s6-rc.d/postgresql/run
COPY rootfs/etc/s6-overlay/s6-rc.d/postgresql/finish /etc/s6-overlay/s6-rc.d/postgresql/finish
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/postgresql

# ---- Redis s6 service ----
RUN mkdir -p /etc/s6-overlay/s6-rc.d/redis/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/redis/type /etc/s6-overlay/s6-rc.d/redis/type
COPY rootfs/etc/s6-overlay/s6-rc.d/redis/run /etc/s6-overlay/s6-rc.d/redis/run
COPY rootfs/etc/s6-overlay/s6-rc.d/redis/finish /etc/s6-overlay/s6-rc.d/redis/finish
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/redis

# ---- Postiz s6 service (depends on postgres + redis) ----
RUN mkdir -p /etc/s6-overlay/s6-rc.d/postiz/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/postiz/type /etc/s6-overlay/s6-rc.d/postiz/type
COPY rootfs/etc/s6-overlay/s6-rc.d/postiz/run /etc/s6-overlay/s6-rc.d/postiz/run
COPY rootfs/etc/s6-overlay/s6-rc.d/postiz/finish /etc/s6-overlay/s6-rc.d/postiz/finish
RUN touch /etc/s6-overlay/s6-rc.d/postiz/dependencies.d/postgresql \
    && touch /etc/s6-overlay/s6-rc.d/postiz/dependencies.d/redis \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/postiz

# ---- Init script (runs once at container start) ----
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-postiz/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/init-postiz/type /etc/s6-overlay/s6-rc.d/init-postiz/type
COPY rootfs/etc/s6-overlay/s6-rc.d/init-postiz/up /etc/s6-overlay/s6-rc.d/init-postiz/up
COPY rootfs/etc/cont-init.d/postiz-init.sh /etc/cont-init.d/postiz-init.sh
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/init-postiz \
    && touch /etc/s6-overlay/s6-rc.d/postgresql/dependencies.d/init-postiz \
    && touch /etc/s6-overlay/s6-rc.d/redis/dependencies.d/init-postiz

# ---- Make scripts executable ----
RUN chmod -R +x /etc/s6-overlay/s6-rc.d/*/run 2>/dev/null || true \
    && chmod -R +x /etc/s6-overlay/s6-rc.d/*/finish 2>/dev/null || true \
    && chmod +x /etc/cont-init.d/postiz-init.sh

# ---- Labels ----
LABEL \
    io.hass.name="Postiz - Social Media Manager" \
    io.hass.description="Self-hosted social media scheduling and analytics" \
    io.hass.arch="amd64|aarch64" \
    io.hass.type="addon" \
    io.hass.version="1.0.0"

# Expose Postiz web UI
EXPOSE 4007
