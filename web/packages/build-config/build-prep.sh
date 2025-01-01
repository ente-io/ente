#!/bin/sh

# Fail the build if the user is setting any of the legacy environment variables
# which have now been replaced with museum configuration. This is meant to help
# self hosters find the new setting instead of being caught unawares.

if test -n "$NEXT_PUBLIC_ENTE_ACCOUNTS_URL"
then
    echo "The NEXT_PUBLIC_ENTE_ACCOUNTS_URL environment variable is not supported."
    echo "Use apps.accounts in the museum configuration instead."
    exit 1
fi

if test -n "$NEXT_PUBLIC_ENTE_FAMILY_URL"
then
    echo "The NEXT_PUBLIC_ENTE_FAMILY_URL environment variable is not supported."
    echo "Use apps.family in the museum configuration instead."
    exit 1
fi
