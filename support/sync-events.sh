#!/bin/bash

source ./support/hero.sh

for dir in packages/*-skill; do
    (
        cd $dir
        spruce sync.events >>/dev/null
    ) &
done

hero "Syncing events, this may take a few minutes..."

wait
