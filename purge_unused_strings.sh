#!/bin/bash

# Set the path to the JSON file and folder
json_file_path="./public/locales/en/translation.json"
folder_path="./src"

# Check if jq and grep are installed
if ! command -v jq &> /dev/null || ! command -v grep &> /dev/null
then
    echo "jq or grep command not found. Please install jq and grep."
    exit
fi

# Get the keys from the JSON file
keys=$(jq -r 'keys[]' "$json_file_path")

# Loop through the keys
for key in $keys
do
    # Check if the key is present in any of the files in the folder
    grep -rqE "'$key'|\"$key\""  "$folder_path"
    if [ $? -ne 0 ]
    then
        echo "$key is not present as a string in any of the files in the folder"
        # Remove the key from the JSON file
        jq "del(.\"$key\")" "$json_file_path" > "$json_file_path.tmp" && mv "$json_file_path.tmp" "$json_file_path"
    fi
done
