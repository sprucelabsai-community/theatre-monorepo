#!/bin/bash

missing=()

for skill_dir in packages/*-skill; do
    settings="$skill_dir/src/.spruce/settings.json"
    if [ ! -f "$settings" ]; then
        continue
    fi

    dependencies=$(jq -c '.dependencies[]?' "$settings" 2>/dev/null)
    if [ -z "$dependencies" ]; then
        continue
    fi

    while read -r dep; do
        # Get namespace and vendor from dependency
        dep_namespace=$(echo "$dep" | jq -r '.namespace')
        dep_id=$(echo "$dep" | jq -r '.id // empty')

        # Skip if namespace is empty or "**"
        if [ -z "$dep_namespace" ] || [ "$dep_namespace" = "**" ]; then
            continue
        fi

        # Try to resolve the skill dir
        dep_dir=$(./support/resolve-skill-dir.sh "$dep_namespace" 2>/dev/null)
        if [ $? -ne 0 ]; then
            missing+=("$dep_namespace (referenced in $skill_dir)")
        fi
    done <<<"$dependencies"
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing skill dependencies:"
    for dep in "${missing[@]}"; do
        echo "  - $dep"
    done
    exit 1
else
    echo "All skill dependencies are present."
fi
