#!/bin/bash

source ./support/hero.sh

shouldOpenVsCodeOnFail=false
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
    --shouldOpenVsCodeOnFail=*)
        shouldOpenVsCodeOnFail="${arg#*=}"
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
    echo "  --shouldOpenVsCodeOnFail: Open VS Code if the upgrade process fails. Default is false."
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

# intentional mapping of shouldOpenVsCodeOnPendingChanges to shouldOpenVsCodeOnFail since a pending change would count as a fail
yarn run update --shouldRebuild=false --shouldOpenVsCodeOnPendingChanges="$shouldOpenVsCodeOnFail" --shouldCheckForPendingChanges="$shouldCheckForPendingChanges"

if [ "$shouldCheckForPendingChanges" = true ]; then
    for dir in packages/*/; do
        if [ -d "$dir" ]; then
            dir="${dir%/}"
            dirName="$(basename "$dir")"

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
        dir="${dir%/}"
        dirName="$(basename "$dir")"

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

        if [ "$shouldOpenVsCodeAfterUpgrade" = true ]; then
            code "$dir"
            echo "Opened VS Code for $dirName"
            echo "Press any key to continue:"
            read -n 1 -s
        fi
    fi
done

if [[ -d "packages/spruce-mercury-api" ]]; then
    cd "packages/spruce-mercury-api"
    git pull
    yarn upgrade.packages.all

    if [ "$shouldOpenVsCodeAfterUpgrade" = true ]; then
        code .
    fi
    cd ../../
fi

yarn clean
yarn
yarn sync.events
yarn rebuild --shouldOpenVsCodeOnFail="$shouldOpenVsCodeOnFail"
