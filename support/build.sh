#!/usr/bin/env bash

source ./support/hero.sh

hero "Building skills..."

echo "Checking build strategy..."

build_strategy="parallel"
should_boot_message_receiver=false

THEATRE=$(node ./support/blueprint.js blueprint.yml theatre)
BUILD_STRATEGY=$(echo "$THEATRE" | jq -r '.BUILD_STRATEGY' 2>/dev/null)

if [ "$BUILD_STRATEGY" != null ]; then
    build_strategy=$BUILD_STRATEGY
fi

if [ "$build_strategy" = "series" ]; then
    echo "Building skills in series..."
    yarn run build.serial
else
    echo "Building skills in parallel..."
    yarn run build.parallel
fi

yarn bundle.heartwood
