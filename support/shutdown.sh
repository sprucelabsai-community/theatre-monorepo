#!/bin/bash

shouldListRunning=true
positional_args=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --shouldListRunning=*)
        shouldListRunning="${1#*=}"
        shift
        ;;
    *)
        positional_args+=("$1")
        shift
        ;;
    esac
done

# If there are positional arguments, call shutdown-skill.sh and pass them through
if [ ${#positional_args[@]} -gt 0 ]; then
    ./support/shutdown-skill.sh "${positional_args[@]}"
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

# Check if pm2 jlist was successful
if ! echo "$pm2_json" | jq empty; then
    echo "Getting PM2 list failed. Going to update PM2 and retry..."

    # Update PM2 and retry
    ./support/pm2.sh update
    pm2_json=$(get_pm2_json)

    # Check again if pm2 jlist was successful
    if ! echo "$pm2_json" | jq empty; then
        echo "Failed to get PM2 list. Exiting..."
        exit 0
    fi
fi

# Loop through each application
echo "$pm2_json" | jq -r '.[] | .name' | while read -r app_name; do
    # Skip empty lines
    if [ -z "$app_name" ]; then
        continue
    fi

    # Check if the app_name has 2 or 3 segments
    IFS='-' read -ra ADDR <<<"$app_name"
    if [ ${#ADDR[@]} -eq 3 ]; then
        # If app_name has two segments: vendor-name-skill
        vendor="${ADDR[0]}"
        namespace="${ADDR[1]}"
    elif [ ${#ADDR[@]} -eq 4 ]; then
        # If app_name has three segments: vendor-name1-name2-skill
        vendor="${ADDR[0]}"
        namespace="${ADDR[1]}-${ADDR[2]}"
    elif [ "$app_name" == "message-receiver" ]; then
        continue
    else
        echo "Invalid app name format: $app_name"
        continue
    fi

    if [ "$namespace" == "mercury" ]; then
        vendor="spruce"
    fi

    ./support/shutdown-skill.sh "$namespace" "$vendor" >/dev/null &
done

if [ ! -d packages/spruce-heartwood-skill ]; then
    hero "All skills shutdown"
else
    yarn stop.serving.heartwood
    wait
    hero "All skills shutdown"
fi

if [ -f .processes/message-receiver ]; then
    hero "Shutting down message receiver..."
    ./support/pm2.sh stop "message-receiver"
fi

# Check if shouldListRunning is true before running yarn list.running
if [ "$shouldListRunning" = true ]; then
    yarn list.running
fi

# kill pm2
./support/pm2.sh kill
