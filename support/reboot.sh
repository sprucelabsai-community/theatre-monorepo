#!/bin/bash

# if any arguments, call reboot-skill.sh
if [ $# -ge 1 ]; then
    ./support/reboot-skill.sh "$@"
    exit $?
fi

yarn shutdown
yarn boot
