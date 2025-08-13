#!/usr/bin/env bash

# Usage: open-in-vs-code.sh <match>
# <match> is a pattern to match directory names inside ./packages/
# Example: open-in-vs-code.sh utils
# This will open all directories in ./packages/ whose names contain "utils" in VS Code.
# You can also use partial names or substrings to match multiple directories.
# Options:
#   -h, --help    Show this help message and exit

match="$1"

if [ "$match" = "-h" ] || [ "$match" = "--help" ]; then
    grep '^#' "$0" | sed 's/^# //'
    exit 0
fi

if [ -z "$match" ]; then
    echo "Usage: $0 <match-pattern>"
    exit 1
fi

for dir in ./packages/*; do
    if [[ -d "$dir" && "$(basename "$dir")" == *"$match"* ]]; then
        echo "Opening $dir in VS Code..."
        code "$dir"
    fi
done
