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

# if spruce-mercury-api exists, do the same thing but run "yarn upgrade.packages.all" instead of "spruce upgrade"
if [[ -d "spruce-mercury-api" ]]; then
    cd "spruce-mercury-api"
    git pull
    yarn upgrade.packages.all
    yarn build.dev
fi
