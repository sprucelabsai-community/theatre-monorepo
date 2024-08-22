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

yarn shutdown

wait

sleep 2

wait

if [ "$shouldServeHeartwood" = true ]; then
    yarn boot.serve
else
    yarn boot
fi
