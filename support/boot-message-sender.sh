#!/usr/bin/env bash

source ./support/hero.sh

hero "Starting Message Sender..."

./support/boot-pm2-process.sh \
	--name "message-sender" \
	--command "boot.message.sender" \
	--cwd "packages/spruce-mercury-api" \
	--out_file ".processes/logs/message-sender-out.log" \
	--error_file ".processes/logs/message-sender-error.log"
