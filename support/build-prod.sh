#!/usr/bin/env bash

source ./support/hero.sh

hero "Building for production..."

hero "Pulling all dependencies to build..."

./support/yarn.sh

export ENVIRONMENT=production

./support/build.sh

hero "Cleaning up..."

rm -rf node_modules

hero "Installing only production dependencies..."

rm yarn.lock
./support/yarn.sh
