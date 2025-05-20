#!/bin/bash

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Pass in a namespace or dir name and optionally a vendor, and get back the dir name"
    echo ""
    echo "Usage: $0 <namespaceOrDirName> [vendor]"
    exit 1
fi

namespace="$1"

# Use the vendor provided as an argument if available; otherwise, use resolve-vendor.sh
if [ $# -ge 2 ] && [ -n "$2" ]; then
    vendor="$2"
else
    vendor=$(./support/resolve-vendor.sh "$namespace")
fi

# Set directory name based on namespace and vendor
if [ "$namespace" == "mercury" ]; then
    skill_dir_name="spruce-mercury-api"
elif [ "$vendor" ]; then
    skill_dir_name="${vendor}-${namespace}-skill"
else
    skill_dir_name="$namespace"
fi

if [ ! -d "./packages/$skill_dir_name" ]; then
    echo "The directory '$skill_dir_name' does not exist in ./packages."
    exit 1
fi

echo "$skill_dir_name"
