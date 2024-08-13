#!/bin/bash

echo "Cleaning old build files..."
yarn clean

echo "Starting to update dependencies..."
rm -rf node_modules
yarn

echo "Building..."
yarn run build
