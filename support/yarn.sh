#!/bin/bash

source ./support/get_environment.sh

echo "Environment detected: $ENVIRONMENT"

if [ "$ENVIRONMENT" = "production" ]; then
    echo "Environment is production. Installing production dependencies only."
    yarn install --production
else
    echo "Environment is $ENVIRONMENT. Installing all dependencies."
    yarn install
fi
