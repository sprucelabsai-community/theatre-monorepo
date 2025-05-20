#!/bin/bash

source ./support/hero.sh

# Check for at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <namespace> [vendor]"
    echo "Example: $0 heartwood"
    exit 1
fi

namespace="$1"
vendor="$2"

hero "Updating $namespace..."

# Use resolve-skill-dir.sh to get the directory name
skill_dir_name=$(./support/resolve-skill-dir.sh "$namespace" "$vendor")

cd packages/$skill_dir_name

# if there are local changes, blow up
if ! git diff --quiet; then
    echo "There are local changes in $skill_dir_name. Please commit or stash them before updating."
    exit 1
fi

git checkout .
git pull
rm yarn.lock
rm package-lock.json
yarn
yarn build.dev

if [ "$namespace" == "heartwood" ]; then
    yarn build.cdn
fi

hero "$namespace has been updated"
