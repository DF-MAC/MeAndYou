#!/bin/bash

check_network_access() {
    # Checking connectivity to GitHub
    if ! curl -s --connect-timeout 5 https://github.com > /dev/null; then
        echo "Unable to reach GitHub. Please check your internet connection."
        exit 1
    fi

    # Checking connectivity to npm registry
    if ! curl -s --connect-timeout 5 https://registry.npmjs.org > /dev/null; then
        echo "Unable to reach npm registry. Please check your internet connection."
        exit 1
    fi

    echo "Network check passed."
}
