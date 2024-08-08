#!/bin/bash

echo -e "Checking skills for registration...\n"

shouldForceRegister=false # Default value for the flag

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    --shouldForceRegister=true)
        shouldForceRegister=true
        shift
        ;;
    *)
        shift
        ;;
    esac
done

cd packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        # Extract NAMESPACE from directory name
        NAMESPACE=$(jq -r '.skill.namespace' ./package.json)

        # Check if .env file exists
        if [ -f .env ]; then

            # Set remote if no HOST exists in env
            if ! grep -q "^HOST=" .env; then
                spruce set.remote --remote=local
            fi

            # Check if SKILL_ID is defined in .env file
            if ! grep -q "^SKILL_ID=" .env || [ "$shouldForceRegister" = "true" ]; then
                echo "Registering $NAMESPACE..."
                spruce register --nameReadable="$NAMESPACE" --nameKebab="$NAMESPACE" >/dev/null &
            else
                echo "$NAMESPACE is already registered, logging in..."
                spruce login.skill --skillSlug="$NAMESPACE" >/dev/null &
            fi
        else
            echo "$NAMESPACE is missing a .env file!" >&2
            exit 1
        fi

        cd ..
    fi
done

wait
