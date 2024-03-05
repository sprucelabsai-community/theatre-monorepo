#!/bin/bash

git pull

cd packages || exit 1

for dir in */; do
    (
        echo "Updating $dir"
        cd "$dir" || continue
        git checkout .
        git pull
    ) &
done

#wait for all to finish
wait

cd ..

# remove if exists
rm -rf node_modules/npm
rm yarn.lock
rm package-lock.json
yarn

yarn build
yarn build.heartwood
rm yarn.lock
rm package-lock.json
