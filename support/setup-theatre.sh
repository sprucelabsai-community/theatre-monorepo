#!/bin/bash

source ./support/hero.sh

set -e

# Function to print usage and exit
usage() {
    echo "Usage: yarn setup.theatre <blueprint.yml> [--runUntil=<step>] [--startFrom=<step>] [--shouldValidateSkillDependencies=<true|false>]"
    echo "Steps: update, syncSkills, skillDependencies, build, publish"
    exit 1
}

run_remaining_steps=false

should_run_step() {
    local step="$1"
    # If startFrom is empty, run all steps
    if [ -z "$startFrom" ]; then
        return 0
    fi
    # If we've already reached the starting step, continue running
    if [ "$run_remaining_steps" = true ]; then
        return 0
    fi
    # If the current step matches startFrom, mark flag and run this step
    if [ "$startFrom" = "$step" ]; then
        run_remaining_steps=true
        return 0
    fi
    # Otherwise, skip this step
    return 1
}

# Check if the correct number of arguments is provided
if [ $# -lt 1 ]; then
    usage
fi

blueprint=$1
runUntil=""
startFrom=""
shouldValidateSkillDependencies=true

# Parse arguments
for arg in "$@"; do
    case $arg in
    --runUntil=*)
        runUntil="${arg#*=}"
        shift
        ;;
    --startFrom=*)
        startFrom="${arg#*=}"
        shift
        ;;
    --shouldValidateSkillDependencies=*)
        shouldValidateSkillDependencies="${arg#*=}"
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

if [ "$runUntil" != "" ]; then
    echo "Running until: $runUntil"
fi

if should_run_step "update"; then
    hero "Updating Theatre..."
    git pull

    hero "Setting up theatre dependencies..."
    ./support/yarn.sh
fi

# check for required options in the blueprint (admin.PHONE), if missing, exit 1
ADMIN_SECTION=$(node support/blueprint.js $blueprint admin)
PHONE=$(echo "$ADMIN_SECTION" | jq -r '.PHONE')
if [ -z "$PHONE" ]; then
    echo "ERROR: The admin phone number is missing in your blueprint.yml. Add\n\nadmin:\n  PHONE: <phone number>"
    exit 1
fi

#if there is a host in universal, us it for host
ENV=$(node support/blueprint.js $blueprint env)
HOST=$(echo "$ENV" | jq -r '.universal[] | select(has("HOST")) | .HOST' 2>/dev/null)
if [ -n "$HOST" ]; then
    echo "HOST=\"$HOST\"" >.env
else
    #if there is a mercury block in the bluprint, use it's port
    MERCURY_PORT=$(echo "$ENV" | jq -r '.mercury[] | select(has("PORT")) | .PORT' 2>/dev/null)
    echo "HOST=\"http://127.0.0.1:${MERCURY_PORT:-8081}\"" >.env
fi

#if there is a env.universal.DB_CONNECTION_STRING in the bluprint, use it
DB_CONNECTION_STRING=$(echo "$ENV" | jq -r '.universal[] | select(has("DB_CONNECTION_STRING")) | .DB_CONNECTION_STRING' 2>/dev/null)

if should_run_step "syncSkills"; then
    hero "Syncing skills with blueprint..."
    ./support/sync-skills-with-blueprint.sh $blueprint
fi

#if spruce-mercury-api exists and there is no mercury.ADMIN_NUMBERS, drop in PHONE to the env
if [ -d "packages/spruce-mercury-api" ]; then
    MERCURY_ADMIN_NUMBERS=$(echo "$ENV" | jq -r '.mercury[] | select(has("ADMIN_NUMBERS")) | .ADMIN_NUMBERS' 2>/dev/null)
    if [ -z "$MERCURY_ADMIN_NUMBERS" ]; then
        echo "ADMIN_NUMBERS=\"$PHONE\"" >>packages/spruce-mercury-api/.env
    fi
fi

# Validate skill dependencies if shouldValidateSkillDependencies is true
if [ "$shouldValidateSkillDependencies" = true ]; then
    ./support/validate-skill-to-skill-dependencies.sh
fi

# Check if we should end the script after the build step
if [ "$runUntil" == "syncSkills" ]; then
    hero "Reached 'syncSkills' step. Exiting as requested."
    exit 0
fi

if should_run_step "skillDependencies"; then
    # Handle the lock file by executing the script
    ./support/handle-lock-file.sh "$blueprint"

    hero "Pulling skill dependencies..."
    set +e
    ./support/yarn.sh
    set -e
fi

# Check if we should end the script after the build step
if [ "$runUntil" == "skillDependencies" ]; then
    hero "Reached 'skillDependencies' step. Exiting as requested."
    exit 0
fi

if should_run_step "build"; then
    set +e
    hero "Building skills..."
    yarn build
    set -e
fi

# Check if we should end the script after the build step
if [ "$runUntil" == "build" ]; then
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

# Check if we should end the script after the build step
if [ "$runUntil" == "publish" ]; then
    yarn shutdown
    hero "Reached 'publish' step. Exiting as requested."
    exit 0
fi

hero "Booting..."

yarn boot

wait

hero "Theatre setup complete!"
