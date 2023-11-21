#!/bin/bash

# Alert if path is missing
if [ -z "$1" ]; then
    echo "ERROR: Missing path to blueprint.yml. Try 'yarn sync ./path/to/blueprint.yml'"
    exit 1
fi

BLUEPRINT_FILE=$(dirname $1)/blueprint.yml
if [ ! -f "$BLUEPRINT_FILE" ]; then
    echo "ERROR: blueprint.yml file not found at $BLUEPRINT_FILE"
    exit 1
fi

# Navigate to the correct directory
cd $(dirname $0)

ADMIN_SECTION=$(node blueprint.js $1 admin)

# Check if admin section contains phone number
if [[ $ADMIN_SECTION != *phone* ]]; then
    echo "ERROR: The admin number is missing in your blueprint.yml. Add it as follows:"
    echo ""
    echo "admin:"
    echo "  - phone: \"1234567890\""
    exit 1
fi

# Fetch repos from blueprint.js
REPOS=$(node blueprint.js $1 skills)

clear

echo "Pulling skills..."

# Declare an empty array to collect PIDs of background processes
PIDS=()

cd ../packages

# Loop over each repo and attempt to add in the background
for REPO in $REPOS; do
    # Run add-skill.sh in the background
    # REPO_NAME=$(basename $REPO .git)

    git clone $REPO
    # ./add-skill.sh $REPO $1
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

echo "Sync complete..."
exit 0
