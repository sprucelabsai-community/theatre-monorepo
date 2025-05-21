#!/usr/bin/env bash

set -e

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

echo "Version: 4.0.0"

setupTheatreUntil=""
setupMode=""
blueprint=""
theatreDestination=""
isAlreadyInstalled=false
minNodeVersion="20.0.0"
shouldInstallNode=false
shouldInstallMongo=true
shouldInstallCaddy=true
personal_access_token=""

for arg in "$@"; do
    case $arg in
    --setupTheatreUntil=*)
        setupTheatreUntil="${arg#*=}"
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
    --shouldInstallMongo=*)
        shouldInstallMongo="${arg#*=}"
        shift
        ;;
    --shouldInstallCaddy=*)
        shouldInstallCaddy="${arg#*=}"
        shift
        ;;
    --personalAccessToken=*)
        personal_access_token="${arg#*=}"
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

check_is_already_installed() {
    # check if spruce cli is installed
    if command -v spruce &>/dev/null; then
        isAlreadyInstalled=true
    fi
}

ask_to_install() {
    local message="$1"

    if [ "$setupMode" == "production" ]; then
        return 1
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
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo yum install -y "$package_name"
    else
        echo "Unsupported package manager. Please install $package_name manually."
        exit 1
    fi
}

install_git() {
    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew install git
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
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
        # canvas requirements (heartwood)
        brew install pkg-config cairo pango libpng jpeg giflib librsvg pixman
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get update
        # canvas requirements (heartwood)
        sudo apt-get install -y fuse libfuse2 pkg-config libpixman-1-dev build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo yum update -y
        # canvas requirements (heartwood)
        sudo yum install -y pkgconfig cairo-devel pango-devel libpng-devel libjpeg-turbo-devel giflib-devel librsvg2-devel pixman-devel
    else
        echo "Unsupported package manager. Please update your system manually."
        exit 1
    fi

    source $(get_profile)
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
        if [[ "$(printf '%s\n' "$minNodeVersion" "$installed_version" | sort -V | head -n1)" == "$minNodeVersion" ]]; then
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
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
        sudo yum install -y nodejs
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
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo npm install -g yarn
    else
        echo "Unsupported package manager. Please install Yarn manually."
        exit 1
    fi

    echo 'export PATH="$PATH:$(yarn global bin)"' >>$(get_profile)
}

install_mongo() {
    if [ "$shouldInstallMongo" = false ]; then
        echo "Skipping MongoDB installation..."
        return
    fi

    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew tap mongodb/brew
        brew install mongodb-community
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        apt-get update
        apt-get install -y gnupg curl

        # Remove old GPG key if it exists
        rm -f /usr/share/keyrings/mongodb-server-6.0.gpg

        # Import the MongoDB public GPG key
        curl -fsSL https://pgp.mongodb.com/server-6.0.asc |
            gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg

        # Create the list file for MongoDB
        echo "deb [signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" |
            tee /etc/apt/sources.list.d/mongodb-org-6.0.list

        # Reload local package database
        apt-get update

        # Install MongoDB
        apt-get install -y mongodb-org

        # Create the data directory
        mkdir -p /data/db
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        if [ "$shouldInstallMongo" = false ]; then
            echo "Skipping MongoDB installation..."
            return
        fi
        sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo >/dev/null <<'EOM'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-6.0.asc
EOM
        sudo yum clean all
        sudo yum install -y mongodb-org
        sudo mkdir -p /data/db
    else
        echo "Unsupported package manager. Please install MongoDB manually."
        exit 1
    fi
}

start_mongo() {
    if [ "$shouldInstallMongo" = false ]; then
        echo "Skipping MongoDB startup settings..."
        return
    fi

    if [ "$PACKAGE_MANAGER" == "brew" ]; then
        brew services start mongodb-community
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo systemctl daemon-reload
        sudo systemctl enable mongod
        sudo systemctl start mongod
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo systemctl daemon-reload
        sudo systemctl enable mongod
        sudo systemctl start mongod
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
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo yum install -y yum-plugin-copr
        sudo yum copr enable @caddy/caddy -y
        sudo yum install -y caddy
    else
        echo "Unsupported package manager. Please install Caddy manually."
        exit 1
    fi
}

optionally_install_node() {
    if is_node_installed; then
        echo "Node is installed..."
        if is_node_outdated; then
            echo "Node is outdated..."
            shouldInstallNode=true
        else
            echo "Node is up to date..."
        fi
    else
        echo "Node is not installed..."
        shouldInstallNode=true
    fi

    if [ "$shouldInstallNode" = true ]; then
        if ask_to_install "Node"; then
            install_node
            source $(get_profile)
        else
            echo "Please install Node manually from https://nodejs.org/."
            exit 1
        fi
    fi
}

introduction_message() {
    if [ "$setupMode" != "production" ] && [ "$isAlreadyInstalled" = false ]; then
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
}

optionally_install_brew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_brew
    fi
}

optionally_install_git() {
    if ! [ -x "$(command -v git)" ]; then
        if ask_to_install "Git"; then
            install_git
        else
            echo "Please install Git manually from https://git-scm.com/downloads."
            exit 1
        fi
    fi
}

install_spruce_cli() {
    yarn global add @sprucelabs/spruce-cli
    source $(get_profile)
}

optionally_install_and_boot_mongo() {

    if [ "$shouldInstallMongo" = false ]; then
        echo "Skipping MongoDB installation..."
        return
    fi

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
}

