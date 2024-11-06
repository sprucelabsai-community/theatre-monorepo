#!/bin/bash

source ./support/hero.sh

shouldOpenVsCodeAfterUpgrade=false
shouldOpenVsCodeOnPendingChanges=false
shouldCheckForPendingChanges=true
shouldShowHelp=false
startWith=""

for arg in "$@"; do
    case $arg in
    --shouldOpenVsCodeAfterUpgrade=*)
        shouldOpenVsCodeAfterUpgrade="${arg#*=}"
        shift
        ;;
    --shouldOpenVsCodeOnPendingChanges=*)
        shouldOpenVsCodeOnPendingChanges="${arg#*=}"
        shift
        ;;
    --shouldCheckForPendingChanges=*)
        shouldCheckForPendingChanges="${arg#*=}"
        shift
        ;;
    --startWith=*)
        startWith="${arg#*=}"
        shift
        ;;
    --help)
        shouldShowHelp=true
        shift
        ;;
    esac
done

if [ "$shouldShowHelp" = true ]; then
    echo "Usage: ./support/upgrade.sh [options]"
    echo ""
    echo "Options:"
    echo "  --shouldOpenVsCodeAfterUpgrade: Open VS Code after upgrading each skill. Default is false."
    echo "  --shouldOpenVsCodeOnPendingChanges: Open VS Code if there are pending changes in a skill. Default is false."
    echo "  --shouldCheckForPendingChanges: Check for pending changes in skills before upgrading. Default is true."
    echo "  --startWith: Start the upgrade process with the specified skill directory."
    echo "  --help: Show this help message."
    exit 0
fi

hero "Upgrading skills..."
if [ $# -ge 1 ]; then
    ./support/upgrade-skill.sh "$@"
    exit 0
fi

if [ "$startWith" ]; then
    startWith=$(./support/resolve-skill-dir.sh "$startWith")
fi

foundStart=false

if [ "$shouldCheckForPendingChanges" = true ]; then
    for dir in packages/*/; do
        if [ -d "$dir" ]; then
            dir="${dir%/}"               # Remove trailing slash
            dirName="$(basename "$dir")" # Get directory name without path

            # If startWith is set, skip until we reach the startWith directory
            if [ -n "$startWith" ]; then
                if [ "$foundStart" = false ]; then
                    if [ "$dirName" = "$startWith" ]; then
                        foundStart=true
                    else
                        continue
                    fi
                fi
            fi
            if ! git -C "$dir" diff --quiet; then
                echo "There are local changes in $dir. Please commit or stash them before updating."
                if [ "$shouldOpenVsCodeOnPendingChanges" = true ]; then
                    code "$dir"
                fi
                exit 1
            fi
        fi
    done
fi

foundStart=false

for dir in packages/*-skill/; do
    if [[ -d $dir ]]; then
        dir="${dir%/}"               # Remove trailing slash
        dirName="$(basename "$dir")" # Get directory name without path

        # If startWith is set, skip until we reach the startWith directory
        if [ -n "$startWith" ]; then
            if [ "$foundStart" = false ]; then
                if [ "$dirName" = "$startWith" ]; then
                    foundStart=true
                else
                    continue
                fi
            fi
        fi

        ./support/upgrade-skill.sh "$dirName"

        # Open VS Code if flag is set
        if [ "$shouldOpenVsCodeAfterUpgrade" = true ]; then
            code "$dir"
            echo "Opened VS Code for $dirName"
            echo "Press any key to continue:"
            read -n 1 -s
        fi
    fi
done

# If packages/spruce-mercury-api exists, do the same thing but run "yarn upgrade.packages.all" instead of "spruce upgrade"
if [[ -d "packages/spruce-mercury-api" ]]; then
    cd "packages/spruce-mercury-api"
    git pull
    yarn upgrade.packages.all
    # Open VS Code if flag is set
    if [ "$shouldOpenVsCodeAfterUpgrade" = true ]; then
        code .
    fi
    cd ../../
fi

yarn
yarn build
