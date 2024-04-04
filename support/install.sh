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

function get_profile() {
  if [[ $SHELL == "/bin/zsh" ]]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bash_profile"
  fi
}

# Check if Node.js is installed, if not, install it
if ! [ -x "$(command -v node)" ]; then
  echo "Checking for Node.js...
Node.js is not installed...
Installing Node.js via Homebrew..."

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
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $(get_profile)
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $(get_profile)
        eval "$(/usr/local/bin/brew shellenv)"
      fi

      source $(get_profile)
    else
      echo "Please install Node.js manually from https://nodejs.org/en/download/."
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
echo 'export PATH="$PATH:$(yarn global bin)"' >> $(get_profile)

source $(get_profile)

# Check if vscode is installed
echo -n "Would you like to setup your machine for development? (y/n): "

read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Setting up your machine for development..."
  echo "Checking for Visual Studio Code..."
  
  # check for vscode
  if ! [ -x "$(command -v code)" ]; then
    echo "Visual Studio Code is not installed..."
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

