#!/bin/bash

set -e

git pull

cd packages || {
    echo "Failed to change directory to 'packages'"
    exit 1
}

for dir in */; do
    echo "Pulling latest to $dir"

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
yarn build.heartwood

rm -f yarn.lock >/dev/null 2>&1
rm -f package-lock.json >/dev/null 2>&1
