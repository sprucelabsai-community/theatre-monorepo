#!/bin/bash

source ./support/hero.sh

hero "Cleaning old build files..."
yarn clean

hero "Starting to update dependencies..."
rm -rf node_modules
yarn

hero "Building..."
yarn run build
