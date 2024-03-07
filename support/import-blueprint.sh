
#!/bin/bash

# Default values for options
shouldInferUnitCode=true

# Usage message
usage() {
    echo "Usage: $0 path/to/blueprint [--shouldInferUnitCode=[true|false]] [PARAMETER=value]..."
}

# Parse positional arguments
BLUEPRINT=$1
shift  # Remove the first argument, leaving only options and parameters

if [ -z "$BLUEPRINT" ]; then
    usage
    exit 1
fi

# Parse options and parameters
while [ $# -gt 0 ]; do
    case "$1" in
        --shouldInferUnitCode=*)
            shouldInferUnitCode="${1#*=}"
            ;;
        *=*)
            # Assuming arguments are in the form PARAMETER=value
            key="${1%%=*}"
            value="${1#*=}"
            # Export parameter for later use in sed command
            export "$key"="$value"
            ;;
        *)
            # Unknown option
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

echo "Processing blueprint: $BLUEPRINT"
echo "Should infer unit code: $shouldInferUnitCode"

# Convert BLUEPRINT to blueprint.yml in the base directory
cp "$BLUEPRINT" blueprint.yml

# Get the unit code from the hostname (default behavior)
if $shouldInferUnitCode 
  export UNIT_CODE="LUM-$(hostname | sed -e 's/mini-//' -e 's/\.lan$//')"
fi

# Replace parameters in the blueprint.yml
while read -r line; do
    if [[ "$line" =~ \{\{(.+)\}\} ]]; then
        param="${BASH_REMATCH[1]}"
        if [[ -v "$param" ]]; then
            sed -i "s|\{\{$param\}\}|${!param}|g" blueprint.yml
        fi
    fi
done < blueprint.yml

# Check for uncaught parameters in blueprint.yml and list them
uncaught_params=$(grep -o '{{[^}]*}}' blueprint.yml | sort | uniq)
if [ -n "$uncaught_params" ]; then
    echo "Error: Missing dynamic parameters detected in blueprint.yml."
    echo "These parameters can be passed via command line e.g. "
    echo "Usage: yarn import blueprint [...] PARAMETER1=value1 ..."
    echo "$uncaught_params"
    exit 1
fi

# Loop through every dir inside of packages
# and run ./propagate-blueprint.sh {dir} {blueprint} with "--configStrategy=replace"
for dir in packages/*; do
    if [ -d "$dir" ]; then
        ./support/propagate-blueprint.sh "$dir" blueprint.yml "--configStrategy=replace"
    fi
done
