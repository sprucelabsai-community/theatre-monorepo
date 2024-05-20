#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [namespace]"
    exit 1
fi

namespace=$1
matches=()

for dir in packages/*-"$namespace"-skill; do
    if [ -d "$dir" ]; then
        vendor=$(echo "$dir" | sed -E 's/packages\/(.*)-'"$namespace"'-skill/\1/')
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
