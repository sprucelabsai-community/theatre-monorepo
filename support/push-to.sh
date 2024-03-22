#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <branch_name>"
    exit 1
fi

branch_name="$1"

cd packages

for skill_dir in *-skill *-api; do
    (
        cd "$skill_dir"
        # Check if the branch already exists
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            # Branch exists, so check it out and reset it to the latest code from the default branch
            git checkout "$branch_name"
            git reset --hard "origin/$default_branch"
        else
            # Branch does not exist, so create it based on the current (default) branch
            git checkout -b "$branch_name"
        fi

        # Push the branch to the remote repository, with force to overwrite any existing content
        git push -u origin "$branch_name" --force
    ) &
done

# Wait for all background processes to finish
wait

echo "All skills have been pushed to $branch_name."
