ARG BUILD_FROM
FROM ghcr.io/gitroomhq/postiz-app:latest AS postiz-source

FROM ${BUILD_FROM}

# ---------------------------------------------------------------------------
# Install PostgreSQL 17 from official PGDG repo (signed-by keyring)
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg lsb-release \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
        https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-17 \
        postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install Redis
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends redis-server \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install Node.js 22 from nodesource
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install nginx
# ---------------------------------------------------------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install pnpm and pm2 globally
# ---------------------------------------------------------------------------
RUN npm install -g pnpm pm2

# ---------------------------------------------------------------------------
# Copy Postiz application from source image
# ---------------------------------------------------------------------------
COPY --from=postiz-source /app /app
COPY --from=postiz-source /etc/nginx/nginx.conf /etc/nginx/nginx.conf

# ---------------------------------------------------------------------------
# Copy rootfs (s6 services + init script)
# ---------------------------------------------------------------------------
# Create www user for nginx
RUN addgroup --system www 2>/dev/null; adduser --system --ingroup www --home /www --shell /usr/sbin/nologin www 2>/dev/null; mkdir -p /www; true

COPY rootfs /

# ---------------------------------------------------------------------------
# Make all scripts executable
# ---------------------------------------------------------------------------
RUN chmod +x /etc/postiz-init.sh \
    && find /etc/s6-overlay/s6-rc.d -name "run" -exec chmod +x {} \; \
    && find /etc/s6-overlay/s6-rc.d -name "finish" -exec chmod +x {} \;

# ---------------------------------------------------------------------------
# s6 service registration
# ---------------------------------------------------------------------------
# init-postiz (oneshot)
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-postiz/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/init-postiz

# postgresql (longrun) — depends on init-postiz
RUN mkdir -p /etc/s6-overlay/s6-rc.d/postgresql/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/postgresql/dependencies.d/init-postiz \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/postgresql

# redis (longrun) — depends on init-postiz
RUN mkdir -p /etc/s6-overlay/s6-rc.d/redis/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/redis/dependencies.d/init-postiz \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/redis

# postiz (longrun) — depends on postgresql + redis
RUN mkdir -p /etc/s6-overlay/s6-rc.d/postiz/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/postiz/dependencies.d/postgresql \
    && touch /etc/s6-overlay/s6-rc.d/postiz/dependencies.d/redis \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/postiz

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------
ARG BUILD_ARCH
ARG BUILD_VERSION

LABEL \
    io.hass.name="Postiz - Social Media Manager" \
    io.hass.description="Self-hosted social media scheduling and analytics" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION}

EXPOSE 5000
