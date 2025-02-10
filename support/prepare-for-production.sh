#!/bin/bash

# Step 1: clean out development node_modules using npm
npm prune --production

# Step 2: remove src dirs in all packages/* directories
find packages -name src -type d -exec rm -rf {} +
