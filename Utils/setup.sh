#!/bin/bash
ROOT_DIR="$(dirname "$(readlink -f "$0")")"

echo "ROOT_DIR: $ROOT_DIR"

source "$ROOT_DIR/General/OS_check.sh" # This auto-runs and detects the OS.
source "$ROOT_DIR/.env.general"

chmod +x "$ROOT_DIR/General/OS_check.sh"
chmod +x "$ROOT_DIR/General/findFilePath.sh"
chmod +x "$ROOT_DIR/General/check_network_access.sh"
chmod +x "$ROOT_DIR/General/check_system_resources.sh"
chmod +x "$ROOT_DIR/General/detect_windows_shell_environment.sh"
chmod +x "$ROOT_DIR/GitHub/git_logins.sh"
chmod +x "$ROOT_DIR/GitHub/create_repo.sh"
chmod +x "$ROOT_DIR/General/check_UNIX_shell.sh"


# Function to display progress
show_progress() {
    local progress=$1
    local total=100  # Total number of characters for the progress bar
    local filled=$((progress * total / 100))
    local empty=$((total - filled))
    printf "\r["  # Start progress bar
    printf "%${filled}s" | tr ' ' '#'  # Fill with '#'
    printf "%${empty}s" "]"  # Fill the rest with spaces
    printf " %d%%" "$progress"  # Show percentage
}

# Function to install Homebrew if not installed
install_homebrew() {
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        until brew help &>/dev/null; do
            sleep 1
        done
    fi
}

# Function to install a package using Homebrew, checking for its presence first
brew_install() {
    local package=$1
    if ! brew list "$package" &>/dev/null; then
        brew install "$package"
        until brew list "$package" &>/dev/null; do
            sleep 1
        done
    fi
}

# Function to execute a list of steps and update progress
execute_steps() {
    local -a steps=("$@")
    local total_steps=${#steps[@]}
    local current_step=0

    for step in "${steps[@]}"; do
        ((current_step++))
        eval "$step"
        local progress=$((current_step * 100 / total_steps))
        show_progress "$progress"
    done
    echo ""  # Move to the next line after completion
}

docker_step() {
    open -a "Docker Desktop" || brew install --cask docker && open -a "Docker Desktop"
    until docker system info &>/dev/null; do
            sleep 1
        done
    osascript -e 'tell application "System Events" to keystroke "h" using command down'
}

# Main logic
main() {
    show_progress 0

    # Define steps as commands
    local -a steps=(
        "install_homebrew"
        "brew_install docker"
        "brew_install docker-compose"
        "docker_step"
        "brew_install awscli"
        "brew_install terraform"
        "brew_install go"
        "brew_install jq"
        # Add more steps as needed
    )

    execute_steps "${steps[@]}"

    echo "Installation process complete!"
    exit 0
}

# Run the main function
main



#------------------------------------------------------------
# Additional setup options that can be added to the commands array
#------------------------------------------------------------

# # check if GitHub CLI is installed. If it isn't installed, install it.
# gh --version || brew install gh

# # check if oh-my-zsh is installed. If it isn't installed, install it.
# [[ -d "$HOME/.oh-my-zsh" ]] || sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# # check if zsh is the default shell. If it isn't the default shell, set it as the default shell.
# if [[ "$SHELL" != "/bin/zsh" ]]; then
#   chsh -s /bin/zsh
# fi
# # check if everything needed for Node.js is installed. If it isn't installed, install it.
# node --version || brew install node
# npm --version || brew install npm
# yarn --version || brew install yarn

# # check if nvm is installed. If it isn't installed, install it.
# # NVM initialization script
# NVM_INIT_SCRIPT='export NVM_DIR="$HOME/.nvm"
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion'

# # Check if the NVM init script is already in ~/.zshrc
# if ! grep -q 'nvm.sh' ~/.zshrc; then
#   echo "Adding NVM initialization script to ~/.zshrc..."
#   # Append the NVM initialization script to ~/.zshrc
#   echo "$NVM_INIT_SCRIPT" >> ~/.zshrc
#   source ~/.zshrc
#   echo "NVM initialization script added successfully."
# else
#   echo "NVM initialization script already exists in ~/.zshrc. This is good."
# fi
# nvm --version || brew install nvm