#!/bin/bash

# Check if a command line argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path_to_config_zip"
    exit 1
fi

# Get the path to the zip file from the command line argument
ZIP_FILE="$1"

# Check if the zip file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Zip file does not exist: $ZIP_FILE"
    exit 1
fi

# Define the base directory as the current directory
BASE_DIR="."

# Define the directory where the files will be extracted
EXTRACT_DIR="${BASE_DIR}"

# Extract the config contents
unzip -o "$ZIP_FILE" -d "${EXTRACT_DIR}"

echo "Config files have been extracted to ${EXTRACT_DIR}"