optionally_install_caddy() {
    if [ "$shouldInstallCaddy" = false ]; then
        echo "Skipping Caddy installation..."
        return
    fi

    if ! [ -x "$(command -v caddy)" ]; then
        if ask_to_install "Caddy (to serve the front end)"; then
            install_caddy
        else
            echo "Please install Caddy manually from https://caddyserver.com/docs/install."
            exit 1
        fi
    fi
}

optionally_install_jq() {
    if ! [ -x "$(command -v jq)" ]; then
        if ask_to_install "jq (to parse JSON)"; then
            install_package jq
        else
            echo "Please install jq manually from https://stedolan.github.io/jq/download/."
            exit 1
        fi
    fi

}

ask_for_blueprint() {
    if [ -z "$blueprint" ]; then
        echo -n "Path to blueprint.yml (optional):"
        read -r blueprint_path
    else
        blueprint_path=$blueprint
    fi
}

determine_executable() {
    local architecture
    architecture=$(uname -m)
    local os_type
    os_type=$(uname -s)

    case "$os_type" in
    Linux)
        case "$architecture" in
        x86_64)
            if command -v snap &>/dev/null; then
                echo "sprucebot-theatre_amd64.snap"
            elif command -v rpm &>/dev/null; then
                echo "Sprucebot Theatre-x86_64.rpm"
            else
                echo "Sprucebot Theatre-x86_64.AppImage"
            fi
            ;;
        arm64 | aarch64)
            echo "Sprucebot Theatre-arm64.AppImage"
            ;;
        *)
            echo "ERROR_UNSUPPORTED_ARCH: $architecture"
            ;;
        esac
        ;;
    Darwin)
        case "$architecture" in
        x86_64)
            echo "Sprucebot Theatre-x64.dmg"
            ;;
        arm64)
            echo "Sprucebot Theatre-arm64.dmg"
            ;;
        *)
            echo "ERROR_UNSUPPORTED_ARCH: $architecture"
            ;;
        esac
        ;;
    *)
        echo "ERROR_UNSUPPORTED_OS: $os_type"
        ;;
    esac
}

# Function to install the downloaded executable
install_executable() {
    local executable="$1"

    # Check for error conditions
    if [[ "$executable" == ERROR_UNSUPPORTED_ARCH* || "$executable" == ERROR_UNSUPPORTED_OS* ]]; then
        echo "Unsupported system configuration: $executable"
        exit 1
    fi

    # Set the download URL and filename based on architecture
    DOWNLOAD_URL="https://spruce-theatre.s3.amazonaws.com/$(echo ${executable} | sed 's/ /%20/g')"
    DOWNLOAD_FILE="$HOME/Downloads/${executable}"

    echo "Downloading Sprucebot Development Theatre from ${DOWNLOAD_URL}..."
    rm -f "$DOWNLOAD_FILE"

    # Use the curl command to download the file
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

    # Install the downloaded file based on its type
    case "$executable" in
    *.dmg)
        echo "Installing Sprucebot Development Theatre..."
        hdiutil attach "$DOWNLOAD_FILE" -mountpoint /Volumes/Sprucebot\ Theatre
        rm -rf /Applications/Sprucebot\ Theatre.app
        cp -R /Volumes/Sprucebot\ Theatre/Sprucebot\ Theatre.app /Applications
        hdiutil detach /Volumes/Sprucebot\ Theatre

        clear
        echo "Sprucebot Development Theatre installed into /Applications/Sprucebot Theatre."
        sleep 3
        echo "Opening now..."
        open /Applications/Sprucebot\ Theatre.app
        ;;
    *.deb)
        echo "Installing Sprucebot Development Theatre..."
        sudo dpkg -i "$DOWNLOAD_FILE"
        sudo apt-get install -f # Fix any dependency issues
        ;;
    *.rpm)
        echo "Installing Sprucebot Development Theatre..."
        sudo rpm -i "$DOWNLOAD_FILE"
        ;;
    *.AppImage)
        echo "Installing Sprucebot Development Theatre..."
        chmod +x "$DOWNLOAD_FILE"
        "$DOWNLOAD_FILE" --no-sandbox &
        ;;
    *.snap)
        echo "Installing Sprucebot Development Theatre..."
        sudo snap install --dangerous "$DOWNLOAD_FILE"
        ;;
    *)
        echo "Unsupported file type: $executable"
        exit 1
        ;;
    esac
}

echo "Checking for existing installation..."
check_is_already_installed
introduction_message

touch $(get_profile)

echo "Checking for package manager..."
optionally_install_brew

echo "Updating package manager..."
update_package_manager

echo "Checking for Git..."
optionally_install_git

echo "Checking for Node..."
optionally_install_node

echo "Installing Yarn..."
install_yarn

echo "Installing Spruce CLI..."
install_spruce_cli

echo "Optionally installing MongoDB..."
optionally_install_and_boot_mongo

echo "Optionally installing Caddy..."
optionally_install_caddy
optionally_install_jq
ask_for_blueprint

if [ -z "$blueprint_path" ]; then
    executable=$(determine_executable)
    install_executable "$executable"
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
    if [ -z "$personal_access_token" ]; then
        git clone git@github.com:sprucelabsai-community/theatre-monorepo.git .
    else
        git clone https://"$personal_access_token"@github.com/sprucelabsai-community/theatre-monorepo.git .
    fi

    cp $blueprint_path ./blueprint.yml

    yarn setup.theatre blueprint.yml --runUntil="$setupTheatreUntil"

    echo "You're all set up! 🚀"
    echo "You can now access your Sprucebot Development Theatre at http://localhost:8080/ 🎉"
    echo "When you're ready to build your first skill, run \"spruce create.skill [skill-name]\""
    echo "Go team! 🌲🤖"
fi
