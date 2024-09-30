#!/bin/bash

# Pull out PUBLIC_ASSET_DIR if exists
blueprint="blueprint.yml"

ENV=$(node support/blueprint.js $blueprint env)
PUBLIC_ASSETS_DIR=$(echo "$ENV" | jq -r '.heartwood[] | select(has("PUBLIC_ASSETS_DIR")) | .PUBLIC_ASSETS_DIR' 2>/dev/null)

heartwood_dir="packages/spruce-heartwood-skill"

if [ ! -d "$heartwood_dir" ]; then
  echo "Skipping building Heartwood."
  exit 0
fi

cd $heartwood_dir
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

# if there is a PUBLIC_ASSETS_DIR, copy everything from it to $heartwood_dir/dist/public/assets
if [ -n "$PUBLIC_ASSETS_DIR" ]; then
  cd ../..
  echo "Copying public assets to $heartwood_dir/dist/public/assets"
  mkdir -p $heartwood_dir/dist/public/assets
  cp -r $PUBLIC_ASSETS_DIR/* $heartwood_dir/dist/public/assets

  echo "command: cp -r $PUBLIC_ASSETS_DIR/* $heartwood_dir/dist/public/assets"
fi
