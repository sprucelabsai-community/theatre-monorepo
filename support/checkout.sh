#!/usr/bin/env bash

source ./support/hero.sh

# Initialize variables
branch_name=""
hard=false
should_update_dependencies=true
should_build=true

# Function to display usage details
show_help() {
    echo "Usage: $0 <branch> [options]"
    echo ""
    echo "Options:"
    echo "  <branch>                      Specify the branch name to checkout (can be passed as the first argument)."
    echo "  --branchName=<branch>         Specify the branch name to checkout (alternative to passing as the first argument)."
    echo "  --hard                        Clobber all local changes."
    echo "  --shouldUpdateDependencies=   Specify whether to run 'yarn' after checking out. Default is true."
    echo "  --shouldBuild                 Specify whether to run 'yarn build' after checking out. Default is true."
    echo "  --help                        Show this help message."
}

# Check if the first argument is not an option and treat it as branchName
if [[ "$1" != --* ]]; then
    branch_name="$1"
    shift
fi

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --branchName=*) branch_name="${1#*=}" ;;
    --hard) hard=true ;;
    --shouldUpdateDependencies=false) should_update_dependencies=false ;;
    --help)
        show_help
        exit 0
        ;;
    *)
        echo "Unknown parameter passed: $1"
        show_help
        exit 1
        ;;
    esac
    shift
done

for skill_dir in packages/*-skill packages/*-api; do
    (
        echo "Checking out $skill_dir..."

        # Call the checkout-skill.sh script with the appropriate arguments
        if [ "$hard" == "true" ]; then
            # if branch name and it's not equal to "default"
            if [ -n "$branch_name" ] && [ "$branch_name" != "default" ]; then
                ./support/checkout-skill.sh --hard "$skill_dir" --branchName="$branch_name"
            else
                ./support/checkout-skill.sh --hard "$skill_dir"
            fi
        else
            if [ -n "$branch_name" ] && [ "$branch_name" != "default" ]; then
                ./support/checkout-skill.sh "$skill_dir" --branchName="$branch_name"
            else
                ./support/checkout-skill.sh "$skill_dir"
            fi
        fi
    ) &
done

# Wait for all background processes to finish
wait

if [ "$should_update_dependencies" == "true" ] && [ "$should_build" == "true" ]; then
    yarn rebuild
else
    if [ "$should_update_dependencies" == "true" ]; then
        yarn
    fi
    if [ "$should_build" == "true" ]; then
        yarn build
    fi
fi

if [ -n "$branch_name" ]; then
    hero "All skills have been checked out from $branch_name."
else
    hero "All skills have been checked out from their default branch."
fi
