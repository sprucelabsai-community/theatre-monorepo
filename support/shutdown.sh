#!/bin/bash

processes_dir="$(pwd)/.processes"

# Ensure the .processes directory exists
if [ ! -d "$processes_dir" ]; then
    echo "Platform not running..."
    exit 1
fi

# Loop through all files in the .processes directory
for pid_file in "$processes_dir"/*.pid; do
    # Check if the file exists
    if [ ! -f "$pid_file" ]; then
        # No PID files found
        echo "No running skills found."
        exit 0
    fi

    # Extract vendor and namespace from the filename
    filename=$(basename "$pid_file")

    # Split the filename into an array and pick the first two elements
    IFS='-' read -ra ADDR <<<"$filename"
    vendor="${ADDR[0]}"
    namespace="${ADDR[1]}"

    # Remove the .pid extension from namespace
    namespace="${namespace%.*}"

    # Call shutdown-skill.sh with vendor and namespace
    ./support/shutdown-skill.sh "$namespace" "$vendor"
done

echo "Shutdown complete."
