#!/bin/bash

# Check if a commit message was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <commit_message>"
    exit 1
fi

commit_message="$1"

cd packages

for skill_dir in *-skill; do
    echo "Committing changes for $skill_dir..."

    cd "$skill_dir"

    git add .
    git commit -m "$commit_message"
    git pull
    git push

    cd ..
done
