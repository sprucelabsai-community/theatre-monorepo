#!/bin/bash
set -e

# ────────────────────────────────────────────────────
# Kill any previous serve-heartwood.sh instances
# ────────────────────────────────────────────────────
SCRIPT_NAME="serve-heartwood.sh"
CURRENT_PID=$$

# Get all other running serve-heartwood.sh PIDs (excluding current)
OTHER_PIDS=$(pgrep -f "$SCRIPT_NAME" | grep -v "$CURRENT_PID" || true)

if [ -n "$OTHER_PIDS" ]; then
	echo "Found other running instances of $SCRIPT_NAME: $OTHER_PIDS"
	echo "Terminating previous instances..."
	echo "$OTHER_PIDS" | xargs kill -9 2>/dev/null || true
fi

# ────────────────────────────────────────────────────
# Set DIR to the current working directory
# ────────────────────────────────────────────────────
DIR="$(pwd)"
source ./support/hero.sh
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
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

# ────────────────────────────────────────────────────
# Validate Heartwood installation
# ────────────────────────────────────────────────────
heartwood_skill_dir="$DIR/packages/spruce-heartwood-skill"
if [ ! -d "$heartwood_skill_dir" ]; then
	echo "Heartwood not installed. Skipping server start."
	exit 0
fi

heartwood_dist_dir="$heartwood_skill_dir/dist"
if [ ! -d "$heartwood_dist_dir" ]; then
	echo "Error: The $heartwood_dist_dir directory does not exist. Please run 'yarn bundle.heartwood'."
	exit 0
fi

# ────────────────────────────────────────────────────
# Determine web server port from blueprint.yml
# ────────────────────────────────────────────────────
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

# ────────────────────────────────────────────────────
# Setup (no file logging)
# ────────────────────────────────────────────────────
mkdir -p .processes

# ────────────────────────────────────────────────────
# Delegate any pre-existing Heartwood shutdown to yarn
# ────────────────────────────────────────────────────
yarn stop.serving.heartwood >/dev/null 2>&1 || true

hero "Starting Heartwood..."
echo "Heartwood port: $web_server_port ($port_source)"

# ────────────────────────────────────────────────────
# Create Caddyfile if required
# ────────────────────────────────────────────────────
if [ "$shouldCreateCaddyfile" = true ]; then
	cat >Caddyfile <<EOF
:$web_server_port {
    bind 0.0.0.0
    root * $heartwood_dist_dir
    file_server

    log {
        output file .processes/caddy-access.log {
            roll_size 10mb
            roll_keep 5
        }
        format json
    }
}
EOF
else
	: # Skipping Caddyfile creation
fi

# ────────────────────────────────────────────────────
# Start Caddy
# ────────────────────────────────────────────────────
(caddy run --config ./Caddyfile >/dev/null 2>&1) &
caddy_pid=$!

echo "$caddy_pid" >.processes/caddy-heartwood.pid
echo "Heartwood is serving on port $web_server_port..."
sleep 3

# ────────────────────────────────────────────────────
# Health checks
# ────────────────────────────────────────────────────
if ! ps -p "$caddy_pid" >/dev/null 2>&1; then
	echo "Error: Caddy exited unexpectedly."
	exit 1
fi

if ! nc -zv 127.0.0.1 "$web_server_port" >/dev/null 2>&1; then
	echo "Error: Caddy is not responding on port $web_server_port."
	exit 1
fi
hero "Heartwood is now available at http://localhost:$web_server_port"
