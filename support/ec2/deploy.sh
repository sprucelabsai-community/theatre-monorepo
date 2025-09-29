#!/usr/bin/env bash
# deploy.sh – copy a local setup script to an EC2 host and execute it
# Usage:
#   ./support/ec2/deploy.sh [-k key.pem] -h host [options]
#
# Required:
#   -k key.pem              Path to SSH private key (optional if ssh config handles it)
#   -h host                 EC2 host (IPv4/DNS)
#
# Optional SSH/deployment options:
#   -u user                 SSH username (default: ec2-user)
#   (setup script fixed to support/ec2/setup.sh)
#   -b blueprint.yml        Local blueprint to upload (default: blueprint.yml)
#
# Optional install.sh flags (forwarded to remote setup script):
#   --setupMode=MODE
#   --setupTheatreUntil=STEP
#   --theatreDestination=folder   (placed inside /home/ec2-user)
#   --shouldInstallMongo=true|false
#   --shouldInstallCaddy=true|false
#   --shouldGrantNodeSecurePermissions=true|false
#   --personalAccessToken=TOKEN
#   --debug / --debug=true|false / --no-debug
#
# Extras:
#   (blueprint always uploaded to /home/ec2-user/blueprint.yml)
#
# Extras:
#   --interactive           Prompt for missing values instead of requiring flags

set -euo pipefail

usage() {
	echo "Usage: $0 [-k key.pem] -h host [options]" >&2
	echo "Run $0 --help for full details." >&2
	exit 1
}

help() {
	cat <<'HELP'
Usage: support/ec2/deploy.sh [-k key.pem] -h host [options]

Required:
  -k key.pem              Path to SSH private key (optional if ssh config handles it)
  -h host                 EC2 host (IPv4/DNS)

Optional SSH/deployment options:
  -u user                 SSH username (default: ec2-user)
  (setup script fixed to support/ec2/setup.sh)
  -b blueprint.yml        Local blueprint to upload (default: blueprint.yml)

Optional install.sh flags forwarded to remote setup script:
  --setupMode=MODE
  --setupTheatreUntil=STEP
  --theatreDestination=folder   (placed inside /home/ec2-user)
  --shouldInstallMongo=true|false
  --shouldInstallCaddy=true|false
  --shouldGrantNodeSecurePermissions=true|false
  --personalAccessToken=TOKEN
  --debug / --debug=true|false / --no-debug
  
Extras:
  --interactive           Prompt for any missing values instead of requiring flags
  --help                  Show this message and exit

Examples:
  yarn deploy.ec2 -k ~/.ssh/key.pem -h 18.119.161.185 \
    --theatreDestination=spruce-theatre \
    --setupMode=production
HELP
	exit 0
}

prompt_value() {
	local var_name=$1
	local prompt_text=$2
	local default_value=${!var_name}
	local suffix=""
	[[ -n $default_value ]] && suffix=" [$default_value]"
	local input
	read -r -p "$prompt_text$suffix: " input
	if [[ -n $input ]]; then
		printf -v "$var_name" '%s' "$input"
	fi
}

prompt_bool() {
	local var_name=$1
	local prompt_text=$2
	local current=${!var_name}
	local hint
	if [[ $current == "true" ]]; then
		hint="Y/n"
	else
		hint="y/N"
	fi

	local input value=$current
	while true; do
		read -r -p "$prompt_text ($hint): " input || exit 1
		if [[ -z $input ]]; then
			break
		fi
		case ${input,,} in
		y | yes)
			value="true"
			break
			;;
		n | no)
			value="false"
			break
			;;
		*)
			echo "Please enter y or n." >&2
			;;
		esac
	done

	printf -v "$var_name" '%s' "$value"
}

prompt_optional() {
	local var_name=$1
	local prompt_text=$2
	local current=${!var_name}
	local suffix=""
	[[ -n $current ]] && suffix=" [$current]"
	local input
	read -r -p "$prompt_text$suffix: " input
	if [[ -n $input ]]; then
		printf -v "$var_name" '%s' "$input"
	fi
}

