#!/usr/bin/env bash

boot_command="$(pwd)/support/boot-skill.sh"

# if there are arguments, call boot-skill.sh and pass everything through
if [ "$#" -gt 0 ]; then
    bash "$boot_command" "$@"
    exit 0
fi

# Function to boot a skill
boot_skill() {
    local namespace=$1
    local vendor=${2:-spruce} # Default vendor to "spruce"

    echo "Booting ${vendor}-${namespace}..."
    bash "$boot_command" "$namespace" "$vendor"
}

# Boot Mercury API if mercury exists
if [[ -d $(pwd)/packages/spruce-mercury-api ]]; then
    boot_skill "mercury" >/dev/null &
    echo "Booting Mercury API..."
    echo "Waiting 5 seconds for boot to complete..."
    sleep 5
else
    echo "Mercury API not found. Skipping..."
fi

# Boot Heartwood Skill if it exists
if [[ -d $(pwd)/packages/spruce-heartwood-skill ]]; then
    boot_skill "heartwood" >/dev/null &
    echo "Booting Heartwood Skill..."
    echo "Waiting 5 seconds for boot to complete..."
    sleep 5
else
    echo "Heartwood Skill not found. Skipping..."
fi

# Boot theatre skill if it exists
if [[ -d $(pwd)/packages/spruce-theatre-skill ]]; then
    boot_skill "theatre" >/dev/null &
    echo "Booting Theatre Skill..."
    echo "Waiting 5 seconds for boot to complete..."
    sleep
    echo "Theatre Skill booted."
else
    echo "Theatre Skill not found. Skipping..."
fi

# Boot remaining skills
echo "Booting remaining skills..."
for skill_dir in $(pwd)/packages/*-skill; do
    # Extract vendor and namespace from directory name
    skill_name=$(basename "$skill_dir" -skill)
    vendor=$(echo "$skill_name" | cut -d '-' -f 1)
    namespace=$(echo "$skill_name" | cut -d '-' -f 2)

    if [[ "$namespace" != "heartwood" && "$namespace" != "mercury" && "$namespace" != "theatre" ]]; then
        echo "Booting ${namespace}..."
        boot_skill "$namespace" "$vendor" >/dev/null &
    fi
done

yarn list.running
