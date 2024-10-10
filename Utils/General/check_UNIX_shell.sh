#!/bin/bash

# This function is used to check the shell environment and execute the necessary steps to install and configure the required tools
check_UNIX_shell() {
    if [[ "$SHELL" == */zsh ]]; then
        echo "The default shell is zsh."
    elif [[ "$SHELL" == */bash ]]; then
        echo "The default shell is bash."
    else
        echo "The default shell is neither zsh nor bash."
    fi
}
