#!/usr/bin/env bash

# Usage
if [ -z "$1" ]; then
    echo "Usage: $0 <skill_dir>"
    exit 1
fi

skill_dir="$1"

# Navigate to the skill directory
cd "$skill_dir" || exit 1

# Use git ls-remote to get the default branch name
default_branch=$(git ls-remote --symref origin HEAD | grep 'ref:' | sed 's/.*refs\/heads\/\(.*\)\tHEAD/\1/')
echo "$default_branch"
