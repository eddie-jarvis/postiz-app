#!/command/with-contenv bashio

bashio::log.info "Initializing Postiz add-on..."

# Read config
JWT_SECRET=$(bashio::config 'JWT_SECRET')
MAIN_URL=$(bashio::config 'MAIN_URL')
IS_GENERAL=$(bashio::config 'IS_GENERAL')
DISABLE_REGISTRATION=$(bashio::config 'DISABLE_REGISTRATION')

MAIN_URL="${MAIN_URL%/}"
if [ -z "${MAIN_URL}" ]; then
    MAIN_URL="http://localhost:5000"
fi

POSTGRES_PASSWORD="postiz-password"
DATABASE_URL="postgresql://postiz:${POSTGRES_PASSWORD}@localhost:5432/postiz-db"

bashio::log.info "Postiz URL: ${MAIN_URL}"

# Write env file
cat > /etc/postiz-env <<EOF
DATABASE_URL=${DATABASE_URL}
REDIS_URL=redis://localhost:6379
JWT_SECRET=${JWT_SECRET}
MAIN_URL=${MAIN_URL}
FRONTEND_URL=${MAIN_URL}
NEXT_PUBLIC_BACKEND_URL=${MAIN_URL}/api
BACKEND_INTERNAL_URL=http://localhost:3000
IS_GENERAL=${IS_GENERAL}
DISABLE_REGISTRATION=${DISABLE_REGISTRATION}
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/uploads
NEXT_PUBLIC_UPLOAD_DIRECTORY=/uploads
NODE_ENV=production
EOF

# Create dirs
mkdir -p /data/postgres /data/redis /run/postgresql /uploads
chown -R postgres:postgres /data/postgres /run/postgresql
chmod 700 /data/postgres

# Init PostgreSQL if needed
if [ ! -f /data/postgres/PG_VERSION ]; then
    bashio::log.info "First run — initializing PostgreSQL..."
    
    # Use pg_createcluster-like approach but manual since we use /data
    chown postgres:postgres /data/postgres
    
    # initdb as postgres user
    /usr/lib/postgresql/17/bin/initdb \
        -D /data/postgres \
        --auth=trust \
        --encoding=UTF8 \
        --locale=C \
        --username=postgres 2>&1 || {
        bashio::log.error "initdb failed"
        exit 1
    }
    
    chown -R postgres:postgres /data/postgres
    
    # Configure
    {
        echo "listen_addresses = 'localhost'"
        echo "port = 5432"
        echo "max_connections = 100"
        echo "shared_buffers = 128MB"
        echo "unix_socket_directories = '/run/postgresql'"
    } >> /data/postgres/postgresql.conf
    
    {
        echo "local   all   all   trust"
        echo "host    all   all   127.0.0.1/32  trust"
        echo "host    all   all   ::1/128       trust"
    } > /data/postgres/pg_hba.conf
    
    # Start postgres in background
    /usr/lib/postgresql/17/bin/pg_ctl \
        -D /data/postgres \
        -l /data/pg_init.log \
        -o "-c unix_socket_directories=/run/postgresql" \
        start 2>&1
    
    # Wait for it
    for i in $(seq 1 30); do
        if /usr/lib/postgresql/17/bin/pg_isready -h /run/postgresql > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Create user and database
    /usr/lib/postgresql/17/bin/psql -h /run/postgresql -U postgres \
        -c "CREATE USER postiz WITH PASSWORD '${POSTGRES_PASSWORD}' SUPERUSER;" 2>&1
    /usr/lib/postgresql/17/bin/psql -h /run/postgresql -U postgres \
        -c "CREATE DATABASE \"postiz-db\" OWNER postiz;" 2>&1
    
    # Stop
    /usr/lib/postgresql/17/bin/pg_ctl -D /data/postgres stop -w 2>&1
    sleep 2
    
    bashio::log.info "PostgreSQL initialized successfully."
else
    bashio::log.info "PostgreSQL data exists, skipping init."
    chown -R postgres:postgres /data/postgres /run/postgresql
fi

bashio::log.info "Postiz initialization complete."
