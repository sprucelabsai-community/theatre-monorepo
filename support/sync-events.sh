#!/bin/bash

source ./support/hero.sh

for dir in packages/*-skill; do
    (
        cd $dir
        spruce sync.events
    ) &
done

wait
