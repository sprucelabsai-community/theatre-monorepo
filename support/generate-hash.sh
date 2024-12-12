#!/usr/bin/env bash

#!/bin/bash

# Function to generate a hash for a single Git repository
generate_git_hash() {
    local repo_dir=$1
    pushd "$repo_dir" >/dev/null || return 1

    # Get the latest commit hash
    local commit_hash=$(git rev-parse HEAD)

    # Hash of untracked and modified files
    local status_hash=$(git status --porcelain | sha256sum | awk '{print $1}')

    # Hash of unstaged changes
    local diff_hash=$(git diff | sha256sum | awk '{print $1}')

    # Combine hashes
    echo -n "$commit_hash$status_hash$diff_hash" | sha256sum | awk '{print $1}'

    popd >/dev/null || return 1
}

# Function to traverse all repos and combine their hashes
generate_monorepo_hash() {
    local root_dir=$1
    local final_hash=""

    # Hash for the main repository (if the root is a Git repo)
    if git -C "$root_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        final_hash+=$(generate_git_hash "$root_dir")
    fi

    # Loop through each package's Git repository
    for package in "$root_dir"/packages/*; do
        if [ -d "$package/.git" ]; then
            package_hash=$(generate_git_hash "$package")
            final_hash+="$package_hash"
        fi
    done

    # Compute the overall hash for the monorepo
    echo -n "$final_hash" | sha256sum | awk '{print $1}'
}

# Main script execution
MONOREPO_ROOT=$(pwd) # Adjust this to the path of your monorepo
monorepo_hash=$(generate_monorepo_hash "$MONOREPO_ROOT")
echo "$monorepo_hash"
