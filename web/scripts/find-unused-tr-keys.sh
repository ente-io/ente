#!/bin/sh

# Find localization keys that are possibly not being used.
#
# Caveat emptor. Uses a heuristic grep, not perfect.

jq -r 'keys[]' packages/next/locales/en-US/translation.json | head | while read key
do
    if ! git grep --quiet --fixed 't("'$key'")' -- :^'**/translation.json'
    then
        echo "possibly unused key ${key}"
    fi
done

