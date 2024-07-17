#!/bin/bash

# Define the base directory for the repo
BASE_DIR="."

# Initialize the backup flag
DO_BACKUP=false

UNIT_NUMBER=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup)
            DO_BACKUP=true
            shift # Consume the flag
            ;;
        --unit-number=*)
            UNIT_NUMBER="-${1#*=}" # Extract the number after the equal sign
            shift # Consume the flag and its argument
            ;;
        *)
            # Assume the argument is the unit config path
            UNIT_CONFIG_PATH="$1"
            shift # Consume the argument
            ;;
    esac
done

# Validate the unit-specific config file if specified
if [ -n "$UNIT_CONFIG_PATH" ] && [ ! -f "$UNIT_CONFIG_PATH" ]; then
    echo "Specified unit config file does not exist: $UNIT_CONFIG_PATH"
    exit 1
fi

# Create a timestamp
TIMESTAMP=$(date +%Y%m%d%H%M)

# Define the directory where the blueprint files will be stored, appending _backup if necessary
if $DO_BACKUP; then
    SNAPSHOT_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}_backup"
else
    SNAPSHOT_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}"
fi

# Create the directory
mkdir -p "${SNAPSHOT_DIR}"

# Navigate to the base directory
cd "${BASE_DIR}"

