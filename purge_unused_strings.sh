#!/bin/bash

# Check if jq and grep are installed
if ! command -v jq &> /dev/null || ! command -v grep &> /dev/null
then
    echo "jq or grep command not found. Please install jq and grep."
    exit
fi

# Get the keys from the JSON file
keys=$(jq -r 'keys[]' ./public/locales/en/translation.json)

# Loop through the keys
for key in $keys
do
    # Check if the key is present in any of the files in the folder
    grep -rqE "'$key'|\"$key\""  ./src
    if [ $? -ne 0 ]
    then
        echo "$key is not present as a string in any of the files in the folder"
        # Remove the key from the JSON file
        jq "del(.\"$key\")" ./public/locales/en/translation.json > /tmp/temp.json && mv /tmp/temp.json ./public/locales/en/translation.json
    fi
done
