#!/bin/bash

if [ -z "$ENVIRONMENT" ]; then
    # Extract the environment from blueprint.yml
    environment=$(grep -A 10 '^theatre:' blueprint.yml | grep 'ENVIRONMENT:' | awk -F ': ' '{print $2}' | tr -d '"')

    if [ -z "$environment" ]; then
        echo "No environment defined in blueprint.yml. Falling back to dev."
        environment="dev"
    fi

    # Export the environment variable for use in other scripts
    export ENVIRONMENT=$environment
fi
