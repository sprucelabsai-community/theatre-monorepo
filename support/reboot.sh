#!/bin/bash

shouldServeHeartwood=true

# Parse arguments
for arg in "$@"; do
    case $arg in
    --shouldServeHeartwood=*)
        shouldServeHeartwood="${arg#*=}"
        shift
        ;;
    *)
        # If any other arguments are provided, call reboot-skill.sh
        ./support/reboot-skill.sh "$@"
        exit $?
        ;;
    esac
done

yarn shutdown --shouldListRunning=false

source ./support/hero.sh

hero "Resetting reboot counts..."

./support/pm2.sh reset all --silent

# check if heartwood is installed at packages/spruce-heartwood-skill
if [ ! -d packages/spruce-heartwood-skill ]; then
    shouldServeHeartwood=false
fi

if [ "$shouldServeHeartwood" = true ]; then
    yarn boot.serve
else
    yarn boot
fi
