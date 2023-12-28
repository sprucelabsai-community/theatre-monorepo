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

# Construct PID file path
processes_dir="$(pwd)/.processes"
pid_file="${processes_dir}/${vendor}-${namespace}"

# Check if the PID file exists and kill the process
if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file")

    # Check if the PID is a running process
    if ps -p $pid >/dev/null 2>&1; then
        echo "Shutting down ${vendor}-${namespace}"
        kill $pid

        # Optional: Check if the process was killed successfully
        if ! ps -p $pid >/dev/null 2>&1; then
            echo "${vendor}-${namespace} shutdown."
        else
            echo "Failed to stop ${vendor}-${namespace} ($pid)."
        fi
    else
        echo "${vendor}-${namespace} was not running... skipping"
    fi

    # Delete the PID file
    rm "$pid_file"
fi
