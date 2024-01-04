#!/bin/bash

git pull

cd packages || exit 1

for dir in */; do
    (
        cd "$dir" || continue
        git checkout .
        git pull
    ) &
done

cd ..

yarn
rm yarn.lock
rm package-lock.json
yarn build
yarn build.heartwood
rm yarn.lock
rm package-lock.json
yarn
