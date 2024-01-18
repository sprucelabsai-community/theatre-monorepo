#!/bin/bash

heartwood_dir="packages/spruce-heartwood-skill"

if [ ! -d "$heartwood_dir" ]; then
    echo "Skipping building Heartwood."
    exit 0
fi

cd packages/spruce-heartwood-skill
yarn build.cdn

# Get the current timestamp
timestamp=$(date +%s)

# Replace {{version}} with the current timestamp in ./dist/index.html
sed -i '' "s/{{version}}/${timestamp}/g" ./dist/index.html
