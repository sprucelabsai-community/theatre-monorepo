#!/bin/bash

# Set DIR to the current working directory
DIR="$(pwd)"

source ./support/hero.sh

# Define the path to the heartwood-skill directory
heartwood_skill_dir="$DIR/packages/spruce-heartwood-skill/dist"

# Check if the heartwood-skill directory exists
if [ ! -d "$heartwood_skill_dir" ]; then
    echo "Error: The $heartwood_skill_dir directory does not exist. You may need to run 'yarn build.heartwood'."
    exit 1
fi

# Create a Caddyfile
echo ":8080
bind 0.0.0.0
root * $heartwood_skill_dir
file_server" >Caddyfile

# Ensure the .processes directory exists
mkdir -p .processes

# Run Caddy and save the PID
caddy run >/dev/null 2>.processes/caddy-heartwood.log &

# Save the PID of the Caddy process in .processes
echo $! >.processes/caddy-heartwood.pid

echo "Starting webserver on 8080..."

# Wait for a few seconds to give Caddy time to start
sleep 1

# Check if Caddy is running on port 8080
if ! nc -zv 127.0.0.1 8080 >/dev/null 2>&1; then
    echo "Error: Caddy did not start successfully. See below for details:"
    cat .processes/caddy-heartwood.log
    exit 1
fi

clear

hero "Heartwood is now serving at http://localhost:8080"
