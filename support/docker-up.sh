#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'HELP'
Usage: ./support/docker-up.sh --blueprint=PATH [--network=NAME]

Options:
  --blueprint=PATH   Path to blueprint.yml (required)
  --network=NAME     Docker network name (default: current directory name)
  --help             Show this help and exit
HELP
}

blueprint_path=""
network_name=""

for arg in "$@"; do
	case $arg in
	--blueprint=*)
		blueprint_path="${arg#*=}"
		;;
	--network=*)
		network_name="${arg#*=}"
		;;
	--help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $arg" >&2
		usage >&2
		exit 1
		;;
	esac
done

if [ -z "$blueprint_path" ]; then
	echo "Error: --blueprint is required." >&2
	usage >&2
	exit 1
fi

root_dir=$(cd "$(dirname "$0")/.." && pwd)
project_name=$(basename "$root_dir")

if [ -z "$network_name" ]; then
	network_name="$project_name"
fi

if ! command -v node >/dev/null 2>&1; then
	echo "Error: node is required to parse blueprint.yml." >&2
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq is required to parse blueprint.yml." >&2
	exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "Error: docker is required." >&2
	exit 1
fi

resolve_path() {
	if command -v python3 >/dev/null 2>&1; then
		python3 - <<'PY' "$1"
import os
import sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
	else
		echo "$1"
	fi
}

blueprint_abs=$(resolve_path "$blueprint_path")

if [ ! -f "$blueprint_abs" ]; then
	echo "Error: blueprint.yml not found at $blueprint_abs" >&2
	exit 1
fi

if grep -q '<<[^>]*>>' "$blueprint_abs"; then
	echo "Error: blueprint.yml contains placeholders. Run 'yarn fill.out.blueprint' first." >&2
	exit 1
fi

env_json=$(node "$root_dir/support/blueprint.js" "$blueprint_abs" env)

theatre_json=$(node "$root_dir/support/blueprint.js" "$blueprint_abs" theatre)
should_serve_heartwood=$(echo "$theatre_json" | jq -r '.SHOULD_SERVE_HEARTWOOD')

install_caddy=true
if [ "$should_serve_heartwood" = "false" ]; then
	install_caddy=false
fi

db_connection=$(echo "$env_json" | jq -r '.universal[]? | select(has("DB_CONNECTION_STRING")) | .DB_CONNECTION_STRING' | head -n1)

if [ -z "$db_connection" ] || [ "$db_connection" = "null" ]; then
	echo "Error: DB_CONNECTION_STRING is missing in blueprint." >&2
	exit 1
fi

mongo_host=$(printf '%s' "$db_connection" | sed -E 's|^mongodb(\+srv)?://||' | sed -E 's|^[^@]*@||' | cut -d'/' -f1 | cut -d':' -f1)

install_mongo=true
if [ -n "$mongo_host" ]; then
	case "$mongo_host" in
		localhost|127.0.0.1)
			install_mongo=true
			;;
		mongo)
			install_mongo=false
			;;
		*)
			install_mongo=false
			;;
	esac
fi

heartwood_port=$(echo "$env_json" | jq -r '.heartwood[]? | select(has("WEB_SERVER_PORT")) | .WEB_SERVER_PORT' | head -n1)
if [ -z "$heartwood_port" ] || [ "$heartwood_port" = "null" ]; then
	heartwood_port=8080
fi

mercury_port=$(echo "$env_json" | jq -r '.mercury[]? | select(has("PORT")) | .PORT' | head -n1)
if [ -z "$mercury_port" ] || [ "$mercury_port" = "null" ]; then
	mercury_port=8081
fi

mongo_user=""
mongo_pass=""
if printf '%s' "$db_connection" | grep -q '@'; then
	creds=$(printf '%s' "$db_connection" | sed -E 's|^mongodb(\+srv)?://||' | cut -d'@' -f1)
	mongo_user=$(printf '%s' "$creds" | cut -d':' -f1)
	mongo_pass=$(printf '%s' "$creds" | cut -d':' -f2-)
fi

ensure_network() {
	local name=$1
	if ! docker network inspect "$name" >/dev/null 2>&1; then
		echo "Creating network $name"
		docker network create "$name" >/dev/null
	fi
}

find_free_port() {
	local port=$1
	while true; do
		if ! lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
			echo "$port"
			return
		fi
		port=$((port + 1))
	done
}

ensure_network "$network_name"

mongo_container_name="${network_name}-mongo"
theatre_container_name="${network_name}-theatre"
mongo_volume_dir="$root_dir/.docker-mongo-data-${network_name}"

mongo_port_host=""

if [ "$mongo_host" = "mongo" ]; then
	mongo_port_host=$(find_free_port 27017)

	if docker ps -a --format '{{.Names}}' | grep -q "^${mongo_container_name}$"; then
		echo "Mongo container ${mongo_container_name} already exists."
		if ! docker ps --format '{{.Names}}' | grep -q "^${mongo_container_name}$"; then
			docker start "$mongo_container_name" >/dev/null
		fi
	else
		mkdir -p "$mongo_volume_dir"

		mongo_env=()
		if [ -n "$mongo_user" ] && [ -n "$mongo_pass" ]; then
			mongo_env+=("-e" "MONGO_INITDB_ROOT_USERNAME=$mongo_user")
			mongo_env+=("-e" "MONGO_INITDB_ROOT_PASSWORD=$mongo_pass")
		fi

		docker run -d \
			--name "$mongo_container_name" \
			--network "$network_name" \
			-p "${mongo_port_host}:27017" \
			-v "$mongo_volume_dir:/data/db" \
			"${mongo_env[@]}" \
			mongo:6 >/dev/null
	fi
fi

echo "Building theatre image..."
cd "$root_dir"
	yarn build.docker --blueprint="$blueprint_abs"

if docker ps -a --format '{{.Names}}' | grep -q "^${theatre_container_name}$"; then
	echo "Removing existing theatre container ${theatre_container_name}..."
	docker rm -f "$theatre_container_name" >/dev/null
fi

run_args=(
	"--name" "$theatre_container_name"
	"--network" "$network_name"
	"-p" "${heartwood_port}:${heartwood_port}"
	"-p" "${mercury_port}:${mercury_port}"
)

if [ "$install_mongo" = "true" ]; then
	run_args+=("-e" "INSTALL_MONGO=true")
else
	run_args+=("-e" "INSTALL_MONGO=false")
fi

if [ "$install_caddy" = "true" ]; then
	run_args+=("-e" "INSTALL_CADDY=true")
else
	run_args+=("-e" "INSTALL_CADDY=false")
fi

if [ "$mongo_host" = "mongo" ]; then
	echo "Mongo exposed on host port ${mongo_port_host}."
	echo "Mongo container: ${mongo_container_name}"
fi


docker run -d "${run_args[@]}" theatre-local:latest >/dev/null

echo "Theatre container: ${theatre_container_name}"
echo "Heartwood: http://localhost:${heartwood_port}"
echo "Mercury: http://localhost:${mercury_port}"
