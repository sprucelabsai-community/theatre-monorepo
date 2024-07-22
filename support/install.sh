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

echo "Version: 3.1.0"

shouldSetupTheatreUntil=""
setupMode=""
blueprint=""
theatreDestination=""
already_installed=false

for arg in "$@"; do
    case $arg in
    --shouldSetupTheatreUntil=*)
        shouldSetupTheatreUntil="${arg#*=}"
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
    --theatreDestination=*)
        theatreDestination="${arg#*=}"
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

ask_to_install() {
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
    if [ -n "$ZSH_VERSION" ]; then
        echo "$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        echo "$HOME/.bashrc"
    else
        echo "$HOME/.profile"
    fi
}

install_jq() {
    if [ -x "$(command -v apt)" ]; then
        echo "Installing jq using apt..."
        sudo apt-get update
        sudo apt-get install -y jq
    elif [ -x "$(command -v brew)" ]; then
        echo "Installing jq using Homebrew..."
        brew install jq
    else
        echo "No suitable package manager found for installing jq."
        exit 1
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

    # Check if Homebrew or apt is installed
    if ! [ -x "$(command -v brew)" ] && ! [ -x "$(command -v apt)" ]; then
        if ask_to_install "Homebrew"; then
            echo "Installing Homebrew..."

            # Detect the operating system
            OS="$(uname)"
            case $OS in
            'Linux')
                if [ -x "$(command -v apt)" ]; then
                    echo "apt is available, skipping Homebrew installation."
                else
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    echo "Homebrew installed..."

                    # Add Homebrew to PATH
                    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>$(get_profile)
                    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
                fi
                ;;
            'Darwin')
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                echo "Homebrew installed..."

                # Add Homebrew to PATH for macOS
                if [[ "$(uname -m)" == "arm64" ]]; then
                    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$(get_profile)
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                else
                    echo 'eval "$(/usr/local/bin/brew shellenv)"' >>$(get_profile)
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
                ;;
            *)
                echo "Unsupported operating system: $OS"
                exit 1
                ;;
            esac

            source $(get_profile)
        else
            echo "$fail_message"
            exit 1
        fi
    fi
}

install_node() {
    if [ -x "$(command -v apt)" ]; then
        sudo apt-get update
        sudo apt-get install -y nodejs npm
        sudo mkdir -p /usr/local/lib/node_modules/
        sudo chown -R root:$(whoami) /usr/local/lib/node_modules/
        sudo chmod -R 775 /usr/local/lib/node_modules/
    elif [ -x "$(command -v brew)" ]; then
        brew install node
    else
        echo "No suitable package manager found for installing Node.js."
        exit 1
    fi
}

install_mongo() {
    if [ -x "$(command -v apt)" ]; then
        echo "Installing MongoDB using apt..."
        sudo apt-get install -y mongodb-org
    elif [ -x "$(command -v brew)" ]; then
        echo "Installing MongoDB using Homebrew..."
        brew tap mongodb/brew
        brew install mongodb-community
    else
        echo "No suitable package manager found for installing MongoDB."
        exit 1
    fi
}

update_package_manager() {
    if [ -x "$(command -v apt)" ]; then
        echo "Updating apt package list..."
        sudo apt-get update
    elif [ -x "$(command -v brew)" ]; then
        echo "Updating Homebrew..."
        brew update
    else
        echo "No suitable package manager found for updating."
        exit 1
    fi
}

install_yarn() {
    if [ -x "$(command -v apt)" ]; then
        echo "Installing Yarn using npm without sudo..."
        sudo npm install -g yarn
    elif [ -x "$(command -v brew)" ]; then
        echo "Installing Yarn using Homebrew..."
        brew install yarn
    else
        echo "No suitable package manager found for installing Yarn."
        exit 1
    fi
}

install_mongo() {
    if [ -x "$(command -v apt)" ]; then
        echo "Installing MongoDB using apt..."

        sudo apt-get install gnupg curl

        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc |
            sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
                --dearmor

        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org
    elif [ -x "$(command -v brew)" ]; then
        echo "Installing MongoDB using Homebrew..."
        brew tap mongodb/brew
        brew install mongodb-community
    else
        echo "No suitable package manager found for installing MongoDB."
        exit 1
    fi
}

