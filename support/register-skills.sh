#!/bin/bash

echo -e "Checking skills for registration...\n"

cd packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        # Extract NAMESPACE from directory name
        NAMESPACE=$(jq -r '.skill.namespace' ./package.json)

        # Check if .env file exists
        if [ -f .env ]; then
            # Check if SKILL_ID is defined in .env file
            if ! grep -q "^SKILL_ID=" .env; then
                spruce set.remote --remote=local
                spruce register --nameReadable="$NAMESPACE" --nameKebab="$NAMESPACE"
            fi
        else
            echo "$dir is missing a .env file!" >&2
            exit 1
        fi

        cd ..
    fi
done
