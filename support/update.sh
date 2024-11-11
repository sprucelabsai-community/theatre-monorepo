#!/bin/bash

source ./support/hero.sh

shouldOpenVsCodeAfterUpdate=false
shouldOpenVsCodeOnPendingChanges=false
shouldCheckForPendingChanges=true
shouldShowHelp=false
startWith=""

for arg in "$@"; do
    case $arg in
    --shouldOpenVsCodeAfterUpdate=*)
        shouldOpenVsCodeAfterUpdate="${arg#*=}"
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
    echo "Usage: ./support/update.sh [options]"
    echo ""
    echo "Options:"
    echo "  --shouldOpenVsCodeAfterUpdate: Open VS Code after upgrading each skill. Default is false."
    echo "  --shouldOpenVsCodeOnPendingChanges: Open VS Code if there are pending changes in a skill. Default is false."
    echo "  --shouldCheckForPendingChanges: Check for pending changes in skills before upgrading. Default is true."
    echo "  --startWith: Start the upgrade process with the specified skill directory."
    echo "  --help: Show this help message."
    exit 0
fi

hero "Updating skills..."

if [ $# -ge 1 ]; then
    ./support/update-skill.sh "$@"
    exit 0
fi

if [ "$startWith" ]; then
    startWith=$(./support/resolve-skill-dir.sh "$startWith")
fi

foundStart=false

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

        (
            cd "$dir"
            git checkout .
            git pull

            if [ "$shouldOpenVsCodeAfterUpdate" = true ]; then
                code "$dir"
            fi
        ) &
    fi
done

wait

if [[ -d "packages/spruce-mercury-api" ]]; then
    cd "packages/spruce-mercury-api"
    git checkout .
    git pull

    if [ "$shouldOpenVsCodeAfterUpdate" = true ]; then
        code .
    fi
    cd ../../
fi

yarn rebuild
