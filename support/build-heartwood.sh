#!/bin/bash

cd packages/spruce-heartwood-skill
yarn build.cdn

timestamp=$(date +%s)
sed -i "s/{{version}}/${timestamp}/g" ./dist/index.html
