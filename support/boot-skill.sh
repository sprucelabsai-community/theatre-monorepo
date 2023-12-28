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
    pid_file_name="${vendor}-${namespace}-api" # For PID file naming
else
    skill_dir="${packages_dir}/${vendor}-${namespace}-skill"
    pid_file_name="${vendor}-${namespace}-skill"
fi

# Call boot-skill-forever.sh in the background and capture the PID
bash "$forever_script" "$skill_dir" &>/dev/null &

# Write the PID to file
echo $! >"${processes_dir}/${pid_file_name}"
