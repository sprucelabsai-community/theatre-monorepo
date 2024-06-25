#!/bin/bash

# Initialize variables
BASE_DIR="."
DO_BACKUP=false
RELEASE=false

# Parse command line arguments
for arg in "$@"; do
    if [[ "$arg" == "--release" ]]; then
        RELEASE=true
        RELEASE_DATE=$(date +%Y-%m-%d)
    elif [[ "$arg" == "--backup" ]]; then
        DO_BACKUP=true
    fi
done

# Determine the appropriate directory based on whether this is a backup
TIMESTAMP=$(date +%Y%m%d%H%M)
if $DO_BACKUP; then
    ZIP_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}_backup"
elif $RELEASE; then
    ZIP_DIR="${BASE_DIR}/snapshots/release-${RELEASE_DATE}"
else
    ZIP_DIR="${BASE_DIR}/snapshots/${TIMESTAMP}"
fi

# Ensure the ZIP_DIR exists
mkdir -p "${ZIP_DIR}"

# Navigate to the base directory for other operations
cd "${BASE_DIR}"

# Zip the theatre contents, ensuring to exclude specified files and directories
zip -qr -y "${ZIP_DIR}/theatre.zip" . -x "packages/*/.env" -x "*.DS_Store" -x "snapshots/*" -x "*.log" -x "blueprint.yml" 

# Confirm completion of the operation
echo "Theatre files have been zipped into ${ZIP_DIR}/theatre.zip"
