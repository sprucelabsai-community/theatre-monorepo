#!/usr/bin/env bash

source ./support/hero.sh

hero "Starting production build..."

read -p "Building for production will overwrite all local changes, are you sure? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Cancelling."
    exit 1
fi

yarn
yarn run update --shouldCheckForPendingChanges=false --shouldRebuild=false

export ENVIRONMENT=production

./support/build.sh

hero "Cleaning up..."

rm -rf node_modules

hero "Installing only production dependencies..."

./support/yarn.sh

hero "Recursively deleting all type files..."

find . -name "*.d.ts" -type f -delete

hero "Recursively deleting all esm files in all @sprucelabs packages..."

find . -path "*/node_modules/@sprucelabs/*/esm" -type d -exec rm -rf {} +

hero "Cleaning up extra Heartwood files..."

rm -rf ./packages/spruce-heartwood-skill/public
find ./packages/spruce-heartwood-skill -type d -name "storybook-support" -exec rm -rf {} +

hero "Removing all src directories..."

find ./packages -type d -name "src" -exec rm -rf {} +

hero "Production build completed successfully!"
