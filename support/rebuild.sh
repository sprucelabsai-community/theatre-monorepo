#!/bin/bash

source ./support/hero.sh

hero "Shutting down all skills..."
./support/shutdown.sh

hero "Killing PM2..."
./support/pm2.sh kill
rm -rf ./.pm2

hero "Cleaning old build files..."
yarn clean

hero "Starting to update dependencies..."
rm -rf node_modules
yarn

hero "Building..."
yarn run build
