#!/bin/sh

# Run the configured linters.
#
# These checks will run when a PR is opened and new commits are pushed, but it
# can also be run locally.

set -o errexit
set -o xtrace

go vet ./...
go run honnef.co/go/tools/cmd/staticcheck@latest ./...
