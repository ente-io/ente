#!/bin/sh

# ci_pre_xcodebuild.sh
# This script runs before xcodebuild

set -e

echo "🔧 Pre-build setup starting..."

# Set up environment
export PATH="$PATH:$HOME/flutter/bin"
export PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env || true

# Navigate to Flutter project root
cd ../../../

# Build Flutter iOS framework
echo "🏗️ Building Flutter framework..."
flutter build ios-framework --no-debug --no-profile

# Run any code generation if needed
flutter pub run build_runner build --delete-conflicting-outputs || true

echo "✅ Pre-build setup completed!"