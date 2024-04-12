#!/bin/bash

echo -e "Logging in as skills...\n"

cd packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        # Extract NAMESPACE from directory name
        NAMESPACE=$(jq -r '.skill.namespace' ./package.json)

        #set remote if no HOST exists in env
        if ! grep -q "^HOST=" .env; then
            spruce set.remote --remote=local
        fi

        spruce login.skill --skillSlug="$NAMESPACE"

        cd ..
    fi
done
