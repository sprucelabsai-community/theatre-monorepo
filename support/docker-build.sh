#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'HELP'
Usage: ./support/docker-build.sh [options]

Options:
  --blueprint=PATH   Path to blueprint.yml (default: ./blueprint.yml)
  --image=NAME       Docker image name (default: theatre-local)
  --tag=TAG          Docker image tag (default: latest)
  --platform=PLAT    Docker platform (default: linux/arm64)
  --help             Show this help and exit
HELP
}

blueprint_path=""
image_name="theatre-local"
image_tag="latest"
platform="linux/arm64"

for arg in "$@"; do
	case $arg in
	--blueprint=*)
		blueprint_path="${arg#*=}"
		;;
	--image=*)
		image_name="${arg#*=}"
		;;
	--tag=*)
		image_tag="${arg#*=}"
		;;
	--platform=*)
		platform="${arg#*=}"
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
	read -r -p "Blueprint path [blueprint.yml]: " blueprint_path
	if [ -z "$blueprint_path" ]; then
		blueprint_path="blueprint.yml"
	fi
fi

root_dir=$(cd "$(dirname "$0")/.." && pwd)
cd "$root_dir"

if ! command -v node >/dev/null 2>&1; then
	echo "Error: node is required to parse blueprint.yml." >&2
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq is required to parse blueprint.yml." >&2
	exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "Error: docker is required to build the image." >&2
	exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
	echo "Error: docker buildx is required (Docker Desktop or buildx plugin)." >&2
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

if ! node -e "require('js-yaml')" >/dev/null 2>&1; then
	echo "Error: js-yaml is missing. Run 'yarn install' in the repo root." >&2
	exit 1
fi

theatre_json=$(node "$root_dir/support/blueprint.js" "$blueprint_abs" theatre)
should_serve_heartwood=$(echo "$theatre_json" | jq -r '.SHOULD_SERVE_HEARTWOOD')

install_caddy=true
if [ "$should_serve_heartwood" = "false" ]; then
	install_caddy=false
fi

env_json=$(node "$root_dir/support/blueprint.js" "$blueprint_abs" env)
db_connection=$(echo "$env_json" | jq -r '.universal[]? | select(has("DB_CONNECTION_STRING")) | .DB_CONNECTION_STRING' | head -n1)

install_mongo=true
if [ -n "$db_connection" ] && [ "$db_connection" != "null" ]; then
	case "$db_connection" in
		*localhost*|*127.0.0.1*)
			install_mongo=true
			;;
		*)
			install_mongo=false
			;;
	esac
fi

blueprint_rel=""
tmp_blueprint=""
if [[ "$blueprint_abs" == "$root_dir"/* ]]; then
	blueprint_rel="${blueprint_abs#"$root_dir"/}"
else
	mkdir -p "$root_dir/.tmp"
	blueprint_rel=".tmp/blueprint.docker.yml"
	tmp_blueprint="$root_dir/$blueprint_rel"
	cp "$blueprint_abs" "$tmp_blueprint"
fi

cleanup() {
	if [ -n "$tmp_blueprint" ] && [ -f "$tmp_blueprint" ]; then
		rm -f "$tmp_blueprint"
	fi
}
trap cleanup EXIT

if [ -z "${SSH_AUTH_SOCK:-}" ]; then
	echo "Warning: SSH_AUTH_SOCK is not set. Private repos may fail to clone." >&2
fi

image_ref="${image_name}:${image_tag}"

echo "Building image: $image_ref"
echo "Blueprint: $blueprint_abs"
echo "Platform: $platform"
echo "Install Mongo: $install_mongo"
echo "Install Caddy: $install_caddy"

docker buildx build \
	--platform "$platform" \
	--build-arg BLUEPRINT_PATH="$blueprint_rel" \
	--build-arg INSTALL_MONGO="$install_mongo" \
	--build-arg INSTALL_CADDY="$install_caddy" \
	-t "$image_ref" \
	--load \
	-f "$root_dir/support/docker/Dockerfile" \
	"$root_dir"