normalize_folder_name() {
	local value=$1
	value=${value%/}
	value=${value##*/}
	echo "$value"
}

interactive=false
user="ec2-user"
script="support/ec2/setup.sh"
blueprint="blueprint.yml"
key=""
host=""

install_setup_mode="production"
install_setup_until=""
install_theatre_folder=""
install_should_install_mongo="true"
install_should_install_caddy="false"
install_should_grant_node_secure_permissions="true"
install_personal_access_token=""
install_debug="true"

remote_home="/home/ec2-user"
remote_blueprint_path="$remote_home/blueprint.yml"

while getopts "k:h:u:b:-:" opt; do
	case $opt in
	k) key=$OPTARG ;;
	h) host=$OPTARG ;;
	u) user=$OPTARG ;;
	b) blueprint=$OPTARG ;;
	-)
		case $OPTARG in
		help)
			help
			;;
		interactive)
			interactive=true
			;;
		*)
			echo "Unknown long option --$OPTARG" >&2
			usage
			;;
		esac
		;;
	*)
		usage
		;;
	esac
done

shift $((OPTIND - 1))

while [[ $# -gt 0 ]]; do
	case $1 in
	--setupMode=*)
		install_setup_mode=${1#*=}
		;;
	--setupTheatreUntil=*)
		install_setup_until=${1#*=}
		;;
	--blueprint=*)
		echo "Warning: --blueprint is ignored; remote blueprint path is fixed to $remote_blueprint_path." >&2
		;;
	--theatreDestination=*)
		value=${1#*=}
		sanitized=$(normalize_folder_name "$value")
		if [[ -z $sanitized || $value != "$sanitized" ]]; then
			echo "--theatreDestination must be a folder name (no slashes)." >&2
			exit 1
		fi
		install_theatre_folder=$sanitized
		;;
	--shouldInstallMongo=*)
		install_should_install_mongo=${1#*=}
		;;
	--shouldInstallCaddy=*)
		install_should_install_caddy=${1#*=}
		;;
	--shouldGrantNodeSecurePermissions=*)
		install_should_grant_node_secure_permissions=${1#*=}
		;;
	--personalAccessToken=*)
		install_personal_access_token=${1#*=}
		;;
	--debug)
		install_debug="true"
		;;
	--no-debug)
		install_debug="false"
		;;
	--debug=*)
		case ${1#*=} in
		true | 1 | yes)
			install_debug="true"
			;;
		false | 0 | no)
			install_debug="false"
			;;
		*)
			echo "Unknown value for --debug: ${1#*=}" >&2
			usage
			;;
		esac
		;;
	--interactive)
		interactive=true
		;;
	--help)
		help
		;;
	*)
		echo "Unknown option: $1" >&2
		usage
		;;
	esac
	shift
done

if [[ $interactive == true ]]; then
	echo "Interactive mode – press Enter to accept the shown default." >&2
	prompt_optional key "SSH private key (leave blank to use ssh config)"
	while [[ -n $key && ! -f $key ]]; do
		echo "Cannot find key: $key" >&2
		prompt_optional key "SSH private key (leave blank to use ssh config)"
	done

	prompt_value host "Host (IPv4 or DNS name)"
	while [[ -z $host ]]; do
		echo "Host is required." >&2
		prompt_value host "Host (IPv4 or DNS name)"
	done

	prompt_value user "SSH username"
	prompt_value blueprint "Local blueprint"
	while [[ ! -f $blueprint ]]; do
		echo "Cannot find blueprint: $blueprint" >&2
		prompt_value blueprint "Local blueprint"
	done

	prompt_value install_setup_mode "install.sh --setupMode"
	prompt_optional install_setup_until "Run install until (blank for full run)"

	if [[ -z $install_theatre_folder ]]; then
		install_theatre_folder="sholder-theatre"
	fi

	while true; do
		prompt_value install_theatre_folder "Remote theatre folder name (inside $remote_home)"
		entered=$install_theatre_folder
		install_theatre_folder=$(normalize_folder_name "$install_theatre_folder")
		if [[ -z $install_theatre_folder ]]; then
			echo "Folder name is required." >&2
			continue
		fi
		if [[ $entered != "$install_theatre_folder" ]]; then
			echo "Please provide only the folder name (no slashes)." >&2
			continue
		fi
		break
	done

	prompt_bool install_should_install_mongo "Install MongoDB"
	prompt_bool install_should_install_caddy "Install Caddy"
	prompt_bool install_should_grant_node_secure_permissions "Grant node secure port permissions"

	prompt_optional install_personal_access_token "GitHub personal access token (blank to skip)"
	prompt_bool install_debug "Enable debug output"
