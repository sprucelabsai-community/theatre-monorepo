#!/usr/bin/env bash

# Usage: ./boot-skill-forever.sh <skill_directory>

skill_dir=$1

# Set up a trap to kill all child processes when this script exits
trap "exit" INT TERM
trap "kill 0" EXIT

# Continuously try to boot the skill with a 10-second delay
while true; do
    cd "$skill_dir"
    yarn boot
    sleep 10
done
