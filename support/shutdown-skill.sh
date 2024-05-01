#!/bin/bash

# Default vendor
vendor="spruce"

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
fi

# Construct the PM2 application name
# Append '-api' if namespace is 'mercury', otherwise '-skill'
if [ "$namespace" = "mercury" ]; then
    app_name="${vendor}-${namespace}-api"
else
    app_name="${vendor}-${namespace}-skill"
fi

# Stop the PM2 process
./support/pm2.sh stop "$app_name" && echo "Successfully stopped ${app_name}" || echo "Failed to stop ${app_name}, it might not be running"
