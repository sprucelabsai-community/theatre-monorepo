#!/usr/bin/env bash

# Define the dump directory
DUMP_DIR="core_db_dump"

# Create the backup directory if it doesn't exist
mkdir -p "$DUMP_DIR"

# Dump all databases
mongodump --out "$DUMP_DIR"

echo "Backup completed. All databases have been dumped to '$DUMP_DIR'"
