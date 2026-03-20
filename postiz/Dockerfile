ARG BUILD_FROM
FROM ghcr.io/gitroomhq/postiz-app:latest AS postiz-source

FROM ${BUILD_FROM}

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

COPY --from=postiz-source /app /opt/postiz

RUN mkdir -p \
    /data/postgres \
    /data/redis \
    /data/uploads \
    /data/config \
    /run/postgresql \
    /run/redis

# s6 services
RUN mkdir -p /etc/s6-overlay/s6-rc.d/postgresql/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/postgresql/type /etc/s6-overlay/s6-rc.d/postgresql/type
COPY rootfs/etc/s6-overlay/s6-rc.d/postgresql/run /etc/s6-overlay/s6-rc.d/postgresql/run
COPY rootfs/etc/s6-overlay/s6-rc.d/postgresql/finish /etc/s6-overlay/s6-rc.d/postgresql/finish
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/postgresql

RUN mkdir -p /etc/s6-overlay/s6-rc.d/redis/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/redis/type /etc/s6-overlay/s6-rc.d/redis/type
COPY rootfs/etc/s6-overlay/s6-rc.d/redis/run /etc/s6-overlay/s6-rc.d/redis/run
COPY rootfs/etc/s6-overlay/s6-rc.d/redis/finish /etc/s6-overlay/s6-rc.d/redis/finish
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/redis

RUN mkdir -p /etc/s6-overlay/s6-rc.d/postiz/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/postiz/type /etc/s6-overlay/s6-rc.d/postiz/type
COPY rootfs/etc/s6-overlay/s6-rc.d/postiz/run /etc/s6-overlay/s6-rc.d/postiz/run
COPY rootfs/etc/s6-overlay/s6-rc.d/postiz/finish /etc/s6-overlay/s6-rc.d/postiz/finish
RUN touch /etc/s6-overlay/s6-rc.d/postiz/dependencies.d/postgresql \
    && touch /etc/s6-overlay/s6-rc.d/postiz/dependencies.d/redis \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/postiz

RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-postiz/dependencies.d
COPY rootfs/etc/s6-overlay/s6-rc.d/init-postiz/type /etc/s6-overlay/s6-rc.d/init-postiz/type
COPY rootfs/etc/s6-overlay/s6-rc.d/init-postiz/up /etc/s6-overlay/s6-rc.d/init-postiz/up
COPY rootfs/etc/cont-init.d/postiz-init.sh /etc/cont-init.d/postiz-init.sh
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/init-postiz \
    && touch /etc/s6-overlay/s6-rc.d/postgresql/dependencies.d/init-postiz \
    && touch /etc/s6-overlay/s6-rc.d/redis/dependencies.d/init-postiz

RUN find /etc/s6-overlay/s6-rc.d -name "run" -exec chmod +x {} \; 2>/dev/null; \
    find /etc/s6-overlay/s6-rc.d -name "finish" -exec chmod +x {} \; 2>/dev/null; \
    chmod +x /etc/cont-init.d/postiz-init.sh 2>/dev/null; \
    true

ARG BUILD_ARCH
ARG BUILD_VERSION

LABEL \
    io.hass.name="Postiz - Social Media Manager" \
    io.hass.description="Self-hosted social media scheduling and analytics" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION}

EXPOSE 4007
