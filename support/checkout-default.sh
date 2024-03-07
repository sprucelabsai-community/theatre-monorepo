#!/usr/bin/env bash

cd packages

for skill_dir in *-skill; do
    (
        cd $skill_dir
        echo "Checking $skill_dir..."

        # Use git ls-remote to get the default branch name
        default_branch=$(git ls-remote --symref origin HEAD | grep 'ref:' | sed 's/.*refs\/heads\/\(.*\)\tHEAD/\1/')

        echo "Default Branch: $default_branch"

        git checkout $default_branch
        git pull
    ) &
done

# Wait for all background processes to finish
wait

echo "All skills have been updated to their default branches."

cd ..

yarn
