#!/bin/bash

ROOT_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
source "$ROOT_DIR/General/OS_check.sh" # This auto-runs and detects the OS and CPU architecture.

check_system_resources() {
    # Check free disk space in the root partition. Adjust the path as necessary for your needs.
    local free_space=$(df / | awk 'NR==2 { print $4 }') # Free space in KB
    local min_space=1048576 # TODO: Input amount of space needed for your case. Example: 1GB in KB
    local min_space_human_readable="1GB" # TODO: Input amount of space needed for your case. Example: 1GB

    if [ "$free_space" -lt "$min_space" ]; then
        echo "Insufficient disk space. Please ensure you have at least $min_space_human_readable free on your root partition."
        exit 1
    fi

    # Check available memory
    local free_mem
    if [[ "$os" == "macOS" ]]; then
        # For macOS, using vm_stat to get free memory
        free_mem=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        free_mem=$((free_mem * 4096 / 1024 / 1024)) # Convert pages to MB
    else
        # For Linux, using free to get available memory
        free_mem=$(free -m | awk 'NR==2 { print $7 }') # Available memory in MB
    fi

    local min_mem=1024 # Example: 1GB in MB

    if [ "$free_mem" -lt "$min_mem" ]; then
        echo "Insufficient memory. Please ensure you have at least $min_space_human_readable available."
        exit 1
    fi

    echo "Resource check passed."
}

# # Call the system resource check function
# detect_os # Assuming this function sets the 'os' variable
# check_system_resources
