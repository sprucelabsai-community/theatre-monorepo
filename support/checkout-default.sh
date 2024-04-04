#!/usr/bin/env bash

cd packages

for skill_dir in *-skill *-api; do
    ../support/checkout-default-skill.sh "$@" "$skill_dir" &
done

# Wait for all background processes to finish
wait

echo "All skills have been updated to their default branches."

cd ..

yarn
