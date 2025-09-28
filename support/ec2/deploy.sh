#!/usr/bin/env bash
# deploy.sh – copy a local setup script to an EC2 host and execute it
# Usage:
#   ./support/ec2/deploy.sh -k key.pem -h host [options]
#
# Required:
#   -k key.pem              Path to SSH private key
#   -h host                 EC2 host (IPv4/DNS)
#
# Optional SSH/deployment options:
#   -u user                 SSH username (default: ec2-user)
#   -s script               Local provisioning script (default: support/ec2/setup.sh)
#   -b blueprint.yml        Local blueprint to upload (default: blueprint.yml)
#
# Optional install.sh flags (forwarded to remote setup script):
#   --setupMode=MODE
#   --setupTheatreUntil=STEP
#   --blueprint=/remote/path
#   --theatreDestination=/remote/dir
#   --shouldInstallMongo=true|false
#   --shouldInstallCaddy=true|false
#   --shouldGrantNodeSecurePermissions=true|false
#   --personalAccessToken=TOKEN
#   --debug / --debug=true|false / --no-debug

set -euo pipefail

usage() {
    echo "Usage: $0 -k key.pem -h host [options]" >&2
    echo "Run $0 --help for full details." >&2
    exit 1
}

help() {
    cat <<'HELP'
Usage: support/ec2/deploy.sh -k key.pem -h host [options]

Required:
  -k key.pem              Path to SSH private key
  -h host                 EC2 host (IPv4/DNS)

Optional SSH/deployment options:
  -u user                 SSH username (default: ec2-user)
  -s script               Local provisioning script (default: support/ec2/setup.sh)
  -b blueprint.yml        Local blueprint to upload (default: blueprint.yml)

Optional install.sh flags forwarded to remote setup script:
  --setupMode=MODE
  --setupTheatreUntil=STEP
  --blueprint=/remote/path
  --theatreDestination=/remote/dir
  --shouldInstallMongo=true|false
  --shouldInstallCaddy=true|false
  --shouldGrantNodeSecurePermissions=true|false
  --personalAccessToken=TOKEN
  --debug / --debug=true|false / --no-debug

Examples:
  yarn deploy.ec2 -k ~/.ssh/key.pem -h 18.119.161.185 \
    --theatreDestination=/home/ec2-user/spruce-theatre \
    --setupMode=production
HELP
    exit 0
}

user="ec2-user"
script="support/ec2/setup.sh"
blueprint="blueprint.yml"
key=""
host=""

install_setup_mode="production"
install_setup_until=""
install_blueprint_path=""
install_theatre_destination=""
install_should_install_mongo="true"
install_should_install_caddy="false"
install_should_grant_node_secure_permissions="true"
install_personal_access_token=""
install_debug="true"

while getopts "k:h:u:s:b:-:" opt; do
    case $opt in
    k) key=$OPTARG ;;
    h) host=$OPTARG ;;
    u) user=$OPTARG ;;
    s) script=$OPTARG ;;
    b) blueprint=$OPTARG ;;
    -)
        case $OPTARG in
        help)
            help
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
        install_blueprint_path=${1#*=}
        ;;
    --theatreDestination=*)
        install_theatre_destination=${1#*=}
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
        true|1|yes)
            install_debug="true"
            ;;
        false|0|no)
            install_debug="false"
            ;;
        *)
            echo "Unknown value for --debug: ${1#*=}" >&2
            usage
            ;;
        esac
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

[[ -z $key || -z $host ]] && usage
[[ ! -f $key ]] && {
    echo "Key not found: $key" >&2
    exit 1
}
[[ ! -f $script ]] && {
    echo "Script not found: $script" >&2
    exit 1
}
[[ ! -f $blueprint ]] && {
    echo "Blueprint not found: $blueprint" >&2
    exit 1
}

remote_script=$(basename "$script")
remote_blueprint=$(basename "$blueprint")

if [[ -z $install_blueprint_path ]]; then
    install_blueprint_path="/home/${user}/${remote_blueprint}"
fi

if [[ -z $install_theatre_destination ]]; then
    install_theatre_destination="/home/${user}/sholder-theatre"
fi

# Upload certificates directory if it exists
if [[ -d certificates ]]; then
    echo "→ Copying certificates/ to $user@$host:~/certificates/ …"
    scp -r -i "$key" -o StrictHostKeyChecking=accept-new certificates/ "$user@$host:~/certificates"
fi

echo "→ Copying $blueprint to $user@$host as $remote_blueprint …"
scp -i "$key" -o StrictHostKeyChecking=accept-new "$blueprint" "$user@$host:~/$remote_blueprint"

echo "→ Copying $script to $user@$host as $remote_script …"
scp -i "$key" -o StrictHostKeyChecking=accept-new "$script" "$user@$host:~/$remote_script"

install_args=(
    "--setupMode=$install_setup_mode"
    "--blueprint=$install_blueprint_path"
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
ssh -A -i "$key" -o StrictHostKeyChecking=accept-new "$user@$host" "$remote_cmd"

echo "✓ Done"
