#!/bin/bash

# Create a "bin" directory if it doesn't exist
mkdir -p bin

# List of target operating systems
OS_TARGETS=("windows" "linux" "darwin")

# Corresponding architectures for each OS
ARCH_TARGETS=("386 amd64" "386 amd64 arm arm64" "amd64 arm64")

# Loop through each OS target
for index in "${!OS_TARGETS[@]}"
do
    OS=${OS_TARGETS[$index]}
    for ARCH in ${ARCH_TARGETS[$index]}
    do
        # Set the GOOS environment variable for the current target OS
        export GOOS="$OS"
        export GOARCH="$ARCH"

        # Set the output binary name to "ente-decrypt" for the current OS and architecture
        BINARY_NAME="ente-decrypt-$OS-$ARCH"

        # Add .exe extension for Windows
        if [ "$OS" == "windows" ]; then
            BINARY_NAME="ente-decrypt-$OS-$ARCH.exe"
        fi

        # Build the binary and place it in the "bin" directory
        go build -o "bin/$BINARY_NAME" decrypt.go crypt.go stream.go

        # Print a message indicating the build is complete for the current OS and architecture
        echo "Built for $OS ($ARCH) as bin/$BINARY_NAME"
    done
done

# Clean up any environment variables
unset GOOS
unset GOARCH

# Print a message indicating the build process is complete
echo "Build process completed for all platforms and architectures. Binaries are in the 'bin' directory."
