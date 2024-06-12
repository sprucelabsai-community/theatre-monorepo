#!/usr/bin/env bash

echo "
   _____                          
  / ___/____  _______  __________ 
  \__ \/ __ \/ ___/ ___/ _ \ 
 ___/ / /_/ / /  / /_/ / /__/  __/
/____/ .___/_/   \__,_/\___/\___/ 
    /_/                           
    ____                 __                                 __ 
   / __ \___ _   _____  / /___  ____  ____ ___  ___  ____  / /_
  / / / / _ \ | / / _ \/ / __ \/ __ \/ __ \`__ \/ _ \/ __ \/ __/
 / /_/ /  __/ |/ /  __/ / /_/ / /_/ / / / / / /  __/ / / / /_  
/_____/\___/|___/\___/_/\____/ .___/_/ /_/ /_/\___/_/ /_/\__/  
                            /_/    
    ____  __      __  ____                   
   / __ \/ /___ _/ /_/ __/___  _________ ___ 
  / /_/ / / __ \`/ __/ /_/ __ \/ ___/ __ \`__ \ 
 / ____/ / /_/ / /_/ __/ /_/ / /  / / / / / /
/_/   /_/\__,_/\__/_/  \____/_/  /_/ /_/ /_/ 
                                                                         
"

echo "Version: 1.0.0"

shouldSetupMonoRepoUntil=""
setupMode=""
blueprint=""
theatrePath=""
already_installed=false

for arg in "$@"; do
    case $arg in
    --shouldSetupMonoRepoUntil=*)
        shouldSetupMonoRepoUntil="${arg#*=}"
        shift
        ;;
    --setupMode=*)
        setupMode="${arg#*=}"
        shift
        ;;
    --blueprint=*)
        blueprint="${arg#*=}"
        shift
        ;;
    --theatrePath=*)
        theatrePath="${arg#*=}"
        shift
        ;;
    *)
        echo "Unknown option: $arg"
        exit 1
        ;;
    esac
done

check_already_installed() {
    if [ -d "/Applications/Sprucebot Theatre.app" ]; then
        already_installed=true
    fi
}

askToInstall() {
    local message="$1"

    if [ "$setupMode" == "production" ]; then
        return 0
    else
        echo -n "Would you like me to install $message? (Y/n): "
        read -r response
        if [[ -z "$response" || "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

get_profile() {
    if [[ $SHELL == "/bin/zsh" ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bash_profile"
    fi
}

is_node_installed() {
    if command -v node >/dev/null 2>&1; then
        return 0 # Node is installed
    else
        return 1 # Node is not installed
    fi
}

get_installed_node_version() {
    if is_node_installed; then
        local version=$(node --version | cut -d 'v' -f 2)
        echo "$version"
    else
        echo ""
    fi
}

is_node_outdated() {
    if is_node_installed; then
        local installed_version=$(get_installed_node_version)
        if [[ "$(printf '%s\n' "$min_node_version" "$installed_version" | sort -V | head -n1)" == "$min_node_version" ]]; then
            return 1 # Node is not outdated
        else
            return 0 # Node is outdated
        fi
    else
        return 0 # Node is not installed, consider it outdated
    fi
}

install_homebrew() {
    local fail_message="$1"

    # Check if Homebrew is installed
    if ! [ -x "$(command -v brew)" ]; then
        echo -n "Homebrew is not installed. Would you like me to install it now? (Y/n): "
        read -r response

        # Check if user wants to install Homebrew
        if [[ -z "$response" || "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo "Homebrew installed..."

            if [[ "$(uname -m)" == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$(get_profile)
                eval "$(/opt/homebrew/bin/brew shellenv)"
            else
                echo 'eval "$(/usr/local/bin/brew shellenv)"' >>$(get_profile)
                eval "$(/usr/local/bin/brew shellenv)"
            fi

            source $(get_profile)
        else
            echo "$fail_message"
            exit 1
        fi
    fi
}

check_already_installed
if [ "$setupMode" != "production" ] && [ "$already_installed" = false ]; then
    sleep 1
    echo "Hey there! 👋"
    sleep 1
    echo "Sprucebot here! 🌲🤖"
    sleep 1
    echo "By the time I'm done, I'll have done the following:"
    sleep 1
    echo "1. Installed Node.js, Yarn and Mongo (or skip any already installed)."
    sleep 2
    echo "  1a. If something is not installed, I'll ask you if you want me to use Brew to install it."
    sleep 2
    echo "  2a. If you don't want me to install something, I'll give you instructions to install it manually."
    sleep 2
    echo "2. Installed the Spruce CLI."
    sleep 1
    echo "3. Setup your computer for development."
    sleep 1
    echo "  4a. If you have a blueprint.yml, I'll setup a Sprucebot Development Theatre based on that."
    sleep 2
    echo "  4b. If you don't have a blueprint.yml, I'll setup a Sprucebot Development Theatre from scratch."
    sleep 3
    echo "Let's get started! 🚀"
    sleep 1
    echo -n "Press enter when ready: "
    read -r response
fi

min_node_version="20.0.0"
should_install_node=false

touch $(get_profile)
source $(get_profile)

echo "Checking for Node..."

if is_node_installed; then
    echo "Node is installed..."
    if is_node_outdated; then
        echo "Node is outdated..."
        should_install_node=true
    else
        echo "Node is up to date..."
    fi
else
    echo "Node is not installed..."
    should_install_node=true
fi

if [ "$should_install_node" = true ]; then
    if askToInstall "Node"; then
        install_homebrew "Please install Node manually from https://nodejs.org/."
        brew install node
        source $(get_profile)
    else
        echo "Please install Node manually from https://nodejs.org/."
        exit 1
    fi
fi

npm install --global yarn

yarn global add @sprucelabs/spruce-cli

echo 'export PATH="$PATH:$(yarn global bin)"' >>$(get_profile)

source $(get_profile)

if ! [ -x "$(command -v mongod)" ]; then
    if askToInstall "MongoDB"; then
        install_homebrew "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
        brew tap mongodb/brew
        brew install mongodb-community
    else
        echo "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
        exit 1
    fi
fi

if ! pgrep -x "mongod" >/dev/null; then
    echo "Starting MongoDB..."
    brew services start mongodb-community
fi

if ! [ -x "$(command -v caddy)" ]; then
    if askToInstall "Caddy (to serve the front end)"; then
        install_homebrew "Please install Caddy manually from https://caddyserver.com/docs/install."
        brew install caddy
    else
        echo "Please install Caddy manually from https://caddyserver.com/docs/install."
        exit 1
    fi
fi

if ! [ -x "$(command -v jq)" ]; then
    if askToInstall "jq (to parse JSON)"; then
        install_homebrew "Please install jq manually from https://stedolan.github.io/jq/download/."
        brew install jq
    else
        echo "Please install jq manually from https://stedolan.github.io/jq/download/."
        exit 1
    fi
fi

if [ -z "$blueprint" ]; then
    echo -n "Path to blueprint.yml. Leave empty if you don't have one or have no idea what I'm talking about: "
    read -r blueprint_path
else
    blueprint_path=$blueprint
fi

if [ -z "$blueprint_path" ]; then
    echo "Downloading Sprucebot Development Theatre..."

    rm -f ~/Downloads/Sprucebot+Theatre-arm64.dmg

    curl -o ~/Downloads/Sprucebot+Theatre-arm64.dmg https://s3.amazonaws.com/developer.spruce.bot/development-theatre/Sprucebot+Theatre-arm64.dmg

    echo "Installing Sprucebot Development Theatre..."

    hdiutil attach ~/Downloads/Sprucebot+Theatre-arm64.dmg -mountpoint /Volumes/Sprucebot\ Theatre

    rm -rf /Applications/Sprucebot\ Theatre.app
    cp -R /Volumes/Sprucebot\ Theatre/Sprucebot\ Theatre.app /Applications

    hdiutil detach /Volumes/Sprucebot\ Theatre

    clear

    echo "Sprucebot Development Theatre installed into /Applications/Sprucebot Theatre."
    sleep 3
    echo "Opening now..."
    open /Applications
    open /Applications/Sprucebot\ Theatre.app

    exit 0
else
    if [ ! -f "$blueprint_path" ]; then
        echo "Invalid path to blueprint.yml. You can try this whole thing again."
        exit 1
    fi

    if [ -z "$theatrePath" ]; then
        echo "Where would you like to setup your Sprucebot Development Theatre?"
        echo -n "Destination: "
        read -r path
    else
        path=$theatrePath
    fi

    cd $path

    # Clone theatre mono repo
    git clone git@github.com:sprucelabsai-community/theatre-monorepo.git .
    cp $blueprint_path ./blueprint.yml

    yarn setup.theatre blueprint.yml --shouldRunUntil="$shouldSetupMonoRepoUntil"

    echo "You're all set up! 🚀"
    echo "You can now access your Sprucebot Development Theatre at http://localhost:8080/ 🎉"
    echo "When you're ready to build your first skill, run \"mkdir [skill-name] && spruce onboard\""
    echo "Go team! 🌲🤖"
fi
