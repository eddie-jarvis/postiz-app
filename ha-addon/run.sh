#!/usr/bin/with-contenv bashio
# ==============================================================================
# Postiz Add-on: Main entry point
# This script is called by s6-overlay's init system.
# Configuration is read from /data/options.json (HA convention).
# The actual initialization happens in /etc/cont-init.d/postiz-init.sh
# and services are managed by s6-rc service definitions.
# ==============================================================================

bashio::log.info "==================================================="
bashio::log.info " Postiz - Social Media Manager"
bashio::log.info " Version: 1.0.0"
bashio::log.info "==================================================="

# Validate JWT_SECRET is changed from default
JWT_SECRET=$(bashio::config 'JWT_SECRET')
if [ "${JWT_SECRET}" = "CHANGE_ME_TO_A_RANDOM_STRING" ]; then
    bashio::log.warning "================================================"
    bashio::log.warning " WARNING: JWT_SECRET is set to the default value!"
    bashio::log.warning " Please change it in the add-on configuration."
    bashio::log.warning " Generating a random one for this session..."
    bashio::log.warning "================================================"
fi

bashio::log.info "Starting s6-overlay managed services..."
bashio::log.info "  - PostgreSQL 17"
bashio::log.info "  - Redis 7"
bashio::log.info "  - Postiz App"

# s6-overlay handles the rest — this script is sourced by the init system
