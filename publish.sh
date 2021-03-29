#!/usr/bin/env bash

set -x

# Make sure to start in the right dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Just in case, remove accidentally-added draft posts
rm -rf .site/posts/2099 || true

die() { echo "$@"; exit 1; }
status="$(git status --porcelain)"
[[ -z "$status" ]] || die "clean up git repo before publishing"

# This picks up cryptoisland from your ~/.ssh/config
rsync -rvz --delete .site/ cryptoisland:///var/www/cryptoisland/
