#!/bin/bash

processes_dir="$(pwd)/.processes"

# Ensure the .processes directory exists
if [ ! -d "$processes_dir" ]; then
    echo "Platform not running..."
    exit 1
fi

# Loop through all files in the .processes directory
for pid_file in "$processes_dir"/*; do
    # Extract vendor and namespace from the filename
    filename=$(basename "$pid_file")
    IFS='-' read -r vendor namespace <<<"$filename"

    # Call shutdown-skill.sh with vendor and namespace
    ./support/shutdown-skill.sh "$namespace" "$vendor"
done

echo "Shutdown complete."
