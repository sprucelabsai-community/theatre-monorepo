#!/bin/bash

# Navigate to the correct directory
cd $(dirname $0)

# Fetch repos from blueprint.js
REPOS=$(node blueprint.js repos)

# Declare an empty array to collect PIDs of background processes
PIDS=()

# Loop over each repo and attempt to add in the background
for REPO in $REPOS; do
    # Run add-repo.sh in the background
    ./add-repo.sh $REPO &
    # Store the PID of the background process
    PIDS+=($!)
done

# Wait for all background processes to finish
for PID in "${PIDS[@]}"; do
    wait $PID
    STATUS=$?

    # Check exit status from add-repo.sh
    # Only fail script if the exit code is 1, indicating an unexpected error
    if [ $STATUS -eq 1 ]; then
        echo "Error processing a repo with PID $PID."
        exit 1
    fi
done

echo "All repos processed."
exit 0
