#!/bin/bash
#
# Usage: ./get-circleci-status-for-skill.sh --pathToSkill=<path> --circleToken=<token>
# Example: ./get-circleci-status-for-skill.sh --pathToSkill=/path/to/repo --circleToken=abc123

# Parse arguments
for i in "$@"; do
    case $i in
    --pathToSkill=*)
        SKILL_PATH="${i#*=}"
        shift
        ;;
    --circleToken=*)
        CIRCLECI_TOKEN="${i#*=}"
        shift
        ;;
    *) ;;
    esac
done

if [ -z "$SKILL_PATH" ] || [ -z "$CIRCLECI_TOKEN" ]; then
    echo "Usage: $0 --pathToSkill=<path> --circleToken=<token>"
    exit 1
fi

# Move to the given path
cd "$SKILL_PATH" || exit 1

# Extract remote URL
REMOTE_URL="$(git remote get-url origin 2>/dev/null)"
if [ -z "$REMOTE_URL" ]; then
    echo "Could not get remote URL from Git."
    exit 1
fi

# Extract GitHub org/repo from the remote URL
REPO_ORG="$(echo "$REMOTE_URL" | sed -E 's#(git@|https://)github\.com[:/]([^/]+)/([^\.]+)(\.git)?#\2#')"
REPO_NAME="$(echo "$REMOTE_URL" | sed -E 's#(git@|https://)github\.com[:/]([^/]+)/([^\.]+)(\.git)?#\3#')"

# Fetch pipelines
RESPONSE="$(curl -s -H "Circle-Token: $CIRCLECI_TOKEN" \
    "https://circleci.com/api/v2/project/gh/$REPO_ORG/$REPO_NAME/pipeline?limit=20")"

# Check if CircleCI returned a valid array of pipelines
ITEMS_LENGTH="$(echo "$RESPONSE" | jq -r '.items | length? // 0')"

if [ "$ITEMS_LENGTH" -eq 0 ]; then
    echo "Status: not configured"
    exit 1
fi

# Iterate until we find a pipeline with at least one workflow
PIPELINE_IDS=($(echo "$RESPONSE" | jq -r '.items[].id'))
WORKFLOW_STATUS="no-workflow-found"

for ID in "${PIPELINE_IDS[@]}"; do
    WORKFLOW_RESPONSE="$(curl -s -H "Circle-Token: $CIRCLECI_TOKEN" "https://circleci.com/api/v2/pipeline/$ID/workflow")"
    COUNT="$(echo "$WORKFLOW_RESPONSE" | jq -r '.items | length')"
    if [ "$COUNT" -gt 0 ]; then
        WORKFLOW_STATUS="$(echo "$WORKFLOW_RESPONSE" | jq -r '.items[0].status')"
        echo "Status: $WORKFLOW_STATUS"
        exit 0
    fi
done

# If we get here, none of the pipelines had a workflow
echo "Status: $WORKFLOW_STATUS"
