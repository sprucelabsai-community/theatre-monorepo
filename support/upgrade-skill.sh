#!/bin/bash

# Default vendor
vendor="spruce"

source ./support/hero.sh

# Default shouldBuild to true
shouldBuild="true"

# Check for at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <namespaceOrDirName> [vendor] [--shouldBuild=true|false]"
    echo "Example: $0 heartwood spruce --shouldBuild=false"
    exit 1
fi

# Assign arguments
namespace="$1"
vendor="$2"

# Parse --shouldBuild argument
if [[ "$2" == --shouldBuild=* ]]; then
    vendor="spruce"
    shouldBuild="${2#--shouldBuild=}"
elif [ -n "$3" ] && [[ "$3" == --shouldBuild=* ]]; then
    shouldBuild="${3#--shouldBuild=}"
fi

skill_dir_name=$(./support/resolve-skill-dir.sh "$namespace" "$vendor")

cd packages/$skill_dir_name

hero "Upgrading $skill_dir_name..."

git checkout .
git pull
rm yarn.lock
rm package-lock.json
spruce upgrade --shouldBuild=$shouldBuild
cd ../../
if [ "$shouldBuild" = "true" ]; then
    yarn
fi
