#!/bin/bash

set -e

# Alert if path is missing
if [ -z "$1" ]; then
	echo "ERROR: Missing path to blueprint.yml. Try 'yarn sync ./path/to/blueprint.yml'"
	exit 1
fi

BLUEPRINT_FILE=$(dirname $1)/blueprint.yml
if [ ! -f "$BLUEPRINT_FILE" ]; then
	echo "ERROR: blueprint.yml file not found at $BLUEPRINT_FILE"
	exit 1
fi

PACKAGES_DIR=$(dirname $1)/packages
if [ ! -d "$PACKAGES_DIR" ]; then
	echo "ERROR: packages directory not found at $PACKAGES_DIR"
	exit 1
fi

# Collect installed skills; if none, leave the variable empty
if [ -d "$PACKAGES_DIR" ]; then
	INSTALLED_SKILLS=$(find "$PACKAGES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
else
	INSTALLED_SKILLS=""
fi

if [ -z "$INSTALLED_SKILLS" ]; then
	echo "No installed skills found."
else
	echo "Installed skills:"
	# Loop through the installed skills and print them
	for SKILL in $INSTALLED_SKILLS; do
		echo " - $SKILL"
	done
fi

RESOLVED_PACKAGES_DIR=$(realpath "$PACKAGES_DIR")

# Navigate to the correct directory
cd $(dirname $0)

# Fetch repos from blueprint.js and split into lines
echo "Fetching repos from blueprint..."
REPOS_RAW=$(node blueprint.js $1 skills)

# Debug the splitting logic
REPOS_RAW_ARRAY=()
while IFS= read -r line; do
	REPOS_RAW_ARRAY+=("$line")
done <<<"$REPOS_RAW"

# Remove surrounding quotes from each entry in REPOS_RAW_ARRAY
for i in "${!REPOS_RAW_ARRAY[@]}"; do
	REPOS_RAW_ARRAY[$i]="${REPOS_RAW_ARRAY[$i]%\"}"
	REPOS_RAW_ARRAY[$i]="${REPOS_RAW_ARRAY[$i]#\"}"
done

REPOS=()
TARGET_DIRS=()

# Ensure the loop iterates over all elements
for ENTRY in "${REPOS_RAW_ARRAY[@]}"; do
	if [[ "$ENTRY" == *"->"* ]]; then
		REPO_URL=$(echo "$ENTRY" | awk -F'->' '{print $1}' | xargs)
		TARGET_DIR=$(echo "$ENTRY" | awk -F'->' '{print $2}' | xargs)
	else
		REPO_URL="$ENTRY"
		TARGET_DIR=$(basename "$REPO_URL" .git)
	fi

	# Validate cleaned repo URL and target directory
	if [ -z "$REPO_URL" ] || [ -z "$TARGET_DIR" ]; then
		echo "Error: Invalid repo or target directory mapping for entry: $ENTRY"
		exit 1
	fi

	if [[ "$TARGET_DIR" =~ [^a-zA-Z0-9_-] ]]; then
		echo "Error: Invalid target directory name: $TARGET_DIR"
		exit 1
	fi

	# Add to REPOS and TARGET_DIRS arrays and log the operation
	REPOS+=("$REPO_URL")
	TARGET_DIRS+=("$TARGET_DIR")
done

# Compare installed skills against TARGET_DIRS and prompt for removal
for SKILL in $INSTALLED_SKILLS; do
	SKILL_FOUND=false
	for TARGET_DIR in "${TARGET_DIRS[@]}"; do
		if [[ "$SKILL" == "$TARGET_DIR" ]]; then
			SKILL_FOUND=true
			break
		fi
	done

	if [ "$SKILL_FOUND" = false ]; then
		read -p "Do you want to remove the skill '$SKILL' (y/N): " REMOVE_SKILL
		if [[ $REMOVE_SKILL =~ ^[Yy]$ ]]; then
			echo "Removing $SKILL..."
			rm -rf "$RESOLVED_PACKAGES_DIR/$SKILL"
		fi
	fi
done

# Ensure repo URLs are treated as strings in subsequent operations
for i in "${!REPOS[@]}"; do
	REPO=${REPOS[$i]}
	TARGET_DIR=${TARGET_DIRS[$i]}

	CLEAN_REPO="${REPO%\"}"
	CLEAN_REPO="${CLEAN_REPO#\"}"

	# Run add-skill.sh in the background with additional arguments and log output
	./add-skill.sh "$CLEAN_REPO" "$1" "$ADDITIONAL_ARGS" --targetDir="$TARGET_DIR" &
	PID=$!

	# Validate the PID before adding to the PIDS array
	if [[ ! $PID =~ ^[0-9]+$ ]]; then
		echo "Error: Failed to start add-skill.sh for $REPO. Invalid PID: $PID"
		exit 1
	fi

	# Store the PID of the background process
	PIDS+=($PID)
done

# Wait for all background processes to finish
for PID in "${PIDS[@]}"; do
	wait $PID
	STATUS=$?

	# Check exit status from add-skill.sh
	if [ $STATUS -ne 0 ]; then
		echo "Error processing a repo with PID $PID. Check debug.log for details."
		exit 1
	fi
done

echo "Sync complete..."
exit 0
