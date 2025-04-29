#!/bin/bash

# Fetch the latest tag that starts with "cli-"
# shellcheck disable=SC2046
# shellcheck disable=SC2006
LATEST_TAG=$(git describe --tags `git rev-list --tags='cli-*' --max-count=1`)

# Check if the LATEST_TAG variable is empty
if [ -z "$LATEST_TAG" ]; then
    echo "No 'cli-' tag found. Exiting..."
    exit 1
fi
VERSION=${LATEST_TAG#cli-}
# Create a "bin" directory if it doesn't exist
mkdir -p bin

# List of target operating systems
OS_TARGETS=("windows" "linux" "darwin")

# Corresponding architectures for each OS
ARCH_TARGETS=("386 amd64" "386 amd64 arm arm64" "amd64 arm64")

export CGO_ENABLED=0
# Loop through each OS target
for index in "${!OS_TARGETS[@]}"
do
    OS=${OS_TARGETS[$index]}
    for ARCH in ${ARCH_TARGETS[$index]}
    do
        # Set the GOOS environment variable for the current target OS
        export GOOS="$OS"
        export GOARCH="$ARCH"

        # Set the output binary name to "ente-cli" for the current OS and architecture
        BINARY_NAME="ente-$OS-$ARCH"

        # Add .exe extension for Windows
        if [ "$OS" == "windows" ]; then
            BINARY_NAME="ente-$OS-$ARCH.exe"
        fi

        # Build the binary and place it in the "bin" directory
        go build -ldflags="-X main.AppVersion=${VERSION} -s -w" -trimpath -o "bin/$BINARY_NAME" main.go

        # Print a message indicating the build is complete for the current OS and architecture
        echo "Built for $OS ($ARCH) as bin/$BINARY_NAME"
    done
done

# Print a message indicating the build process is complete
echo "Build process completed for all platforms and architectures. Binaries are in the 'bin' directory."
