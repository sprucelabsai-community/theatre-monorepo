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

npm install --force
npm run build
