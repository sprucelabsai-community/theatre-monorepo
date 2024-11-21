#!/usr/bin/env bash

# Usage: ./boot-skill.sh <namespace> [<vendor>]

namespace="$1"

# Validate namespace argument
if [ -z "$namespace" ]; then
    echo "Usage: ./boot-skill.sh <namespace> [<vendor>]"
    exit 1
fi

# Determine vendor
if [ $# -ge 2 ]; then
    vendor="$2"
else
    # Use resolve-vendor script to determine the vendor
    vendor=$(./support/resolve-vendor.sh "$namespace")
    # Default to "spruce" if resolve-vendor.sh doesn't return a value
    vendor="${vendor:-spruce}"
fi

export PATH="$HOME/.yarn/bin:$PATH"

packages_dir="$(pwd)/packages"
processes_dir="$(pwd)/.processes"
logs_dir="${processes_dir}/logs"

# Ensure .processes and logs directories exist
mkdir -p "$processes_dir" "$logs_dir"

# Determine skill directory
suffix="-skill"
if [ "$namespace" == "mercury" ]; then
    suffix="-api"
fi

skill_dir="${packages_dir}/${vendor}-${namespace}${suffix}"
app_name="${vendor}-${namespace}${suffix}"
config_file="${processes_dir}/${app_name}.json"
version_file="${processes_dir}/${app_name}.version"

# Check if it's the first boot
if [ -f "$config_file" ]; then
    is_first_boot=false
else
    is_first_boot=true
fi

# Initialize should_register_views based on is_first_boot
should_register_views="$is_first_boot"

# Check for pending git changes in the skill_dir
if [ -d "$skill_dir/.git" ] && git -C "$skill_dir" status --porcelain | grep . >/dev/null; then
    should_register_views=true
fi

# Check if the version in package.json has changed since the last boot
if [ -f "$skill_dir/package.json" ]; then
    # Extract current version from package.json
    current_version=$(grep '"version"' "$skill_dir/package.json" | head -n 1 | sed -E 's/.*"version":\s*"([^"]+)".*/\1/')

    # Read the last stored version
    if [ -f "$version_file" ]; then
        last_version=$(cat "$version_file")
    else
        last_version=""
    fi

    # Compare versions
    if [ "$current_version" != "$last_version" ]; then
        should_register_views=true
    fi
else
    echo "Warning: package.json not found in $skill_dir"
fi

# Convert should_register_views to "true" or "false" string for JSON
if [ "$should_register_views" = true ]; then
    should_register_views_str="true"
else
    should_register_views_str="false"
fi

# Check if yarn is installed
if ! command -v yarn &>/dev/null; then
    echo "Error: yarn is not installed or not found in PATH."
    exit 1
fi

max_restarts=10
restart_delay=5000 # Delay between restarts in milliseconds
yarn_path=$(which yarn)

# Construct the JSON configuration
json_config=$(
    cat <<EOF
{
    "name": "$app_name",
    "script": "$yarn_path",
    "args": "boot",
    "cwd": "$skill_dir",
    "interpreter": "bash",
    "max_restarts": $max_restarts,
    "restart_delay": $restart_delay,
    "out_file": "${logs_dir}/${app_name}-out.log",
    "error_file": "${logs_dir}/${app_name}-error.log"
}
EOF
)

# Write the JSON configuration to the file
echo "$json_config" >"$config_file"

echo "Booting ${vendor}-${namespace}-${suffix}..."

# Start or Restart the application with PM2 using the JSON configuration file
{
    ./support/pm2.sh startOrRestart "$config_file"
    ./support/pm2.sh save
} &
