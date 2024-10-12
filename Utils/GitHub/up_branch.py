#!/usr/bin/env python3
"""
Rebase the current branch onto the specified branch from the remote.

Usage:
    up_branch(branch='main')

Example:
    up_branch('main')
    up_branch('master')
    up_branch('develop')
    up_branch('feature/branch-name')
    up_branch('bugfix/branch-name')
    up_branch('release/branch-name')
    up_branch('hotfix/branch-name')
"""

import subprocess
import sys
import shutil


def run_command(command, capture_output=False, check=True):
    """
    Helper function to run shell commands.
    """
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=check,
            stdout=subprocess.PIPE if capture_output else None,
            stderr=subprocess.PIPE if capture_output else None,
            text=True
        )
        if capture_output:
            return result.stdout.strip()
        return None
    except subprocess.CalledProcessError as e:
        if capture_output and e.stdout:
            return e.stdout.strip()
        else:
            raise e


def up_branch(branch='main'):
    """
    Rebase the current branch onto the specified branch from the remote.
    """
    if not shutil.which('git'):
        print("Error: Git is not installed.")
        sys.exit(1)

    # Check if inside a Git repository
    try:
        run_command('git rev-parse --is-inside-work-tree', check=True)
    except subprocess.CalledProcessError:
        print("Error: Not inside a Git repository.")
        sys.exit(1)

    # Check if the specified branch exists on the remote
    branch_exists = False
    try:
        run_command(
            f'git ls-remote --exit-code --heads origin {branch}', check=True)
        branch_exists = True
    except subprocess.CalledProcessError:
        pass

    if not branch_exists:
        print(f"Error: Branch '{branch}' does not exist on remote 'origin'.")
        # Get the default branch from remote
        try:
            remote_info = run_command(
                'git remote show origin', capture_output=True)
            remote_default_branch = None
            for line in remote_info.split('\n'):
                if 'HEAD branch' in line:
                    remote_default_branch = line.split(':')[-1].strip()
                    break
        except subprocess.CalledProcessError:
            remote_default_branch = None

        if remote_default_branch:
            print(f"The default branch on remote 'origin' is '{
                  remote_default_branch}'.")
            print("Please specify the branch to rebase onto:")
            print(f"Example:  up_branch('{remote_default_branch}')")
        else:
            print("Could not determine the default branch on remote 'origin'.")
            print("Please specify the branch to rebase onto.")
        sys.exit(1)

    # Save the current branch name
    current_branch = run_command(
        'git rev-parse --abbrev-ref HEAD', capture_output=True)

    # Check for uncommitted changes, including untracked files
    try:
        run_command('git diff-index --quiet HEAD --', check=True)
        uncommitted_changes = False
    except subprocess.CalledProcessError:
        uncommitted_changes = True

    untracked_files = run_command(
        'git ls-files --others --exclude-standard', capture_output=True)
    if untracked_files:
        uncommitted_changes = True

    stash_pushed = False
    if uncommitted_changes:
        # Uncommitted changes or untracked files exist
        print("Stashing uncommitted changes, including untracked files.")
        run_command(
            f'git stash push --include-untracked -m "Auto-stash before rebasing onto origin/{branch}"')
        stash_pushed = True
    else:
        print("No uncommitted changes to stash.")
        stash_pushed = False

    # Fetch updates from origin, including the specified branch
    print("Fetching updates from origin...")
    try:
        run_command(f'git fetch origin {branch}', check=True)
    except subprocess.CalledProcessError:
        print("Error: Failed to fetch from origin.")
        if stash_pushed:
            print("Restoring stashed changes.")
            run_command('git stash pop')
        sys.exit(1)

    # Rebase current branch onto origin/<branch>
    print(f"Rebasing '{current_branch}' onto 'origin/{branch}'...")
    try:
        run_command(f'git rebase origin/{branch}', check=True)
    except subprocess.CalledProcessError:
        print("Merge conflicts detected during rebase.")
        print("----------------------------------------")
        print("To resolve merge conflicts using VS Code:")
        print("1. Open the terminal and navigate to your repository.")
        print("2. Run 'code .' to open the repository in VS Code.")
        print("3. Use the Source Control panel to view and resolve conflicts.")
        print("4. After resolving conflicts, in the terminal run:")
        print("   git add <file(s)>")
        print("   git rebase --continue")
        print("----------------------------------------")
        print("Alternatively, resolve conflicts in the terminal:")
        print("1. Use 'git status' to see conflicting files.")
        print("2. Edit the files to resolve conflicts.")
        print("3. After resolving conflicts, run:")
        print("   git add <file(s)>")
        print("   git rebase --continue")
        print("----------------------------------------")
        print("If you want to abort the rebase, run 'git rebase --abort'.")
        sys.exit(1)

    # Pop the stash to restore changes
    if stash_pushed:
        print("Restoring stashed changes.")
        try:
            run_command('git stash pop', check=True)
        except subprocess.CalledProcessError:
            print("Merge conflicts detected when applying stashed changes.")
            print("----------------------------------------")
            print("To resolve merge conflicts using VS Code:")
            print("1. Open the terminal and navigate to your repository.")
            print("2. Run 'code .' to open the repository in VS Code.")
            print("3. Use the Source Control panel to view and resolve conflicts.")
            print("4. After resolving conflicts, in the terminal run:")
            print("   git add <file(s)>")
            print("   git commit -m 'Resolved conflicts after stash pop'")
            print("----------------------------------------")
            print("Alternatively, resolve conflicts in the terminal:")
            print("1. Use 'git status' to see conflicting files.")
            print("2. Edit the files to resolve conflicts.")
            print("3. After resolving conflicts, run:")
            print("   git add <file(s)>")
            print("   git commit -m 'Resolved conflicts after stash pop'")
            print("----------------------------------------")
            print("Please resolve the conflicts and commit the changes.")
            sys.exit(1)

    # Success message
    print(f"Successfully rebased '{current_branch}' onto 'origin/{branch}'.")


if __name__ == '__main__':
    # Check if a branch name was provided as an argument
    if len(sys.argv) > 1:
        BRANCH_NAME = sys.argv[1]
    else:
        BRANCH_NAME = 'main'

    up_branch(BRANCH_NAME)
