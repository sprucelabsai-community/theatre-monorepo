#!/usr/bin/env zsh

# Create a timestamp
TIMESTAMP=$(date +%Y%m%d%H%M)

packages_dir="./packages"
input_yaml="blueprint.yml"
output_dir="./snapshots/$TIMESTAMP"
output_yaml="${output_dir}/blueprint.yml"

mkdir -p "${output_dir}"

# Copy the skills section from the original blueprint and ensure admin isn't duplicated
{
    awk '/^skills:/{flag=1} /^admin:/{flag=0}flag' $input_yaml > $output_yaml
    awk '/^admin:/{flag=1} /^env:/{flag=0}flag' $input_yaml >> $output_yaml
    # Do not add an additional newline here if it's not needed
}

# Initialize associative array for holding skill settings and capture universal settings separately
declare -A skill_settings
universal_settings=""

# Process existing settings from the original blueprint
current_skill=""
while IFS= read -r line || [[ -n $line ]]; do
    if [[ "$line" =~ ^"  universal:" ]]; then
        current_skill="universal"
        universal_settings="  universal:\n"
        continue  # Skip to next line after setting the section
    elif [[ "$line" =~ ^"  "[a-z]+":" ]]; then
        current_skill=${line#"  "}
        current_skill=${current_skill%":"}
        skill_settings[$current_skill]=""
    elif [[ "$current_skill" == "universal" ]]; then
        universal_settings+="$line\n"
    elif [[ "$current_skill" != "" && "$line" =~ ^"    "-.* ]]; then
        skill_settings[$current_skill]+="$line\n"
    fi
done < "$input_yaml"
# Remove all trailing newlines from universal_settings
while [[ "$universal_settings" == *$'\n'* ]]; do
    universal_settings=${universal_settings%$'\n'}
done

# Function to merge settings from .env files into existing skill settings
function merge_env_into_skill_settings() {
    local skill=$1
    local env_file=$2

    if [[ -f $env_file ]]; then
        while IFS='=' read -r key value; do
            key=${key//[[:space:]]/}
            value=${value//[[:space:]]/}
            value=${value//\"/}  # Strip double quotes for consistency

            # If key already exists in skill settings, replace; otherwise, append
            if [[ "${skill_settings[$skill]}" =~ "${key}:" ]]; then
                skill_settings[$skill]=$(echo "${skill_settings[$skill]}" | sed "s|    - ${key}: \".*\"|    - ${key}: \"${value}\"|")
            else
                # Check if the last character of the current settings is not a newline and prepend one if necessary
                [[ "${skill_settings[$skill]: -1}" != $'\n' ]] && skill_settings[$skill]+=$'\n'
                # Now append the new setting, which will start on a new line
                skill_settings[$skill]+="    - ${key}: \"${value}\"\n"
            fi
        done < "$env_file"
    fi
}

# Merge .env settings into existing skill settings
for skill_dir in $packages_dir/*; do
    if [[ -d $skill_dir ]]; then
        skill_name=$(basename $skill_dir)
        skill_key=$(echo $skill_name | cut -d '-' -f2)  # Assumes format like 'spruce-units-skill'
        env_file="$skill_dir/.env"
        merge_env_into_skill_settings $skill_key $env_file
    fi
done

# Write out the final merged settings starting with 'env' and 'universal'
{
    echo "env:" >> $output_yaml
    echo "$universal_settings" >> $output_yaml  # Add universal settings first under 'env'

    # Add each skill-specific set of settings under 'env'
    for skill in ${(k)skill_settings}; do
        if [[ -n "${skill_settings[$skill]}" && "$skill" != "universal" ]]; then  # Exclude empty and universal sections
            echo "  $skill:" >> $output_yaml
            # Ensure settings are trimmed of excess newlines, then add a final newline
            echo "${skill_settings[$skill]}" | sed '/^$/d' >> $output_yaml  # Avoid empty lines
        fi
    done
}  # Use curly braces to group echo commands for clarity

echo "All updates completed. Check $output_yaml for the new configuration."
