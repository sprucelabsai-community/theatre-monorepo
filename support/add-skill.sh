#!/bin/bash

# Function to display usage details
show_help() {
    echo "Usage: $0 <repo_url> [options]"
    echo ""
    echo "Options:"
    echo "  --targetDir=<directory>  Specify the target directory for cloning. Defaults to the repo name."
    echo "  --help                  Show this help message."
}

# Parse arguments
TARGET_DIR=""
for arg in "$@"; do
    case $arg in
    --targetDir=*)
        TARGET_DIR="${arg#*=}"
        ;;
    --help)
        show_help
        exit 0
        ;;
    esac
done

# Extract repo name from the URL
REPO_NAME=$(basename $1 .git)

# Default targetDir to REPO_NAME if not provided
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$REPO_NAME"
fi

# Change to the target directory
DESTINATION_DIR="../packages/$TARGET_DIR"
DOES_EXIST=false
if [ -d "$DESTINATION_DIR" ]; then
    DOES_EXIST=true
fi
mkdir -p $DESTINATION_DIR
cd "../packages/$TARGET_DIR"

ADDITIONAL_ARGS="${@:2}"

# Path to the SSH key
SSH_KEY_PATH="../deploy_keys/$REPO_NAME"

# Clone the repo if it doesn't exist
if [ "$DOES_EXIST" = false ]; then
    echo "Cloning repository: $1 into $TARGET_DIR"
    if [ -f "$SSH_KEY_PATH" ]; then
        echo "Using SSH key: $SSH_KEY_PATH"
        GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH" git clone $1
    else
        git clone $1 .
    fi

    if [ $? -ne 0 ]; then
        echo "Error cloning $REPO_NAME."
        exit 1
    fi

    echo "$REPO_NAME cloned successfully."
else
    echo "Skipping $REPO_NAME. Already exists."
fi

REPO_PATH=$(pwd)

git pull

cd ../../

echo "Propogating from $(pwd)"

./support/propagate-blueprint.sh $REPO_PATH $ADDITIONAL_ARGS
