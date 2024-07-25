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

# Cross-platform sed in-place edit
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/{{version}}/${timestamp}/g" ./dist/index.html
else
  # Linux and others
  sed -i "s/{{version}}/${timestamp}/g" ./dist/index.html
fi