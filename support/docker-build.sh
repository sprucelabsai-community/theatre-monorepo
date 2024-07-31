#!/bin/bash
# Default values
BLUEPRINT_PATH="./blueprint.yml"
ARCH=""
SSH_PRIVATE_KEY=""
SSH_PUBLIC_KEY=""

# Function to print usage
print_usage() {
    echo "Usage: $0 --arch=<ubuntu-x86|ubuntu-arm> [--blueprintPath=<path>] [--sshPrivateKey=<path>] [--sshPublicKey=<path>]"
    echo "  --arch: Specify the architecture (ubuntu-x86 or ubuntu-arm)"
    echo "  --blueprintPath: Optional. Specify the path to the blueprint file"
    echo "  --sshPrivateKey: Optional. Specify the path to the SSH private key"
    echo "  --sshPublicKey: Optional. Specify the path to the SSH public key"
}

# Function to expand tilde in path
expand_path() {
    echo "${1/#\~/$HOME}"
}

# Parse arguments
for arg in "$@"; do
    case $arg in
    --arch=*)
        ARCH="${arg#*=}"
        ;;
    --blueprintPath=*)
        BLUEPRINT_PATH=$(expand_path "${arg#*=}")
        ;;
    --sshPrivateKey=*)
        SSH_PRIVATE_KEY=$(expand_path "${arg#*=}")
        ;;
    --sshPublicKey=*)
        SSH_PUBLIC_KEY=$(expand_path "${arg#*=}")
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

# Ask for SSH keys if not provided as arguments
if [[ -z "$SSH_PRIVATE_KEY" ]]; then
    read -p "Enter the path to your GitHub SSH private key: " SSH_PRIVATE_KEY_INPUT
    SSH_PRIVATE_KEY=$(expand_path "$SSH_PRIVATE_KEY_INPUT")
fi

if [[ -z "$SSH_PUBLIC_KEY" ]]; then
    read -p "Enter the path to your GitHub SSH public key: " SSH_PUBLIC_KEY_INPUT
    SSH_PUBLIC_KEY=$(expand_path "$SSH_PUBLIC_KEY_INPUT")
fi

# Validate SSH key files
if [[ ! -f "$SSH_PRIVATE_KEY" ]]; then
    echo "Error: SSH private key file not found at $SSH_PRIVATE_KEY"
    exit 1
fi

if [[ ! -f "$SSH_PUBLIC_KEY" ]]; then
    echo "Error: SSH public key file not found at $SSH_PUBLIC_KEY"
    exit 1
fi

# Determine Dockerfile path based on architecture
DOCKERFILE_PATH="support/dockerfile.$ARCH"

# Set the image name
IMAGE_NAME="theatre-$ARCH"

# Build the Docker command
DOCKER_CMD="docker build --no-cache --progress=plain -f $DOCKERFILE_PATH -t $IMAGE_NAME \
    --build-arg BLUEPRINT_PATH=${BLUEPRINT_PATH} \
    --build-arg SSH_PRIVATE_KEY_PATH=${SSH_PRIVATE_KEY} \
    --build-arg SSH_PUBLIC_KEY_PATH=${SSH_PUBLIC_KEY} \
    ."

# Echo the command (optional, for debugging)
echo "Executing: $DOCKER_CMD"

# Execute the Docker command
eval $DOCKER_CMD
