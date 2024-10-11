#!/bin/zsh
# TEST
# This script is used to switch between different GitHub accounts so you can easily
# push and pull from different repositories using different GitHub accounts.
# TODO: You will need to have already authenticated with the GitHub CLI for 
# each account you want to switch between.
ROOT_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"


if [[ -f "$ROOT_DIR/.env.github" ]]; then
  source "$ROOT_DIR/.env.github"
else
  echo "Error: .env.github file does not exist."
  exit 1
fi

# # Function to configure GitHub environment for TomHawk123
fn_login_TomHawk123() {
  if [[ -f "$ROOT_DIR/.env.github.currentUser" ]]; then
    source "$ROOT_DIR/.env.github.currentUser"
  else
    echo "Error: .env.github.currentUser file does not exist."
    exit 1
  fi


  echo 'export GITHUB_USER_NAME="$PERSONAL_USERNAME"' > "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_USER_EMAIL="$PERSONAL_EMAIL"' >> "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_SSH_HOST="$PERSONAL_SSH_HOST"' >> "$ROOT_DIR/.env.github.currentUser"

  git config --global user.name "$PERSONAL_USERNAME"
  git config --global user.email "$PERSONAL_EMAIL"

  

  eval "$(ssh-agent -s)"

  ssh-add --apple-use-keychain $PERSONAL_SSH_KEY_PATH

  ssh -T "$PERSONAL_SSH_HOST"

  if ! gh auth switch --hostname github.com --user "$PERSONAL_USERNAME"; then
    echo "Error: Failed to switch GitHub CLI user to $PERSONAL_USERNAME."
    exit 1
    else
    echo "Successfully switched GitHub CLI user to $PERSONAL_USERNAME."
  fi
}

# Function to configure GitHub environment for DF-MAC
fn_login_DF-MAC() {
  if [[ -z "$ROOT_DIR/.env.github.currentUser" || ! -w "$ROOT_DIR/.env.github.currentUser" ]]; then
    echo "Error: CURRENT_GH_USER_PATH is not set or the path is not writable."
    exit 1
  fi
  

  echo 'export GITHUB_USER_NAME="$WORK_USERNAME"' > "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_USER_EMAIL="$WORK_EMAIL"' >> "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_SSH_HOST="$WORK_SSH_HOST"' >> "$ROOT_DIR/.env.github.currentUser"

  git config --global user.name "$WORK_USERNAME"
  git config --global user.email "$WORK_EMAIL"

  eval "$(ssh-agent -s)"

  ssh-add --apple-use-keychain $WORK_SSH_KEY_PATH

  ssh -T "$WORK_SSH_HOST"

  if ! gh auth switch --hostname github.com --user "$WORK_USERNAME"; then
    echo "Error: Failed to switch GitHub CLI user to $WORK_USERNAME."
    exit 1
    else
    echo "Successfully switched GitHub CLI user to $WORK_USERNAME."
  fi
}

fn_login_Promo() {
  if [[ -z "$ROOT_DIR/.env.github.currentUser" || ! -w "$ROOT_DIR/.env.github.currentUser" ]]; then
    echo "Error: CURRENT_GH_USER_PATH is not set or the path is not writable."
    exit 1
  fi

  echo 'export GITHUB_USER_NAME="$PROMO_USERNAME"' > "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_USER_EMAIL="$PROMO_EMAIL"' >> "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_SSH_HOST="$PROMO_SSH_HOST"' >> "$ROOT_DIR/.env.github.currentUser"

  git config --global user.name "$PROMO_USERNAME"
  git config --global user.email "$PROMO_EMAIL"

  eval "$(ssh-agent -s)"

  ssh-add --apple-use-keychain $PROMO_SSH_KEY_PATH

  # osascript -e 'tell application "System Events" to keystroke "ssh -T '"$PROMO_SSH_HOST"'" & return'

  ssh -T "$PROMO_SSH_HOST"

  if ! gh auth switch --hostname github.com --user "$PROMO_USERNAME"; then
    echo "Error: Failed to switch GitHub CLI user to $PROMO_USERNAME."
    exit 1
    else
    echo "Successfully switched GitHub CLI user to $PROMO_USERNAME."
  fi
}

fn_login_CLEARLINE() {
  if [[ -z "$ROOT_DIR/.env.github.currentUser" || ! -w "$ROOT_DIR/.env.github.currentUser" ]]; then
    echo "Error: CURRENT_GH_USER_PATH is not set or the path is not writable."
    exit 1
  fi

  echo 'export GITHUB_USER_NAME="$CLEARLINE_USERNAME"' > "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_USER_EMAIL="$CLEARLINE_EMAIL"' >> "$ROOT_DIR/.env.github.currentUser"
  echo 'export GITHUB_SSH_HOST="$CLEARLINE_SSH_HOST"' >> "$ROOT_DIR/.env.github.currentUser"

  git config --global user.name "$CLEARLINE_USERNAME"
  git config --global user.email "$CLEARLINE_EMAIL"

  eval "$(ssh-agent -s)"

  ssh-add --apple-use-keychain $CLEARLINE_SSH_KEY_PATH

  # osascript -e 'tell application "System Events" to keystroke "ssh -T '"$CLEARLINE_SSH_HOST"'" & return'

  ssh -T "$CLEARLINE_SSH_HOST"

  if ! gh auth switch --hostname github.com --user "$CLEARLINE_USERNAME"; then
    echo "Error: Failed to switch GitHub CLI user to $CLEARLINE_USERNAME."
    exit 1
    else
    echo "Successfully switched GitHub CLI user to $CLEARLINE_USERNAME."
  fi
}
