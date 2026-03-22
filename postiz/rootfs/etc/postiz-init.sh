#!/command/with-contenv bashio

bashio::log.info "Initializing Postiz add-on..."

JWT_SECRET=$(bashio::config 'JWT_SECRET')
MAIN_URL=$(bashio::config 'MAIN_URL')
IS_GENERAL=$(bashio::config 'IS_GENERAL')
DISABLE_REGISTRATION=$(bashio::config 'DISABLE_REGISTRATION')
MAIN_URL="${MAIN_URL%/}"
[ -z "${MAIN_URL}" ] && MAIN_URL="http://localhost:5000"

bashio::log.info "Postiz URL: ${MAIN_URL}"

cat > /etc/postiz-env <<EOF
DATABASE_URL=postgresql://postiz:postiz-password@localhost:5433/postiz-db
REDIS_URL=redis://localhost:6380
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
TEMPORAL_ADDRESS=
DISABLE_TEMPORAL=true
EOF

mkdir -p /data/postgres /data/redis /run/postgresql /uploads
chown -R postgres:postgres /data/postgres /run/postgresql
chmod 700 /data/postgres

# Only run initdb - do NOT start postgres here
if [ ! -f /data/postgres/PG_VERSION ]; then
    bashio::log.info "First run — initializing PostgreSQL data..."
    s6-setuidgid postgres /usr/lib/postgresql/17/bin/initdb -D /data/postgres --auth=trust --encoding=UTF8 --locale=C --username=postgres 2>&1
    chown -R postgres:postgres /data/postgres
    
    echo "listen_addresses = 'localhost'" >> /data/postgres/postgresql.conf
    echo "port = 5433" >> /data/postgres/postgresql.conf
    echo "unix_socket_directories = '/run/postgresql'" >> /data/postgres/postgresql.conf
    
    printf "local all all trust\nhost all all 127.0.0.1/32 trust\nhost all all ::1/128 trust\n" > /data/postgres/pg_hba.conf
    
    # Mark that we need to create user/db on first real start
    touch /data/.needs_db_setup
    bashio::log.info "PostgreSQL data initialized."
else
    bashio::log.info "PostgreSQL data exists."
fi

bashio::log.info "Init complete."
