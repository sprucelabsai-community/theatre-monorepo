#!/bin/bash

echo -e "Logging in as skills...\n"

cd packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        # Extract NAMESPACE from directory name
        NAMESPACE=$(jq -r '.skill.namespace' ./package.json)

        spruce set.remote --remote=local
        spruce login.skill --skillSlug="$NAMESPACE"

        cd ..
    fi
done
