#!/bin/zsh

upBranch() {
    # Set the default branch to 'main'
    default_branch="main"

    # Check if 'main' exists on remote
    if ! git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
        # 'main' doesn't exist, get default branch from remote
        default_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        if [ -z "$default_branch" ]; then
            echo "Error: Could not determine the default branch from the remote repository."
            return 1
        fi
        echo "Default branch 'main' not found. Using remote default branch Example:'$default_branch'."
    fi

    # Get the branch to rebase from, defaulting to the determined default branch
    branch="${1:-$default_branch}"

    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git is not installed."
        return 1
    fi

    # Check if inside a Git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Not inside a Git repository."
        return 1
    fi

    # Check if 'origin/main' exists
    if ! git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        # 'main' doesn't exist on remote
        echo "Error: Branch '$branch' does not exist on remote 'origin'."
        # Get the default branch from remote
        remote_default_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        if [ -n "$remote_default_branch" ]; then
            echo "The default branch on remote 'origin' is '$remote_default_branch'."
            echo "Please specify the branch to rebase onto:"
            echo "  upBranch $remote_default_branch"
        else
            echo "Could not determine the default branch on remote 'origin'."
            echo "Please specify the branch to rebase onto."
        fi
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
    if ! git fetch origin "$branch"; then
        echo "Error: Failed to fetch from origin."
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
