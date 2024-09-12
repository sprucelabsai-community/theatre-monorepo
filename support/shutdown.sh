#!/bin/bash

# if any arguments are passed, call shutdown-skill.sh and pass everything through
if [ "$#" -gt 0 ]; then
    ./support/shutdown-skill.sh "$@"
    exit 0
fi

source ./support/hero.sh

# Function to get PM2 list in JSON format
get_pm2_json() {
    pm2_json=$(./support/pm2.sh jlist 2>&1) # Capture stderr as well
    echo "$pm2_json"
}

# Try to get PM2 list
pm2_json=$(get_pm2_json)
#
# Check if pm2 jlist was successful
if ! echo "$pm2_json" | jq empty; then
    echo "pm2 jlist failed, attempting to update PM2 and retry."

    # Update PM2 and retry
    ./support/pm2.sh update
    pm2_json=$(get_pm2_json)

    # Check again if pm2 jlist was successful
    if ! echo "$pm2_json" | jq empty; then
        echo "pm2 jlist failed again after update. Exiting script."
        exit 1
    fi
fi

# Loop through each application
echo "$pm2_json" | jq -r '.[] | .name' | while read -r app_name; do
    # Skip empty lines
    if [ -z "$app_name" ]; then
        continue
    fi

    # Assume app_name is formatted as 'vendor-namespace-suffix'
    IFS='-' read -ra ADDR <<<"$app_name"
    vendor="${ADDR[0]}"
    namespace="${ADDR[1]}"

    if [ "$namespace" == "mercury" ]; then
        vendor="spruce"
    fi

    ./support/shutdown-skill.sh "$namespace" "$vendor" >/dev/null &
done

if [ ! -d packages/spruce-heartwood-skill ]; then
    hero "All skills shutdown."
else
    yarn stop.serving.heartwood
    wait
    hero "All skills shutdown and Heartwood is no longer serving."
fi

yarn list.running
