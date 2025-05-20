#!/bin/sh

#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 tag"
    exit 1
}

# Ensure a tag was provided
[[ $# -eq 0 ]] && usage

# Exit immediately if a command exits with a non-zero status
set -e

# Go to the project root directory
cd "$(dirname "$0")/.."

# Get the tag from the command line argument
TAG=$1


# Get the version from the pubspec.yaml file and cut everything after the +
VERSION=$(grep "^version:" pubspec.yaml | awk '{ print $2 }' | cut -d '+' -f 1)

PREFIX="auth-v"

# Ensure the tag has the correct prefix
if [[ $TAG != $PREFIX* ]]; then
    echo "Invalid tag. tags must start with '$PREFIX'."
    exit 1
fi

# Ensure the tag version is in the pubspec.yaml file
if [[ $TAG != *$VERSION ]]; then
    echo "Invalid tag."
    echo "The version $VERSION in pubspec doesn't match the version in tag $TAG"
    exit 1
fi

## If all checks pass, create the tag
git tag $TAG
echo "Tag $TAG created."

exit 0
