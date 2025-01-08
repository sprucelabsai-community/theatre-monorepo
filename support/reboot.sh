#!/bin/bash

# Check if additional arguments are passed
if [ "$#" -gt 0 ]; then
    # Pass all arguments to reboot-skill.sh
    ./support/reboot-skill.sh "$@"
    exit $?
fi

yarn shutdown --shouldListRunning=false

source ./support/hero.sh

hero "Resetting reboot counts..."

./support/pm2.sh reset all --silent

yarn boot
