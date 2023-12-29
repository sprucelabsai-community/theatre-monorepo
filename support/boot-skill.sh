#!/usr/bin/env bash

# Usage: ./boot-skill.sh <namespace> [<vendor>]

namespace=$1
vendor=${2:-spruce} # Default vendor to "spruce"
packages_dir="$(pwd)/packages"
processes_dir="$(pwd)/.processes"
forever_script="$(pwd)/support/boot-skill-forever.sh"

# Ensure .processes directory exists
mkdir -p "$processes_dir"

# Determine skill directory
# If the namespace is 'mercury', treat it as an API
if [ "$namespace" == "mercury" ]; then
    skill_dir="${packages_dir}/${vendor}-${namespace}-api"
    file_name="${vendor}-${namespace}-api" # For PID and log file naming
else
    skill_dir="${packages_dir}/${vendor}-${namespace}-skill"
    file_name="${vendor}-${namespace}-skill"
fi

# Call boot-skill-forever.sh and redirect output to a log file
bash "$forever_script" "$skill_dir" >"${processes_dir}/${file_name}.log" 2>&1 &

# Write the PID to a file with .pid extension
echo $! >"${processes_dir}/${file_name}.pid"
