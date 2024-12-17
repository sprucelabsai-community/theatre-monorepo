#!/usr/bin/env bash

source ./support/hero.sh

boot_command="$(pwd)/support/boot-skill.sh"

# if there are arguments, call boot-skill.sh and pass everything through
if [ "$#" -gt 0 ]; then
    bash "$boot_command" "$@"
    exit 0
fi

boot_strategy="parallel"

THEATRE=$(node ./support/blueprint.js blueprint.yml theatre)
BOOT_STRATEGY=$(echo "$THEATRE" | jq -r '.BOOT_STRATEGY' 2>/dev/null)
if [ "$BOOT_STRATEGY" != null ]; then
    boot_strategy=$BOOT_STRATEGY
fi

hero "Booting theatre..."

# Function to boot a skill
boot_skill() {
    local namespace=$1
    local vendor=${2:-spruce} # Default vendor to "spruce"

    echo "Booting ${vendor}-${namespace}..."
    bash "$boot_command" "$namespace" "$vendor"
}

# Boot Mercury API if mercury exists
if [[ -d $(pwd)/packages/spruce-mercury-api ]]; then
    echo "Booting Mercury API..."
    boot_skill "mercury" >/dev/null
    sleep 5
    echo "Mercury API booted."
else
    echo "Mercury API not found. Skipping boot..."
fi

# Boot Heartwood Skill if it exists
if [[ -d $(pwd)/packages/spruce-heartwood-skill ]]; then
    echo "Booting Heartwood Skill..."
    boot_skill "heartwood" >/dev/null
    sleep 5
    echo "Heartwood Skill booted."
else
    echo "Heartwood Skill not found. Skipping boot..."
fi

# Boot theatre skill if it exists
if [[ -d $(pwd)/packages/spruce-theatre-skill ]]; then
    echo "Booting Theatre Skill..."
    boot_skill "theatre" >/dev/null
    echo "Theatre Skill booted."
else
    echo "Theatre Skill not found. Skipping boot..."
fi

# Boot remaining skills

if [ "$boot_strategy" == "serial" ]; then
    echo "Booting skills one at a time..."
    echo "This may take a few minutes..."
else
    echo "Booting remaining skills..."
fi

for skill_dir in $(pwd)/packages/*-skill; do
    # Extract vendor and namespace from directory name
    skill_name=$(basename "$skill_dir" -skill)
    vendor=$(echo "$skill_name" | cut -d '-' -f 1)
    namespace=$(echo "$skill_name" | cut -d '-' -f 2-)

    if [[ "$namespace" != "heartwood" && "$namespace" != "mercury" && "$namespace" != "theatre" ]]; then
        echo "Booting ${namespace}..."
        boot_skill "$namespace" "$vendor" >/dev/null

        if [ "$boot_strategy" == "serial" ]; then
            sleep 5
        fi
    fi
done

yarn list.running
