#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Go to the project root directory
cd "$(dirname "$0")/.."

# Check that there are no uncommitted changes
git diff-index --quiet HEAD --
if [ $? -ne 0 ]; then
  echo "Error: There are uncommitted changes"
  exit 1
fi

# Check that the current branch is main
if [[ $(git rev-parse --abbrev-ref HEAD) != "main" ]]; then
  echo "Error: Not on main branch"
  exit 1
fi

# Pull the latest changes from main branch
git pull origin main

# Create a new branch with the current date and time as a suffix
new_branch="bump-version-$(date +'%Y%m%d%H%M%S')"
git checkout -b "$new_branch"

# Find the version line in pubspec.yaml
version_line=$(grep -E '^version:' pubspec.yaml)

# Extract and bump the version number and code
new_version=$(echo $version_line | awk -F '[.+]' '{printf "version: 0.%s.%d+%d", $2, $3+1, $4+1}')

# Replace the version line in pubspec.yaml (macOS compatible)
sed -i '' "s/$version_line/$new_version/" pubspec.yaml

# Commit the version bump with new_version in the commit message
git add pubspec.yaml
git commit -m "Bump $new_version"

gh pr create --fill -r ashilkn --base main
