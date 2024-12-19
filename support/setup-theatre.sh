#!/bin/bash

source ./support/hero.sh

# Function to print usage and exit
usage() {
    echo "Usage: yarn setup.theatre <blueprint.yml> [--runUntil=<step>] [--shouldServeHeartwood=<true|false>]"
    echo "Steps: build"
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -lt 1 ]; then
    usage
fi

blueprint=$1
runUntil=""
shouldServeHeartwood=true

# Parse arguments
for arg in "$@"; do
    case $arg in
    --runUntil=*)
        runUntil="${arg#*=}"
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

# check for required options in the blueprint (admin.PHONE), if missing, exit 1
ADMIN_SECTION=$(node support/blueprint.js $blueprint admin)
PHONE=$(echo "$ADMIN_SECTION" | jq -r '.PHONE')
if [ -z "$PHONE" ]; then
    echo "ERROR: The admin phone number is missing in your blueprint.yml. Add\n\nadmin:\n  PHONE: <phone number>"
    exit 1
fi

#if there is a mercury block in the bluprint, use it's port
ENV=$(node support/blueprint.js $blueprint env)
MERCURY_PORT=$(echo "$ENV" | jq -r '.mercury[] | select(has("PORT")) | .PORT' 2>/dev/null)
echo "HOST=\"http://127.0.0.1:${MERCURY_PORT:-8081}\"" >.env

#if there is a env.universal.DB_CONNECTION_STRING in the bluprint, use it
DB_CONNECTION_STRING=$(echo "$ENV" | jq -r '.universal[] | select(has("DB_CONNECTION_STRING")) | .DB_CONNECTION_STRING' 2>/dev/null)

hero "Updating Theatre..."
git pull

hero "Setting up theatre dependencies..."

#if there is a theatre.lock file in the blueprint, dowload it before installing
THEATRE=$(node support/blueprint.js $blueprint theatre)
LOCK=$(echo "$THEATRE" | jq -r '.LOCK' 2>/dev/null)

if [ "$LOCK" != null ]; then
    echo "Downloading lock file..."
    curl -O $LOCK
fi

#if there is a theatre.should_serve_heartwood in the blueprint, use it
SHOULD_SERVE_HEARTWOOD=$(echo "$THEATRE" | jq -r '.SHOULD_SERVE_HEARTWOOD' 2>/dev/null)
if [ "$SHOULD_SERVE_HEARTWOOD" == "false" ]; then
    shouldServeHeartwood=false
fi

yarn

hero "Syncing skills with blueprint..."

./support/sync-skills-with-blueprint.sh $blueprint

# Check if we should end the script after the build step
if [ "$runUntil" == "syncSkills" ]; then
    hero "Reached 'syncSkills' step. Exiting as requested."
    exit 0
fi

hero "Pulling skill dependencies..."

yarn

# Check if we should end the script after the build step
if [ "$runUntil" == "skillDependencies" ]; then
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

hero "Logging in using cli..."

./support/login.sh $blueprint

hero "Registering all new skills..."

./support/register-skills.sh --shouldForceRegister=true

hero "Logging in as any existing skills..."

./support/login-skills.sh

hero "Publishing core skills..."

./support/publish-skills.sh --mongoConnectionString="$DB_CONNECTION_STRING"

hero "Booting..."

if [ "$shouldServeHeartwood" = true ]; then
    yarn boot.serve
else
    yarn boot
fi

wait

hero "Theatre setup complete!"
