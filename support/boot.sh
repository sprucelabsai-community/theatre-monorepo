#!/usr/bin/env bash

source ./support/hero.sh

boot_command="$(pwd)/support/boot-skill.sh"

# Default boot strategy
boot_strategy="parallel"

# Parse arguments
namespace=""
vendor=""
for arg in "$@"; do
	case $arg in
	--bootStrategy=*)
		boot_strategy="${arg#*=}"
		shift
		;;
	*)
		# Assume the first argument is namespace and the second is vendor
		if [ -z "$namespace" ]; then
			namespace="$arg"
		elif [ -z "$vendor" ]; then
			vendor="$arg"
		fi
		shift
		;;
	esac
done

# If a namespace is provided, call boot-skill.sh with namespace and vendor and exit
if [ -n "$namespace" ]; then
	bash "$boot_command" "$namespace" "$vendor"
	exit 0
fi

# If no namespace is provided, proceed with the boot process
echo "Using boot strategy: $boot_strategy"

THEATRE=$(node ./support/blueprint.js blueprint.yml theatre)
BOOT_STRATEGY=$(echo "$THEATRE" | jq -r '.BOOT_STRATEGY' 2>/dev/null)
if [ "$BOOT_STRATEGY" != null ]; then
	boot_strategy=$BOOT_STRATEGY
fi

ENV=$(node support/blueprint.js blueprint.yml env)
SHOULD_BOOT_MERCURY_MESSAGE_RECEIVER=$(echo "$ENV" | jq -r '.mercury[] | select(has("SHOULD_BOOT_MESSAGE_RECEIVER")) | .SHOULD_BOOT_MESSAGE_RECEIVER' 2>/dev/null)
if [ -n "$SHOULD_BOOT_MERCURY_MESSAGE_RECEIVER" ]; then
	echo "Found message receiver configuration in blueprint.yml"
	echo "Should boot message receiver = $SHOULD_BOOT_MERCURY_MESSAGE_RECEIVER"
	should_boot_message_receiver=$SHOULD_BOOT_MERCURY_MESSAGE_RECEIVER
fi

hero "Checking for Heartwood"

if [[ -d $(pwd)/packages/spruce-heartwood-skill ]]; then
	echo "Heartwood found. Checking blueprint if should serve."
	SHOULD_SERVE=$(echo "$THEATRE" | jq -r '.SHOULD_SERVE_HEARTWOOD' 2>/dev/null)
	if [ "$SHOULD_SERVE" != false ]; then
		echo "Serving Heartwood..."
		yarn serve.heartwood
	else
		echo "Not serving Heartwood."
	fi
fi

hero "Booting theatre"

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
	boot_skill "mercury" "spruce" >/dev/null
	sleep 5
	echo "Mercury API booted."
else
	echo "Mercury API not found. Skipping boot..."
fi

# Boot Heartwood Skill if it exists
if [[ -d $(pwd)/packages/spruce-heartwood-skill ]]; then
	echo "Booting Heartwood Skill..."
	boot_skill "heartwood" "spruce" >/dev/null
	sleep 5
	echo "Heartwood Skill booted."
else
	echo "Heartwood Skill not found. Skipping boot..."
fi

# Boot theatre skill if it exists
if [[ -d $(pwd)/packages/spruce-theatre-skill ]]; then
	echo "Booting Theatre Skill..."
	boot_skill "theatre" "spruce" >/dev/null
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

if [ "$should_boot_message_receiver" = true ]; then
	./support/boot-message-receiver.sh
fi

# Run POST_BOOT_SCRIPT if set
POST_BOOT_SCRIPT=$(echo "$THEATRE" | jq -r '.POST_BOOT_SCRIPT' 2>/dev/null)
if [ -n "$POST_BOOT_SCRIPT" ] && [ "$POST_BOOT_SCRIPT" != "null" ]; then
	echo "Running POST_BOOT_SCRIPT..."
	eval "$POST_BOOT_SCRIPT"
fi

yarn list.running
