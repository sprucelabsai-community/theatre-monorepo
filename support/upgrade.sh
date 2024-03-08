#!/bin/bash

echo "Upgrading skills..."

cd ./packages

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"

        git pull

        # Upgrade skill
        spruce upgrade

        cd ..
    fi
done
