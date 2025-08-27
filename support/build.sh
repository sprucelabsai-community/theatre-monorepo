#!/usr/bin/env bash

source ./support/hero.sh
source ./support/get_environment.sh

# Check for namespace argument
namespace=""
vendor="spruce" # Default vendor
if [ $# -ge 1 ]; then

    hero "Building skill: $1"

    namespace="$1"
    # Resolve vendor if not provided
    if [ $# -ge 2 ]; then
        vendor="$2"
    else
        vendor=$(./support/resolve-vendor.sh "$namespace")
    fi

    # Navigate to the skill directory and build it
    skill_dir="packages/${vendor}-${namespace}-skill"
    if [ -d "$skill_dir" ]; then
        echo "Building: ${vendor}-${namespace}-skill..."
        cd "$skill_dir"
        yarn build.dev
        exit 0
    else
        echo "Error: Skill directory ${skill_dir} not found."
        exit 1
    fi
fi

hero "Building Skills"
echo "Checking build strategy..."

build_strategy="parallel"
should_boot_message_receiver=false

THEATRE=$(node ./support/blueprint.js blueprint.yml theatre)
BUILD_STRATEGY=$(echo "$THEATRE" | jq -r '.BUILD_STRATEGY' 2>/dev/null)

if [ "$BUILD_STRATEGY" != null ]; then
    build_strategy=$BUILD_STRATEGY
fi

if [ "$ENVIRONMENT" = "production" ]; then
    if [ "$build_strategy" = "serial" ]; then
        echo "Building skills in production (serial)..."
        yarn run build.serial
    else
        echo "Building skills in production (parallel)..."
        yarn run build.parallel
    fi
else
    if [ "$build_strategy" = "serial" ]; then
        echo "Building skills in development (serial)..."
        yarn run build.dev.serial
    else
        echo "Building skills in development (parallel)..."
        yarn run build.dev.parallel
    fi
fi

yarn bundle.heartwood