fi

[[ -z $host ]] && usage
if [[ -n $key && ! -f $key ]]; then
	echo "Key not found: $key" >&2
	exit 1
fi
[[ ! -f $blueprint ]] && {
	echo "Blueprint not found: $blueprint" >&2
	exit 1
}

remote_script=$(basename "$script")
if [[ -z $install_theatre_folder ]]; then
	install_theatre_folder="sholder-theatre"
fi
install_theatre_folder=$(normalize_folder_name "$install_theatre_folder")
if [[ -z $install_theatre_folder ]]; then
	echo "Remote theatre folder name cannot be empty." >&2
	exit 1
fi
install_theatre_destination="$remote_home/$install_theatre_folder"

remote_blueprint_dir=$(dirname "$remote_blueprint_path")

if [[ $interactive == true ]]; then
	replay_cmd=("$0")
	if [[ -n $key ]]; then
		replay_cmd+=(-k "$key")
	fi
	replay_cmd+=(-h "$host")
	if [[ $user != "ec2-user" ]]; then
		replay_cmd+=(-u "$user")
	fi
    replay_cmd+=(-b "$blueprint")
	replay_cmd+=("--setupMode=$install_setup_mode")
	if [[ -n $install_setup_until ]]; then
		replay_cmd+=("--setupTheatreUntil=$install_setup_until")
	fi
	replay_cmd+=("--theatreDestination=$install_theatre_folder")
	replay_cmd+=("--shouldInstallMongo=$install_should_install_mongo")
	replay_cmd+=("--shouldInstallCaddy=$install_should_install_caddy")
	replay_cmd+=("--shouldGrantNodeSecurePermissions=$install_should_grant_node_secure_permissions")
	if [[ -n $install_personal_access_token ]]; then
		replay_cmd+=("--personalAccessToken=$install_personal_access_token")
	fi
	if [[ $install_debug == "true" ]]; then
		replay_cmd+=("--debug")
	else
		replay_cmd+=("--no-debug")
	fi

	printf '→ Replay with:\n  '
	printf '%q ' "${replay_cmd[@]}"
	printf '\n\n'
fi

ssh_opts=(-A -o StrictHostKeyChecking=accept-new)
scp_opts=(-o StrictHostKeyChecking=accept-new)
if [[ -n $key ]]; then
	ssh_opts+=(-i "$key")
	scp_opts+=(-i "$key")
fi

# Upload certificates directory if it exists
if [[ -d certificates ]]; then
	echo "→ Copying certificates/ to $user@$host:~/certificates/ …"
	scp "${scp_opts[@]}" -r certificates/ "$user@$host:~/certificates"
fi

echo "→ Ensuring $user@$host:$remote_blueprint_dir exists …"
remote_dir_cmd="mkdir -p $(printf '%q' "$remote_blueprint_dir")"
ssh "${ssh_opts[@]}" "$user@$host" "$remote_dir_cmd" >/dev/null

echo "→ Copying $blueprint to $user@$host:$remote_blueprint_path …"
scp "${scp_opts[@]}" "$blueprint" "$user@$host:$remote_blueprint_path"

echo "→ Copying $script to $user@$host as $remote_script …"
scp "${scp_opts[@]}" "$script" "$user@$host:~/$remote_script"

install_args=(
	"--setupMode=$install_setup_mode"
	"--blueprint=$remote_blueprint_path"
	"--theatreDestination=$install_theatre_destination"
	"--shouldInstallMongo=$install_should_install_mongo"
	"--shouldInstallCaddy=$install_should_install_caddy"
	"--shouldGrantNodeSecurePermissions=$install_should_grant_node_secure_permissions"
)

if [[ -n $install_setup_until ]]; then
	install_args+=("--setupTheatreUntil=$install_setup_until")
fi

if [[ -n $install_personal_access_token ]]; then
	install_args+=("--personalAccessToken=$install_personal_access_token")
fi

if [[ $install_debug == "true" ]]; then
	install_args+=("--debug")
fi

remote_cmd="chmod +x ~/$remote_script && ~/$remote_script"
for arg in "${install_args[@]}"; do
	remote_cmd+=" $(printf '%q' "$arg")"
done

echo "→ Executing on remote host …"
ssh "${ssh_opts[@]}" "$user@$host" "$remote_cmd"

echo "✓ Done"
