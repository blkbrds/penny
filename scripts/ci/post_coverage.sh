#!/bin/bash

set -e

if [[ "$(uname)" != 'Darwin' ]]; then exit 0; fi

APP='CFTR'

bundle exec slather coverage \
    --scheme "$APP" \
    --input-format profdata \
    --binary-basename App \
    "$APP.xcodeproj"

bash <(curl -s https://codecov.io/bash) -J "$APP"

rm -rf ./*coverage*
