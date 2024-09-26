#!/bin/bash

# Default MongoDB connection string
mongo_connection_string="mongodb://localhost:27017"

# Parse command line arguments
for arg in "$@"; do
    case $arg in
    --mongoConnectionString=*)
        mongo_connection_string="${arg#*=}"
        # Escape dollar signs in the connection string
        # mongo_connection_string="${mongo_connection_string//\$/\\\$}"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $arg"
        exit 1
        ;;
    esac
done

echo -e "Publishing skills...\n"
cd packages

# namespaces of skills that cannot be installed
namespaces=("feed" "files" "images" "organization" "locations" "heartwood" "people" "roles" "skills" "permissions" "theatre")

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"
        namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
        if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
            mongosh "$mongo_connection_string" --eval "db = db.getSiblingDB('mercury'); db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: false}})"
            echo "Publishing "$namespace" and setting canBeInstalled to false"
        else
            echo "Publishing "$namespace" and setting canBeInstalled to true"
            mongosh "$mongo_connection_string" --eval "db = db.getSiblingDB('mercury'); db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: true}})"
        fi
        cd ..
    fi
done
