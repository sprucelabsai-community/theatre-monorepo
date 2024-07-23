#!/bin/bash

# if any arguments, call reboot-skill.sh
if [ $# -ge 1 ]; then
    ./support/reboot-skill.sh "$@"
    exit $?
fi

yarn shutdown

wait

./support/pm2.sh kill

rm -rf ./.pm2

sleep 2

wait

yarn boot.serve
