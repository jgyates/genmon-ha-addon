#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

CONF_DIR=/data/genmon/
LOG_DIR=/data/log/
GENMON_CONF="${CONF_DIR}genmon.conf"
PLACEHOLDER_PORT=/run/genmon/no-serial-port

set_genmon() {
    genmon-setconf "${GENMON_CONF}" GenMon "$1" "$2" || bashio::log.warning "Could not set $1"
}

stop_genmon() {
    bashio::log.info "Stopping genmon..."
    python3 /genmon/genloader.py -x -c "${CONF_DIR}"
    nginx -s quit 2>/dev/null
}

mkdir -p "${CONF_DIR}" "${LOG_DIR}"

# Seed missing config files only; existing user settings are kept
for f in /genmon/conf/*.conf; do
    if [ ! -f "${CONF_DIR}$(basename "${f}")" ]; then
        bashio::log.info "Adding default $(basename "${f}")"
        cp "${f}" "${CONF_DIR}"
    fi
done

# Required by the container layout (persistent logs, nginx proxy target, plain HTTP for ingress)
set_genmon loglocation "${LOG_DIR}"
set_genmon http_port 8000
set_genmon usehttps False

# App options override genmon.conf only when set
if bashio::config.has_value 'serial_port'; then
    set_genmon port "$(bashio::config 'serial_port')"
fi
if bashio::config.has_value 'use_serial_tcp'; then
    set_genmon use_serial_tcp "$(bashio::config 'use_serial_tcp')"
fi
if bashio::config.has_value 'serial_tcp_address'; then
    set_genmon serial_tcp_address "$(bashio::config 'serial_tcp_address')"
fi
if bashio::config.has_value 'serial_tcp_port'; then
    set_genmon serial_tcp_port "$(bashio::config 'serial_tcp_port')"
fi
if bashio::config.has_value 'modbus_tcp'; then
    set_genmon modbus_tcp "$(bashio::config 'modbus_tcp')"
fi

bashio::log.info "Starting ingress proxy..."
nginx || bashio::exit.nok "nginx failed to start"

# Calling exit from a trap while inside a function corrupts bash state, so only set a flag
stopping=false
trap 'stopping=true' TERM INT

read_genmon() {
    sed -n -E "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*(.*[^[:space:]])?[[:space:]]*$/\1/p" "${GENMON_CONF}" | head -n 1
}

check_connection() {
    local port
    STATUS_NOTE=""
    if [ "$(read_genmon use_serial_tcp | tr '[:upper:]' '[:lower:]')" = "true" ]; then
        bashio::log.info "Generator connection: TCP $(read_genmon serial_tcp_address):$(read_genmon serial_tcp_port)"
        return
    fi
    port="$(read_genmon port)"
    if [ "${port}" = "${PLACEHOLDER_PORT}" ]; then
        start_placeholder
        STATUS_NOTE="No serial port is configured yet. Genmon will start with a placeholder port - set the real port in Settings."
        bashio::log.warning "No serial port configured - genmon runs with a placeholder port and shows communication errors until a real port is set in the genmon web UI (Settings)."
        log_serial_devices
    elif [ -e "${port}" ]; then
        bashio::log.info "Generator connection: serial port ${port}"
    else
        STATUS_NOTE="Serial port ${port} does not exist. Genmon will start with a placeholder port - set the real port in Settings."
        bashio::log.warning "Serial port '${port}' does not exist."
        log_serial_devices
        # /dev is read-only in the container, so the placeholder lives elsewhere and genmon.conf is pointed at it
        bashio::log.warning "Switching genmon to a placeholder port so the web UI can start. Set the real port in the genmon web UI (Settings) or the app Configuration tab."
        start_placeholder
        set_genmon port "${PLACEHOLDER_PORT}"
    fi
}

log_serial_devices() {
    bashio::log.warning "Available serial devices: $(ls /dev/ttyUSB* /dev/ttyACM* /dev/ttyAMA* /dev/ttyS[0-9] /dev/serial/by-id/* 2>/dev/null | tr '\n' ' ')"
    if [ -e /dev/ttyAMA10 ] && [ ! -e /dev/ttyAMA0 ]; then
        bashio::log.warning "/dev/ttyAMA10 is the Pi 5 debug connector, not GPIO 14/15. Add 'dtparam=uart0=on' to config.txt on the HAOS boot partition to get /dev/ttyAMA0."
    fi
}

start_placeholder() {
    if ! pgrep -f "genmon-placeholder-port" >/dev/null; then
        genmon-placeholder-port "${PLACEHOLDER_PORT}" &
        sleep 1
    fi
}

start_genmon() {
    bashio::log.info "Starting genmon..."
    genmon-status starting "${STATUS_NOTE}"
    state=starting
    python3 /genmon/genloader.py -s -c "${CONF_DIR}"
}

# Started before genmon so startup errors are shown in the app log
tail -F -n 0 "${LOG_DIR}genloader.log" "${LOG_DIR}genmon.log" "${LOG_DIR}genserv.log" 2>/dev/null &

state=""
check_connection
start_genmon

# Grace period covers the web UI "Restart"; afterwards retry with backoff instead of exiting
missing=0
retry_after=60
while ! ${stopping}; do
    sleep 10 &
    wait $!
    if ${stopping}; then
        break
    fi
    if pgrep -f "/genmon/genmon\.py" >/dev/null; then
        missing=0
        retry_after=60
        if [ "${state}" != "running" ]; then
            genmon-status running "${STATUS_NOTE}"
            state=running
        fi
    else
        missing=$((missing + 10))
        if [ "${state}" != "error" ]; then
            genmon-status error "Genmon stopped unexpectedly." $((retry_after - missing))
            state=error
        fi
        if [ "${missing}" -ge "${retry_after}" ]; then
            bashio::log.error "genmon.py is not running - see ${LOG_DIR}genmon.log. Retrying..."
            check_connection
            start_genmon
            missing=0
            if [ "${retry_after}" -lt 600 ]; then
                retry_after=$((retry_after * 2))
            fi
        fi
    fi
done

stop_genmon
