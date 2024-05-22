#!/bin/bash

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

hero() {
    local text="$1"

    local colors=("$RED" "$GREEN" "$YELLOW" "$BLUE" "$MAGENTA" "$CYAN")
    local random_color=${colors[$RANDOM % ${#colors[@]}]}

    local length=${#text}
    local padding=$((length + 4))

    echo -e "${random_color}$(printf '=%.0s' $(seq 1 $padding))${NC}"
    echo -e "${random_color}|  $text  |${NC}"
    echo -e "${random_color}$(printf '=%.0s' $(seq 1 $padding))${NC}"
}

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

./support/register-skills.sh

hero "Logging in as existing skills..."

./support/login-skills.sh

hero "Publishing core skills..."

./support/publish-skills.sh

hero "Booting..."

yarn boot.serve

hero "Theatre setup complete! Visit http://localhost:8080"
