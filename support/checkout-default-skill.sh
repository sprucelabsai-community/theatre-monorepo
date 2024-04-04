#!/usr/bin/env bash

# pull out optional --hard flag to clobber local changes
if [ "$1" == "--hard" ]; then
    hard=true
    shift
fi

# usage
if [ -z "$1" ]; then
    echo "Usage: $0 [--hard] <skill_dir>"
    exit 1
fi

skill_dir=$1

echo "Checking $skill_dir..."

# Navigate to the skill directory
cd "$skill_dir" || exit

# if hard, clobber all local changes
if [ "$hard" == "true" ]; then
    git reset --hard
fi

# Use git ls-remote to get the default branch name
default_branch=$(git ls-remote --symref origin HEAD | grep 'ref:' | sed 's/.*refs\/heads\/\(.*\)\tHEAD/\1/')

echo "Default Branch: $default_branch"

# Checkout the default branch and pull the latest changes
git checkout "$default_branch"
git pull
