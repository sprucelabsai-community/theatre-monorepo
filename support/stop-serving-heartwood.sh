#!/bin/bash

source ./support/hero.sh

# does packages/spruce-heartwood-skill exist?
if [ ! -d packages/spruce-heartwood-skill ]; then
    echo "Heartwood not found. Skipping stop serve...."
    exit 0
fi

# Check if the .processes/caddy-heartwood.pid file exists
if [ -f .processes/caddy-heartwood.pid ]; then
    # Read the PID from the file
    pid=$(cat .processes/caddy-heartwood.pid)

    # Kill the specific Caddy process
    if kill -9 "$pid"; then
        rm .processes/caddy-heartwood.pid
    fi
fi

web_server_port=8080
if [ -f "$heartwood_dist_dir/../.env" ]; then
    source "$heartwood_dist_dir/../.env"
    web_server_port=${WEB_SERVER_PORT:-8080}
fi

if ! command -v lsof &>/dev/null; then
    echo "Warning: 'lsof' is not installed. Skipping orphaned Caddy process cleanup."
    skip_lsof=true
else
    skip_lsof=false
fi

# Kill any orphaned caddy processes on the specified port
if [ "$skip_lsof" = false ]; then
    CADDY_PIDS=$(lsof -ti :$web_server_port -sTCP:LISTEN | xargs ps -o pid=,comm= | grep caddy | awk '{print $1}' || true)

    if [ -n "$CADDY_PIDS" ]; then
        echo "Terminating orphaned Caddy processes on port $web_server_port: $CADDY_PIDS"
        echo "$CADDY_PIDS" | xargs kill -9 2>/dev/null || true
    fi
else
    echo "Skipping orphaned Caddy process cleanup due to missing 'lsof'."
fi
