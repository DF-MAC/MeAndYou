#!/bin/bash

VITE_PROJECT_NAME = $1

# Check if the project name is empty
if [ -z "$VITE_PROJECT_NAME" ]; then
    echo "Project name cannot be empty. Please enter a valid project name."
    exit 1
fi

# Check if yarn is installed
if ! command -v yarn &> /dev/null; then
    echo "Yarn could not be found. Please install it and try again."
    exit 1
fi

# Create the Vite project, assume project name provided is accepted
echo "Creating a new Vite project with React JavaScript and SWC..."
printf "$VITE_PROJECT_NAME\n" | yarn create vite "$VITE_PROJECT_NAME" --template react
if [ $? -ne 0 ]; then
    echo "Failed to create Vite project."
    exit 1
fi

# Print current working directory
echo "Current working directory: $(pwd)"

# Check if the project directory exists and move into it
if [ -d "$VITE_PROJECT_NAME" ]; then
    cd "$VITE_PROJECT_NAME"
else
    echo "Failed to find the project directory $VITE_PROJECT_NAME. Please check if the directory was created."
    exit 1
fi

# Install project dependencies
echo "Installing dependencies..."
yarn add react-dom react-router-dom && yarn add -D postcss autoprefixer tailwindcss
if [ $? -ne 0 ]; then
    echo "Failed to install dependencies."
    exit 1
fi
