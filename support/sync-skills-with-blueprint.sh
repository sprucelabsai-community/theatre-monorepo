#!/bin/bash

# Alert if path is missing
if [ -z "$1" ]; then
    echo "Missing path to blueprint.yml. Try 'yarn sync ./path/to/blueprint.yml'"
    exit 1
fi

# Navigate to the correct directory
cd $(dirname $0)

# Fetch repos from blueprint.js
REPOS=$(node blueprint.js $1 repos)

# Declare an empty array to collect PIDs of background processes
PIDS=()

# Loop over each repo and attempt to add in the background
for REPO in $REPOS; do
    # Run add-skill.sh in the background
    ./add-skill.sh $REPO &
    # Store the PID of the background process
    PIDS+=($!)
done

# Wait for all background processes to finish
for PID in "${PIDS[@]}"; do
    wait $PID
    STATUS=$?

    # Check exit status from add-skill.sh
    # Only fail script if the exit code is 1, indicating an unexpected error
    if [ $STATUS -eq 1 ]; then
        echo "Error processing a repo with PID $PID."
        exit 1
    fi
done

echo "All repos processed."
exit 0
