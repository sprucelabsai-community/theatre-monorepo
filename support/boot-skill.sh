#!/usr/bin/env bash

# Usage: ./boot-skill.sh <namespace> [<vendor>]

namespace=$1
vendor=${2:-spruce} # Default vendor to "spruce"
packages_dir="$(pwd)/packages"
processes_dir="$(pwd)/.processes"

# Ensure .processes directory exists
mkdir -p "$processes_dir"

# Determine skill directory
suffix="-skill"
if [ "$namespace" == "mercury" ]; then
    suffix="-api"
fi

skill_dir="${packages_dir}/${vendor}-${namespace}${suffix}"
app_name="${vendor}-${namespace}${suffix}"
config_file="${processes_dir}/${app_name}.json"

# Find the path to yarn
yarn_path=$(which yarn)

# Check if yarn was found
if [ -z "$yarn_path" ]; then
    echo "Error: yarn not found"
    exit 1
fi

# Construct the JSON configuration
json_config="{
    \"name\": \"$app_name\",
    \"script\": \"$yarn_path\",
    \"args\": \"boot\",
    \"cwd\": \"$skill_dir\",
    \"interpreter\": \"bash\"
}"

# Write the JSON configuration to the file
echo "$json_config" >"$config_file"

# Start or Restart the application with PM2 using the JSON configuration file
pm2 startOrRestart "$config_file"
pm2 save
