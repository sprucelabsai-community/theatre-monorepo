#!/bin/bash

# Default vendor
vendor="spruce"

source ./support/hero.sh

# Check for at least one argument
if [ $# -lt 1 ]; then
	echo "Usage: $0 <namespace> [vendor]"
	echo "Example: $0 heartwood"
	exit 1
fi

# Assign arguments
namespace="$1"
if [ $# -ge 2 ]; then
	vendor="$2"
else
	# Use resolve-vendor script to determine the vendor
	vendor=$(./support/resolve-vendor.sh "$namespace")
fi

# Construct the PM2 application name
if [ "$namespace" = "message-receiver" ]; then
	app_name="message-receiver"
elif [ "$namespace" = "message-sender" ]; then
	app_name="message-sender"
elif [ "$namespace" = "mercury" ]; then
	app_name="${vendor}-${namespace}-api"
else
	app_name="${vendor}-${namespace}-skill"
fi

# Stop the PM2 process
./support/pm2.sh stop "$app_name" && echo "Successfully stopped ${app_name}" || echo "Failed to stop ${app_name}, it might not be running"

hero "Shutdown of ${namespace} complete."
