
#!/usr/bin/env python3

import os
import subprocess
import json
import argparse
from datetime import datetime

CONFIG_DIR = os.path.join(os.environ.get('XDG_CONFIG_HOME') or os.path.expanduser('~/.config'), 'bin', 'megagit')
JSON_FILE = os.path.join(CONFIG_DIR, 'megagit.json')
WIP_BASE_DIR = os.path.join("u", os.environ.get('USER'), "megagit") if os.environ.get('USER') else None
VERBOSE = False
DRY_RUN = False

def verbose_print(message):
    if VERBOSE:
        print(message)

def run_git_command(repo_path, command_list, check=True):
    verbose_print(f"Executing in '{repo_path}': git {' '.join(command_list)}")
    if not DRY_RUN:
        process = subprocess.run(['git', '-C', repo_path] + command_list, capture_output=True, text=True)
        if check and process.returncode != 0:
            print(f"Error in '{repo_path}': git {' '.join(command_list)}")
            verbose_print(f"Stdout: {process.stdout}")
            verbose_print(f"Stderr: {process.stderr}")
        return process
    else:
        return subprocess.CompletedProcess(args=['git'] + command_list, returncode=0, stdout="Dry run", stderr="")

def find_git_repos():
    repos = []
    for root, dirs, files in os.walk('.'):
        if '.git' in dirs:
            repos.append(os.path.abspath(root))
            dirs.remove('.git')
    return sorted(list(set(repos)))

def is_http_remote(repo_path):
    process = run_git_command(repo_path, ['remote', 'get-url', 'origin'], check=False)
    return process and process.returncode == 0 and process.stdout.strip().startswith('http')

def is_ssh_remote(repo_path):
    process = run_git_command(repo_path, ['remote', 'get-url', 'origin'], check=False)
    return process and process.returncode == 0 and process.stdout.strip().startswith('git@')

def is_repo_clean(repo_path):
    diff_process = run_git_command(repo_path, ['diff', '--quiet'], check=False)
    staged_process = run_git_command(repo_path, ['diff', '--staged', '--quiet'], check=False)
    return diff_process.returncode == 0 and staged_process.returncode == 0

def create_wip_branch(repo_path):
    original_branch = run_git_command(repo_path, ['symbolic-ref', '--short', 'HEAD'], check=False).stdout.strip()
    timestamp = datetime.now().strftime("%Y%m%d%H%M")
    wip_branch_name = os.path.join("wip", os.environ.get('USER'), f"{timestamp}-{original_branch}") if os.environ.get('USER') else f"wip/unknown/{timestamp}-{original_branch}"
    if WIP_BASE_DIR:
        full_wip_branch_name = os.path.join(WIP_BASE_DIR, f"{timestamp}-{original_branch}")
        verbose_print(f"  Creating WIP branch: {full_wip_branch_name}")
        run_git_command(repo_path, ['checkout', '-b', full_wip_branch_name])
    else:
        print("Warning: USER environment variable not set, using a simpler WIP branch name.")
        verbose_print(f"  Creating WIP branch: {wip_branch_name}")
        run_git_command(repo_path, ['checkout', '-b', wip_branch_name])

def handle_wip_dirty(repo_path):
    print(f"  Repository '{repo_path}' is dirty.")
    if not DRY_RUN:
        create_wip_branch(repo_path)
    else:
        verbose_print(f"  Dry-run: Would create a WIP branch for dirty repo '{repo_path}'.")

def handle_wip_clean(repo_path):
    print(f"  Repository '{repo_path}' is clean.")
    rebase_repo(repo_path)
    if not DRY_RUN:
        current_branch = run_git_command(repo_path, ['symbolic-ref', '--short', 'HEAD'], check=False).stdout.strip()
        remote_branch_process = run_git_command(repo_path, ['rev-parse', '--abbrev-ref', '--symbolic-full-name', "@{u}"], check=False)
        remote_branch = remote_branch_process.stdout.strip() if remote_branch_process.returncode == 0 else None

        if remote_branch:
            verbose_print(f"  Pushing '{current_branch}' to '{remote_branch}'.")
            push_process = run_git_command(repo_path, ['push', 'origin', current_branch], check=False)
            if push_process.returncode != 0:
                print(f"  Warning: Problems encountered during push in '{repo_path}'. Creating WIP branch.")
                create_wip_branch(repo_path)
        else:
            verbose_print(f"  No remote tracking branch found for '{current_branch}' in '{repo_path}'. Skipping push.")
    else:
        verbose_print(f"  Dry-run: Would rebase and potentially push clean repo '{repo_path}'.")

