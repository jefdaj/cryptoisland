#!/usr/bin/env bash

set -x

# Make sure to start in the right dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Just in case, remove accidentally-added draft posts
rm -rf .site/posts/2099 || true

# This picks up cryptoisland from your ~/.ssh/config
rsync -rvz --delete .site/ cryptoisland:///var/www/cryptoisland/
