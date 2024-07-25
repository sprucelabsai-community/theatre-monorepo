#!/usr/bin/env bash

# Initialize dump_dir variable
dump_dir=""
should_use_pin=true

# Function to show usage
usage() {
    echo "Usage: yarn reset.core.database [--dumpDir=/path/to/dump] [--mongoConnectionString=mongodb://...] [--shouldUsePin=false]"
    exit 1
}

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
    --dumpDir=*)
        dump_dir="${arg#*=}"
        shift # Remove argument from processing
        ;;
    --mongoConnectionString=*)
        mongo_connection_string="${arg#*=}"
        shift
        ;;
    --shouldUsePin=false)
        should_use_pin=false
        shift # Remove argument from processing
        ;;
    *)
        # Unknown option
        usage
        ;;
    esac
done

# Set default connection string if not provided
if [ -z "$mongo_connection_string" ]; then
    mongo_connection_string="mongodb://localhost:27017"
    echo "Using local MongoDB instance."
else
    echo "Using provided MongoDB connection string."
fi

# Generate a random 5-digit PIN if should_use_pin is true
if [ "$should_use_pin" = false ]; then
    echo "PIN check bypassed."
else
    PIN=$(((RANDOM % 90000) + 10000))
    echo "You are about to reset the core database. Enter this pin to confirm: $PIN"

    # Ask the user to enter the PIN
    read -p "Enter the PIN: " entered_pin

    # Compare the entered PIN with the generated PIN
    if [ "$entered_pin" != "$PIN" ]; then
        echo "Incorrect PIN. Aborting operation."
        exit 1
    fi
fi

# Ask for the location of dump directory if not provided as an argument
if [ -z "$dump_dir" ]; then
    read -p "Enter the location of dump you want to restore from (empty to skip): " dump_dir
fi

# If the dump_dir is provided, but no directory exists, throw an error
if [ -n "$dump_dir" ] && [ ! -d "$dump_dir" ]; then
    echo "Dump directory not found at $dump_dir. Aborting operation."
    exit 1
fi

# Clear the core database
echo "Clearing core database..."
mongosh "$mongo_connection_string" --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'

# Restore from dump if the dump_dir is provided and valid
if [ -n "$dump_dir" ]; then
    echo "Dump directory found. Restoring databases now..."
    mongorestore --uri "$mongo_connection_string" --dir "$dump_dir"
    echo "Restore complete!"
else
    echo "Database cleared!"
fi

echo "Next steps:"
echo "1. Shutdown the Theatre: yarn shutdown"
echo "2. Setup the Theatre: yarn setup.theatre blueprint.yml"
