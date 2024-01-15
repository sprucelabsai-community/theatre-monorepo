#!/usr/bin/env bash

# Initialize dump_file variable
dump_file=""

# Function to show usage
usage() {
    echo "Usage: $0 [--dumpDir <path_to_dump_directory>]"
    exit 1
}

# Parse command-line arguments
while getopts ":d:" opt; do
    case $opt in
    d)
        dump_file=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        usage
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        usage
        ;;
    esac
done

# Generate a random 5-digit PIN
PIN=$(((RANDOM % 90000) + 10000))
echo "You are about to reset the core database. Enter this pin to confirm: $PIN"

# Ask the user to enter the PIN
read -p "Enter the PIN: " entered_pin

# Compare the entered PIN with the generated PIN
if [ "$entered_pin" == "$PIN" ]; then
    echo "PIN verified."

    # Ask for the location of dump file if not provided as an argument
    if [ -z "$dump_file" ]; then
        read -p "Enter the location of dump file (empty to skip): " dump_file
    fi

    # Clear the core database
    echo "Clearing core database..."
    mongosh --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'

    # Restore from dump if the dump_file is provided and valid
    if [ -n "$dump_file" ] && [ -d "$dump_file" ]; then
        echo "Dump file found. Restoring databases..."
        mongorestore --dir "$dump_file"
    elif [ -n "$dump_file" ]; then
        echo "Dump file not found. Skipping restore."
    else
        echo "No dump file provided. Restore skipped."
    fi
else
    echo "Incorrect PIN. Aborting operation."
fi
