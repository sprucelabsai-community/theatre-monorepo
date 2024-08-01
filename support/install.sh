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

echo "Version: 3.4.3"

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

get_package_manager() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "brew"
    elif command -v apt-get &>/dev/null; then
        echo "apt-get"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v apk &>/dev/null; then
        echo "apk"
    else
        echo "unknown"
    fi
}

PACKAGE_MANAGER=$(get_package_manager)

check_already_installed() {
    # check if spruce cli is installed
    if command -v spruce &>/dev/null; then
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

install_package() {
    local package_name="$1"
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew install "$package_name"
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get install -y "$package_name"
    else
        echo "Unsupported package manager. Please install $package_name manually."
        exit 1
    fi
}

install_git() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew install git
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get update
        sudo apt-get install -y git
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo yum update
        sudo yum install -y git
    elif [ "$PACKAGE_MANAGER" == "apk" ]; then
        sudo apk update
        sudo apk add git
    else
        echo "Unsupported package manager. Please install Git manually."
        exit 1
    fi
}

update_package_manager() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew update
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get update
    else
        echo "Unsupported package manager. Please update your system manually."
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

install_brew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            if [[ "$(uname -m)" == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zshrc
                eval "$(/opt/homebrew/bin/brew shellenv)"
            else
                echo 'eval "$(/usr/local/bin/brew shellenv)"' >>~/.zshrc
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            echo "Homebrew is already installed."
        fi
    else
        echo "Homebrew is only supported on macOS. Skipping installation."
    fi
}

install_node() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew install node@20

        # Get the correct Homebrew prefix
        BREW_PREFIX=$(brew --prefix)

        # Update PATH
        echo "export PATH=\"$BREW_PREFIX/opt/node@20/bin:\$PATH\"" >>$(get_profile)

        # Set LDFLAGS and CPPFLAGS
        echo "export LDFLAGS=\"-L$BREW_PREFIX/opt/node@20/lib\"" >>$(get_profile)
        echo "export CPPFLAGS=\"-I$BREW_PREFIX/opt/node@20/include\"" >>$(get_profile)

        # Source the profile
        source $(get_profile)

        brew link --force --overwrite node@20
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo mkdir -p /usr/local/lib/node_modules/
        sudo chown -R root:$(whoami) /usr/local/lib/node_modules/
        sudo chmod -R 775 /usr/local/lib/node_modules/
    else
        echo "Unsupported package manager. Please install Node.js manually."
        exit 1
    fi
    node --version
    npm --version
}

install_yarn() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew install yarn
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo npm install -g yarn
    else
        echo "Unsupported package manager. Please install Yarn manually."
        exit 1
    fi
}

install_mongo() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew tap mongodb/brew
        brew install mongodb-community
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get install gnupg curl
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org
    else
        echo "Unsupported package manager. Please install MongoDB manually."
        exit 1
    fi
}

start_mongo() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew services start mongodb-community
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo systemctl daemon-reload
        sudo systemctl start mongod
        sudo systemctl enable mongod
    else
        echo "Unsupported package manager. Please start MongoDB manually."
        exit 1
    fi
}

install_caddy() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew install caddy
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/caddy-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy-stable.list
        sudo apt-get update
        sudo apt-get install -y caddy
    else
        echo "Unsupported package manager. Please install Caddy manually."
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
    echo "  1a. If something is not installed, I'll ask you if you want me to use a package manager to install it."
    sleep 2
    echo "  2a. If you don't want me to install something, I'll bail and give you instructions to install it manually."
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

if [[ "$OSTYPE" == "darwin"* ]]; then
    install_brew
fi
update_package_manager

source $(get_profile)

echo "Checking for Git..."
if ! [ -x "$(command -v git)" ]; then
    if ask_to_install "Git"; then
        install_git
    else
        echo "Please install Git manually from https://git-scm.com/downloads."
        exit 1
    fi
fi

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
        install_node
        source $(get_profile)
    else
        echo "Please install Node manually from https://nodejs.org/."
        exit 1
    fi
fi

install_yarn
echo 'export PATH="$PATH:$(yarn global bin)"' >>$(get_profile)

yarn global add @sprucelabs/spruce-cli

source $(get_profile)

if ! [ -x "$(command -v mongod)" ]; then
    if ask_to_install "MongoDB"; then
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
        install_caddy
    else
        echo "Please install Caddy manually from https://caddyserver.com/docs/install."
        exit 1
    fi
fi

if ! [ -x "$(command -v jq)" ]; then
    if ask_to_install "jq (to parse JSON)"; then
        install_package jq
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
    if [[ $(uname -m) == 'arm64' ]]; then
        ARCH="arm64"
    else
        ARCH="mac"
    fi

    echo "Detected architecture: $ARCH"

    # Set the download URL and filename based on architecture
    DOWNLOAD_URL="https://spruce-theatre.s3.amazonaws.com/Sprucebot+Theatre-${ARCH}.dmg"
    DOWNLOAD_FILE="$HOME/Downloads/Sprucebot\ Theatre-${ARCH}.dmg"

    echo "Downloading Sprucebot Development Theatre from ${DOWNLOAD_URL}..."
    rm -f "$DOWNLOAD_FILE"

    # Use the curl command that worked manually
    if curl -o "$DOWNLOAD_FILE" "$DOWNLOAD_URL"; then
        echo "Download completed successfully"
    else
        echo "Error downloading file. Exit code: $?"
        echo "Attempted to download from: $DOWNLOAD_URL"
        echo "Attempted to save to: $DOWNLOAD_FILE"
        exit 1
    fi

    # Verify the download
    if [ -f "$DOWNLOAD_FILE" ] && [ -s "$DOWNLOAD_FILE" ]; then
        echo "File downloaded successfully to $DOWNLOAD_FILE"
    else
        echo "Download seems to have failed. File is missing or empty."
        exit 1
    fi

    echo "Installing Sprucebot Development Theatre..."
    hdiutil attach "$DOWNLOAD_FILE" -mountpoint /Volumes/Sprucebot\ Theatre
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
        echo "Could not find blueprint.yml @ '$blueprint_path'. Verify the path and try again."
        exit 1
    fi

    if [ -z "$theatreDestination" ]; then
        echo "Where would you like to setup your Sprucebot Development Theatre?"
        echo -n "Destination: "
        read -r path
    else
        path=$theatreDestination
    fi

    mkdir -p $path
    cd $path

    # Clone theatre mono repo
    git clone git@github.com:sprucelabsai-community/theatre-monorepo.git .
    cp $blueprint_path ./blueprint.yml

    yarn setup.theatre blueprint.yml --shouldRunUntil="$shouldSetupTheatreUntil"

    echo "You're all set up! 🚀"
    echo "You can now access your Sprucebot Development Theatre at http://localhost:8080/ 🎉"
    echo "When you're ready to build your first skill, run \"mkdir [skill-name] && spruce onboard\""
    echo "Go team! 🌲🤖"
fi
