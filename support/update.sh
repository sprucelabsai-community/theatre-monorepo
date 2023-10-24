#!/bin/bash

cd packages || exit 1

for dir in */; do
    (
        cd "$dir" || continue
        git pull && yarn rebuild
    ) &
done

wait
