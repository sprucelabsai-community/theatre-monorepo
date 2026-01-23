#!/usr/bin/env bash

set -euo pipefail

cd /theatre

export PATH="/root/.yarn/bin:/root/.config/yarn/global/node_modules/.bin:$PATH"

install_mongo="${INSTALL_MONGO:-false}"

if [ "$install_mongo" = "true" ]; then
	mkdir -p /data/db /var/log
	if ! pgrep -x mongod >/dev/null 2>&1; then
		echo "Starting MongoDB..."
		mongod --fork --logpath /var/log/mongodb.log --dbpath /data/db || {
			echo "MongoDB failed to start." >&2
			exit 1
		}
	fi
fi

setup_marker=".theatre_setup_done"

if [ ! -f "$setup_marker" ]; then
	echo "Running initial theatre setup (publish + boot)..."
	yarn setup.theatre blueprint.yml --startFrom=publish --bootStrategy=serial
	touch "$setup_marker"
else
	echo "Booting theatre..."
	yarn boot
fi

exec ./support/pm2.sh logs --lines 100