start_mongo() {
    if [ -x "$(command -v brew)" ]; then
        echo "Starting MongoDB using Homebrew services..."
        brew services start mongodb-community
    elif [ -x "$(command -v systemctl)" ]; then
        echo "Starting MongoDB using systemctl..."
        sudo systemctl daemon-reload
        sudo systemctl start mongod
        sudo systemctl enable mongod
    else
        echo "No suitable method found for starting MongoDB."
        exit 1
    fi
}

install_caddy() {
    if [ -x "$(command -v apt)" ]; then
        echo "Installing Caddy using apt..."

        # Install required dependencies
        sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https

        # Add the official Caddy repository
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo apt-key add -
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

        # Update package list and install Caddy
        sudo apt-get update
        sudo apt-get install -y caddy
    elif [ -x "$(command -v brew)" ]; then
        echo "Installing Caddy using Homebrew..."
        brew install caddy
    else
        echo "No suitable package manager found for installing Caddy."
        exit 1
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

update_package_manager

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
    if ask_to_install "Node"; then
        install_homebrew "Please install Node manually from https://nodejs.org/."
        install_node
        source $(get_profile)
    else
        echo "Please install Node manually from https://nodejs.org/."
        exit 1
    fi
fi

install_yarn

yarn global add @sprucelabs/spruce-cli

echo 'export PATH="$PATH:$(yarn global bin)"' >>$(get_profile)

source $(get_profile)

if ! [ -x "$(command -v mongod)" ]; then
    if ask_to_install "MongoDB"; then
        install_homebrew "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
        install_mongo
    else
        echo "Please install MongoDB manually from https://docs.mongodb.com/manual/installation/."
        exit 1
    fi
fi

if ! pgrep -x "mongod" >/dev/null; then
    echo "Starting MongoDB..."
    start_mongo
fi

if ! [ -x "$(command -v caddy)" ]; then
    if ask_to_install "Caddy (to serve the front end)"; then
        install_homebrew "Please install Caddy manually from https://caddyserver.com/docs/install."
        install_caddy
    else
        echo "Please install Caddy manually from https://caddyserver.com/docs/install."
        exit 1
    fi
fi

if ! [ -x "$(command -v jq)" ]; then
    if ask_to_install "jq (to parse JSON)"; then
        install_homebrew "Please install jq manually from https://stedolan.github.io/jq/download/."
        install_jq
    else
        echo "Please install jq manually from https://stedolan.github.io/jq/download/."
        exit 1
    fi
fi

if [ -z "$blueprint" ]; then
    echo -n "Path to blueprint.yml (optional):"
    read -r blueprint_path
else
    blueprint_path=$blueprint
fi

if [ -z "$blueprint_path" ]; then
    echo "Downloading Sprucebot Development Theatre..."

    rm -f ~/Downloads/Sprucebot+Theatre-arm64.dmg

    curl -o ~/Downloads/Sprucebot+Theatre-arm64.dmg https://spruce-theatre.s3.amazonaws.com/Sprucebot+Theatre-arm64.dmg

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

    if [ -z "$theatreDestination" ]; then
        echo "Where would you like to setup your Sprucebot Development Theatre?"
        echo -n "Destination: "
        read -r path
    else
        path=$theatreDestination
    fi

    cd $path

    # Clone theatre mono repo
    git clone git@github.com:sprucelabsai-community/theatre-monorepo.git
    cd theatre-monorepo
    cp $blueprint_path ./blueprint.yml

    yarn setup.theatre blueprint.yml --shouldRunUntil="$shouldSetupTheatreUntil"

    echo "You're all set up! 🚀"
    echo "You can now access your Sprucebot Development Theatre at http://localhost:8080/ 🎉"
    echo "When you're ready to build your first skill, run \"mkdir [skill-name] && spruce onboard\""
    echo "Go team! 🌲🤖"
fi
