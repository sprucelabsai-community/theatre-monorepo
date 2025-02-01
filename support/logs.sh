#!/bin/bash

# Default number of lines
lines=15 # Default value, change if you want a different default

# Parse arguments
namespace=""
for arg in "$@"; do
    if [[ "$arg" == --lines=* ]]; then
        lines="${arg#*=}"
    elif [ -z "$namespace" ]; then
        namespace="$arg"
    else
        vendor="$arg"
    fi
done

# Check for at least one argument
if [ $# -lt 1 ]; then
    ./support/pm2.sh logs --lines "$lines"
    exit 0
fi

# Validate namespace
if [ -z "$namespace" ]; then
    echo "Error: Namespace not specified."
    exit 1
fi

# If vendor is not provided, use the resolve-vendor.sh script to determine the vendor
if [ -z "$vendor" ]; then
    vendor=$(./support/resolve-vendor.sh "$namespace")
fi

# Construct the application name
if [ "$namespace" = "message-receiver" ]; then
    app_name="message-receiver"
elif [ "$namespace" = "mercury" ]; then
    app_name="${vendor}-${namespace}-api"
else
    app_name="${vendor}-${namespace}-skill"
fi

# Show logs for the specified application
echo "Showing last $lines lines of logs for ${app_name}..."
./support/pm2.sh logs "$app_name" --lines "$lines"
