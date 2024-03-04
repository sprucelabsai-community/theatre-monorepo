#!/bin/bash

# pull blueprint from args (should be first arg, if missing, output usage)
BLUEPRINT=$1

if [ -z "$BLUEPRINT" ]; then
    echo "Usage: $0 path/to/blueprint.yml"
    exit 1
fi

# loop through every dir inside of packages
# and run ./sync-config.sh {dir} {blueprint}
for dir in ../packages/*; do
    if [ -d "$dir" ]; then
        ./sync-config.sh $dir $BLUEPRINT
    fi
done
