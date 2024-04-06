#!/bin/bash

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

# Navigate to the correct directory
cd $(dirname $0)

ADMIN_SECTION=$(node blueprint.js $1 admin)

# Check if admin section contains phone number
if [[ $ADMIN_SECTION != *phone* ]]; then
    echo "ERROR: The admin number is missing in your blueprint.yml. Add it as follows:"
    echo ""
    echo "admin:"
    echo "  - phone: \"1234567890\""
    exit 1
fi

# Fetch repos from blueprint.js
REPOS=$(node blueprint.js $1 skills)

clear

echo "Pulling skills..."

# Declare an empty array to collect PIDs of background processes
PIDS=()

# Capture additional arguments passed to this script
# We skip the first argument since it's the path to the blueprint.yml
ADDITIONAL_ARGS="${@:2}"

PM2_SKILLS=$(pm2 list | grep -- '-skill' | awk '{print $4}')
# Prompt the user for each skill to remove
for SKILL in $PM2_SKILLS; do
  echo $SKILL
  SKILL_FOUND=false
  for REPO in $REPOS; do
  echo $REPO
    REPO_NAME=$(basename "$REPO" .git\")
    echo $REPO_NAME
    if [[ "$REPO_NAME" == "$SKILL" ]]; then
      SKILL_FOUND=true
      break
    fi
  done
  
  if [ "$SKILL_FOUND" = false ]; then
    read -p "Do you want to remove the skill '$SKILL' from the PM2 setup? (y/n): " REMOVE_SKILL
    if [[ $REMOVE_SKILL =~ ^[Yy]$ ]]; then
      # Remove the skill from the PM2 setup
      pm2 delete $SKILL
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
