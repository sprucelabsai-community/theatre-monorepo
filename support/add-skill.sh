#!/bin/bash

# Pull env
ENV=$(node ./blueprint.js $2 env)

# Change to the packages directory
cd ../packages

# Extract repo name from the URL
REPO_NAME=$(basename $1 .git)

# Clone the repo if it doesn't exist
if [ ! -d "$REPO_NAME" ]; then
    echo "Cloning skill $REPO_NAME"

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

# Delete .env if exists
if [ -f .env ]; then
    rm .env
fi

## drop in ENV logic here
SKILL_NAMESPACE=$(jq -r '.skill.namespace' ./package.json)

# Loop to set the environment variables
for key in $(jq -r 'keys[]' <<<"$ENV"); do
    if [[ "$key" == "universal" ]]; then
        len=$(jq -r ".$key | length" <<<"$ENV")
        for i in $(seq 0 $(($len - 1))); do
            pair=$(jq -r ".$key[$i] | to_entries[0] | \"\(.key)=\\\"\(.value)\\\"\"" <<<"$ENV")
            echo "$pair" >>.env
        done
    fi
done

for key in $(jq -r 'keys[]' <<<"$ENV"); do
    if [[ "$key" == "$SKILL_NAMESPACE" ]]; then
        len=$(jq -r ".$key | length" <<<"$ENV")
        for i in $(seq 0 $(($len - 1))); do
            pair=$(jq -r ".$key[$i] | to_entries[0] | \"\(.key)=\\\"\(.value)\\\"\"" <<<"$ENV")
            echo "$pair" >>.env
        done
    fi
done

# Define arrays for keys and values
keys=("namespace")
values=("$SKILL_NAMESPACE")

# Loop through the array and apply replacements
for i in "${!keys[@]}"; do
    key="${keys[$i]}"
    value="${values[$i]}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS requires an empty string after -i
        sed -i '' "s/{{${key}}}/${value}/g" .env
    else
        # Linux and other UNIX-like systems do not require the empty string
        sed -i "s/{{${key}}}/${value}/g" .env
    fi
done

exit 0
