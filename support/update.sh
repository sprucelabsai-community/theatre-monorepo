#!/bin/bash

git pull

cd packages || exit 1

for dir in */; do
    (
        cd "$dir" || continue
        git pull
    ) &
done

cd ..

yarn
yarn build.skills

wait
