#!/bin/bash

# Set the path to the JSON file and folder
json_file_path="./public/locales/en/translation.json"
folder_path="./src"
tab_width=4

# Check if jq and grep are installed
if ! command -v jq &> /dev/null || ! command -v grep &> /dev/null
then
    echo "jq or grep command not found. Please install jq and grep."
    exit
fi

# Recursive function to check for keys in nested JSON objects
check_keys() {
    local keys="$1"
    local parent_key="$2"
    for key in $keys
    do
        local full_key=""
        if [[ -z $parent_key ]]; then
            full_key="$key"
        else
            full_key="$parent_key.$key"
        fi
        local children_keys=$(jq -r --arg key "$key" 'select(.[$key] | type == "object") | .[$key] | keys[]' "$json_file_path")
        if [ -n "$children_keys" ]; then
            # check first if the key is not in the ignore list
            check_keys "$children_keys" "$full_key"
        else 
            if ! grep -rqE "'$full_key'|\"$full_key\"" "$folder_path"; then
                # Remove the key from the JSON file
                # echo the command to remove the key from the JSON file
                jq "del(.$(echo $full_key | sed 's/\./"."/g' | sed 's/^/"/' | sed 's/$/"/'))" "$json_file_path" > "$json_file_path.tmp" && mv "$json_file_path.tmp" "$json_file_path"
                echo "Removing key \"$full_key\" from the JSON file"
            else
                echo "Key \"$full_key\" is being used."
            fi
        fi
    done
}

# Get the top-level keys from the JSON file
keys=$(jq -r 'keys[]' "$json_file_path")

# Loop through the keys and recursively check for nested keys
check_keys "$keys" ""

# Format the updated JSON using the specified tab width
jq --indent "$tab_width" '.' "$json_file_path" > "$json_file_path.tmp" && mv "$json_file_path.tmp" "$json_file_path"




echo "Done checking for missing keys."
