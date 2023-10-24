#!/bin/bash

# Change to the packages directory
cd ../packages

# Extract repo name from the URL
REPO_NAME=$(basename $1 .git)

echo "Cloning skill $REPO_NAME..."

# Clone the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    git clone $1
    if [ $? -ne 0 ]; then
        echo "Error cloning $REPO_NAME."
        exit 1
    fi

    echo "$REPO_NAME cloned successfully."
else
    echo "Repo $REPO_NAME already exists."
fi

exit 0
