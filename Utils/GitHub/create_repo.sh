#!/bin/zsh
ROOT_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

# This script is used to create a new GitHub repository in a specified organization (if provided)
# and push the local repository to the remote repository.
# It takes optional arguments to specify the visibility of the repository (public or private, default is private)
# and the name of the organization under which to create the repository.
# TODO: Ensure you are signed in to the correct GitHub CLI account before running this script.
fn_ghrc() {
  # Check for and source the current user's GitHub config if it exists
  if [ -f "$ROOT_DIR/.env.github" ]; then
    echo "Sourcing .env.github"
    source "$ROOT_DIR/.env.github"
  else
    echo "Warning: No .env.github file found. Continuing with default settings."
  fi

  # Initialize Git repository
  echo "Initializing Git repository..."
  git init || { echo "Error initializing Git repository"; return 1; }

  # Add all files to the repository
  echo "Adding files to Git..."
  git add --all || { echo "Error adding files to Git"; return 1; }

  # Commit changes
  echo "Committing files..."
  git commit -m "Initial commit" || { echo "Error committing files. Make sure you have files to commit."; return 1; }

  # Determine repository name from current directory
  REPO_NAME=$(basename "$(pwd)")

  # Determine visibility based on function argument
  VISIBILITY="private"
  if [[ "$1" == "public" ]]; then
    VISIBILITY="public"
  fi

  if [[ "$1" != "private" && "$1" != "public" ]]; then
    ORG_NAME="$1"
  fi

  # Optional organization argument
  if [[ -n "$2" ]]; then # If $2 is not empty
    ORG_NAME="$2"
  fi

  echo "Creating GitHub repository with visibility: $VISIBILITY. Organization: $ORG_NAME"

  # Prepare repository name for creation. If organization name is provided, prefix repository name with it
  if [ -n "$ORG_NAME" ]; then
    FULL_REPO_NAME="$ORG_NAME/$REPO_NAME"
  else
    FULL_REPO_NAME="$REPO_NAME"
  fi
  echo "Full repository name: $FULL_REPO_NAME"

  # Create GitHub repository within the specified organization (if provided) or under the user's account
  if ! gh repo create "$FULL_REPO_NAME" --source=. --$VISIBILITY; then
    echo "Error creating GitHub repository. Ensure 'gh' is authenticated and try again."
    return 1
  fi
  echo "GitHub repository created successfully."

  # Configure SSH host
  GITHUB_SSH_HOST="${GITHUB_SSH_HOST:-github.com}"
  echo "GitHub Host Configure: $GITHUB_SSH_HOST"

  # Set the remote URL for 'origin'
  REMOTE_URL=$(gh repo view --json nameWithOwner --jq .nameWithOwner | sed 's/"//g')
  if [ -z "$REMOTE_URL" ]; then
    echo "Error obtaining repository URL from GitHub."
    return 1
  fi
  echo "Remote URL: $REMOTE_URL"

  git remote set-url origin git@"$GITHUB_SSH_HOST":"$REMOTE_URL".git || { echo "Error setting remote URL"; return 1; }
  echo "Remote URL set successfully."

  # Rename the default branch to 'production'
  git branch -M production || { echo "Error renaming branch to 'production'"; return 1; }
  echo "Setting default branch to 'production'."

  # Push the initial commit
  git push -u origin production || { echo "Error pushing to 'production'. Make sure the branch exists and you have the correct access rights."; return 1; }
  echo "Setting production branch upstream"

  # Create a dev branch and push it to the remote repository
  git switch -c dev || { echo "Error creating 'dev' branch"; return 1; }
  echo "Switched to 'dev' branch."
  git push -u origin dev || { echo "Error pushing to 'dev'. Make sure the branch exists and you have the correct access rights."; return 1; }
  echo "Setting dev branch upstream"
}

# Example usage:
# fn_ghrc private my-organization
# This creates a private repository under 'my
