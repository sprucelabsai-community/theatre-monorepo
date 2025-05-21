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

# Fetch repos from blueprint.js
REPOS=$(node blueprint.js $1 skills)

echo "Pulling skills..."

# Declare an empty array to collect PIDs of background processes
PIDS=()

# Capture additional arguments passed to this script
# We skip the first argument since it's the path to the blueprint.yml
ADDITIONAL_ARGS="${@:2} --configStrategy=replace"

# Prompt the user for each skill to remove
for SKILL in $INSTALLED_SKILLS; do
  SKILL_FOUND=false
  for REPO in $REPOS; do
    REPO_NAME=$(basename "$REPO" .git\")
    if [[ "$REPO_NAME" == "$SKILL" ]]; then
      SKILL_FOUND=true
      break
    fi
  done

  if [ "$SKILL_FOUND" = false ]; then
    read -p "Do you want to remove the skill '$SKILL' (y/N): " REMOVE_SKILL
    if [[ $REMOVE_SKILL =~ ^[Yy]$ ]]; then
      # Remove the skill from the PM2 setup
      ./pm2.sh delete $SKILL >>/dev/null
      rm -rf ../$PACKAGES_DIR/$SKILL
    fi
  fi
done

# Loop over each repo and attempt to add in the background
for REPO in $REPOS; do

  echo "Processing $REPO..."

  CLEAN_REPO="${REPO%\"}"
  CLEAN_REPO="${CLEAN_REPO#\"}"

  # Run add-skill.sh in the background with additional arguments
  ./add-skill.sh $CLEAN_REPO $1 $ADDITIONAL_ARGS &

  # Store the PID of the background process
  PIDS+=($!)
done

# Wait for all background processes to finish
for PID in "${PIDS[@]}"; do
  wait $PID
  STATUS=$?

  # Check exit status from add-skill.sh
  # Only fail script if the exit code is 1, indicating an unexpected error
  if [ $STATUS -eq 1 ]; then
    echo "Error processing a repo with PID $PID."
    exit 1
  fi
done

echo "Sync complete..."
exit 0
