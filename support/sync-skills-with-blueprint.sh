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

# Navigate to the correct directory
cd $(dirname $0)

# Debug logs for directory navigation and blueprint file
echo "Navigating to directory: $(dirname $0)"
echo "Blueprint file path: $BLUEPRINT_FILE"

# Fetch repos from blueprint.js and split into lines
echo "Fetching repos from blueprint.js..."
REPOS_RAW=$(node blueprint.js $1 skills)

# Log the raw output from blueprint.js
echo "Raw REPOS_RAW output from blueprint.js:"
echo "$REPOS_RAW"

# Debug the splitting logic
REPOS_RAW_ARRAY=()
while IFS= read -r line; do
  REPOS_RAW_ARRAY+=("$line")
done <<<"$REPOS_RAW"

echo "Debugging split logic:"
echo "REPOS_RAW_ARRAY length: ${#REPOS_RAW_ARRAY[@]}"
for i in "${!REPOS_RAW_ARRAY[@]}"; do
  echo "Index $i: ${REPOS_RAW_ARRAY[$i]}"
done

# Remove surrounding quotes from each entry in REPOS_RAW_ARRAY
for i in "${!REPOS_RAW_ARRAY[@]}"; do
  REPOS_RAW_ARRAY[$i]="${REPOS_RAW_ARRAY[$i]%\"}"
  REPOS_RAW_ARRAY[$i]="${REPOS_RAW_ARRAY[$i]#\"}"
done

# Log the cleaned REPOS_RAW_ARRAY
echo "Cleaned REPOS_RAW_ARRAY:"
for i in "${!REPOS_RAW_ARRAY[@]}"; do
  echo "Index $i: ${REPOS_RAW_ARRAY[$i]}"
done

# Log the split REPOS_RAW_ARRAY
echo "Split REPOS_RAW_ARRAY:"
REPOS=()
TARGET_DIRS=()

# Debugging REPOS_RAW_ARRAY before the loop
echo "REPOS_RAW_ARRAY length: ${#REPOS_RAW_ARRAY[@]}"
echo "Contents of REPOS_RAW_ARRAY:"
for i in "${!REPOS_RAW_ARRAY[@]}"; do
  echo "Index $i: ${REPOS_RAW_ARRAY[$i]}"
done

# Ensure the loop iterates over all elements
for ENTRY in "${REPOS_RAW_ARRAY[@]}"; do
  echo "Processing entry: $ENTRY"
  if [[ "$ENTRY" == *"->"* ]]; then
    REPO_URL=$(echo "$ENTRY" | awk -F'->' '{print $1}' | xargs)
    TARGET_DIR=$(echo "$ENTRY" | awk -F'->' '{print $2}' | xargs)
  else
    REPO_URL="$ENTRY"
    TARGET_DIR=$(basename "$REPO_URL" .git)
    echo "No alias - using default target directory: $TARGET_DIR for $REPO_URL"
  fi

  # Validate cleaned repo URL and target directory
  if [ -z "$REPO_URL" ] || [ -z "$TARGET_DIR" ]; then
    echo "Error: Invalid repo or target directory mapping for entry: $ENTRY"
    exit 1
  fi

  if [[ ! "$REPO_URL" =~ ^git@github.com:.*\.git$ ]]; then
    echo "Error: Malformed repo URL: $REPO_URL"
    exit 1
  fi

  if [[ "$TARGET_DIR" =~ [^a-zA-Z0-9_-] ]]; then
    echo "Error: Invalid target directory name: $TARGET_DIR"
    exit 1
  fi

  # Add to REPOS and TARGET_DIRS arrays and log the operation
  REPOS+=("$REPO_URL")
  TARGET_DIRS+=("$TARGET_DIR")
  echo "Added REPO_URL: $REPO_URL and TARGET_DIR: $TARGET_DIR to arrays"
done

# Ensure repo URLs are treated as strings in subsequent operations
for i in "${!REPOS[@]}"; do
  REPO=${REPOS[$i]}
  TARGET_DIR=${TARGET_DIRS[$i]}

  echo "Processing $REPO into $TARGET_DIR..."

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
  echo "Started add-skill.sh for $REPO with PID $PID"
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
  echo "Successfully processed repo with PID $PID"
done

echo "Sync complete..."
exit 0
