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

# Define the appdata file path - use absolute path to avoid directory navigation issues
PROJECT_ROOT=$(pwd)
APPDATA_FILE="${PROJECT_ROOT}/linux/packaging/enteauth.appdata.xml"

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

# Extract version number from the tag (remove prefix)
TAG_VERSION=${TAG#$PREFIX}

# Check if this version is already in the releases section of the appdata.xml file
if ! grep -q "<release version=\"$TAG_VERSION\"" "$APPDATA_FILE"; then
    echo "Adding release entry for version $TAG_VERSION to appdata.xml"
    
    # Get today's date in YYYY-MM-DD format
    TODAY=$(date +%Y-%m-%d)
    
    # Use a more reliable approach with awk instead of sed for cross-platform compatibility
    echo "Creating temporary file with updated content..."
    awk '/<releases>/{print $0; print "        <release version=\"'"$TAG_VERSION"'\" date=\"'"$TODAY"'\" />"; next}1' "$APPDATA_FILE" > "${APPDATA_FILE}.tmp"
    mv "${APPDATA_FILE}.tmp" "$APPDATA_FILE"
    
    echo "Added release entry for version $TAG_VERSION with date $TODAY"
    
    # Stage and commit the updated appdata.xml file
    git add "$APPDATA_FILE"
    git commit -m "Add release $TAG_VERSION to appdata.xml"
    echo "Committed appdata.xml changes for version $TAG_VERSION"
fi

# If all checks pass, create the tag
git tag $TAG
echo "Tag $TAG created."

exit 0