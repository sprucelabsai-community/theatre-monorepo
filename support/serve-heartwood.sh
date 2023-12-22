#!/bin/bash

# Define the path to the heartwood-skill directory
heartwood_skill_dir="packages/spruce-heartwood-skill"

# Check if the heartwood-skill directory exists
if [ ! -d "$heartwood_skill_dir" ]; then
    echo "Error: The /heartwood-skill directory does not exist. You need to run 'npm run sync [pathToBlueprint.yml]'"
    exit 1
fi

# Change to the heartwood-skill directory
cd "$heartwood_skill_dir"

# Check if the dist directory exists
if [ ! -d "dist" ]; then
    echo "The 'dist' directory does not exist. Running 'yarn run build.heartwood'"
    yarn run build.heartwood
fi

# Change to the dist directory and start the server
cd dist
python3 -m http.server 8080
