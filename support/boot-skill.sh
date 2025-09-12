#!/usr/bin/env bash

set -euo pipefail

# Usage: ./boot-skill.sh <namespace> [<vendor>]

namespace="$1"

# Validate namespace argument
if [ -z "$namespace" ]; then
	echo "Usage: ./boot-skill.sh <namespace> [<vendor>]"
	exit 1
fi

if [ "$namespace" = "message-receiver" ]; then
	./support/boot-message-receiver.sh
	exit 0
fi

# Determine vendor
if [ $# -ge 2 ]; then
	vendor="$2"
fi

if [ -z "$vendor" ]; then
	vendor=$(./support/resolve-vendor.sh "$namespace")
fi

export PATH="$HOME/.yarn/bin:$PATH"

packages_dir="$(pwd)/packages"
processes_dir="$(pwd)/.processes"
logs_dir="${processes_dir}/logs"

# Ensure .processes and logs directories exist
mkdir -p "$processes_dir" "$logs_dir"

# Determine skill directory
suffix="-skill"
if [ "$namespace" == "mercury" ]; then
	suffix="-api"
fi

skill_dir="${packages_dir}/${vendor}-${namespace}${suffix}"
app_name="${vendor}-${namespace}${suffix}"

config_file="${processes_dir}/${app_name}.json"
version_file="${processes_dir}/${app_name}.version"

# --- Minimal validity checks ---
# helper to print clearly (stderr)
hero_err() {
	if [ -f "./support/hero.sh" ]; then
		# shellcheck disable=SC1091
		source ./support/hero.sh
		hero "$1" 1>&2
	else
		echo "$1" 1>&2
	fi
}

pkg_json="$skill_dir/package.json"

# 1) package.json must exist and be non-empty
if [ ! -s "$pkg_json" ]; then
	hero_err "Cannot boot ${app_name}: missing package.json at $pkg_json"
	exit 2
fi

# 2) package.json must contain skill.namespace
if command -v jq >/dev/null 2>&1; then
	if ! jq -e '.skill and .skill.namespace and (.skill.namespace | type=="string" and length>0)' "$pkg_json" >/dev/null 2>&1; then
		hero_err "Cannot boot ${app_name}: package.json is missing skill.namespace"
		exit 2
	fi
else
	if ! grep -q '"skill"' "$pkg_json" || ! grep -q '"namespace"' "$pkg_json"; then
		hero_err "Cannot boot ${app_name}: package.json is missing skill.namespace"
		exit 2
	fi
fi

# 3) package.json must contain scripts.build
if command -v jq >/dev/null 2>&1; then
	if ! jq -e '.scripts and .scripts.build' "$pkg_json" >/dev/null 2>&1; then
		hero_err "Cannot boot ${app_name}: package.json is missing scripts.build"
		exit 2
	fi
else
	if ! grep -q '"scripts"' "$pkg_json" || ! grep -q '"build"' "$pkg_json"; then
		hero_err "Cannot boot ${app_name}: package.json is missing scripts.build"
		exit 2
	fi
fi

# Check if it's the first boot
if [ -f "$config_file" ]; then
	is_first_boot=false
else
	is_first_boot=true
fi

# Initialize should_register_views based on is_first_boot
should_register_views="$is_first_boot"

# Check for pending git changes
if [ -d "$skill_dir/.git" ] && git -C "$skill_dir" status --porcelain | grep . >/dev/null; then
	should_register_views=true
fi

# Check if the version in package.json has changed
if [ -f "$skill_dir/package.json" ]; then
	current_version=$(grep '"version"' "$skill_dir/package.json" | head -n 1 | sed -E 's/.*"version":\s*"([^"]+)".*/\1/')
	if [ -f "$version_file" ]; then
		last_version=$(cat "$version_file")
	else
		last_version=""
	fi

	if [ "$current_version" != "$last_version" ]; then
		should_register_views=true
	fi
else
	echo "Warning: package.json not found in $skill_dir"
fi

# Convert should_register_views to "true" or "false"
if [ "$should_register_views" = true ]; then
	should_register_views_str="true"
else
	should_register_views_str="false"
fi

./support/boot-pm2-process.sh \
	--name "$app_name" \
	--command "boot" \
	--cwd "$skill_dir" \
	--out_file "${logs_dir}/${app_name}-out.log" \
	--error_file "${logs_dir}/${app_name}-error.log"
