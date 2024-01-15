#!/bin/bash

# Set DIR to the current working directory
DIR="$(pwd)"

# Define the path to the heartwood-skill directory
heartwood_skill_dir="packages/spruce-heartwood-skill"

# Define the directory to serve
SERVE_DIR="$heartwood_skill_dir/dist"

# Create a Caddyfile
echo ":8080
root * $SERVE_DIR
file_server" >Caddyfile

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

# Change back to the root directory
cd $DIR

# Run Caddy
caddy run
