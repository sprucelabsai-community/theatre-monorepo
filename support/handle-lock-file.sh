#!/bin/bash

# Ensure the blueprint argument is provided
if [ $# -lt 1 ]; then
    echo "Usage: ./handle-lock-file.sh <blueprint.yml>"
    exit 1
fi

blueprint=$1

if [ ! -f "$blueprint" ]; then
    echo "Error: Blueprint file '$blueprint' does not exist."
    exit 1
fi

# Extract the theatre section and LOCK value
THEATRE=$(node support/blueprint.js "$blueprint" theatre)
LOCK=$(echo "$THEATRE" | jq -r '.LOCK' 2>/dev/null)

if [ "$LOCK" != null ] && [ -n "$LOCK" ]; then
    echo "Downloading lock file..."
    curl -O "$LOCK"
else
    echo "No lock file defined in blueprint. Removing yarn.log..."
    rm -f yarn.lock
fi
