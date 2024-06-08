#!/usr/bin/env bash

# Usage: ./boot-skill.sh <namespace> [<vendor>]

namespace=$1
vendor=${2:-spruce} # Default vendor to "spruce"
packages_dir="$(pwd)/packages"
processes_dir="$(pwd)/.processes"
logs_dir="${processes_dir}/logs"

if [ $# -ge 2 ]; then
    vendor="$2"
else
    # Use resolve-vendor script to determine the vendor
    vendor=$(./support/resolve-vendor.sh "$namespace")
fi

# Ensure .processes directory exists
mkdir -p "$processes_dir"
mkdir -p "$logs_dir"

# Determine skill directory
suffix="-skill"
if [ "$namespace" == "mercury" ]; then
    suffix="-api"
fi

skill_dir="${packages_dir}/${vendor}-${namespace}${suffix}"
app_name="${vendor}-${namespace}${suffix}"
config_file="${processes_dir}/${app_name}.json"

# Find the path to yarn
yarn_path="yarn"

# Check if yarn was found
if [ -z "$yarn_path" ]; then
    echo "Error: yarn not found"
    exit 1
fi

max_restarts=10
restart_delay=5000 # Set the delay between restarts in milliseconds

# Construct the JSON configuration
json_config="{
     \"name\": \"$app_name\",
    \"script\": \"$yarn_path\",
    \"args\": \"boot\",
    \"cwd\": \"$skill_dir\",
    \"interpreter\": \"bash\",
    \"max_restarts\": $max_restarts,
    \"restart_delay\": $restart_delay,
    \"out_file\": \"${logs_dir}/${app_name}-out.log\",
    \"error_file\": \"${logs_dir}/${app_name}-error.log\"
}"

# Write the JSON configuration to the file
echo "$json_config" >"$config_file"

# Start or Restart the application with PM2 using the JSON configuration file
./support/pm2.sh startOrRestart "$config_file"
./support/pm2.sh save
