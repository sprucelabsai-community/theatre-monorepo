#!/bin/bash

# Default vendor
vendor="spruce"

source ./support/hero.sh

# Check for at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <namespaceOrDirName> [vendor]"
    echo "Example: $0 heartwood"
    exit 1
fi

# Assign arguments
namespace="$1"
vendor="$2"

skill_dir_name=$(./support/resolve-skill-dir.sh "$namespace" "$vendor")

cd packages/$skill_dir_name

hero "Upgrading $skill_dir_name..."

git checkout .
git pull
rm yarn.lock
rm package-lock.json
spruce upgrade
cd ../../
yarn
