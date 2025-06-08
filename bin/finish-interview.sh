#!/usr/bin/env sh

# Usage: finish.sh

echo "Bundling the changes for submission..."

file="interview-$(git branch --show-current).tar.gz"
rm -rf $file

if [ -n "$(git status --porcelain)" ]; then
  echo "Tree is dirty, please commit your changes and run again"
  exit 1
fi

git format-patch -o patches main > /dev/null
tar czf $file patches/
rm -rf patches/

echo "All done! Please submit the $file file to Recurly"
