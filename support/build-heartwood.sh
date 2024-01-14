#!/bin/bash

cd packages/spruce-heartwood-skill
yarn build.cdn

# Get the current timestamp
timestamp=$(date +%s)

# Replace {{version}} with the current timestamp in ./dist/index.html
sed -i '' "s/{{version}}/${timestamp}/g" ./dist/index.html
