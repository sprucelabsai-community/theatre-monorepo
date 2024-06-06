#!/usr/bin/env bash

echo "
   _____                          
  / ___/____  _______  __________ 
  \__ \/ __ \/ ___/ / / / ___/ _ \ 
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

echo "Version: 0.9.3"
sleep 1
echo "Hey there! 👋"
sleep 1
echo "Sprucebot here! 🌲🤖"
sleep 1
echo "By the time I'm done, I'll have done the following:"
sleep 1
echo "1. Installed Node.js, Yarn and Mongo (or skip any already installed). "
sleep 2
echo "  1a. If something is not installed, I'll ask you if you if you want me to use Brew to install it."
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
# wait for return

# Global configuration
min_node_version="20.0.0"
should_install_node=false

# Function to get the shell profile
get_profile() {
    if [[ $SHELL == "/bin/zsh" ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bash_profile"
    fi
}

# Function to check if Node is installed
is_node_installed() {
    if command -v node >/dev/null 2>&1; then
        return 0 # Node is installed
    else
        return 1 # Node is not installed
    fi
}

# Function to get the installed Node version
get_installed_node_version() {
    if is_node_installed; then
        local version=$(node --version | cut -d 'v' -f 2)
        echo "$version"
    else
        echo ""
    fi
}

# Function to check if the installed Node version is outdated
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
        echo -n "Homebrew is not installed...
You OK if I install it now? (y/n): "
        read -r response

        # Check if user wants to install Homebrew
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
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

# Check if Node is installed, if not, ask to install it
if [ "$should_install_node" = true ]; then

    echo -n "Would you like to install Node? (y/n): "
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Node via Homebrew..."

        install_homebrew "Please install Node manually from https://nodejs.org/."
        brew install node

        source $(get_profile)
    else
        echo "Please install Node manually from https://nodejs.org/."
        exit 1
    fi

fi

# install yarn globally
npm install --global yarn

# install spruce-cli
yarn global add @sprucelabs/spruce-cli

# add spruce to PATH from ~/.yarn/bin
echo 'export PATH="$PATH:$(yarn global bin)"' >>$(get_profile)

# Source the profile file to apply changes immediately
source $(get_profile)

# Check if the 'code' command is available
if ! command -v code >/dev/null 2>&1; then
    echo -n "Would you like to setup Visual Studio Code for coding? (y/n): "
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Visual Studio Code CLI tools is not installed..."
        echo "Checking for Visual Studio Code..."

        # Check if Visual Studio Code is installed in /Applications/Visual\ Studio\ Code.app
        if [ -d "/Applications/Visual Studio Code.app" ]; then
            echo "Visual Studio Code is installed..."
            echo "Adding Visual Studio Code CLI to PATH..."

            # Add Visual Studio Code CLI to PATH
            echo 'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"' >>$(get_profile)

            # Source the profile file to apply changes immediately
            source $(get_profile)
        else

            echo -n "Would you like to install Visual Studio Code? (y/n): "
            read -r response

            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                install_homebrew "Please install Visual Studio Code manually from https://code.visualstudio.com/."
                echo "Installing Visual Studio Code..."
                brew install --cask visual-studio-code
            else
                echo "Please install Visual Studio Code manually from https://code.visualstudio.com/."
                exit 1
            fi

        fi
    fi
fi

# install mongodb if not installed
if ! [ -x "$(command -v mongod)" ]; then
    echo -n "Would you like to install MongoDB? (y/n): "
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_homebrew "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
        echo "Installing MongoDB..."

        brew tap mongodb/brew
        brew install mongodb-community
    else
        echo "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
        exit 1
    fi
fi

# start mongo if not running
if ! pgrep -x "mongod" >/dev/null; then
    echo "Starting MongoDB..."
    brew services start mongodb-community
fi

# install caddy if not installed
if ! [ -x "$(command -v caddy)" ]; then
    echo -n "Would you like to install Caddy (to serve the front end)? (y/n): "
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_homebrew "Please install Caddy manually from https://caddyserver.com/docs/install."
        echo "Installing Caddy..."
        brew install caddy
    else
        echo "Please install Caddy manually from https://caddyserver.com/docs/install."
        exit 1
    fi
fi

# install jq if it's not installed
if ! [ -x "$(command -v jq)" ]; then
    echo -n "Would you like to install jq (to parse JSON)? (y/n): "
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_homebrew "Please install jq manually from https://stedolan.github.io/jq/download/."
        echo "Installing jq..."
        brew install jq
    else
        echo "Please install jq manually from https://stedolan.github.io/jq/download/."
        exit 1
    fi
fi

# ask if the person already has a blueprint.yml by supplying a path or empty if nothing
echo -n "Path to blueprint.yml. Leave empty if you don't have one or have no idea what I'm talking about: "
read -r blueprint_path

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

    echo "Sprucebot Development Theatre installed into Applications as Sprucebot Theatre."
    echo "Opening now..."
    open /Applications/Sprucebot\ Theatre.app

    exit 0
else

    # throw if bad path if file does not exist
    if [ ! -f "$blueprint_path" ]; then
        echo "Invalid path to blueprint.yml. You can try this whole thing again."
        exit 1
    fi

    echo "Setting you up with a Sprucebot Development Theatre based on your blueprint.yml."
    echo "Where would you like to setup your Sprucebot Development Theatre?"

    echo -n "Destination: "
    read -r path

    cd $path

    # clone theatre mono repo at
    git clone git@github.com:sprucelabsai-community/theatre-monorepo.git .
    cp $blueprint_path ./blueprint.yml

    yarn setup.threatre blueprint.yml

    echo "You're all set up! 🚀"
    echo "You can now access your Sprucebot Development Theatre at http://localhost:8080/ 🎉"
    echo "When you're ready to build your first skill, run ""mkdir [skill-name] && spruce onboard)"""
    echo "Go team! 🌲🤖"
fi
