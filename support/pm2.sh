#!/bin/bash

# Get the absolute path of the support directory
support_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Get the absolute path of the monorepo root directory
monorepo_root=$(cd "$support_dir/.." && pwd)

# Set the PM2_HOME environment variable relative to the monorepo root
export PM2_HOME="$monorepo_root/.pm2"

# Execute the pm2 command with the provided arguments
pm2 "$@"
