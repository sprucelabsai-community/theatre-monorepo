#!/bin/bash

source ./support/hero.sh

if [ $# -ne 1 ]; then
    echo "Usage: yarn setup.theatre <blueprint.yml>"
    exit 1
fi

blueprint=$1

if [ ! -f "$blueprint" ]; then
    echo "Error: Blueprint file '$blueprint' does not exist."
    exit 1
fi

hero "Setting up theatre dependencies..."

yarn

hero "Syncing skills with blueprint..."

./support/sync-skills-with-blueprint.sh $blueprint

hero "Pulling skill dependencies..."

yarn

hero "Building skills..."

yarn build

hero "Booting Mercury..."

yarn boot mercury

sleep 3

hero "Logging in using cli..."

./support/login.sh $blueprint

hero "Registering all new skills..."

./support/register-skills.sh --shouldForceRegister=true

hero "Logging in as any existing skills..."

./support/login-skills.sh

hero "Publishing core skills..."

./support/publish-skills.sh

hero "Booting..."

yarn boot.serve >/dev/null &

wait

hero "Theatre setup complete! Visit http://localhost:8080"
