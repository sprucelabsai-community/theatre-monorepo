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

echo "Checking $skill_dir..."

# Navigate to the skill directory
cd "$skill_dir" || exit

# If hard, clobber all local changes
if [ "$hard" == "true" ]; then
    git reset --hard
fi

# Determine the branch to use
if [ -z "$branch" ]; then
    # Call the resolve-default-branch.sh script to get the default branch name
    branch=$(./../../support/resolve-default-branch.sh "$skill_dir")
fi

echo "Branch to use: $branch"

# Checkout the specified branch and pull the latest changes
git checkout "$branch"
git pull

hero "Checked out $skill_dir to $branch"
