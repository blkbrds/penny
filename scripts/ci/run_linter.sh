#!/bin/bash

set -e

if [[ "$CI" != 'true' || "$(uname)" != 'Darwin' ]]; then exit 0; fi

export REPO_SLUG="$TRAVIS_REPO_SLUG"
PR_NUMBER="$(/bin/bash ./scripts/ci/get_pr_number.sh)"

echo "REPO_SLUG = $REPO_SLUG"
echo "PR_NUMBER = $PR_NUMBER"

swiftlint lint --reporter json > swiftlint-report.json

if [[ -z "$PR_NUMBER" ]]; then
    echo 'Not in a Pull Request, skip report.'
else
    bundle exec linterbot "$REPO_SLUG" "$PR_NUMBER" < swiftlint-report.json
fi
