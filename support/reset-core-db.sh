#!/usr/bin/env bash

# Generate a random 5-digit PIN
PIN=$(shuf -i 10000-99999 -n 1)
echo "You are about to destroy the core database, enter this pin to confirm: $PIN"

# Ask the user to enter the PIN
PIN=$(((RANDOM % 90000) + 10000))
echo "Generated PIN: $PIN"

# Compare the entered PIN with the generated PIN
if [ "$entered_pin" == "$PIN" ]; then
    echo "PIN verified. Dropping databases..."
    mongosh --quiet --eval 'db.getMongo().getDBNames().forEach(function(i){try { console.log("Dropping",i);db.getSiblingDB(i).dropDatabase() } catch {}})'
else
    echo "Incorrect PIN. Aborting operation."
    exit 1
fi
