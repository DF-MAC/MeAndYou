use std::env;
use std::process::{Command, exit};
use std::io::{self, Write};

fn run_command(command: &str, args: &[&str]) -> Result<(), String> {
    let status = Command::new(command)
        .args(args)
        .status()
        .map_err(|_| format!("Failed to execute command: {} {:?}", command, args))?;

    if !status.success() {
        return Err(format!("Command `{}` with arguments {:?} failed.", command, args));
    }
    Ok(())
}

fn command_output(command: &str, args: &[&str]) -> Result<String, String> {
    let output = Command::new(command)
        .args(args)
        .output()
        .map_err(|_| format!("Failed to execute command: {} {:?}", command, args))?;

    if !output.status.success() {
        return Err(format!("Command `{}` with arguments {:?} failed.", command, args));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn main() {
    // Set the default branch to 'main'
    let default_branch = "main";
    let branch = env::args().nth(1).unwrap_or(default_branch.to_string());

    // Check if Git is installed
    if run_command("git", &["--version"]).is_err() {
        eprintln!("Error: Git is not installed.");
        exit(1);
    }

    // Check if inside a Git repository
    if run_command("git", &["rev-parse", "--is-inside-work-tree"]).is_err() {
        eprintln!("Error: Not inside a Git repository.");
        exit(1);
    }

    // Check if 'branch' exists on remote
    if run_command("git", &["ls-remote", "--exit-code", "--heads", "origin", &branch]).is_err() {
        // 'branch' doesn't exist on remote
        eprintln!("Error: Branch '{}' does not exist on remote 'origin'.", branch);
        match command_output("git", &["remote", "show", "origin"]) {
            Ok(output) => {
                let lines: Vec<&str> = output.lines().collect();
                for line in lines {
                    if line.contains("HEAD branch:") {
                        let remote_default_branch = line.split(':').nth(1).unwrap_or("").trim();
                        println!("The default branch on remote 'origin' is '{}'.", remote_default_branch);
                        println!("Please specify the branch to rebase onto:");
                        println!("Example: up_branch {}");
                        exit(1);
                    }
                }
            }
            Err(_) => {
                eprintln!("Could not determine the default branch on remote 'origin'.");
                eprintln!("Please specify the branch to rebase onto.");
                exit(1);
            }
        }
    }

    // Save the current branch name
    let current_branch = match command_output("git", &["rev-parse", "--abbrev-ref", "HEAD"]) {
        Ok(branch) => branch,
        Err(e) => {
            eprintln!("{}", e);
            exit(1);
        }
    };

    // Check for uncommitted changes, including untracked files
    let stash_pushed = if run_command("git", &["diff-index", "--quiet", "HEAD", "--"]).is_err()
        || !command_output("git", &["ls-files", "--others", "--exclude-standard"]).unwrap_or_default().is_empty()
    {
        println!("Stashing uncommitted changes, including untracked files.");
        if run_command("git", &["stash", "push", "--include-untracked", "-m", "Auto-stash before rebasing"]).is_err() {
            eprintln!("Failed to stash changes.");
            exit(1);
        }
        true
    } else {
        println!("No uncommitted changes to stash.");
        false
    };

    // Fetch updates from origin
    println!("Fetching updates from origin...");
    if run_command("git", &["switch", &branch]).is_err() || run_command("git", &["pull", "origin", &branch]).is_err() {
        eprintln!("Failed to switch to branch '{}' or pull latest changes.", branch);
        if stash_pushed {
            eprintln!("Restoring stashed changes.");
            run_command("git", &["stash", "pop"]).ok();
        }
        exit(1);
    }
    run_command("git", &["switch", "-"]).unwrap_or_else(|e| {
        eprintln!("{}", e);
        exit(1);
    });

    // Rebase current branch onto origin/<branch>
    println!("Rebasing '{}' onto 'origin/{}'.", current_branch, branch);
    if run_command("git", &["rebase", &format!("origin/{}", branch)]).is_err() {
        eprintln!("Merge conflicts detected during rebase. Please resolve them and continue.");
        exit(1);
    }

    // Pop the stash if it was pushed
    if stash_pushed {
        println!("Restoring stashed changes.");
        if run_command("git", &["stash", "pop"]).is_err() {
            eprintln!("Merge conflicts detected when applying stashed changes. Please resolve them and continue.");
            exit(1);
        }
    }

    println!("Successfully rebased '{}' onto 'origin/{}'.", current_branch, branch);
}