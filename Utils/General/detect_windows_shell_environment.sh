#!/bin/bash

detect_shell_environment() {
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        echo "Running under WSL"
    elif [ ! -z "$WSL_DISTRO_NAME" ]; then
        echo "Running under WSL"
    elif [ ! -z "$MSYSTEM" ]; then
        echo "Running in Git Bash"
    elif [ ! -z "$CYGWIN" ]; then
        echo "Running in Cygwin"
    else
        echo "Environment not specifically detected, possibly native Linux or another Unix-like system"
    fi
}

detect_shell_environment
