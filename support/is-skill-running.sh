#!/bin/bash

# Default vendor
vendor="spruce"

# Check for at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <namespace> [vendor]"
    echo "Example: $0 heartwood"
    exit 1
fi

# Assign arguments
namespace="$1"
if [ $# -ge 2 ]; then
    vendor="$2"
fi

# Construct PID file paths for both -skill and -api
processes_dir="$(pwd)/.processes"
pid_file_skill="${processes_dir}/${vendor}-${namespace}-skill"
pid_file_api="${processes_dir}/${vendor}-${namespace}-api"

# Check if the PID file exists for either -skill or -api
if [ -f "$pid_file_skill" ] || [ -f "$pid_file_api" ]; then
    echo "SKILL_RUNNING"
else
    echo "SKILL_NOT_RUNNING"
fi
