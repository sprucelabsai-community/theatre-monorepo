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
else
    # Use resolve-vendor script to determine the vendor
    vendor=$(./support/resolve-vendor.sh "$namespace")
fi

yarn shutdown "$namespace" "$vendor"
yarn boot "$namespace" "$vendor"
