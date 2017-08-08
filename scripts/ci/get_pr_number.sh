#!/bin/bash

set -e

if [[ "$CI" != 'true' ]]; then exit 0; fi

USERNAME="${REPO_SLUG%/*}"
SRC_BRANCH="$(/bin/bash ./scripts/ci/get_src_branch.sh)"
URL="https://api.github.com/repos/$REPO_SLUG/pulls?head=$USERNAME:$SRC_BRANCH"
RESULT=$(curl -X GET -u "$GITHUB_ACCESS_TOKEN":x-oauth-basic "$URL" | jq -r '.[0].url')
if [[ "$RESULT" == 'null' ]]; then
    PR_NUMBER=''
else
    PR_NUMBER="${RESULT//\"}"
fi
PR_NUMBER="$(basename "$PR_NUMBER")"
echo "$PR_NUMBER"
