#!/bin/bash

cd support

# Ensure path to blueprint.yml is provided
if [ -z "$1" ]; then
    echo "ERROR: Missing path to blueprint.yml. Usage: $0 path/to/blueprint.yml"
    exit 1
fi

# Load the admin section using blueprint.js
ADMIN_SECTION=$(node blueprint.js $1 admin)

# Extract the phone number using jq
PHONE=$(echo "$ADMIN_SECTION" | jq -r '.phone')

# Check if phone number is extracted
if [ -z "$PHONE" ]; then
    echo "ERROR: The admin phone number is missing in your blueprint.yml."
    exit 1
fi
spruce set.remote https://localhost:8081

# Run your command with the extracted phone number
spruce login --phone "$PHONE" --pin 0000
