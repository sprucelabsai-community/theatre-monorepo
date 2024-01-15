#!/bin/bash

# Set DIR to the current working directory
DIR="$(pwd)"

# Define the path to the heartwood-skill directory
heartwood_skill_dir="$DIR/packages/spruce-heartwood-skill/dist"

# Create a Caddyfile
echo "http://0.0.0.0:8080
root * $heartwood_skill_dir
file_server" >Caddyfile

# Check if the heartwood-skill directory exists
if [ ! -d "$heartwood_skill_dir" ]; then
    echo "Error: The $heartwood_skill_dir directory does not exist. You need to run 'npm run sync [pathToBlueprint.yml]'"
    exit 1
fi

# Run Caddy
caddy start
