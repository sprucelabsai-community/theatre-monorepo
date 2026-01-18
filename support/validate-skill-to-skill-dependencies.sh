#!/bin/bash

errors=()

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

        # Try to resolve the skill dir, capturing stderr for error details
        resolve_error=$(./support/resolve-skill-dir.sh "$dep_namespace" 2>&1)
        if [ $? -ne 0 ]; then
            # Check if the error is due to multiple matches
            if echo "$resolve_error" | grep -q "Multiple vendors found"; then
                # Extract the matching vendors and convert to full directory names
                vendors=$(echo "$resolve_error" | tail -n +2 | sed 's/^[[:space:]]*//' | grep -v '^$')
                match_dirs=""
                while read -r vendor; do
                    if [ -n "$match_dirs" ]; then
                        match_dirs="$match_dirs, "
                    fi
                    match_dirs="${match_dirs}${vendor}-${dep_namespace}-skill"
                done <<< "$vendors"
                errors+=("Unable to resolve '$dep_namespace' because there are multiple matches: $match_dirs (referenced in $skill_dir)")
            else
                errors+=("Unable to resolve '$dep_namespace': $resolve_error (referenced in $skill_dir)")
            fi
        fi
    done <<<"$dependencies"
done

if [ ${#errors[@]} -gt 0 ]; then
    echo "Skill dependency errors:"
    for err in "${errors[@]}"; do
        echo "  - $err"
    done
    exit 1
else
    echo "All skill dependencies are present."
fi
