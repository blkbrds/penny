#!/bin/bash

set -eo pipefail;

if [[ "$(uname)" != 'Darwin' ]]; then exit 0; fi;

APP='CFTR';

if ! [[ -d "./$APP.xcodeproj" ]]; then
    swift package generate-xcodeproj;
fi;

rm -rf .build/*debug*;
rm -rf .build/*release*;
rm -rf .build/*build*;

swift build;

xcodebuild build \
    -project "$APP.xcodeproj" \
    -scheme "$APP" \
    -enableCodeCoverage YES | bundle exec xcpretty;

xcodebuild test \
    -project "$APP.xcodeproj" \
    -scheme "$APP" \
    -enableCodeCoverage YES
