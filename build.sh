#!/usr/bin/env bash

# Tries to build the site. If successful it will also serve it at
# localhost:8000, and update when files are changed. If unsuccessful it falls
# back to GHCi.

set -x

cd "$( dirname "${BASH_SOURCE[0]}" )/src"

rm -rf .hakyll-cache
rm -rf ../.site

# which apt-get &> /dev/null && sudo apt-get install libgmp-dev zlib1g-dev

stack setup && stack build \
  && (stack exec codeisland clean && stack exec codeisland watch) \
  || stack repl
