#!/bin/bash

set -e

# if any arguments are passed, we'll use update-skill.sh
if [ $# -ge 1 ]; then
    ./support/update-skill.sh "$@"
    exit 0
fi

git pull

cd packages || {
    echo "Failed to change directory to 'packages'"
    exit 1
}

# if any dir has local changes, blow up
for dir in */; do
    if [ -d "$dir" ]; then
        if ! git -C "$dir" diff --quiet; then
            echo "There are local changes in $dir. Please commit or stash them before updating."
            exit 1
        fi
    fi
done

for dir in */; do
    echo "Pulling latest from $dir"

    (
        cd "$dir" || {
            echo "Failed to change directory to '$dir'"
            exit 1
        }
        git checkout .
        if ! git pull; then
            echo "Failed to pull latest for $dir"
            exit 1
        fi
    ) &
done

#wait for all to finish
wait

echo "Done pulling latest..."

cd ..

echo "Starting rebuild..."

yarn rebuild

echo "Rebuild done."
echo "Please restart the Theatre (yarn reboot) to apply changes."
