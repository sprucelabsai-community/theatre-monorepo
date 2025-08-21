#!/bin/bash

# Define the file to process
FILE="blueprint-placeholders.yml"

# Check if the file exists
if [[ ! -f "$FILE" ]]; then
  echo "File $FILE not found!"
  exit 1
fi

# Define the output file to avoid overwriting the source
OUTPUT_FILE="${FILE%.yml}-completed.yml"
cp "$FILE" "$OUTPUT_FILE"

# Read the entire file into a variable
file_content=$(<"$FILE")

# Process each line by splitting on newlines
IFS=$'\n' # Set IFS to newline to handle splitting
for line in $file_content; do
  # Check for placeholders in the format <<>>
  if echo "$line" | grep -q '<<[^>]*>>'; then
    placeholder=$(echo "$line" | grep -o '<<[^>]*>>')
    description=$(echo "$placeholder" | awk -F'"' '{print $2}')
    default=$(echo "$placeholder" | awk -F'"' '{print $3}')

    if [[ "$default" == ">>" ]]; then
      default=""
    fi

    # Prompt the user for input
    if [[ -n "$default" ]]; then
      read -p "$description (default $default): " user_input
    else
      read -p "$description: " user_input
    fi

    # Use default if no input is provided
    if [[ -z "$user_input" ]]; then
      user_input="$default"
    fi

    # Replace the placeholder in the output file
    sed -i '' "s|$placeholder|$user_input|g" "$OUTPUT_FILE"
  fi
done

unset IFS # Reset IFS to default
