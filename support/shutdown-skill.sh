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

# Append '-api' if namespace is 'mercury', otherwise '-skill'
if [ "$namespace" = "mercury" ]; then
    suffix="-api"
else
    suffix="-skill"
fi
pid_file="${processes_dir}/${vendor}-${namespace}${suffix}.pid"

# Check if the PID file exists and kill the process
if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file")

    # Check if the PID is a running process
    if ps -p $pid >/dev/null 2>&1; then
        echo "Shutting down ${vendor}-${namespace}${suffix}"
        kill $pid

        # Optional: Check if the process was killed successfully
        if ! ps -p $pid >/dev/null 2>&1; then
            echo "${vendor}-${namespace}${suffix} shutdown."
        else
            echo "Failed to stop ${vendor}-${namespace}${suffix} ($pid)."
        fi
    else
        echo "${vendor}-${namespace}${suffix} was not running... skipping"
    fi

    # Delete the PID file
    rm "$pid_file"
else
    echo "${vendor}-${namespace}${suffix}.pid was not found... skipping"
fi
