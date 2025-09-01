#!/bin/bash

source ./support/hero.sh

# does packages/spruce-heartwood-skill exist?
if [ ! -d packages/spruce-heartwood-skill ]; then
	echo "Heartwood not found. Skipping stop serve...."
	exit 0
fi

# Determine web server port from blueprint.yml (fallback to 8080)
blueprint="blueprint.yml"
ENV=$(node support/blueprint.js $blueprint env)
extracted_port=$(echo "$ENV" | jq -r '.heartwood[] | select(has("WEB_SERVER_PORT")) | .WEB_SERVER_PORT' 2>/dev/null)
if [ -n "$extracted_port" ] && [ "$extracted_port" != "null" ]; then
	web_server_port="$extracted_port"
	port_source="blueprint"
else
	web_server_port=8080
	port_source="default"
fi

hero "Shutting down Heartwood..."
echo "Heartwood port: $web_server_port ($port_source)"

# Check if the .processes/caddy-heartwood.pid file exists
if [ -f .processes/caddy-heartwood.pid ]; then
	# Read the PID from the file
	pid=$(cat .processes/caddy-heartwood.pid)

	# Kill the specific Caddy process
	if kill -9 "$pid"; then
		rm .processes/caddy-heartwood.pid
	fi
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
