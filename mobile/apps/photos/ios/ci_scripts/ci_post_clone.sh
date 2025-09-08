#!/bin/sh

# ci_post_clone.sh
# This script runs after the repository is cloned

set -e

echo "🚀 Starting post-clone setup..."

# Navigate to the Flutter project root
cd ../../  # Adjust path based on your structure

# Install Flutter
echo "📦 Installing Flutter..."
FLUTTER_VERSION="3.32.8"
git clone https://github.com/flutter/flutter.git --branch $FLUTTER_VERSION --depth 1 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation
flutter --version
flutter doctor -v

# Install Rust (required for Flutter Rust Bridge)
echo "🦀 Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"

# Install Flutter Rust Bridge
echo "🌉 Installing Flutter Rust Bridge..."
cargo install flutter_rust_bridge_codegen

# Generate Rust bindings
echo "⚙️ Generating Rust bindings..."
flutter_rust_bridge_codegen generate

# Get Flutter dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Generate iOS podfile if needed
cd ios
pod install --repo-update

echo "✅ Post-clone setup completed!"