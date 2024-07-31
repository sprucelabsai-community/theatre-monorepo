#!/bin/bash

# Default values
BLUEPRINT_PATH="/default/path/blueprint.yml"
ARCH=""

# Function to print usage
print_usage() {
    echo "Usage: $0 --arch=<ubuntu-x86|ubuntu-arm> [--blueprintPath=<path>]"
    echo "  arch: Specify the architecture (ubuntu-x86 or ubuntu-arm)"
    echo "  --blueprintPath: Optional. Specify the path to the blueprint file"
}

# Parse arguments
for arg in "$@"
do
    case $arg in
        --arch=*)
        ARCH="${arg#*=}"
        ;;
        --blueprintPath=*)
        BLUEPRINT_PATH="${arg#*=}"
        ;;
        *)
        echo "Unknown parameter: $arg"
        print_usage
        exit 1
        ;;
    esac
done

# Validate architecture
if [[ "$ARCH" != "ubuntu-x86" && "$ARCH" != "ubuntu-arm" ]]; then
    echo "Error: Invalid architecture. Must be either ubuntu-x86 or ubuntu-arm."
    print_usage
    exit 1
fi

# Ensure arch is provided
if [[ -z "$ARCH" ]]; then
    echo "Error: Architecture must be specified."
    print_usage
    exit 1
fi

# Determine Dockerfile path based on architecture
DOCKERFILE_PATH="support/dockerfile.$ARCH"

# Build the Docker command
DOCKER_CMD="docker build --no-cache --progress=plain -f $DOCKERFILE_PATH -t $ARCH --build-arg BLUEPRINT_PATH=${BLUEPRINT_PATH} ."

# Echo the command (optional, for debugging)
echo "Executing: $DOCKER_CMD"

# Execute the Docker command
eval $DOCKER_CMD