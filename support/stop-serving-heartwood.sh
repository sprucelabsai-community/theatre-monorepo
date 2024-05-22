#!/bin/bash

source ./support/hero.sh

# Check if the .processes/caddy-heartwood.pid file exists
if [ -f .processes/caddy-heartwood.pid ]; then
    # Read the PID from the file
    pid=$(cat .processes/caddy-heartwood.pid)

    # Kill the specific Caddy process
    if kill -9 "$pid"; then
        rm .processes/caddy-heartwood.pid
        clear
        hero "Heartwood is no longer serving."
    else
        echo "Error: Failed to stop Heartwood."
    fi
else
    echo "PID file not found. Falling back to killing all Caddy processes."
    pkill caddy
    clear
    hero "Heartwood is no longer serving."
fi
