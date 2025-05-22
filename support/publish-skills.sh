#!/bin/bash

# Default MongoDB connection string
mongo_connection_string="mongodb://localhost:27017"

# Parse command line arguments
for arg in "$@"; do
    case $arg in
    --mongoConnectionString=*)
        mongo_connection_string="${arg#*=}"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $arg"
        exit 1
        ;;
    esac
done

echo -e "Publishing skills...\n"
echo "MongoDB connection string: $mongo_connection_string"
cd packages

# namespaces of skills that cannot be installed
namespaces=("feed" "files" "images" "organization" "locations" "heartwood" "people" "roles" "skills" "permissions" "theatre" "marketplace" "rp")

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"
        namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
        if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
            echo "Publishing "$namespace" and setting canBeInstalled to false"
            mongosh "$mongo_connection_string" --eval "db = db.getSiblingDB('mercury'); db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: false}})" >/dev/null 2>&1 || echo "Error occurred while publishing $namespace"
        else
            echo "Publishing "$namespace" and setting canBeInstalled to true"
            mongosh "$mongo_connection_string" --eval "db = db.getSiblingDB('mercury'); db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: true}})" >/dev/null 2>&1 || echo "Error occurred while publishing $namespace"
        fi
        cd ..
    fi
done
