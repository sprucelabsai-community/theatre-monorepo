#!/usr/bin/env bash

# Function to display usage message
usage() {
    echo "Error! No --dumpPath argument provided."
    echo "Usage: yarn dump.core.database --dumpPath PATH"
    exit 1
}

# Define the dump directory name
DUMP_DIR="core_db_dump"

# Parse arguments
while getopts ":p:" opt; do
    case $opt in
    p)
        DUMP_PATH="$OPTARG"
        ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
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
