#!/bin/bash
#
# Usage: ./circle-status.sh --shouldOpenVsCodeOnFail=<true|false>
# Example: ./circle-status.sh --shouldOpenVsCodeOnFail=<true|false>

for i in "$@"; do
    case $i in
    --shouldOpenVsCodeOnFail=*)
        shouldOpenVsCodeOnFail="${i#*=}"
        shift
        ;;
    --help)
        echo "Usage: ./circle-status.sh [--shouldOpenVsCodeOnFail=<true|false>]"
        echo "Example: ./circle-status.sh --shouldOpenVsCodeOnFail=true"
        exit 0
        ;;
    *) ;;
    esac
done

source support/hero.sh

THEATRE_SECTION=$(node support/blueprint.js blueprint.yml theatre)
CIRCLECI_TOKEN=$(echo "$THEATRE_SECTION" | jq -r '.CIRCLECI_TOKEN // ""')

if [ -z "$CIRCLECI_TOKEN" ]; then
    echo -e "ERROR: The CircleCI token is missing from your blueprint.yml. Add\n\ntheatre:\n  CIRCLECI_TOKEN: <token>\n\n"
    exit 1
fi

hero "Checking CircleCI status for each skill..."

for dir in packages/*-skill/ packages/*-api/; do
    if [[ -d $dir ]]; then
        dir="${dir%/}"
        dirName="$(basename "$dir")"
        hero "Checking CircleCI status for $dirName..."

        ./support/print-circleci-status-for-skill.sh --pathToSkill="$dir" --circleToken="$CIRCLECI_TOKEN" --shouldOpenVsCodeOnFail="$shouldOpenVsCodeOnFail"

    fi
done
