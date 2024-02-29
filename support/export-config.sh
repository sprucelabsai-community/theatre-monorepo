#!/bin/bash

# Define the base directory for the repo
BASE_DIR="."

# Initialize the backup flag
DO_BACKUP=false

# Parse command line arguments
for arg in "$@"; do
    if [[ "$arg" == "--backup" ]]; then
        DO_BACKUP=true
    elif [[ -z "$UNIT_CONFIG_PATH" ]]; then # Assume the first non-flag argument is the unit config path
        UNIT_CONFIG_PATH="$arg"
    fi
done

# Validate the unit-specific config file if specified
if [ -n "$UNIT_CONFIG_PATH" ] && [ ! -f "$UNIT_CONFIG_PATH" ]; then
    echo "Specified unit config file does not exist: $UNIT_CONFIG_PATH"
    exit 1
fi

# Create a timestamp
TIMESTAMP=$(date +%Y%m%d%H%M)

# Define the directory where the zip files will be stored, appending _backup if necessary
if $DO_BACKUP; then
    ZIP_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}_backup"
else
    ZIP_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}"
fi

# Create the directory
mkdir -p "${ZIP_DIR}"

# Navigate to the base directory
cd "${BASE_DIR}"

# Prepare the blueprint.yml: Merge with unit-specific config if provided
if [ -n "$UNIT_CONFIG_PATH" ]; then
    # Merge and store in a temporary file, it will be added to the zip and then removed
    TEMP_BLUEPRINT="${ZIP_DIR}/blueprint.yml"
    yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' blueprint.yml "$UNIT_CONFIG_PATH" > "$TEMP_BLUEPRINT"
else
    # If no unit-specific config, use the original blueprint.yml directly for zipping
    TEMP_BLUEPRINT="blueprint.yml"
fi

# Zip the config files including the (potentially merged) blueprint.yml and specific .env files
zip -qr "${ZIP_DIR}/config.zip" "$TEMP_BLUEPRINT" $(find packages -maxdepth 2 -type f -name "*.env") -x "*.DS_Store"

# Clean up: Remove temporary merged blueprint.yml if it was created
if [ -n "$UNIT_CONFIG_PATH" ]; then
    rm "$TEMP_BLUEPRINT"
fi

echo "Config files, including blueprint.yml, have been zipped into ${ZIP_DIR}/config.zip"
