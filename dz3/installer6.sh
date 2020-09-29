#!/usr/bin/env bash

Read_file(){
    while read -r LINE; do
        echo "$LINE"
    done < <(jq -c .[] < "$1")
}




if [[ -r "$1" ]]; then
    Read_file "$1"
elif [[ -r "./json.json" ]]; then
    Read_file "./json.json"
else
    echo "The file does not exist or cannot be read"
fi
