#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

SERVICE_KEY=$(bashio::config 'service_key')
LOG_LEVEL=$(bashio::config 'log_level')
export LOG_LEVEL

if [ -z "${SERVICE_KEY}" ]; then
    bashio::log.fatal "No service_key configured. Generate one in Twingate Admin > Service Accounts."
    exit 1
fi

bashio::log.info "Creating TUN device..."
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

bashio::log.info "Writing service key..."
echo "${SERVICE_KEY}" > /etc/twingate/service_key.json
chmod 600 /etc/twingate/service_key.json

bashio::log.info "Configuring Twingate headless client..."
twingate setup --headless /etc/twingate/service_key.json

bashio::log.info "Starting Twingate client..."
exec twingate start
