#!/usr/bin/env bash

# Initialize dump_file variable
dump_file=""

# Function to show usage
usage() {
    echo "Usage: $0 --dumpDir=/path/to/dump"
    exit 1
}

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
    --dumpDir=*)
        dump_file="${arg#*=}"
        shift # Remove argument from processing
        ;;
    *)
        # Unknown option
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
        read -p "Enter the location of dump you want to restore from (empty to skip): " dump_file
    fi

    # if the dump_file is provided, but no dir exists, throw an error
    if [ -n "$dump_file" ] && [ ! -d "$dump_file" ]; then
        echo "Dump file not founda at $dump_file. Aborting operation."
        exit 1
    fi

    # Clear the core database
    echo "Clearing core database..."
    mongosh --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'

    # Restore from dump if the dump_file is provided and valid
    if [ -n "$dump_file" ]; then
        echo "Dump file found. Restoring databases now..."
        mongorestore --dir "$dump_file"
        echo "Restore complete!"
    else
        echo "Database cleared!"
    fi

    echo "Next steps:"
    echo "1. Shutdown the platform: yarn shutdown"
    echo "2. Start mercury: yarn boot.mercury"
    echo "3. Login: yarn login blueprint.yml"
    if [ -n "$dump_file" ]; then
        echo "4. Register skills: yarn register"
    else
        echo "4. Register skills: yarn register -shouldForceRegister=true"
    fi
    echo "5. Reboot the platform: yarn reboot"

else
    echo "Incorrect PIN. Aborting operation."
fi
