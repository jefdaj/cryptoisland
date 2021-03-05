#!/usr/bin/env bash

# Based on https://jaspervdj.be/hakyll/tutorials/github-pages-tutorial.html

set -x

# Make sure to start in the right dir
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Temporarily store uncommited changes
git stash || true

# Verify correct branch
git checkout develop

# Build new files
pushd src
stack build
stack exec site clean
stack exec site build
popd

# Get previous files
git fetch --all
git checkout -b master --track origin/master
git checkout develop LICENSE README.md

# Overwrite existing files with new files
rsync -a \
  --filter='P .git/' \
  --filter='P .gitignore' \
  --filter='P .site/' \
  --filter='P src/' \
  --delete-excluded \
  LICENSE README.md .site/ .

# Just in case, remove accidentally-added draft posts
rm -rf posts/2099

# Commit
git add -A
git commit -m "update site with publish.sh"

# Push
git push origin master:master

# Restoration
git checkout develop
git branch -D master
git stash pop || true
