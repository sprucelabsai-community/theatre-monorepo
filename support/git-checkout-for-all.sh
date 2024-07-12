#!/bin/bash

for dir in ~/theatre-monorepo/packages/* ; do
    if [ -d "$dir/.git" ]; then
        echo "Entering $dir"
        cd "$dir"
        
        if git show-ref --verify --quiet refs/heads/master; then
            git checkout master
            git pull
            yarn build.dev
        elif git show-ref --verify --quiet refs/heads/main; then
            git checkout main
            git pull
            yarn build.dev
        else
            echo "Neither master nor main branch found in $dir"
        fi
        
        cd ..
    fi
done