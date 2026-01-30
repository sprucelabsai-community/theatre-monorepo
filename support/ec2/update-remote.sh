#!/usr/bin/env bash
# update-remote.sh – run setup.theatre inside an existing EC2 theatre directory

set -euo pipefail

destination=""
blueprint=""

usage() {
	cat <<'HELP'
Usage: update-remote.sh --destination=DIR --blueprint=PATH

This script always cd's into DESTINATION before running anything else,
then runs: yarn setup.theatre <blueprint>
HELP
	exit 1
}

for arg in "$@"; do
	case $arg in
	--destination=*)
		destination="${arg#*=}"
		;;
	--blueprint=*)
		blueprint="${arg#*=}"
		;;
	--help)
		usage
		;;
	*)
		echo "Unknown option: $arg" >&2
		usage
		;;
	esac

done

if [ -z "$destination" ] || [ -z "$blueprint" ]; then
	usage
fi

cd "$destination"

if [ "$blueprint" != "blueprint.yml" ] && [ "$blueprint" != "$destination/blueprint.yml" ]; then
	cp "$blueprint" "./blueprint.yml"
	blueprint="blueprint.yml"
fi

yarn setup.theatre "$blueprint"
