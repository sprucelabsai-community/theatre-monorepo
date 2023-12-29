#!/bin/bash

# Get PM2 list in JSON format
pm2_json=$(pm2 jlist)

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

    ./support/shutdown-skill.sh "$namespace" "$vendor"
done

echo "Shutdown complete."
