#!/usr/bin/env bash

echo "Updating isPublished and canBeInstalled for skills"

# array of lowercase skill namespaces that are private
namespaces=("feed" "files" "images" "locations" "organization" "people" "roles" "skills" "theatre")

# loop through all directories in the current directory that end in -skill
for dir in *-skill; do
    if [[ -d $dir ]]; then
        # change into the directory
        cd "$dir"
        # get the namespace from package.json
        namespace=$(grep '"namespace"' package.json | awk -F: '{print $2}' | tr -d '," ')
        # check if namespace is in the namespaces array
        if [[ " ${namespaces[*]} " == *"$namespace"* ]]; then
            # set isPublished and canBeInstalled to false
            mongosh mercury --eval "db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: false}})"
        else
            # set isPublished and canBeInstalled to true
            mongosh mercury --eval "db.skills.updateMany({slug: '$namespace'}, { \$set: {isPublished: true, canBeInstalled: true}})"
        fi
        # change back to the parent directory
        cd ..
    fi
done
