#!/usr/bin/env bash

# Function to display usage message
usage() {
    echo "Error! No --dumpPath argument provided."
    echo "Usage: $0 --dumpPath PATH"
    exit 1
}

# Define the dump directory name
DUMP_DIR="core_db_dump"

# Initialize DUMP_PATH as empty
DUMP_PATH=""

# Parse arguments
for arg in "$@"; do
    case $arg in
    --dumpPath)
        DUMP_PATH="${2}"
        shift # Remove --dumpPath
        shift # Remove the value of --dumpPath
        ;;
    *)
        # Handle unknown options
        usage
        ;;
    esac
done

# Check if dump path was provided
if [ -z "$DUMP_PATH" ]; then
    usage
fi

# Create the backup directory in the specified path
mkdir -p "$DUMP_PATH/$DUMP_DIR"

# Dump all databases
mongodump --out "$DUMP_PATH/$DUMP_DIR"

echo "Backup completed. All databases have been dumped to '$DUMP_PATH/$DUMP_DIR'"
