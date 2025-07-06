#!/usr/bin/env bash

# Initialize variables
hard=false
branch=""

source ./support/hero.sh

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --hard) hard=true ;;
    --branchName=*) branch="${1#*=}" ;;
    *) skill_dir="$1" ;;
    esac
    shift
done

# Usage
if [ -z "$skill_dir" ]; then
    echo "Usage: $0 [--hard] <skill_dir> [--branchName=<branch>]"
    exit 1
fi

# Determine the branch to use
if [ -z "$branch" ]; then
    # Call the resolve-default-branch.sh script to get the default branch name
    branch=$(./support/resolve-default-branch.sh "$skill_dir")
fi

# Navigate to the skill directory
cd "$skill_dir" || exit

# If hard, clobber all local changes
if [ "$hard" == "true" ]; then
    git reset --hard
fi

echo "Branch to use: $branch"

# Checkout the specified branch and pull the latest changes
if git rev-parse --verify "$branch" >/dev/null 2>&1; then
    echo "Branch $branch exists locally. Checking out..."
    git checkout "$branch"
else
    echo "Branch $branch does not exist locally. Creating it..."
    git checkout -b "$branch"
fi

git pull

hero "Checked out $skill_dir to $branch"
