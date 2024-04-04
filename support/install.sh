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

echo "Version: 0.4.0"
echo -n "Press enter when ready: "
read -r response
# wait for return

# Global configuration
min_node_version="20.0.0"
should_install_node=false

# Function to get the shell profile
function get_profile() {
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

# Check if Node is installed, if not, install it
if [ "$should_install_node" = true ]; then
    echo "Installing Node via Homebrew..."

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
            echo "Please install Node manually from https://nodejs.org/en/download/."
            exit 1
        fi
    fi

    brew install node

    source $(get_profile)
fi

# install yarn globally
npm install --global yarn

# install spruce-cli
yarn global add @sprucelabs/spruce-cli

# add spruce to PATH from ~/.yarn/bin
echo 'export PATH="$PATH:$(yarn global bin)"' >>$(get_profile)

source $(get_profile)

# Check if vscode is installed
echo -n "Would you like to setup your machine for development? (y/n): "

read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Setting up your machine for development..."
    echo "Checking for Visual Studio Code..."

    # check for vscode
    if ! [ -x "$(command -v code)" ]; then
        echo "Visual Studio Code CLI tools is not installed..."
        echo "Checking for Visual Studio Code..."

        # Check if Visual Studio Code is installed in /Applications/Visual\ Studio\ Code.app
        if [ -d "/Applications/Visual Studio Code.app" ]; then
            echo "Visual Studio Code is installed..."
            echo "Adding Visual Studio Code CLI to PATH..."

            # Add Visual Studio Code CLI to PATH
            echo 'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"' >>$(get_profile)

            source $(get_profile)
        else

            echo -n "Would you like to install Visual Studio Code? (y/n): "
            read -r response

            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                echo "Installing Visual Studio Code..."
                brew install --cask visual-studio-code
            else
                echo "Please install Visual Studio Code manually from https://code.visualstudio.com/."
            fi

        fi
    fi

fi

# install mongodb if not installed
if ! [ -x "$(command -v mongod)" ]; then
    echo -n "Would you like to install MongoDB? (y/n): "
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing MongoDB..."
        brew tap mongodb/brew
        brew install mongodb-community
        brew services start mongodb/brew/mongodb-community
    else
        echo "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
    fi
fi

# ask if the person already has a blueprint.yml by supplying a path or empty if nothing
echo -n "Path to blueprinty.yml. Leave empty if you don't have one or have no idea what I'm talking about: "
read -r blueprint_path

if [ -z "$blueprint_path" ]; then
    echo "No blueprint.yml provided..."
    echo "Setting you up with a Sprucebot Development Theatre..."
    echo "Coming soon..."
    exit 1
else

    # throw if bad path if file does not exist
    if [ ! -f "$blueprint_path" ]; then
        echo "Invalid path to blueprint.yml. You can try this whole thing again."
        exit 1
    fi

    # clone theatre mono repo at
    git clone git@github.com:sprucelabsai-community/theatre-monorepo.git
    cp $blueprint_path theatre-monorepo/blueprint.yml
    mv theatre-monorepo spruce-theatre
    cd spruce-theatre
    yarn
    yarn sync blueprint.yml
    yarn boot.mercury
    yarn login blueprint.yml
    yarn register.skills
    yarn boot.serve

    echo "You're all set up! 🚀"
    echo "You can now access your Sprucebot Development Theatre at http://localhost:8080/ 🎉"
    echo "When you're ready to build your first skill, run ""mkdir [skill-name] && spruce onboard)"""
    echo "Go team! 🌲🤖"
fi
