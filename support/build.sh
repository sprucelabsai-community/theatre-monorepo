#!/usr/bin/env bash

source ./support/hero.sh
source ./support/get_environment.sh

# Check for namespace argument
namespace=""
if [ $# -ge 1 ]; then

	hero "Building skill: $1"

	namespace="$1"
	args=("$namespace")
	if [ $# -ge 2 ]; then
		args+=("$2")
	fi

	skill_dir=$(./support/resolve-skill-dir.sh "${args[@]}")
	status=$?
	if [ $status -ne 0 ]; then
		exit $status
	fi

	echo "Building: ${skill_dir}..."
	cd "packages/$skill_dir"
	yarn build.dev
	exit 0
fi

hero "Building Skills"
echo "Checking build strategy..."

build_strategy="parallel"
should_boot_message_receiver=false
should_boot_message_sender=false

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
