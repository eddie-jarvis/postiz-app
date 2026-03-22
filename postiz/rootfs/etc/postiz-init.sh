#!/usr/bin/with-contenv bashio
# ==============================================================================
# Postiz Add-on: Initialization
# Reads HA options, sets up environment, initializes PostgreSQL if needed
# ==============================================================================

bashio::log.info "Initializing Postiz add-on..."

# ---- Read configuration from HA options ----
JWT_SECRET=$(bashio::config 'JWT_SECRET')
MAIN_URL=$(bashio::config 'MAIN_URL')
DISABLE_REGISTRATION=$(bashio::config 'DISABLE_REGISTRATION')
IS_GENERAL=$(bashio::config 'IS_GENERAL')
POSTGRES_PASSWORD=$(bashio::config 'POSTGRES_PASSWORD')

# Determine the external URL
if bashio::config.has_value 'MAIN_URL' && [ -n "${MAIN_URL}" ]; then
    POSTIZ_URL="${MAIN_URL}"
else
    # Default — user must set MAIN_URL for OAuth callbacks to work
    POSTIZ_URL="http://localhost:5000"
fi

bashio::log.info "Postiz URL: ${POSTIZ_URL}"

# ---- Write environment file for all s6 services ----
{
    echo "MAIN_URL=${POSTIZ_URL}"
    echo "FRONTEND_URL=${POSTIZ_URL}"
    echo "NEXT_PUBLIC_BACKEND_URL=${POSTIZ_URL}/api"
    echo "BACKEND_INTERNAL_URL=http://localhost:3000"
    echo "JWT_SECRET=${JWT_SECRET}"
    echo "DATABASE_URL=postgresql://postiz:${POSTGRES_PASSWORD}@localhost:5432/postiz-db"
    echo "REDIS_URL=redis://localhost:6379"
    echo "IS_GENERAL=${IS_GENERAL}"
    echo "DISABLE_REGISTRATION=${DISABLE_REGISTRATION}"
    echo "STORAGE_PROVIDER=local"
    echo "UPLOAD_DIRECTORY=/uploads"
    echo "NEXT_PUBLIC_UPLOAD_DIRECTORY=/uploads"
    echo "NX_ADD_PLUGINS=false"
    echo "API_LIMIT=30"
    echo "NODE_ENV=production"
} > /etc/postiz-env

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
            echo "${key}=${val}" >> /etc/postiz-env
        fi
    fi
done

# ---- Ensure data directories exist (HA mounts /data at runtime) ----
mkdir -p /data/postgres /data/redis /run/postgresql /uploads
chown -R postgres:postgres /data/postgres /run/postgresql
chmod 700 /data/postgres

# ---- Initialize PostgreSQL if first run ----
PG_BIN=/usr/lib/postgresql/17/bin

if [ ! -f /data/postgres/PG_VERSION ]; then
    bashio::log.info "Initializing PostgreSQL database..."

    su -s /bin/bash postgres -c "${PG_BIN}/initdb -D /data/postgres --auth-local=trust --auth-host=md5"

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
        echo "host    all   all   127.0.0.1/32  trust"
    } > /data/postgres/pg_hba.conf

    # Ensure socket dir exists with correct perms before starting
    mkdir -p /run/postgresql
    chown postgres:postgres /run/postgresql
    
    # Start PostgreSQL temporarily to create the database/user
    bashio::log.info "Starting PostgreSQL for initial setup..."
    su -s /bin/bash postgres -c "${PG_BIN}/pg_ctl -D /data/postgres -l /tmp/pg_start.log start -w -t 30"
    if [ $? -ne 0 ]; then
        bashio::log.error "PostgreSQL failed to start. Log:"
        cat /tmp/pg_start.log 2>/dev/null
        exit 1
    fi

    su -s /bin/bash postgres -c "${PG_BIN}/psql -c \"CREATE USER postiz WITH PASSWORD '${POSTGRES_PASSWORD}';\""
    su -s /bin/bash postgres -c "${PG_BIN}/psql -c \"CREATE DATABASE \\\"postiz-db\\\" OWNER postiz;\""
    su -s /bin/bash postgres -c "${PG_BIN}/psql -c \"GRANT ALL PRIVILEGES ON DATABASE \\\"postiz-db\\\" TO postiz;\""

    su -s /bin/bash postgres -c "${PG_BIN}/pg_ctl -D /data/postgres stop -w -t 30"
    bashio::log.info "PostgreSQL initialized successfully."
else
    bashio::log.info "PostgreSQL data directory already exists, skipping init."
    chown -R postgres:postgres /data/postgres /run/postgresql
fi

# ---- Configure Redis ----
cat > /etc/redis/redis.conf <<EOF
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

bashio::log.info "Initialization complete."
