#!/bin/bash

# Check if the correct number of arguments has been provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <branch_name>"
    exit 1
fi

# Store the branch name provided by the user
branch_name="$1"

# Change to the 'packages' directory where the repositories are located
cd packages

# Iterate over all directories that match the pattern *-skill
for skill_dir in *-skill; do
    (
        # Notify the user that the specific directory is being updated
        echo "Pulling latest for $skill_dir..."

        # Change to the directory of the skill
        cd "$skill_dir"

        # Fetch all branches from the origin
        git fetch origin

        # Check if the specified branch exists in the remote repository
        if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
            # If the branch exists, check it out and pull the latest changes from the origin
            git checkout "$branch_name"
            git pull origin "$branch_name"
        else
            # If the branch does not exist, echo a message indicating that the branch is missing
            echo "Branch '$branch_name' does not exist in $skill_dir, skipping..."
        fi

        # Navigate back to the 'packages' directory to process the next skill directory
        cd ..
    ) &
done

# Wait for all background processes to finish
wait

# Notify the user that all skills have been updated
echo "All skills have been pulled from the branch $branch_name."
