#!/usr/bin/env bash

# Usage:
# ./boot-pm2-process.sh \
#   --name my-app \
#   --command "boot" \
#   --cwd /path/to/app \
#   --out_file /some/log-out.log \
#   --error_file /some/log-error.log

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --name)
        name="$2"
        shift
        ;;
    --command)
        command="$2"
        shift
        ;;
    --cwd)
        cwd="$2"
        shift
        ;;
    --out_file)
        out_file="$2"
        shift
        ;;
    --error_file)
        error_file="$2"
        shift
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
done

if [ -z "$name" ] || [ -z "$command" ] || [ -z "$cwd" ]; then
    echo "Missing required arguments"
    exit 1
fi

processes_dir="$(pwd)/.processes"
config_file="${processes_dir}/${name}.json"
max_restarts=10
restart_delay=5000

# Ensure .processes exists
mkdir -p "$processes_dir"

# Absolute path to yarn
yarn_path="$(which yarn)"

echo "Booting $name..."

# Build PM2 config JSON
json_config=$(
    cat <<EOF
{
  "name": "$name",
  "script": "$yarn_path",
  "args": "$command",
  "cwd": "$cwd",
  "interpreter": "bash",
  "max_restarts": $max_restarts,
  "restart_delay": $restart_delay,
  "out_file": "${out_file}",
  "error_file": "${error_file}"
}
EOF
)

# Write JSON config
echo "$json_config" >"$config_file"

# Start or restart using PM2
./support/pm2.sh startOrRestart "$config_file"
./support/pm2.sh save
