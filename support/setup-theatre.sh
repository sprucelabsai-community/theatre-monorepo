#!/bin/bash

source ./support/hero.sh

# Function to print usage and exit
usage() {
    echo "Usage: yarn setup.theatre <blueprint.yml> [--shouldRunUntil=<step>] [--shouldServeHeartwood=<true|false>]"
    echo "Steps: build"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -lt 1 ]; then
    usage
fi

blueprint=$1
shouldRunUntil=""
shouldServeHeartwood=true
shouldServeHeartwood=true

# Parse arguments
for arg in "$@"; do
    case $arg in
    --shouldRunUntil=*)
        shouldRunUntil="${arg#*=}"
        shift
        ;;
    --shouldServeHeartwood=*)
        shouldServeHeartwood="${arg#*=}"
        shift
        ;;
    --shouldServeHeartwood=*)
        shouldServeHeartwood="${arg#*=}"
        shift
        ;;
    *.yml)
        blueprint=$arg
        shift
        ;;
    *)
        usage
        ;;
    esac
done

if [ ! -f "$blueprint" ]; then
    echo "Error: Blueprint file '$blueprint' does not exist."
    exit 1
fi

hero "Setting up theatre dependencies..."

yarn

hero "Syncing skills with blueprint..."

./support/sync-skills-with-blueprint.sh $blueprint

# Check if we should end the script after the build step
if [ "$shouldRunUntil" == "syncSkills" ]; then
    hero "Reached 'syncSkills' step. Exiting as requested."
    exit 0
fi

hero "Pulling skill dependencies..."

yarn

# Check if we should end the script after the build step
if [ "$shouldRunUntil" == "skillDependencies" ]; then
    hero "Reached 'skillDependencies' step. Exiting as requested."
    exit 0
fi

hero "Building skills..."

yarn build

# Check if we should end the script after the build step
if [ "$shouldRunUntil" == "build" ]; then
    hero "Reached 'build' step. Exiting as requested."
    exit 0
fi

yarn shutdown

# Boot mercury if packages/spruce-mercury-api exists
if [ -d "packages/spruce-mercury-api" ]; then
    hero "Booting Mercury..."

    yarn boot mercury

    sleep 3
fi

#if there is a mercury block in the bluprint, use it's port
MERCURY_SECTION=$(node ./support/blueprint.js $blueprint mercury)
MERCURY_PORT=$(echo "$MERCURY_SECTION" | jq -r '.port')

echo "HOST=http://127.0.0.1:${MERCURY_PORT:-8081}" >.env

hero "Logging in using cli..."

./support/login.sh $blueprint

hero "Registering all new skills..."

./support/register-skills.sh --shouldForceRegister=true

hero "Logging in as any existing skills..."

./support/login-skills.sh

hero "Publishing core skills..."

./support/publish-skills.sh

hero "Booting..."

if [ "$shouldServeHeartwood" = true ]; then
    yarn boot.serve
else
    yarn boot
fi

wait

hero "Theatre setup complete!"
