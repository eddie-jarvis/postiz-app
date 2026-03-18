#!/usr/bin/with-contenv bashio
# ==============================================================================
# Postiz Add-on: Initialization
# Reads options.json, sets up environment, initializes PostgreSQL if needed
# ==============================================================================

bashio::log.info "Initializing Postiz add-on..."

# ---- Read configuration from HA options ----
JWT_SECRET=$(bashio::config 'JWT_SECRET')
MAIN_URL=$(bashio::config 'MAIN_URL')
DISABLE_REGISTRATION=$(bashio::config 'DISABLE_REGISTRATION')
IS_GENERAL=$(bashio::config 'IS_GENERAL')
POSTGRES_PASSWORD=$(bashio::config 'POSTGRES_PASSWORD')

# Determine the URL for Postiz
if bashio::config.has_value 'MAIN_URL' && [ -n "${MAIN_URL}" ]; then
    POSTIZ_URL="${MAIN_URL}"
elif bashio::addon.ingress; then
    POSTIZ_URL="$(bashio::addon.ingress_url)"
else
    POSTIZ_URL="http://localhost:4007"
fi

bashio::log.info "Postiz URL: ${POSTIZ_URL}"

# ---- Write environment file for all s6 services ----
{
    echo "MAIN_URL=${POSTIZ_URL}"
    echo "FRONTEND_URL=${POSTIZ_URL}"
    echo "NEXT_PUBLIC_BACKEND_URL=${POSTIZ_URL}/api"
    echo "BACKEND_INTERNAL_URL=http://localhost:3000"
    echo "JWT_SECRET=${JWT_SECRET}"
    echo "DATABASE_URL=postgresql://postiz:${POSTGRES_PASSWORD}@localhost:5432/postiz"
    echo "REDIS_URL=redis://localhost:6379"
    echo "IS_GENERAL=${IS_GENERAL}"
    echo "DISABLE_REGISTRATION=${DISABLE_REGISTRATION}"
    echo "STORAGE_PROVIDER=local"
    echo "UPLOAD_DIRECTORY=/data/uploads"
    echo "NEXT_PUBLIC_UPLOAD_DIRECTORY=/data/uploads"
    echo "NX_ADD_PLUGINS=false"
    echo "API_LIMIT=30"
    echo "NODE_ENV=production"
} > /etc/postiz.env

# Social media API keys — only set if non-empty
declare -a SOCIAL_KEYS=(
    X_API_KEY X_API_SECRET
    LINKEDIN_CLIENT_ID LINKEDIN_CLIENT_SECRET
    REDDIT_CLIENT_ID REDDIT_CLIENT_SECRET
    GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET
    THREADS_APP_ID THREADS_APP_SECRET
    FACEBOOK_APP_ID FACEBOOK_APP_SECRET
    YOUTUBE_CLIENT_ID YOUTUBE_CLIENT_SECRET
    TIKTOK_CLIENT_ID TIKTOK_CLIENT_SECRET
    PINTEREST_CLIENT_ID PINTEREST_CLIENT_SECRET
    DISCORD_CLIENT_ID DISCORD_CLIENT_SECRET DISCORD_BOT_TOKEN_ID
    SLACK_ID SLACK_SECRET SLACK_SIGNING_SECRET
    MASTODON_URL MASTODON_CLIENT_ID MASTODON_CLIENT_SECRET
    DRIBBBLE_CLIENT_ID DRIBBBLE_CLIENT_SECRET
    OPENAI_API_KEY
)

for key in "${SOCIAL_KEYS[@]}"; do
    if bashio::config.has_value "${key}"; then
        val=$(bashio::config "${key}")
        if [ -n "${val}" ]; then
            echo "${key}=${val}" >> /etc/postiz.env
        fi
    fi
done

# ---- Ensure data directories exist ----
mkdir -p /data/postgres /data/redis /data/uploads /data/config
chown -R postgres:postgres /data/postgres
chown -R redis:redis /data/redis
chmod 700 /data/postgres

# ---- Initialize PostgreSQL if first run ----
if [ ! -f /data/postgres/PG_VERSION ]; then
    bashio::log.info "Initializing PostgreSQL database..."
    chown -R postgres:postgres /run/postgresql
    su-exec postgres initdb -D /data/postgres --auth-local=trust --auth-host=md5

    # Configure PostgreSQL
    {
        echo "listen_addresses = '127.0.0.1'"
        echo "port = 5432"
        echo "unix_socket_directories = '/run/postgresql'"
        echo "max_connections = 50"
        echo "shared_buffers = 128MB"
        echo "work_mem = 4MB"
        echo "maintenance_work_mem = 64MB"
        echo "effective_cache_size = 256MB"
        echo "logging_collector = off"
        echo "log_destination = 'stderr'"
    } >> /data/postgres/postgresql.conf

    # Allow local connections
    {
        echo "local   all   all                 trust"
        echo "host    all   all   127.0.0.1/32  md5"
    } > /data/postgres/pg_hba.conf

    # Start PostgreSQL temporarily to create the database/user
    su-exec postgres pg_ctl -D /data/postgres -l /dev/null start -w -t 30

    su-exec postgres psql -c "CREATE USER postiz WITH PASSWORD '${POSTGRES_PASSWORD}';"
    su-exec postgres psql -c "CREATE DATABASE postiz OWNER postiz;"
    su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE postiz TO postiz;"

    su-exec postgres pg_ctl -D /data/postgres stop -w -t 30
    bashio::log.info "PostgreSQL initialized successfully."
else
    bashio::log.info "PostgreSQL data directory already exists, skipping init."
    chown -R postgres:postgres /data/postgres /run/postgresql
fi

# ---- Configure Redis ----
cat > /etc/redis.conf <<EOF
bind 127.0.0.1
port 6379
dir /data/redis
appendonly yes
appendfilename "appendonly.aof"
maxmemory 128mb
maxmemory-policy allkeys-lru
daemonize no
loglevel notice
logfile ""
EOF
chown redis:redis /etc/redis.conf

bashio::log.info "Initialization complete."
