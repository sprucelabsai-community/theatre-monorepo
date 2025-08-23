#!/bin/bash

# This script processes a YAML file and replaces placeholders with user-provided or default values.
#
# Placeholder Format:
# - Placeholders must follow the format: <<KEY "Description" "Default">>
#   - KEY: A unique identifier for the placeholder.
#   - Description: A user-friendly message explaining the purpose of the placeholder.
#   - Default: The default value to use if the user does not provide input. Can be an empty string ("").
#
# Example:
# - <<ENV.HEARTWOOD.WEB_SERVER_PORT "Which port can I use to serve the front end?" "8080">>
# - <<admin.PHONE_NUMBER "Enter the cell number to create the owner account." "">>
#
# Notes:
# - All placeholders must include a default value, even if it is an empty string.
# - The script will prompt the user for input and use the default if no input is provided.

# Define the file to process
FILE="blueprint.yml"

source ./support/hero.sh

# Check if the file exists
if [[ ! -f "$FILE" ]]; then
  echo "File $FILE not found!"
  exit 1
fi

# Read the entire file into a variable
file_content=$(<"$FILE")

# Create a temporary file to track answered placeholders
temp_file=$(mktemp /tmp/replace-placeholders-answers.XXXXXX)

# Restore the trap to delete the temporary file on exit
trap "rm -f $temp_file" EXIT

# Clear the terminal window if any placeholder exists
if echo "$file_content" | grep -q '<<[^>]*>>'; then
  clear
  hero "Configure blueprint"
fi

# Process each line by splitting on newlines
IFS=$'\n' # Set IFS to newline to handle splitting
for line in $file_content; do
  # Check for placeholders in the format <<>>
  if echo "$line" | grep -q '<<[^>]*>>'; then
    # Extract the description and default using sed
    placeholder=$(echo "$line" | grep -o '<<[^>]*>>')
    description=$(echo "$placeholder" | sed -n 's/.*"\(.*\)" ".*".*/\1/p')
    default=$(echo "$placeholder" | sed -n 's/.*".*" "\(.*\)".*/\1/p')

    if [[ "$default" == "" ]]; then
      default=""
    fi

    # Check if the placeholder has already been answered
    if grep -q "^$placeholder=" "$temp_file"; then
      user_input=$(grep "^$placeholder=" "$temp_file" | cut -d'=' -f2)
    else
      # Prompt the user for input
      if [[ -n "$default" ]]; then
        read -p "$description [$default]: " user_input
      else
        read -p "$description: " user_input
      fi

      # Use default if no input is provided
      if [[ -z "$user_input" ]]; then
        user_input="$default"
      fi

      # Store the answer in the temporary file
      echo "$placeholder=$user_input" >>"$temp_file"
    fi

    # Ensure the replacement value is wrapped in quotes
    user_input="$user_input"

    # Replace the placeholder in the output file
    sed -i '' "s|$placeholder|$user_input|g" "$FILE"
  fi
done

unset IFS # Reset IFS to default
