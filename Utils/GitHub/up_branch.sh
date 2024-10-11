#!/bin/zsh

upBranch() {
    # Enable error handling
    set -e

    # Set the default branch to 'main'
    default_branch="main"

    # Get the branch to rebase from, defaulting to 'main' if not provided
    branch="${1:-$default_branch}"

    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is not installed."
        return 1
    fi

    # Check if inside a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Not inside a git repository."
        return 1
    fi

    # Save the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Check for uncommitted changes, including untracked files
    if ! git diff-index --quiet HEAD -- || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        # Uncommitted changes or untracked files exist
        echo "Stashing uncommitted changes, including untracked files."
        git stash push --include-untracked -m "Auto-stash before rebasing onto origin/$branch"
        stash_pushed=true
    else
        echo "No uncommitted changes to stash."
        stash_pushed=false
    fi

    # Fetch updates from origin, including the specified branch
    echo "Fetching updates from origin..."
    git fetch origin "$branch"

    # Check if the specified branch exists on the remote
    if ! git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        echo "Error: Branch '$branch' does not exist on remote 'origin'."
        # Pop the stash if it was pushed
        if [ "$stash_pushed" = true ]; then
            echo "Restoring stashed changes."
            git stash pop
        fi
        return 1
    fi

    # Rebase current branch onto origin/<branch>
    echo "Rebasing '$current_branch' onto 'origin/$branch'..."
    if ! git rebase "origin/$branch"; then
        echo "Merge conflicts detected during rebase."
        echo "----------------------------------------"
        echo "To resolve merge conflicts using VS Code:"
        echo "1. Open the terminal and navigate to your repository."
        echo "2. Run 'code .' to open the repository in VS Code."
        echo "3. Use the Source Control panel to view and resolve conflicts."
        echo "4. After resolving conflicts, in the terminal run:"
        echo "   git add <file(s)>"
        echo "   git rebase --continue"
        echo "----------------------------------------"
        echo "Alternatively, resolve conflicts in the terminal:"
        echo "1. Use 'git status' to see conflicting files."
        echo "2. Edit the files to resolve conflicts."
        echo "3. After resolving conflicts, run:"
        echo "   git add <file(s)>"
        echo "   git rebase --continue"
        echo "----------------------------------------"
        echo "If you want to abort the rebase, run 'git rebase --abort'."
        return 1
    fi

    # Pop the stash to restore changes
    if [ "$stash_pushed" = true ]; then
        echo "Restoring stashed changes."
        if ! git stash pop; then
            echo "Merge conflicts detected when applying stashed changes."
            echo "----------------------------------------"
            echo "To resolve merge conflicts using VS Code:"
            echo "1. Open the terminal and navigate to your repository."
            echo "2. Run 'code .' to open the repository in VS Code."
            echo "3. Use the Source Control panel to view and resolve conflicts."
            echo "4. After resolving conflicts, in the terminal run:"
            echo "   git add <file(s)>"
            echo "   git commit -m 'Resolved conflicts after stash pop'"
            echo "----------------------------------------"
            echo "Alternatively, resolve conflicts in the terminal:"
            echo "1. Use 'git status' to see conflicting files."
            echo "2. Edit the files to resolve conflicts."
            echo "3. After resolving conflicts, run:"
            echo "   git add <file(s)>"
            echo "   git commit -m 'Resolved conflicts after stash pop'"
            echo "----------------------------------------"
            echo "Please resolve the conflicts and commit the changes."
            return 1
        fi
    fi

    # Success message
    echo "Successfully rebased '$current_branch' onto 'origin/$branch'."
}
