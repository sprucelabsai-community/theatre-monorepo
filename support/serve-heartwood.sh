#!/bin/bash

set -e

# Set DIR to the current working directory
DIR="$(pwd)"

source ./support/hero.sh

# Default value for shouldCreateCaddyfile
shouldCreateCaddyfile=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --shouldCreateCaddyfile=*)
        shouldCreateCaddyfile="${key#*=}"
        shift
        ;;
    *)
        # Unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Define the path to the heartwood-skill directory
heartwood_skill_dir="$DIR/packages/spruce-heartwood-skill/dist"

# Check if the heartwood-skill directory exists
if [ ! -d "$heartwood_skill_dir" ]; then
    echo "Error: The $heartwood_skill_dir directory does not exist. You may need to run 'yarn bundle.heartwood'."
    exit 0
fi

web_server_port=8080

# look inside packages/spruce-heartwood-skill/.env
# if it exists, source it
if [ -f "$heartwood_skill_dir/.env" ]; then
    source "$heartwood_skill_dir/.env"
    # if WEB_SERVER_PORT is set, use it
    web_server_port=${WEB_SERVER_PORT:-8080}
fi

# Create a Caddyfile if shouldCreateCaddyfile is true
if [ "$shouldCreateCaddyfile" = true ]; then
    echo ":$web_server_port {
    bind 0.0.0.0
    root * $heartwood_skill_dir
    file_server
}" >Caddyfile
    echo "Caddyfile created."
else
    echo "Skipping Caddyfile creation."
fi

# Ensure the .processes directory exists
mkdir -p .processes

# Run Caddy and save the PID
caddy run >/dev/null 2>.processes/caddy-heartwood.log &

# Save the PID of the Caddy process in .processes
echo $! >.processes/caddy-heartwood.pid

echo "Starting webserver on $web_server_port..."

# Wait for a few seconds to give Caddy time to start
sleep 1

# Check if Caddy is running on port $web_server_port
if ! nc -zv 127.0.0.1 $web_server_port >/dev/null 2>&1; then
    echo "Error: Caddy did not start successfully. See below for details:"
    cat .processes/caddy-heartwood.log
    exit 1
fi

hero "Heartwood is now serving at http://localhost:$web_server_port"
