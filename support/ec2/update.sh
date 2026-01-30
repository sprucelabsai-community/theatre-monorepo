#!/usr/bin/env bash
# update.sh – upload a blueprint and run setup.theatre on an EC2 host
# Usage:
#   ./support/ec2/update.sh /path/to/blueprint.yml

set -euo pipefail

usage() {
	cat <<'HELP'
Usage: support/ec2/update.sh <blueprint.yml>

Reads hosting.ec2.HOST and hosting.ec2.DESTINATION_DIR from the blueprint,
uploads the blueprint to the remote theatre directory, then runs:
  yarn setup.theatre <blueprint>

The remote script always cd's into DESTINATION_DIR before running anything.
HELP
	exit 1
}

resolve_path() {
	if command -v python3 >/dev/null 2>&1; then
		python3 - <<'PY' "$1"
import os
import sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
	elif command -v realpath >/dev/null 2>&1; then
		realpath "$1"
	else
		echo "$1"
	fi
}

blueprint_path=""

for arg in "$@"; do
	case $arg in
	--help)
		usage
		;;
	--blueprint=*)
		blueprint_path="${arg#*=}"
		;;
	*.yml|*.yaml)
		blueprint_path="$arg"
		;;
	*)
		echo "Unknown option: $arg" >&2
		usage
		;;
	esac

done

if [ -z "$blueprint_path" ]; then
	usage
fi

blueprint_abs=$(resolve_path "$blueprint_path")
if [ ! -f "$blueprint_abs" ]; then
	echo "Error: blueprint not found at $blueprint_abs" >&2
	exit 1
fi

root_dir=$(cd "$(dirname "$0")/../.." && pwd)

if ! command -v node >/dev/null 2>&1; then
	echo "Error: node is required to parse blueprint.yml." >&2
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq is required to parse blueprint.yml." >&2
	exit 1
fi

hosting_json=$(node "$root_dir/support/blueprint.js" "$blueprint_abs" hosting)

host=$(echo "$hosting_json" | jq -r '.ec2[]? | select(has("HOST")) | .HOST' | head -n1)
destination_dir=$(echo "$hosting_json" | jq -r '.ec2[]? | select(has("DESTINATION_DIR")) | .DESTINATION_DIR' | head -n1)

if [ -z "$host" ] || [ "$host" = "null" ]; then
	echo "Error: hosting.ec2.HOST is missing in $blueprint_abs" >&2
	exit 1
fi

if [ -z "$destination_dir" ] || [ "$destination_dir" = "null" ]; then
	echo "Error: hosting.ec2.DESTINATION_DIR is missing in $blueprint_abs" >&2
	exit 1
fi

ssh_opts=(-o StrictHostKeyChecking=accept-new)
scp_opts=(-o StrictHostKeyChecking=accept-new)

remote_home=$(ssh "${ssh_opts[@]}" "$host" 'printf "%s" "$HOME"')
if [ -z "$remote_home" ]; then
	echo "Error: could not resolve remote HOME for $host" >&2
	exit 1
fi

case "$destination_dir" in
	/*)
		remote_destination="$destination_dir"
		;;
	*)
		remote_destination="$remote_home/$destination_dir"
		;;
esac

remote_blueprint_path="$remote_home/blueprint.yml"
remote_script="update-remote.sh"

# Ensure destination exists before uploading blueprint
check_cmd="test -d $(printf '%q' "$remote_destination")"
if ! ssh "${ssh_opts[@]}" "$host" "$check_cmd" >/dev/null; then
	echo "Error: destination directory not found on host: $remote_destination" >&2
	exit 1
fi

echo "→ Copying $blueprint_abs to $host:$remote_blueprint_path …"
scp "${scp_opts[@]}" "$blueprint_abs" "$host:$remote_blueprint_path"

echo "→ Copying update helper to $host:~/$remote_script …"
scp "${scp_opts[@]}" "$root_dir/support/ec2/update-remote.sh" "$host:~/$remote_script"

remote_cmd="chmod +x ~/$remote_script && ~/$remote_script"
remote_cmd+=" --destination=$(printf '%q' "$remote_destination")"
remote_cmd+=" --blueprint=$(printf '%q' "$remote_blueprint_path")"

echo "→ Executing on remote host …"
ssh "${ssh_opts[@]}" "$host" "$remote_cmd"

echo "✓ Done"
