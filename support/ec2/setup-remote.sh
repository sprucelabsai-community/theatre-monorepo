#!/usr/bin/env bash
# Provision an Amazon Linux host for comfortable CLI use
# and install Spruce Theatre with configurable options.

set -euo pipefail

# Defaults mirror the prior production configuration
setup_mode="production"
setup_until=""
blueprint_path="/home/ec2-user/blueprint.yml"
theatre_destination="/home/ec2-user/sholder-theatre"
should_install_mongo="true"
should_install_caddy="false"
should_grant_node_secure_permissions="true"
personal_access_token=""
debug="true"

for arg in "$@"; do
    case $arg in
    --setupMode=*)
        setup_mode="${arg#*=}"
        ;;
    --setupTheatreUntil=*)
        setup_until="${arg#*=}"
        ;;
    --blueprint=*)
        blueprint_path="${arg#*=}"
        ;;
    --theatreDestination=*)
        theatre_destination="${arg#*=}"
        ;;
    --shouldInstallMongo=*)
        should_install_mongo="${arg#*=}"
        ;;
    --shouldInstallCaddy=*)
        should_install_caddy="${arg#*=}"
        ;;
    --shouldGrantNodeSecurePermissions=*)
        should_grant_node_secure_permissions="${arg#*=}"
        ;;
    --personalAccessToken=*)
        personal_access_token="${arg#*=}"
        ;;
    --debug)
        debug="true"
        ;;
    --no-debug)
        debug="false"
        ;;
    --debug=*)
        case ${arg#*=} in
        true|1|yes)
            debug="true"
            ;;
        false|0|no)
            debug="false"
            ;;
        *)
            echo "Unknown value for --debug: ${arg#*=}" >&2
            exit 1
            ;;
        esac
        ;;
    *)
        echo "Unknown option passed to setup-remote.sh: $arg" >&2
        exit 1
        ;;
    esac
done

# Detect package manager (AL2023 = dnf, AL2 = yum)
if command -v dnf >/dev/null 2>&1; then
    PM=dnf
else
    PM=yum
fi

sudo "$PM" -y update

# Core packages
sudo "$PM" -y install \
    vim-enhanced \
    bash-completion \
    ncurses-term \
    less \
    git

###############################################################################
# Shell quality-of-life tweaks
###############################################################################

# 1) Bash-completion system-wide
sudo tee /etc/profile.d/bash_completion_extra.sh >/dev/null <<'EOT'
[ -f /etc/profile.d/bash_completion.sh ] && . /etc/profile.d/bash_completion.sh
EOT

# 2) Make sure the terminal description matches macOS Terminal/iTerm2 defaults
if ! grep -q 'export TERM=xterm-256color' ~/.bashrc 2>/dev/null; then
    echo 'export TERM=xterm-256color' >>~/.bashrc
fi

# 3) Ensure Backspace sends ^? (already okay on most AMI images, but keep)
sed -i '/^[[:space:]]*stty erase \^?/d' ~/.bashrc

if ! grep -q 'stty erase' ~/.bashrc 2>/dev/null; then
    echo '[[ $- == *i* ]] && stty erase ^?' >>~/.bashrc
fi

###############################################################################
# Install Spruce Theatre
###############################################################################
install_args=(
    "--setupMode=$setup_mode"
    "--blueprint=$blueprint_path"
    "--theatreDestination=$theatre_destination"
    "--shouldInstallMongo=$should_install_mongo"
    "--shouldInstallCaddy=$should_install_caddy"
    "--shouldGrantNodeSecurePermissions=$should_grant_node_secure_permissions"
)

if [[ -n $setup_until ]]; then
    install_args+=("--setupTheatreUntil=$setup_until")
fi

if [[ -n $personal_access_token ]]; then
    install_args+=("--personalAccessToken=$personal_access_token")
fi

if [[ $debug == "true" ]]; then
    install_args+=("--debug")
fi

curl -fsSL https://raw.githubusercontent.com/sprucelabsai-community/theatre-monorepo/master/support/install.sh |
    bash -s -- "${install_args[@]}"

rm -- "$0" || {
    echo "Warning: could not remove $0"
    echo "Please remove it manually to avoid running it again."
}

rm -f -- "$blueprint_path" || {
    echo "Warning: could not remove $blueprint_path"
    echo "Please remove it manually to avoid running it again."
}

echo -e "\nDone."
