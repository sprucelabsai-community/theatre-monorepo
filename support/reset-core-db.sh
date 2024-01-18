#!/usr/bin/env bash

# Initialize dump_dir variable
dump_dir=""
should_use_pin=true

# Function to show usage
usage() {
    echo "Usage: yarn reset.core.database --dumpDir=/path/to/dump [--shouldUsePin=false]"
    exit 1
}

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
    --dumpDir=*)
        dump_dir="${arg#*=}"
        shift # Remove argument from processing
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
mongosh --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'

# Restore from dump if the dump_dir is provided and valid
if [ -n "$dump_dir" ]; then
    echo "Dump directory found. Restoring databases now..."
    mongorestore --dir "$dump_dir"
    echo "Restore complete!"
else
    echo "Database cleared!"
fi

echo "Next steps:"
echo "1. Shutdown the platform: yarn shutdown"
echo "2. Start mercury: yarn boot.mercury"
echo "3. Login: yarn login blueprint.yml"
if [ -n "$dump_dir" ]; then
    echo "4. Register skills: yarn register"
else
    echo "4. Register skills: yarn register -shouldForceRegister=true"
fi
echo "5. Reboot the platform: yarn reboot"
