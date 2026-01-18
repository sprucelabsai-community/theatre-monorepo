#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [namespace]"
    exit 1
fi

# if $0 == 'mercury' the vendor is 'spruce'
if [ "$1" == "mercury" ]; then
    echo "spruce"
    exit 0
fi

namespace=$1
matches=()

for dir in packages/*-"$namespace"-skill; do
    if [ -d "$dir" ]; then
        vendor=$(echo "$dir" | sed -E 's/packages\/(.*)-'"$namespace"'-skill/\1/')

        # If lookup namespace has no dashes, skip matches where vendor has dashes
        # This prevents "shifts" from matching "spruce-seven-shifts-skill"
        # (where the actual namespace is "seven-shifts", not "shifts")
        if [[ "$namespace" != *-* ]] && [[ "$vendor" == *-* ]]; then
            continue
        fi

        matches+=("$vendor")
    fi
done

if [ ${#matches[@]} -eq 0 ]; then
    echo "Error: No vendor found for namespace '$namespace'"
    exit 1
elif [ ${#matches[@]} -gt 1 ]; then
    echo "Error: Multiple vendors found for namespace '$namespace':"
    printf "  %s\n" "${matches[@]}"
    exit 1
else
    echo "${matches[0]}"
fi
