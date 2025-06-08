#!/usr/bin/env sh

# Usage: setup-repo.sh <branch-name>

if [ -z "$1" ]; then
  echo "Usage: setup-repo.sh <branch-name>"
  exit 1
fi

git init -b main
git add .
git commit -m 'initial commit'
git checkout -b "$1"
