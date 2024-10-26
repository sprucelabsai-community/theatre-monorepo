#!/bin/bash

# Check if a commit message was provided
if [ $# -eq 0 ]; then
    echo "Usage: yarn commit.push.skills <commit_message>"
    exit 1
fi

source ./support/hero.sh

commit_message="$1"

cd packages

# Commit and push changes for each skill + spruce-mercury-api
for skill_dir in *-skill *-api; do
    (
        hero "Committing changes for $skill_dir..."

        cd "$skill_dir"

        git add .
        git commit -m "$commit_message"
        git pull
        git push

    ) &
done
