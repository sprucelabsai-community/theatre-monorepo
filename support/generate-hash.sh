#!/bin/bash

get_combined_checksum() {
    local root_dir=$1
    local temp_file=$(mktemp)
    local combined_hash

    # Find files matching the pattern and exclude 'event-cache.json'
    find "$root_dir" -path "./packages/*/build/*" -type f \
        ! -name "event-cache.json" -print0 |
        sort -z | while IFS= read -r -d '' file; do
        md5sum "$file" >>"$temp_file"
    done

    # Include the yarn.lock file if it exists
    if [ -f "./yarn.lock" ]; then
        md5sum "./yarn.lock" >>"$temp_file"
    fi

    # Sort hashes for consistent order, then hash all hashes together
    combined_hash=$(sort "$temp_file" | md5sum | awk '{print $1}')
    rm -f "$temp_file" # Clean up temp file

    echo "$combined_hash"
}

main() {
    local root_dir="./"
    if [ ! -d "$root_dir" ]; then
        echo "Directory $root_dir does not exist."
        exit 1
    fi

    checksum=$(get_combined_checksum "$root_dir")
    echo -e "$checksum"
}

main