def rebase_repo(repo_path):
    verbose_print(f"  Rebasing branches with remote equivalents in '{repo_path}'.")
    branches_process = run_git_command(repo_path, ['for-each-ref', '--format=%(refname:short)', 'refs/heads'], check=False)
    if branches_process.returncode == 0:
        local_branches = branches_process.stdout.strip().splitlines()
        current_branch = run_git_command(repo_path, ['symbolic-ref', '--short', 'HEAD'], check=False).stdout.strip()

        for branch in local_branches:
            remote_branch_process = run_git_command(repo_path, ['rev-parse', '--abbrev-ref', '--symbolic-full-name', f"origin/{branch}"], check=False)
            remote_branch = remote_branch_process.stdout.strip() if remote_branch_process.returncode == 0 else None

            if remote_branch:
                verbose_print(f"    Rebasing '{branch}' onto '{remote_branch}'.")
                if not DRY_RUN:
                    run_git_command(repo_path, ['checkout', branch], check=True)
                    rebase_process = run_git_command(repo_path, ['rebase', f"origin/{branch}"], check=False)
                    if rebase_process.returncode != 0:
                        print(f"    Warning: Conflicts or errors during rebase of '{branch}' in '{repo_path}'. You may need to resolve them manually.")
                else:
                    verbose_print(f"    Dry-run: Would rebase '{branch}' onto '{remote_branch}'.")

        if not DRY_RUN and current_branch:
            run_git_command(repo_path, ['checkout', current_branch], check=False)

def fetch_repo(repo_path):
    verbose_print(f"  Fetching in '{repo_path}'.")
    run_git_command(repo_path, ['fetch', '--all'] + (['-v'] if VERBOSE else []))

def pull_repo(repo_path):
    if is_repo_clean(repo_path):
        print(f"  Pulling all remote branches in clean repo '{repo_path}'.")
        run_git_command(repo_path, ['pull', '--all'] + (['-v'] if VERBOSE else []))
    else:
        print(f"  Warning: Repository '{repo_path}' is not clean. Skipping pull.")

def check_unchecked_files(repo_path):
    process = run_git_command(repo_path, ['ls-files', '--others', '--exclude-standard'], check=False)
    unchecked_files = [f for f in process.stdout.strip().splitlines() if f]
    if unchecked_files:
        print(f"  Unchecked files in '{repo_path}':")
        for f in unchecked_files:
            print(f"    {f}")
    elif VERBOSE:
        verbose_print(f"  No unchecked files in '{repo_path}'.")

def init_repos():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    http_repos = []
    ssh_repos = []
    for repo_path in find_git_repos():
        if is_http_remote(repo_path):
            http_repos.append(repo_path)
            verbose_print(f"Found HTTP repo: {repo_path}")
            fetch_repo(repo_path)
        elif is_ssh_remote(repo_path):
            ssh_repos.append(repo_path)
            verbose_print(f"Found SSH repo: {repo_path}")

    data = {"http_repos": http_repos, "ssh_repos": ssh_repos}
    with open(JSON_FILE, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Git repository types saved to {JSON_FILE}")

def main():
    global VERBOSE
    global DRY_RUN

    parser = argparse.ArgumentParser(description="Manage multiple Git repositories.")
    parser.add_argument("--init", action="store_true", help="Initialize and categorize Git repositories.")
    parser.add_argument("--fetch", action="store_true", help="Fetch in all Git repositories.")
    parser.add_argument("--pull", action="store_true", help="Pull in clean Git repositories.")
    parser.add_argument("--wip", action="store_true", help="Handle work-in-progress.")
    parser.add_argument("--dry-run", action="store_true", help="Perform a dry run without making changes.")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output.")
    args = parser.parse_args()

    VERBOSE = args.verbose
    DRY_RUN = args.dry_run

    action_performed = False

    if args.init:
        action_performed = True
        init_repos()
    if args.fetch:
        action_performed = True
        print("Fetching all repositories...")
        for repo_path in find_git_repos():
            fetch_repo(repo_path)
    if args.pull:
        action_performed = True
        print("Pulling in clean repositories...")
        for repo_path in find_git_repos():
            pull_repo(repo_path)
    if args.wip:
        action_performed = True
        print("Processing work-in-progress...")
        for repo_path in find_git_repos():
            print(f"Processing repository: {repo_path}")
            if not is_repo_clean(repo_path):
                handle_wip_dirty(repo_path)
            else:
                handle_wip_clean(repo_path)
            if not DRY_RUN:
                check_unchecked_files(repo_path)
            elif VERBOSE:
                verbose_print(f"Dry-run: Would check for unchecked files in '{repo_path}'.")
            print("")

    if not action_performed:
        parser.print_help()

if __name__ == "__main__":
    main()
