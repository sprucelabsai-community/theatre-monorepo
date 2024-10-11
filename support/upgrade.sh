#!/bin/bash

shouldOpenVsCodeAfterUpgrade=false
shouldOpenVsCodeOnPendingChanges=false
shouldCheckForPendingChanges=true
shouldShowHelp=false

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
    --help)
        shouldShowHelp=true
        shift
        ;;
    esac
done

if [ "$shouldShowHelp" = true ]; then
    echo "Usage: ./support/upgrade.sh [--shouldOpenVsCodeAfterUpgrade=true|false] [--shouldOpenVsCodeOnPendingChanges=true|false] [--shouldCheckForPendingChanges=true|false]"
    echo ""
    echo "Options:"
    echo "  --shouldOpenVsCodeAfterUpgrade: Open VS Code after upgrading each skill. Default is false."
    echo "  --shouldOpenVsCodeOnPendingChanges: Open VS Code if there are pending changes in a skill. Default is false."
    echo "  --shouldCheckForPendingChanges: Check for pending changes in skills before upgrading. Default is true."
    echo "  --help: Show this help message."
    exit 0
fi

echo "Upgrading skills..."
if [ $# -ge 1 ]; then
    ./support/upgrade-skill.sh "$@"
    exit 0
fi

cd ./packages

if [ "$shouldCheckForPendingChanges" = true ]; then
    for dir in */; do
        if [ -d "$dir" ]; then
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

for dir in *-skill; do
    if [[ -d $dir ]]; then
        cd "$dir"
        # if pull fails, bail
        git pull || exit 1
        # Upgrade skill
        spruce upgrade
        # Open VS Code if flag is set
        if [ "$shouldOpenVsCodeAfterUpgrade" = true ]; then
            code .
        fi
        cd ..
    fi
done

# if spruce-mercury-api exists, do the same thing but run "yarn upgrade.packages.all" instead of "spruce upgrade"
if [[ -d "spruce-mercury-api" ]]; then
    cd "spruce-mercury-api"
    git pull
    yarn upgrade.packages.all
    # Open VS Code if flag is set
    if [ "$shouldOpenVsCodeAfterUpgrade" = true ]; then
        code .
    fi
fi

yarn
yarn build
