#!/bin/bash

cd packages/spruce-heartwood-skill
yarn build.cdn

sed -i "s/{{version}}/${timestamp}/g" ./dist/index.html
