#!/bin/bash

# Read the environment from blueprint.yml
environment=$(grep -A 10 '^theatre:' blueprint.yml | grep 'ENVIRONMENT:' | awk -F ': ' '{print $2}' | tr -d '"')

if [ -z "$environment" ]; then
    echo "No environment defined blueprint.yml. Falling back to dev."
    environment="dev"
fi

if [ "$environment" = "production" ]; then
    echo "Environment is production. Installing production dependencies only."
    yarn install --production
else
    echo "Environment is $environment. Installing all dependencies."
    yarn install
fi
