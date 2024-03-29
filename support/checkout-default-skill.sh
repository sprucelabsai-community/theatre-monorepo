#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <skill_directory>"
    exit 1
fi

skill_dir=$1

echo "Checking $skill_dir..."

# Navigate to the skill directory
cd "$skill_dir" || exit

git checkout .

# Use git ls-remote to get the default branch name
default_branch=$(git ls-remote --symref origin HEAD | grep 'ref:' | sed 's/.*refs\/heads\/\(.*\)\tHEAD/\1/')

echo "Default Branch: $default_branch"

# Checkout the default branch and pull the latest changes
git checkout "$default_branch"
git pull
