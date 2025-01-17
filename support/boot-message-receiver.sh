#!/usr/bin/env bash

source ./support/hero.sh

hero "Starting Message Receiver..."

./support/boot-pm2-process.sh \
    --name "message-receiver" \
    --command "boot.message.receiver" \
    --cwd "packages/spruce-mercury-api" \
    --out_file ".processes/logs/message-receiver-out.log" \
    --error_file ".processes/logs/message-receiver-error.log"
