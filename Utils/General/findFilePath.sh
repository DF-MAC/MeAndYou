#!/bin/bash

# Description: This file contains the function to find the path of the file that is being executed.
findFilePath() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$( cd -P "$( dirname "$source" )" && pwd )"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$( cd -P "$( dirname "$source" )" && pwd )"
}

# path=$(findFilePath)
# echo "Path: $path"
# source "$path/General/OS_check.sh" # This auto-runs and detects the OS.
# source "$path/.env.general"
