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

echo "Starting to update dependencies..."

# remove if exists
rm -rf node_modules/npm >/dev/null 2>&1

echo "Removing yarn lock..."

rm -f yarn.lock >/dev/null 2>&1

echo "Removing npm lock..."

rm -f package-lock.json >/dev/null 2>&1

echo "Installing dependencies..."

yarn

yarn build

rm -f yarn.lock >/dev/null 2>&1
rm -f package-lock.json >/dev/null 2>&1
