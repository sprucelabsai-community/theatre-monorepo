#!/usr/bin/env bash
echo "Cleaning up dependencies..."

find . -type d -name '@sprucelabs' -exec sh -c 'find "{}" -type d -name "@sprucelabs" -not -path "{}"' \; | xargs rm -r
find ./packages -type d -path '*/node_modules/@sprucelabs' | xargs rm -r
