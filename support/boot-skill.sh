#!/usr/bin/env bash

# Usage: ./boot-skill.sh <namespace> [<vendor>]

namespace="$1"

# Validate namespace argument
if [ -z "$namespace" ]; then
    echo "Usage: ./boot-skill.sh <namespace> [<vendor>]"
    exit 1
fi

if [ "$namespace" = "message-receiver" ]; then
    ./support/boot-message-receiver.sh
    exit 1
fi

# Determine vendor
if [ $# -ge 2 ]; then
    vendor="$2"
else
    vendor=$(./support/resolve-vendor.sh "$namespace")
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

# Check for pending git changes
if [ -d "$skill_dir/.git" ] && git -C "$skill_dir" status --porcelain | grep . >/dev/null; then
    should_register_views=true
fi

# Check if the version in package.json has changed
if [ -f "$skill_dir/package.json" ]; then
    current_version=$(grep '"version"' "$skill_dir/package.json" | head -n 1 | sed -E 's/.*"version":\s*"([^"]+)".*/\1/')
    if [ -f "$version_file" ]; then
        last_version=$(cat "$version_file")
    else
        last_version=""
    fi

    if [ "$current_version" != "$last_version" ]; then
        should_register_views=true
    fi
else
    echo "Warning: package.json not found in $skill_dir"
fi

# Convert should_register_views to "true" or "false"
if [ "$should_register_views" = true ]; then
    should_register_views_str="true"
else
    should_register_views_str="false"
fi

./support/boot-pm2-process.sh \
    --name "$app_name" \
    --command "boot" \
    --cwd "$skill_dir" \
    --out_file "${logs_dir}/${app_name}-out.log" \
    --error_file "${logs_dir}/${app_name}-error.log"
