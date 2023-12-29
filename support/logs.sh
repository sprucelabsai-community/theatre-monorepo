#!/bin/bash

# Default vendor
vendor="spruce"

# Check for at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: yarn logs <namespace> [vendor]"
    echo "Example: yarn logs heartwood"
    exit 1
fi

# Assign arguments
namespace="$1"
if [ $# -ge 2 ]; then
    vendor="$2"
fi

# Construct the application name
# Append '-api' if namespace is 'mercury', otherwise '-skill'
if [ "$namespace" = "mercury" ]; then
    app_name="${vendor}-${namespace}-api"
else
    app_name="${vendor}-${namespace}-skill"
fi

# Show logs for the specified application
echo "Showing logs for ${app_name}..."
pm2 logs "$app_name"
