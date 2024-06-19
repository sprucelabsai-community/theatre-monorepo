#!/bin/bash

source ./support/hero.sh

# does packages/spruce-heartwood-skill exist?
if [ ! -d packages/spruce-heartwood-skill ]; then
    echo "Heartwood not found, skipping...."
    exit 0
fi

# Check if the .processes/caddy-heartwood.pid file exists
if [ -f .processes/caddy-heartwood.pid ]; then
    # Read the PID from the file
    pid=$(cat .processes/caddy-heartwood.pid)

    # Kill the specific Caddy process
    if kill -9 "$pid"; then
        rm .processes/caddy-heartwood.pid
        hero "Heartwood is no longer serving."
    else
        echo "Error: Failed to stop Heartwood."
    fi
fi
