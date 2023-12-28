#!/usr/bin/env bash

boot_command="$(pwd)/support/boot-skill.sh"

# Function to boot a skill
boot_skill() {
    local namespace=$1
    local vendor=${2:-spruce} # Default vendor to "spruce"

    echo "Booting ${vendor}-${namespace}..."
    bash "$boot_command" "$namespace" "$vendor"
}

# Boot skills
# Example: boot_skill "heartwood" (defaults vendor to "spruce")
# For a non-default vendor: boot_skill "namespace" "vendor"

# Boot Mercury API
boot_skill "mercury"

# Wait for 5 seconds
sleep 5

# Boot Heartwood Skill
boot_skill "heartwood"

# Wait for 5 seconds
sleep 5

# Boot remaining skills
echo "Booting remaining skills..."
for skill_dir in $(pwd)/packages/*-skill; do
    # Extract vendor and namespace from directory name
    skill_name=$(basename "$skill_dir" -skill)
    vendor=$(echo "$skill_name" | cut -d '-' -f 1)
    namespace=$(echo "$skill_name" | cut -d '-' -f 2)

    if [[ "$namespace" != "heartwood" && "$namespace" != "mercury" ]]; then
        boot_skill "$namespace" "$vendor"
    fi
done
