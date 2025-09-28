#!/usr/bin/env bash
# Provision an Amazon Linux host for comfortable CLI use
# and install Spruce Theatre in production mode.

set -euo pipefail

# Detect package manager (AL2023 = dnf, AL2 = yum)
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
# Shell quality‑of‑life tweaks
###############################################################################

# 1) Bash‑completion system‑wide
sudo tee /etc/profile.d/bash_completion_extra.sh >/dev/null <<'EOF'
[ -f /etc/profile.d/bash_completion.sh ] && . /etc/profile.d/bash_completion.sh
EOF

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
# Install Spruce Theatre in production mode
###############################################################################
curl -fsSL https://raw.githubusercontent.com/sprucelabsai-community/theatre-monorepo/master/support/install.sh |
	bash -s -- \
		--setupMode=production \
		--shouldInstallMongo=true \
		--shouldInstallCaddy=false \
		--theatreDestination=/home/ec2-user/sholder-theatre \
		--blueprint=/home/ec2-user/blueprint.yml \
		--shouldGrantNodeSecurePermissions=true --debug

rm -- "$0" || {
	echo "Warning: could not remove $0"
	echo "Please remove it manually to avoid running it again."
}

rm $HOME/blueprint.yml || {
	echo "Warning: could not remove $HOME/blueprint.yml"
	echo "Please remove it manually to avoid running it again."
}

echo -e "\nDone."
