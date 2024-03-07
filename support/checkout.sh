#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <branch_name>"
    exit 1
fi

branch_name="$1"

cd packages

for skill_dir in *-skill; do
    (
        echo "Checkout out $skill_dir..."

        cd "$skill_dir"

        git checkout "$branch_name"
        git pull origin "$branch_name"
    ) &
done

# Wait for all background processes to finish
wait

echo "All skills have been checked out to $branch_name."

cd ..

yarn
