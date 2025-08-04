// filepath: /Users/amanraj/development/ente/mobile/packages/script.sh
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting dependency fetch for all Flutter/Dart projects..."

# Find all directories containing a pubspec.yaml and run 'flutter pub get' in them.
# This covers 'apps' and 'packages' directories.
find . -name "pubspec.yaml" -execdir flutter pub get \;

echo "✅ All dependencies fetched successfully!"