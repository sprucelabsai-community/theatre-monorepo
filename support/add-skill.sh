#!/bin/bash

# Change to the packages directory
cd ../packages

ADDITIONAL_ARGS="${@:2}"

# Extract repo name from the URL
REPO_NAME=$(basename $1 .git)

# Clone the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then

    git clone $1

    if [ $? -ne 0 ]; then
        echo "Error cloning $REPO_NAME."
        exit 1
    fi

    echo "$REPO_NAME cloned successfully."
else
    echo "Skipping $REPO_NAME. Already exists."
fi

# Change to the repo directory
cd $REPO_NAME

REPO_PATH=$(pwd)

cd ../../support

./sync-config.sh $REPO_PATH $ADDITIONAL_ARGS
