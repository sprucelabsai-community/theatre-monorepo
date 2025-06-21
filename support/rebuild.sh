#!/bin/bash

# Default to false unless explicitly set
shouldOpenVsCodeOnFail=false

# Parse arguments
for arg in "$@"; do
    case $arg in
    --shouldOpenVsCodeOnFail=*)
        shouldOpenVsCodeOnFail="${arg#*=}"
        ;;
    esac
done

source ./support/hero.sh

hero "Cleaning old build files..."
yarn clean

# Handle the lock file by executing the script
./support/handle-lock-file.sh "blueprint.yml"

hero "Starting to update dependencies..."
rm -rf node_modules

./support/yarn.sh

hero "Building..."
if [ "$shouldOpenVsCodeOnFail" = true ]; then
    yarn run build.ci
else
    yarn run build
fi
build_exit_code=$?

if [ $build_exit_code -ne 0 ]; then
    echo "Build failed! Checking for type errors in individual packages..."

    if [ "$shouldOpenVsCodeOnFail" = true ]; then
        # Loop through all packages and check for type errors
        for package in ./packages/*; do
            if [ -d "$package" ]; then
                echo "Checking $package for type errors..."

                # Run TypeScript type check for the specific package
                yarn --cwd "$package" tsc --noEmit >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    echo "Type errors found in $package. Opening in VSCode..."
                    code "$package"
                fi
            fi
        done
    else
        echo "Build failed, but --shouldOpenVsCodeOnFail=false. Exiting."
    fi
else
    hero "Build completed successfully!"
fi
