#!/usr/bin/env bash

# Usage: ./boot-skill-forever.sh <skill_directory>

skill_dir=$1

# Continuously try to boot the skill with a 10-second delay
while true; do
    cd "$skill_dir"
    yarn boot
    sleep 10
done
