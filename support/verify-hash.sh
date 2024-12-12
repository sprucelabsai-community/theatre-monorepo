#!/bin/bash

# Verify the input argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <expected_hash>"
    exit 2 # Exit with code 2 for incorrect usage
fi

EXPECTED_HASH=$1
GENERATE_HASH_SCRIPT="./support/generate-hash.sh" # Path to generate-hash.sh

# Ensure the generate-hash.sh script exists and is executable
if [ ! -f "$GENERATE_HASH_SCRIPT" ] || [ ! -x "$GENERATE_HASH_SCRIPT" ]; then
    echo "Error: $GENERATE_HASH_SCRIPT not found or not executable."
    exit 3 # Exit with code 3 for missing dependency
fi

# Generate the current monorepo hash
CURRENT_HASH=$($GENERATE_HASH_SCRIPT)

# Check for errors in the hash generation process
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate monorepo hash."
    exit 4 # Exit with code 4 for hash generation failure
fi

# Compare the hashes
if [ "$CURRENT_HASH" == "$EXPECTED_HASH" ]; then
    echo "PASS: Hash matches."
    exit 0 # Exit with code 0 for success
else
    echo "FAIL: Hash does not match."
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $CURRENT_HASH"
    exit 1 # Exit with code 1 for mismatch
fi
