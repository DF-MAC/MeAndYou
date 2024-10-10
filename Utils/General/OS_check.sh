#!/bin/bash

ROOT_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")

echo "ROOT_DIR: $ROOT_DIR"
# Function to detect the operating system
detect_os() {
    # Use 'uname -s' to get the OS name of the current system.
    local unameOut="$(uname -s)"
    # Use 'uname -m' to get the machine hardware name of the CPU architecture (ARM, x86_64, etc.)
    local machineOut="$(uname -m)"
    case "${unameOut}" in
        # If 'uname -s' returns a string that starts with "Linux", set os variable to "Linux".
        Linux*)     os=Linux;;
        
        # If 'uname -s' returns "Darwin", it's macOS, so set os variable to "macOS".
        Darwin*)    os=macOS;;
        
        # If 'uname -s' returns any of these strings, it's a Windows environment
        # under a compatibility layer like Cygwin or MinGW. Set os to "Windows".
        CYGWIN*|MINGW32*|MSYS*|MINGW*) os=Windows;;
        
        # If none of the above, set os to "UNKNOWN" followed by the actual output of 'uname -s'.
        *)          os="UNKNOWN:${unameOut}"
    esac
    
    # Detect CPU architecture
    case "${machineOut}" in
        arm64*)    arch=AppleSilicon;;
        x86_64*)   arch=Intel;;
        *)         arch="UNKNOWN:${machineOut}"
    esac
}

# Example of how to use the detect_os function in a script

# Call the detect_os function to set the 'os' and 'arch' variables.
detect_os
# Echo the detected OS to the terminal.
echo "Detected OS: ${os}"

# Use conditional logic to check the value of 'os' and perform OS-specific operations.
if [ "${os}" == "Linux" ]; then
    echo "Performing Linux-specific operations..."
elif [ "${os}" == "macOS" ]; then
    echo "Performing macOS-specific operations..."
    if [ "${arch}" == "AppleSilicon" ]; then
        echo "This is an Apple Silicon Mac."
    elif [ "${arch}" == "Intel" ]; then
        echo "This is an Intel Mac."
    fi
elif [ "${os}" == "Windows" ]; then
    echo "Performing Windows-specific operations..."
else
    echo "Unsupported OS: ${os}, exiting..."
    exit 1
fi 
