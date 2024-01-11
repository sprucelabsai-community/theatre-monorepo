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

# remove if exists
rm -rf node_modules/npm/lib/utils/explain-dep.js
yarn
rm yarn.lock
rm package-lock.json

yarn build
yarn build.heartwood
rm yarn.lock
rm package-lock.json
yarn
