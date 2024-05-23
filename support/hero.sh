# hero.sh

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
    local padding=$((length + 6))

    printf "${random_color}$(printf '=%.0s' $(seq 1 $padding))${NC}\n"
    printf "${random_color}|  %s  |${NC}\n" "$text"
    printf "${random_color}$(printf '=%.0s' $(seq 1 $padding))${NC}\n"
}
