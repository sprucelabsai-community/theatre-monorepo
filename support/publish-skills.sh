#!/bin/bash

# Default MongoDB connection string and DB name
mongo_connection_string="mongodb://localhost:27017"
db_name="mercury"

# Try to load DB settings from the Mercury API .env
env_file="packages/spruce-mercury-api/.env"
if [ -f "$env_file" ]; then
    # Read DB_NAME
    env_db_name=$(grep -E '^DB_NAME=' "$env_file" | tail -n1 | cut -d= -f2- | tr -d '"' | xargs)
    if [ -n "$env_db_name" ]; then
        db_name="$env_db_name"
    fi

    # Read DB_CONNECTION_STRING if default is still set
    env_conn_string=$(grep -E '^DB_CONNECTION_STRING=' "$env_file" | tail -n1 | cut -d= -f2- | tr -d '"' | xargs)
    if [ "$mongo_connection_string" = "mongodb://localhost:27017" ] && [ -n "$env_conn_string" ]; then
        mongo_connection_string="$env_conn_string"
    fi
fi

# Parse command line arguments
for arg in "$@"; do
    case $arg in
    --mongoConnectionString=*)
        mongo_connection_string="${arg#*=}"
        shift
        ;;
    --dbName=*)
        db_name="${arg#*=}"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $arg"
        exit 1
        ;;
    esac
done

if [[ "$mongo_connection_string" != mongodb://* ]]; then
    echo "Skipping publishing skills because not using Mongodb."
    exit 0
fi

echo -e "Publishing skills...\n"
echo "MongoDB connection string: $mongo_connection_string"
echo "MongoDB database name: $db_name"
cd packages

# namespaces of skills that cannot be installed
namespaces=("feed" "files" "images" "organization" "locations" "heartwood" "people" "roles" "skills" "permissions" "theatre" "marketplace" "rp")

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"
        namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
        if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
            echo "Publishing $namespace and setting canBeInstalled to false"
            mongosh_output=$(mongosh "$mongo_connection_string" --eval "db = db.getSiblingDB('$db_name'); db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: false}})" 2>&1)
            mongosh_exit=$?
            if [ $mongosh_exit -ne 0 ]; then
                echo "❌ Error occurred while publishing $namespace"
                echo "$mongosh_output"
            fi
        else
            echo "Publishing $namespace and setting canBeInstalled to true"
            mongosh_output=$(mongosh "$mongo_connection_string" --eval "db = db.getSiblingDB('$db_name'); db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: true}})" 2>&1)
            mongosh_exit=$?
            if [ $mongosh_exit -ne 0 ]; then
                echo "❌ Error occurred while publishing $namespace"
                echo "$mongosh_output"
            fi
        fi
        cd ..
    fi
done
